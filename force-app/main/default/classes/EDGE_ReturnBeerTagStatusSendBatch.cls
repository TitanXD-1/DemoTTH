/**

* @description :  EDGE_ReturnBeerTagStatusSendBatch

* @history :

* Version   Developer      Date       User Story	  Purpose
* 1.1       Prasanth T   20/08/2021    ES20-10373      New Return Beer Tags with Status-New is sent to SAP and The Status is updated based on the response.

*/
global with sharing class EDGE_ReturnBeerTagStatusSendBatch implements Database.Batchable<SObject>, Database.AllowsCallouts,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode = '';
    private Final String newString= 'New';
    /*Start Method*/
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
         //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String queryString='';
        this.countryCode = batchSetting.Country_Code__c;
        
         queryString= 'SELECT ID,Status__c,Tag_Number__c,Keg_number__c,Reason_Category__c,Reason_Category__r.Reason_Category_Name__c,Reason_Code__c,'
             + 'Reason_Code__r.Reason_Code_Name__c,Volume__c,Sample_Taken__c,Broached_Keg__c,Product__c,Product__r.Product__r.SAP_SKU_Code__c,'
             + 'CreatedDate,Case_Task__c,Case_Task__r.Account__c,Case_Task__r.Account__r.Country__r.Code__c FROM Return_Beer_Tag__c WHERE Status__c = : newString'
             +' AND Case_Task__r.Account__r.Country__r.Code__c =:countryCode';
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Return_Beer_Tag__c> scope){
        list<Return_Beer_Tag__c> returnBeerTagsList =  new list<Return_Beer_Tag__c>();
        // Instance of Retrun Beer Handler class
        EDGE_ReturnBeerTagStatusSendHandler returnBeerHandler = new EDGE_ReturnBeerTagStatusSendHandler();
        try{
            for(Return_Beer_Tag__c returnBeerObj:scope){    
                returnBeerTagsList.add(returnBeerObj);
            }
            if(returnBeerTagsList != null && returnBeerTagsList.Size()>0){
                 returnBeerHandler.sendTagsDetails(returnBeerTagsList);
            }        
        }catch(Exception ex) {
            hasError = true;
            String exceptionMsg = 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + ' Stack Trace : ' + ex.getStackTraceString() + '\n';
            system.debug(exceptionMsg);
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ReturnBeerTagStatusSendBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}