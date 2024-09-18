/**
* @Name: EDGE_SalesManagerKPIAchievementBatch

* @Req: Calculate the Terrritory level Actual Volume and Target
* @User Story : ES20-4971, ES20-4955, ES20-4980, ES20-4961, ES20-4981

* @History                                                            
                                                           
* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Dipanjan D          03/02/2020      ES20-7371  
*  2.0 		   Juned Khan		   28/09/2020	   ES20-8415 Aggregation of Virtual call count region level_Salesforce_Virtual call
*  3.0         Anand Uppalapati    02/11/2021      ES20-11187 
*  4.0         Anamika Shukla      02/11/2021      ES20-11202
*  5.0         Monalisa Halder     22/03/2022      ES20-12221

*  6.0         Prasanth T		   25/03/2022	   ES20-12218

*  7.0		   Supriya G			29/04/2022     ES20-12223
*  8.0         Anand                29/04/2022     ES20-12233 (Commented line 60 activationTerritoryList in execute method)

**/

public class EDGE_SalesManagerKPIAchievementBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode = '';
    String languageName = '';
    Id marketBatchJobId; //Update ES20-6594
    Set<Id> terrHierSet = new Set<Id>();//global set for handling territory hierarchy ids
    
    //Get Record Type ID
    Id territoryRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Territory_KPI').getRecordTypeId();
    Id territoryHierarchyRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Territory_Hierarchy_KPI').getRecordTypeId();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        boolean pendingForBatch = true;//filter added in scope query to process those Territory Hierarchies which have Pending_For_Batch__c as true
        
        //Query String   
        //ES20-12223 -> Removed the check (RecordType.Name = \'Activation Territory\') from the below query    
        String queryString = 'SELECT ID, Geography__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c, Plan_Calls_Compliance_Target__c, Outlet_Visit_Compliance_Target__c,' +
            + ' Coverage_Compliance_Target__c, Volume_Category_Deluxe_Target__c, Volume_Category_Premium_Core_Target__c, Volume_Category_Reserve_Target__c, Volume_Category_RTD_Target__c,RecordType.Name,' +
            + ' Volume_Category_Super_Deluxe_Target__c, Volume_Target_Points__c FROM Territory_Hierarchy__c WHERE Geography__r.Code__c = :countryCode' + 
           + ' AND (RecordType.Name = \'Quality Territory Hierarchy\' OR (RecordType.Name = \'Region\' AND Pending_For_Batch__c = :pendingForBatch))'; // added by juned
        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Territory_Hierarchy__c> lstTerritoryHierarchy){
        List<Territory_Hierarchy__c> regionList = new List<Territory_Hierarchy__c>();
       // List<Territory_Hierarchy__c> activationTerritoryList = new List<Territory_Hierarchy__c>();//ES20-12225,ES20-12233
        List<Territory_Hierarchy__c> qualityRegionList = new List<Territory_Hierarchy__c>();
        
        try{
            for(Territory_Hierarchy__c terrHie : lstTerritoryHierarchy){ 
                if(terrHie.RecordType.Name == 'Region'){
                    regionList.add(terrHie);
                    terrHierSet.add(terrHie.Id);
                }
                if(terrHie.RecordType.Name == 'Quality Territory Hierarchy'){
                    qualityRegionList.add(terrHie);
                    //terrHierSet.add(terrHie.Id);
                }
                
               //ES20-12223,ES20-12221 -> Commented the below code
               /*if(terrHie.RecordType.Name == 'Activation Territory'){
                    activationTerritoryList.add(terrHie);
                }*/
            }
            
            //Call helper method based on record type of Hierarchy
            if(regionList != null && regionList.size() > 0){//Sales
                EDGE_SalesMgrKPIAchievementBatchHelper.calculateTerrHierarchyKPIs(regionList,true,'Sales');
            }
            if(qualityRegionList != null && qualityRegionList.size() > 0){//Quality
                EDGE_SalesMgrKPIAchievementBatchHelper.calculateTerrHierarchyKPIs(qualityRegionList,true,'Quality');
            }
            
            //ES20-12223,ES20-12221 -> Commented the below code
            /*if(activationTerritoryList !=null && activationTerritoryList.size() > 0){//AT
                EDGE_SalesMgrKPIAchievementBatchHelper.calculateTerrHierarchyKPIs(activationTerritoryList, false,'Activation Territory'); 
            }*/
            
        }catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug(batchException.getStackTraceString());
            hasError = true;
        }
      
    }
    
    //Finish Method
    public void finish(Database.BatchableContext bc){  
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_SalesManagerKPIAchievementBatch', exceptionMsg);
            system.debug('batchJobLog'+batchJobLog);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
            
            //updating the processed Territory Hierarchies
            system.debug('terrHierSet '+terrHierSet);
            if(terrHierSet != null && terrHierSet.size() > 0 && Schema.sObjectType.Territory_Hierarchy__c.isUpdateable()){
                List<Territory_Hierarchy__c> terrHierListProcess = new List<Territory_Hierarchy__c>();
                for(Id terrHierId : terrHierSet){
                    Territory_Hierarchy__c terrHierObj = new Territory_Hierarchy__c(Id=terrHierId);
                    terrHierObj.Pending_For_Batch__c = false;
                    terrHierListProcess.add(terrHierObj);
                }
                Database.update(terrHierListProcess,false);
            }
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
           EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
        
    }  
    
}