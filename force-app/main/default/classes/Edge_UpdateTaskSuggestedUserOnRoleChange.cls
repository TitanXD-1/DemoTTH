/**

* @Description: Edge_UpdateTaskSuggestedUserOnRoleChange

* @Purpose: Update Case Task Suggested User on Change of case Task type Default Role

* @VERSION     AUTHOR          DATE            DETAIL

*   1.1       Sudipta     25/01/2022       ES20-11823

*/ 

public class Edge_UpdateTaskSuggestedUserOnRoleChange implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass 
{
    DateTime batchRundate = system.now();
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    Map<Id,Quality_Case_Configuration__c> configList = new Map<Id,Quality_Case_Configuration__c>();
    Map<Id, String> caseTaskTypeRole = new Map<Id, String>();
    List<Quality_Case_Configuration__c> processedConfigList = new List<Quality_Case_Configuration__c>();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting)
    {
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String query = '';
        string countryCode = batchSetting.Country_Code__c;
        Set<Id> caseTaskTypeIds = new Set<Id>();
        List<String> caseTaskStatusList = new List<String>();
        caseTaskStatusList.add('Open');
        caseTaskStatusList.add('Pending');     
        
        for(Quality_Case_Configuration__c caseTaskTypeName :[SELECT Id,Name,Default_Business_Role__c,Is_Default_Role_Changed__c from Quality_Case_Configuration__c WHERE Is_Default_Role_Changed__c = True AND country__r.Code__c =: countryCode]){
            caseTaskTypeRole.put(caseTaskTypeName.Id, caseTaskTypeName.Default_Business_Role__c);
        }
        caseTaskTypeIds.addAll(caseTaskTypeRole.keySet());
        
        query = 'SELECT Id,Name,Account__c,Achievement_Status__c,Case_Task_Type__c,Suggested_User__c'
            + ' FROM Case_Task__c WHERE Country__r.Code__c =:countryCode AND Achievement_Status__c IN :caseTaskStatusList AND Case_Task_Type__c IN :caseTaskTypeIds';
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Case_Task__c> caseTaskList)
    {
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
    
    //Finish Method 
    public void finish(Database.BatchableContext bc)
    {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed')
            hasError = true;
        
        //Update Batch Job Status
        if(hasError)
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'Edge_UpdateTaskSuggestedUserOnRoleChange', exceptionMsg);
        else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            for(Id taskTypeId : caseTaskTypeRole.keySet()){
                Quality_Case_Configuration__c configObject = new Quality_Case_Configuration__c(Id = taskTypeId);
                configObject.Is_Default_Role_Changed__c = false;
                if(!processedConfigList.contains(configObject)){
                    processedConfigList.add(configObject);    
                }
            }
            if(processedConfigList != null && processedConfigList.size()>0){
                Database.update(processedConfigList,false);
            }
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){

             EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);

        }
    }
}