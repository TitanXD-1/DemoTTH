/**

* @description :  EDGE_SalesManagerOutletShareBatch

* @purpose : Share Outlets with Sales Managers by Outlet Member and Account Team

* @history :

* Version    Developer                Date             User Story/Purpose

*  1.1       Dipanjan D             02/09/2019        ES20-3836 - Sales force Sharing Rules - Technical
*  1.2       Kapil Baliyan          30/12/2019        Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*  1.3       Sandip Ghosh           29/10/2020        ES20-8778 (Batch to add Activation Specialists to outlet)
*  1.4       Prasanth T             27/04/2022        ES20-12358(Removal of Activation Specialist creation in OutletMember and AccountTeamMember)
*  1.5       Rajarshri/Mayukh       08/11/2022        ES20-13475/ES20-13505 - Fix for Batch Failure
*  1.6       Mayukh SRoy            06/12/2022        ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.7       Mayukh SRoy            01/02/2023        ES20-13558 - Change in Existing Batch Logic To Add Sales Manager to a region with more than 10000 accounts_ SFDC_ Technical Debt
*/

public class EDGE_SalesManagerOutletShareBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';   
    Id marketBatchJobId;
    Id salesrRegionRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Region').getRecordTypeId();
    Id qualityHierarchyRecordId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
	Map<Id,Id> thmUserMap = new Map<Id,Id>();
    Set<Id> usrSet = new Set<Id>();

    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }

    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        String countryCode; 
        String active;
        Date currentDate;
        String strQuery;
        countryCode = batchSetting.Country_Code__c;
		active = 'Active';
       	currentDate = Date.today();
        Set<Id> regionSet = new Set<Id>();
        
        //get THM whose start date is toda
        for(Territory_Hierarchy_Member__c thm : [Select Id,Name,Territory_Hierarchy__c,User__c,User__r.IsActive,User__r.Profile.Name from Territory_Hierarchy_Member__c 
                                                 where Start_Date__c =:currentDate and Territory_Hierarchy__r.Geography__r.Code__c =:countryCode and User__c != Null and 
                                                 User__r.IsActive = true WITH SECURITY_ENFORCED]){
            thmUserMap.put(thm.Territory_Hierarchy__c,thm.User__c);
            usrSet.add(thm.User__c);
        }
        
        if(usrSet!=Null && usrSet.size()>0){
            regionSet = thmUserMap.keySet();
            strQuery = 'SELECT Outlet__c, Territory__c, Territory__r.Region__c,Territory__r.RecordTypeId,Territory__r.Region__r.RecordTypeId FROM Outlet_Territory__c WHERE ' + 
                     + 'Outlet__r.Country_Code__c =:countryCode And Active__c =:active and Outlet__c != Null and Territory__r.Region__c != Null and ' +
                     + '(Territory__r.Region__r.RecordTypeId = :salesrRegionRecTypeId or Territory__r.Region__r.RecordTypeId = :qualityHierarchyRecordId) ' +
                     + 'and Territory__r.Region__c IN :regionSet';
        }
        else{
            strQuery = 'SELECT Id from Outlet_Territory__c LIMIT 0';
        }
        return Database.getQueryLocator(strQuery);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Outlet_Territory__c> oTList){
        try {
            List<Outlet_Member__c> outletMemberListToInsert = new List<Outlet_Member__c>();
            List<AccountTeamMember> accountTeamToInsList = new List<AccountTeamMember>();
            
            if(isNotNull(oTList)){
                outletMemberListToInsert = EDGE_SalesManagerOutletShareHelper.getOutletMemberList(oTList,thmUserMap,usrSet);
            }
            
            //DML To Insert OutletMembers and ContactSharing
            if(isNotNull(outletMemberListToInsert)){
                Database.insert(outletMemberListToInsert,false);
                accountTeamToInsList = EDGE_OutletMemberAccountTeamSync.createAccountTeamMember(outletMemberListToInsert);
            }
            
            //DML To Insert AccountTeamMembers
            if(isNotNull(accountTeamToInsList)){
                Database.insert(accountTeamToInsList,false);
            }

            EDGE_UtilityClass.printGovLimits(91);  
            
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG,'@@Exception' + ex.getMessage());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }   
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_SalesManagerOutletShareBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
    //Common Null Check to reduce PMD violations 
    public static Boolean isNotNull(List<SObject> objList){
        Boolean isNotNull = false;
        if(objList!=Null && objList.size()>0){
            isNotNull = true;
        }
        return isNotNull;
    }
}