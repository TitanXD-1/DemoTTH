/********************************************************************************************
Class Name: EDGE_OperatorKPIAchievementBatch

Author          Version    Date           Detail
Sandip Ghosh    V1.0       15/09/2020     [ES20-8500]
Monalisa Halder   V2.0      25/03/2021     [ES20-10004]
*********************************************************************************************/
public class EDGE_OperatorKPIAchievementBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceExtended{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    String operatorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
    String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    List<EDGE_BatchSObjectWrapper> noOfCallsRecords;
    
     //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting, List<Object> noOfCallsRecords){
        this.batchSetting = batchSetting;
        this.noOfCallsRecords = (List<EDGE_BatchSObjectWrapper>)noOfCallsRecords;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(23);
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        boolean isOperatorTrue = TRUE;     
        String queryString = 'SELECT Id,Name,Country__c,Outlet_Calls_List__c '+
            'FROM Account WHERE RecordTypeId =:operatorRecordTypeId AND IsOperator__c =:isOperatorTrue AND Country__r.Code__c =:countryCode LIMIT 10000';
        System.debug('queryString = '+ queryString);
		return Database.getQueryLocator(queryString);
    
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> listOfOps){ 
        System.debug('listOfOps size = '+ listOfOps.size());
        try{
            EDGE_OutletCallCountHelper.createOutletWrapListOperator(listOfOps,noOfCallsRecords);
        }
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug('StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
        }
    }
    //finish method
    public void finish(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(61);
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OperatorKPIAchievementBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
          //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
}