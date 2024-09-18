/**
* @description :  EDGE_TechnicalCaseRetryBatch
* @purpose : Batch Class for retrying cases which could not be sent to SNOW before
* @history :
* Version    Developer                Date             User Story/Purpose
* 1.1		Monalisa Halder			10/09/2021		   ES20-10567
*/

public class EDGE_TechnicalCaseRetryBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        string countryCode = batchSetting.Country_Code__c;
         
        String strQuery = 'Select Id, Reason_for_Failure__c, sys_id__c, Inc_Req_Number__c, CreatedById, RecordTypeId, Retry_Count__c  from Case' +
            ' where (sys_id__c = null OR Inc_Req_Number__c = null) AND (Retry_Count__c = null OR Retry_Count__c <5) AND User_Country__c =:countryCode' +
            ' AND RecordType.Name = \'Technical Issue\'';
        return Database.getQueryLocator(strQuery);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Case> caseList){
        system.debug('@@caseList' +caseList);
        try {
            Map<Id,Case> techIssueCaseMap = new Map<Id,Case>();
            List<Case> caseUpdateList = new List<Case>();
            for(Case caseRec : caseList){
                if(caseRec.Retry_Count__c == null){
                   caseRec.Retry_Count__c = 1; 
                }else{
                    caseRec.Retry_Count__c += 1;
                }
                
                caseUpdateList.add(caseRec);
                techIssueCaseMap.put(caseRec.id,caseRec);
                
            }
            
           
             if(!caseUpdateList.isEmpty() && Schema.sObjectType.Case.isUpdateable()){
                 Database.update(caseUpdateList,false);
            }
            
            if(techIssueCaseMap != null && techIssueCaseMap.size() > 0){
            	System.enqueueJob(new EDGE_CaseIntegrationWithSNOW(techIssueCaseMap));
        	}
        
        }
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug('StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
        }
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(234);
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TechnicalCaseRetryBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
        EDGE_UtilityClass.printGovLimits(90);
    }
}