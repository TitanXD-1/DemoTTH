/**********************************************************************
Name:EDGE_TerritoryHistoricMonthlyBatch
=======================================================================
Req: Update Territory KPIs in Territory Historic object from Territory (KPI Achievement)

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                   DATE              DETAIL

***********************************************************************/

public class EDGE_TerritoryHistoricMonthlyBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    //Interface Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  //Update ES20-6594 
        String territoryType='Sales'; 
        String countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        
        String queryString = 'SELECT Id FROM Territory__c WHERE Territory_Type__c =:territoryType AND Country__r.Code__c =:countryCode AND Status__c =:activeStatus';
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Territory__c> territoryList){ 
        Set<Id> territoryIds = (new Map<Id, Territory__c>(territoryList)).keySet();
        Map<Id,Territory_Historic__c> newTerrHistoricMap = EDGE_TerritoryHistoricUpdate.territoryHistoricCalculation(territoryIds);  
        if(null != newTerrHistoricMap && !newTerrHistoricMap.isEmpty()){
            Database.upsert(newTerrHistoricMap.values());   
        }
        
    }
    
    public void finish(Database.BatchableContext bc) {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TerritoryHistoricMonthlyBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting,marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        
    }
    
    
}