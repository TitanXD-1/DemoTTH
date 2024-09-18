/*
* @description :  EDGE_SalesManagerOutletRemoveBatch

* @purpose : Share Outlets with Sales Managers by Outlet Member and Account Team
* @history :

* Version    Developer         Date           User Story/Purpose
*  1.1      Dipanjan D       05/09/2019       ES20-3836 - Sales force Sharing Rules - Technical
*  1.2	    Sandip Ghosh     28/10/2020       ES20-8778 (Batch to add Activation Specialists to outlet)
*  1.3 		Juned Khan	     04/12/2020		  ES20-8780(Batch to remove Activation Specialists from outlet)
*  1.4 		Subhodeep Sarkar 26/04/2022		  ES20-12425(Removal of batch logic to remove Activation Specialist)
*  1.5      Mayukh SRoy      06/12/2022       ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.6      Mayukh SRoy      22/02/2023       ES20-13559 - Change in Existing Batch Logic To Remove and Change Sales Manager to region with more than 10000 accounts_ SFDC_ Technical Debt
*/

public class EDGE_SalesManagerOutletRemoveBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';   
    Id marketBatchJobId;
    Id salesRegionRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Region').getRecordTypeId();
    Id qualityHierarchyRecordId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
    Map<Id,Id> thmUserMap = new Map<Id,Id>();

    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }

    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        String countryCode = batchSetting.Country_Code__c; 
        String active;
        Date currentDate = Date.today();
        Date yesterdayDate = currentDate.addDays(-1);
        String strQuery;
		active = 'Active';
        Set<Id> regionSet = new Set<Id>();
        
        //get THM whose end date is yesterday
        for(Territory_Hierarchy_Member__c thm : [Select Id,Name,Territory_Hierarchy__c,User__c,User__r.IsActive,User__r.Profile.Name from Territory_Hierarchy_Member__c 
                                                 where End_Date__c = :yesterdayDate and Territory_Hierarchy__r.Geography__r.Code__c = :countryCode and User__c != Null WITH SECURITY_ENFORCED]){
            thmUserMap.put(thm.Territory_Hierarchy__c,thm.User__c);
            regionSet.add(thm.Territory_Hierarchy__c);
        }
        
        if(regionSet != Null && regionSet.size()>0){
            strQuery = 'SELECT Outlet__c, Territory__c, Territory__r.Region__c,Territory__r.RecordTypeId,Territory__r.Region__r.RecordTypeId FROM Outlet_Territory__c WHERE ' + 
                     + 'Outlet__r.Country_Code__c =:countryCode And Active__c =:active and Outlet__c != Null and Territory__r.Region__c != Null and ' +
                     + '(Territory__r.Region__r.RecordTypeId = :salesRegionRecTypeId or Territory__r.Region__r.RecordTypeId = :qualityHierarchyRecordId) ' +
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
            Set<Id> outletIdSet = new Set<Id>();
            Set<String> outletUserKeyList = new Set<String>();
            List<Outlet_Member__c> outletMemberListToDelete = new List<Outlet_Member__c>();
            List<AccountTeamMember> accTeamMemberListToDelete = new List<AccountTeamMember>();
            
            //create outletUserKeyList from each OT
            for(Outlet_Territory__c ot : oTList){
                if(salesManagerRemovalCheck(ot.Territory__r.Region__c)){
                    outletIdSet.add(ot.Outlet__c);
                    String key = thmUserMap.get(ot.Territory__r.Region__c)+'_'+ot.Outlet__c;
                    outletUserKeyList.add(key);
                }
            }
            
            //get Outlet Member records that needs to be deleted
            outletMemberListToDelete = getoutletMemberToDelete(outletIdSet,outletUserKeyList);
            
            //Get the AccountTeamMembers to Delete and Delete the Outlet Members
            if(isNotNull(outletMemberListToDelete)){
                accTeamMemberListToDelete = EDGE_OutletMemberAccountTeamSync.deleteAccountTeamMember(outletMemberListToDelete);
                Database.delete(outletMemberListToDelete,false);
            }
            
            //Delete the AccountTeamMembers
            if(isNotNull(accTeamMemberListToDelete)){
                Database.delete(accTeamMemberListToDelete,false);
            }

            EDGE_UtilityClass.printGovLimits(94);  
            
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG,'@@Exception ' + ex.getMessage());
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_SalesManagerOutletRemoveBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
    
    
    //Fetching Outlet Members for Selected Outlets to delete
    public List<Outlet_Member__c> getoutletMemberToDelete(Set<Id> outletIdSet,Set<String> outletUserKeyList){
        List<Outlet_Member__c> outletMemberListToDelete = new List<Outlet_Member__c>();
        for(Outlet_Member__c outletMem : [SELECT Id, Outlet__c, User__c FROM Outlet_Member__c WHERE Outlet__c IN :outletIdSet AND User__c IN :thmUserMap.values()]){
            String key = outletMem.User__c + '_' + outletMem.Outlet__c;
            if(outletUserKeyList.contains(key)){
                outletMemberListToDelete.add(outletMem);
            }
        }
        return outletMemberListToDelete;
    }
    
    
    
    //Common Null Check to reduce PMD violations 
    public static Boolean isNotNull(List<SObject> objList){
        Boolean isNotNull = false;
        if(objList != Null && objList.size() > 0){
            isNotNull = true;
        }
        return isNotNull;
    }
        
    
    
    //Check if the salesmanager needs to be removed for this OT
    public boolean salesManagerRemovalCheck(String region){
        Boolean isValid = false;
        if(thmUserMap != Null && thmUserMap.containsKey(region) && thmUserMap.get(region) != Null){
            isValid = true;
        }
        return isValid;
    }
}