/********************************************************************************************
Class Name: EDGE_DistributorPersonRespBatch

Author              Version       Date           Detail
Shahbaz Khan        V1.0        10/11/2020     [ES20-8661]
*********************************************************************************************/
public class EDGE_DistributorPersonRespBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    Boolean pendingTrue = true;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        Id distRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Distributor_Wholesaler').getRecordTypeId();
        String querySt = 'SELECT Id,Person_Responsible__c,Person_Responsible_2__c,Person_Responsible_3__c,Pending_for_Distributor_Batch__c '+ 
            +'FROM Account WHERE Country_Code__c  =:countryCode AND recordTypeId =:distRecTypeId AND Pending_for_Distributor_Batch__c =:pendingTrue';
        
        return Database.getQueryLocator(querySt);
    }
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> distList){
        
        
        try{
            if(distList!=null && distList.size()>0){
                EDGE_DistributorPersonRespBatchHelper.createAndDeleteTeamMembers(distList);
            }
        
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }
        catch(Exception ex){
            system.debug('@@Exception' + ex.getMessage());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    //finish method
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_DistributorPersonRespBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}