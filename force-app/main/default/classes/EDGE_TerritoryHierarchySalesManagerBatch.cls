/**

* @description :  EDGE_TerritoryHierarchySalesManagerBatch

* @purpose : Sales Manager Assignment to Sales Reps from Territory Hierarchy Member

* @history :

* Version    Developer         Date             User Story/Purpose

*  1.1      Dipanjan D       25/07/2019        ES20-3211 - Sales Manager Assignment to Sales Reps
*  1.2      Manikant P       06/03/2020        ES20-7406 - Logic added to assign approval access to sales manager in personlInformatin object record.

*/

public class EDGE_TerritoryHierarchySalesManagerBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        Id regionRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Region').getRecordTypeId();
        //ES20-9831
        Id qualityHierarchyRecordId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Quality_Territory_Hierarchy').getRecordTypeId();
        String countryCode = batchSetting.Country_Code__c;
        Date currentDate = Date.today();
        Date yesterdayDate = currentDate.addDays(-1);
        
        String strQuery = 'SELECT Id, Start_Date__c, Territory_Hierarchy__c, End_Date__c, Status__c, Territory_Hierarchy__r.Geography__r.Code__c, User__c FROM Territory_Hierarchy_Member__c' +
            ' WHERE Start_Date__c <= :currentDate AND (End_Date__c >= :yesterdayDate OR End_Date__c=null) AND (Territory_Hierarchy__r.recordTypeId = :regionRecTypeId OR Territory_Hierarchy__r.recordTypeId = :qualityHierarchyRecordId) AND Territory_Hierarchy__r.Geography__r.Code__c = :countryCode';
        
        return Database.getQueryLocator(strQuery);
    }   
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Territory_Hierarchy_Member__c> terrHierMemList){
        Set<Id> regionIds = new Set<Id>();        
        Map<Id, Id> activeMgrWithRegionMap = new Map<Id, Id>();
        Map<Id, Id> inactiveMgrWithRegionMap = new Map<Id, Id>();
        Map<Id, Id> repsWithRegionMap = new Map<Id, Id>();
        List<personal_Information__c> pInfoListToUpdate = new List<personal_Information__c>();
        List<personal_information__share> personInfoshareList = new list<personal_information__share>();
        Map<Id, User> userMapToUpdate = new Map<Id, User>();
        List<Coaching_Report__Share> crShareList = new List<Coaching_Report__Share>();
        List<Coaching_Report__c> coachingReportListToUpdate = new List<Coaching_Report__c>();
        list<String> territoryTypes = new list<String>();
        
        //Get Custom Label for Territory Types
        territoryTypes = System.Label.Edge_Territory_Types.split(',');
        
        system.debug('@@territoryTypes'+territoryTypes);
        
        for(Territory_Hierarchy_Member__c thm : terrHierMemList){
            regionIds.add(thm.Territory_Hierarchy__c);
            if(thm.Status__c == 'Active'){
                activeMgrWithRegionMap.put(thm.Territory_Hierarchy__c, thm.User__c);
            }else{
                inactiveMgrWithRegionMap.put(thm.Territory_Hierarchy__c, thm.User__c);
            }
        }
        for(Territory_Member__c terrMem : [SELECT Id, User__c, Territory__r.Region__c FROM Territory_Member__c WHERE Territory__r.Region__c IN :regionIds AND Territory__r.Territory_Type__c IN : territoryTypes AND Type__c = 'Primary' AND (End_Date__c >= :Date.today() OR End_Date__c=null)]){ 
            repsWithRegionMap.put(terrMem.User__c, terrMem.Territory__r.Region__c);
        }
        for(User salesRep : [SELECT Id, ManagerId FROM User WHERE Id IN :repsWithRegionMap.keySet()]){
            if(salesRep.ManagerId != null && inactiveMgrWithRegionMap.containsKey(repsWithRegionMap.get(salesRep.Id)) && salesRep.ManagerId == inactiveMgrWithRegionMap.get(repsWithRegionMap.get(salesRep.Id))){
                salesRep.ManagerId = null;
                userMapToUpdate.put(salesRep.Id, salesRep);
            }
            if(salesRep.ManagerId == null || (activeMgrWithRegionMap.containsKey(repsWithRegionMap.get(salesRep.Id)) && salesRep.ManagerId != activeMgrWithRegionMap.get(repsWithRegionMap.get(salesRep.Id)))){
                salesRep.ManagerId = activeMgrWithRegionMap.get(repsWithRegionMap.get(salesRep.Id));
                userMapToUpdate.put(salesRep.Id, salesRep);
            }
        }
        
        //======================= Logic added for ES20-6524 ============================
   
        for(personal_Information__c pInfoRec : [Select id,sales_manager__c,User__c,Geography__c FROM personal_Information__c where User__c IN : userMapToUpdate.keySet() ]){
            if(userMapToUpdate.containsKey(pInfoRec.User__c)){
                pInfoRec.Sales_Manager__c = userMapToUpdate.get(pInfoRec.User__c).ManagerId; 
                pInfoListToUpdate.add(pInfoRec);
            } 
        }
        for(personal_Information__c pInfo : pInfoListToUpdate){
            if(pInfo.Sales_Manager__c != null){
                personal_information__share pInfoShareManger = new  personal_information__share();
                pInfoShareManger.ParentId = pInfo.ID;
                pInfoShareManger.UserOrGroupId =pInfo.Sales_Manager__c;
                pInfoShareManger.AccessLevel = 'Read';
                personInfoshareList.add(pInfoShareManger); 
            }
        }
        
        //=======================END ================================
        
        System.debug('pInfoShareManger '+personInfoshareList);
        system.debug('pInfoListToUpdate '+pInfoListToUpdate);
        
        for(Coaching_Report__c cr : [SELECT Id, Current_Sales_Manager__c, Sales_Representative__c FROM Coaching_Report__c WHERE Sales_Representative__c IN: userMapToUpdate.keySet()]){
            if(userMapToUpdate.get(cr.Sales_Representative__c).ManagerId != null){
                Id newManagerId = userMapToUpdate.get(cr.Sales_Representative__c).ManagerId;
                cr.ownerId = newManagerId;
                cr.Original_Sales_Manager__c = cr.Current_Sales_Manager__c;
                cr.Current_Sales_Manager__c = newManagerId; 
                coachingReportListToUpdate.add(cr);                 
            }
        }
        
        for(Coaching_Report__c cr : coachingReportListToUpdate){
            if(cr.Sales_Representative__c != null){
                Coaching_Report__Share crShareRep = new Coaching_Report__Share();
                crShareRep.ParentId = cr.Id;
                crShareRep.UserOrGroupId = cr.Sales_Representative__c;
                crShareRep.AccessLevel = 'Read';
                crShareList.add(crShareRep);                
            }          
        }
        
        try {            
            if(userMapToUpdate != null && userMapToUpdate.values().size() > 0){
                database.update (userMapToUpdate.values());             
            }   
            if(coachingReportListToUpdate != null && coachingReportListToUpdate.size() > 0){
                database.update (coachingReportListToUpdate, false);
            }
            if(crShareList != null && crShareList.size()>0){
                Database.insert(crShareList,false);
            }  
            if(pInfoListToUpdate != null && pInfoListToUpdate.size() > 0){
                database.update(pInfoListToUpdate,false);
            }
            if(personInfoshareList != null && personInfoshareList.size() > 0){
                database.insert(personInfoshareList,false); 
            }
        }catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex){
            system.debug('@@Exception' + ex.getMessage());
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TerritoryHierarchySalesManagerBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }  
}