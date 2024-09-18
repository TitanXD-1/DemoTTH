/**
* @ Name : EDGE_UpdateCaseTaskAssignedUserBatch
* @ Description : 
* @ History  
* @ Author            Version    				Date           Detail
* @	Anamika Shukla     Initial Development	   09-02-2022     Created for ES20-12029
**/

public class EDGE_UpdateCaseTaskAssignedUserBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }    
    boolean batchGenerated = true;
    Date currentDate = date.today();
    boolean dateMatch = false;
    
    List<Line_Cleaning_Cycle__c> mCycles = new List<Line_Cleaning_Cycle__c> ();
    
    //start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        String queryString='';
        List<String> caseTaskStatusList = new List<String>();
        caseTaskStatusList.add('Open');
        caseTaskStatusList.add('Pending');
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
		System.debug('marketBatchJobId'+marketBatchJobId);        
        countryCode = batchSetting.Country_Code__c;
        
        
        Id  lineCleaningId;
        //Get all future cycles (used to get the next cycle for each current cycle)
        mCycles  =  [SELECT Name, country__c, Start_Date__c, End_Date__c,Batch_Processed__c 
                     FROM Line_Cleaning_Cycle__c WHERE country__r.code__c =: countryCode AND Active__c = true AND Start_Date__c >= :currentDate
                     Order By country__c, Start_Date__c limit 2];
        
        if(mCycles.size() !=null && mCycles.size() >0){
            for(Line_Cleaning_Cycle__c lc1 : mCycles){
                if(lc1.Start_Date__c == currentDate){
                    dateMatch = true;
                    lineCleaningId = lc1.Id;
                }
            }
        }
        if(dateMatch){
            queryString = 'SELECT Id,Name,Account__c,Achievement_Status__c,Case_Task_Type__c,User_Assigned_To__c,Suggested_User__c,Batch_Generated__c,Line_Cleaning_Cycle__c,Call__c,Call__r.Assigned_To__c'
                + ' FROM Case_Task__c WHERE Country__r.Code__c =:countryCode AND Batch_Generated__c = :batchGenerated AND Line_Cleaning_Cycle__c = :lineCleaningId AND Achievement_Status__c IN :caseTaskStatusList';
        }
        else{
            queryString = 'Select Id FROM Case_Task__c limit 0';
        }
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Case_Task__c> caseTaskList){
        Map<Id,Case_Task__c> caseTaskToUpdate = new Map<Id,Case_Task__c>();
        Map<Id,Call__c> updateCallMap = new Map<Id,Call__c>();
        try{
            if(dateMatch){
                if(caseTaskList != null && caseTaskList.size() >0){
                    caseTaskToUpdate = Edge_UpdateCTSuggestedUserBatchHelper.processCaseTaskSuggestedUser(caseTaskList,true);
                }
                if(caseTaskToUpdate != null && caseTaskToUpdate.values().size() >0){
                    for(Case_Task__c caseTaskRec: caseTaskToUpdate.values()){ 
                        if(CaseTaskRec.Call__c != null){
                            Call__c callObj = new Call__c(Id = CaseTaskRec.Call__c);
                            callObj.Assigned_To__c = caseTaskRec.User_Assigned_To__c;
                            if(!updateCallMap.containsKey(callObj.Id)){
                                updateCallMap.put(callObj.Id,callObj);
                            }
                        }
                    }
                    if(updateCallMap != null && updateCallMap.size()>0){
                        Database.update(updateCallMap.values(),false);
                    }
                    Database.update(caseTaskToUpdate.values(), false); 
                }
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_UpdateCaseTaskAssignedUserBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
    }
}