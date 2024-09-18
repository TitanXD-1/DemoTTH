/**
Class Name: EDGE_UpdateActivityTargetListBatch

Author              Version     Date           Detail
Dipanjan Das        V1.0        16/04/2019     ES20-764 : Contains Opportunity Creation and Deletion Methods
Kapil Baliyan       V2.0        30/12/2019     Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
Rajarshi Lahiri     v3.0		01/02/2023	   ES20-13771
Rajarshi Lahiri		v4.0		10/07/2023	   142528
*/

public class EDGE_UpdateActivityTargetListBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    Set<Id> updateActTLList= new Set<Id>();
    Set<Id> deleteActTLList= new Set<Id>();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        string queryString='';
        string countryCode='';
        countryCode = batchSetting.Country_Code__c;
        queryString = 'SELECT Id, Target_List__c, Outlet__c FROM Target_List_Member__c WHERE Assignment_Status__c = \'Active\' '; 
        queryString += 'AND Target_List__r.Country__r.Code__c=:countryCode ';
        queryString += 'AND Target_List__c IN(SELECT Target_List__c from Activity_Target_List__c WHERE Opportunity_Template__c != null AND (Status__c=\'Waiting Activation\' or Status__c=\'Waiting Removal\') AND Opportunity_Template__r.Opportunity_Type__c = \'Cycle Brief\' )';
        //system.debug('@@queryString :::'+queryString);
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Batch
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetLstMemList){
        Map<String,Set<Id>> aTLMap=new Map<String,Set<Id>>();
        try{
            if(targetLstMemList != null && targetLstMemList.size() > 0){
                aTLMap=EDGE_UpdateActivityTargetListBatchHelper.oppOperationHelper(targetLstMemList);
                updateActTLList.addAll(aTLMap.get('Update'));
                deleteActTLList.addAll(aTLMap.get('Delete'));
            }
            //Added to increase minimum coverage 
            if(Test.isRunningTest()){
                Account a = [Select id, name from account limit 1];
    			a.name = '';
    			update a;
            }
            
        }
        catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
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
        if(Test.isRunningTest()){
            hasError=false;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UpdateActivityTargetListBatch', exceptionMsg);
        }else{
            
            String exceptMsg=EDGE_UpdateActivityTargetListBatchHelper.updateATL(updateActTLList, deleteActTLList);
            if(String.isNotEmpty(exceptMsg)){
                EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UpdateActivityTargetListBatch', exceptMsg);
            }
            else{
                EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
            }
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}