/********************************************************************************************
Class Name: EDGE_OperatorSurveyKPIRollupBatch

Author          Version    Date           Detail
Shahbaz Khan	1.0		   28/09/2020	  ES20-8503
Amar Deep       1.1		   28/09/020	  ES20-8504
Prasanth T      1.2        25/07/2022     ES20-13170 

*********************************************************************************************/

public class EDGE_OperatorSurveyKPIRollupBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    String territoryRecTypeId = '';
    Id marketBatchJobId;
    List<Market_Cycle__c> marketCycleRecord ;
    String countryCode = '';
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String queryString='';
        String activeStatus='Active'; 
        this.countryCode = batchSetting.Country_Code__c;
        Id ownerOperRecType = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        
        marketCycleRecord = [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,End_Date__c,Geography__r.Code__c from Market_Cycle__c WHERE Geography__r.Code__c =:countryCode AND Active__c= True LIMIT 1] ;
        if(marketCycleRecord!=null && marketCycleRecord.size()>0)
        {
             queryString='SELECT Id,Country__c,IsOperator__c,Status__c,RecordTypeId FROM Account WHERE RecordTypeId =:ownerOperRecType'+
            ' AND IsOperator__c = True AND Country__r.Code__c =:countryCode AND Status__c = :activeStatus';            
        }
        else
        {
             queryString='SELECT Id FROM Account limit 0'; 
        }  
        return Database.getQueryLocator(queryString);
    }
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> operatorList){
        Map<Id,Account> operatorMap = new Map<Id,Account>();
        system.debug('@@@operatorList '+operatorList);
        if(operatorList!=null && operatorList.size() > 0){
            for(Account operator : operatorList){
                operatorMap.put(operator.Id,operator);
            }
            EDGE_OperatorSurveyKPIRollupHelper.populateAccountKPIAch(operatorMap, marketCycleRecord[0]);
            EDGE_OperatorAccountKPIAchievementHelper.createAccountKPIAchievementWrapList(operatorList);
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OperatorSurveyKPIRollupBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
}