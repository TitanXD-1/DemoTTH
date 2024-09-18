/**
* @ Name : EDGE_UpdateCaseTaskSuggestedUserBatch
* @ Description : 
* @ History  
* @ Author          Version    				Date           Detail
* @	Saranya L       Initial Development	   24-01-2022     Created for ES20-11815
**/

public class EDGE_UpdateCaseTaskSuggestedUserBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode;
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        String queryString='';
        List<String> caseTaskStatusList = new List<String>();
        caseTaskStatusList.add('Open');
        caseTaskStatusList.add('Pending');
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());        
        countryCode = batchSetting.Country_Code__c;

        queryString = 'SELECT Id,Name,Account__c,Achievement_Status__c,Case_Task_Type__c,Suggested_User__c,Batch_Generated__c'

            + ' FROM Case_Task__c WHERE Country__r.Code__c =:countryCode AND Achievement_Status__c IN :caseTaskStatusList';
        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Case_Task__c> caseTaskList){    
       Map<Id,Case_Task__c> caseTaskToUpdate = new Map<Id,Case_Task__c>();
        try{   
            if(caseTaskList != null && caseTaskList.size() >0){

                caseTaskToUpdate = Edge_UpdateCTSuggestedUserBatchHelper.processCaseTaskSuggestedUser(caseTaskList,false);

            }
            if(caseTaskToUpdate != null && caseTaskToUpdate.values().size() >0){
                Database.update(caseTaskToUpdate.values(), false); 
            }
        }
        catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';  
        }
    }
    //Finish method
    public void finish(Database.BatchableContext bc){ 
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_UpdateCaseTaskSuggestedUserBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){

            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  

        }
    }
}