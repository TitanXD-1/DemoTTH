/*
@Name: ECM_ContractEndDateNotificationBatch
@Purpose: This batch is to send email notification to the owner of a contract when the expiry period for the contract starts

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Subhodeep Sarkar     23/06/2022        Initial Development (ECM-5539)

*/

public class ECM_ContractEndDateNotificationBatch implements Database.Batchable<sObject>, Database.Stateful, BatchJobManagementInterfaceClass{
    
    String exceptionMsg = '';
    Boolean hasError = false ;
    String countryCode = '';
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    
    /*
* @description : get the batch detail for corresponding market 
* @return : void
* @param : Market_Batch_Setting Metadata
*/
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
        
    }
    
    /*
* @description : start method of batch
* @return : Database.QueryLocator
* @param : Database.BatchableContext
*/
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        List<String> conRecordTypeNames = Label.ECM_ActualVolumeYTDBatchConRecordType.split(','); //Outlet,Group
        List<String> approvedStatus = Label.ECM_ContractApprovedStatus.split(',');
        
        String query = 'Select Id, ECM_Contract_Owner__c,Owner.Email, Name, StartDate, Contract_End_Date__c,AccountId,Account.Country__c, Account.Country__r.Code__c, '+
            'ECM_Duration__c, Account.Name, ContractNumber, ECM_Expiration_Notification_sent__c, ECM_Agreement_Type__c,'+
            'ECM_Agreement_Type__r.ECM_Expiration_Start_Date_Rule_in_Months__c from Contract '+ 
            'where Contract_End_Date__c = NEXT_N_MONTHS:9 and Contract_End_Date__c != today and ECM_Expiration_Notification_sent__c = false and ECM_Agreement_Type__r.ECM_Expiration_Start_Date_Rule_in_Months__c!=null and Status IN: approvedStatus and RecordType.Name IN: conRecordTypeNames and  Account.Country__r.Code__c =: countryCode';
        return Database.getQueryLocator(query);
        
    }
    
    /*
* @description : execute method of batch
* @return : void
* @param : Database.BatchableContext, List<Contract>
*/
    
    public void execute(Database.BatchableContext bc, List<Contract> contractList){
        if(contractList!=null && contractList.size()>0){
            
            ECM_ContractNotifcationMailHelper.sendNotificationMail(contractList,countryCode);
        }
        
        
    }
    
    /*
* @description : finish method of batch
* @return : void
* @param : Database.BatchableContext
*/
    public void finish(database.BatchableContext bc) {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_PaymentSummarySendEmailBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
}