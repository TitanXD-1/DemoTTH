/*
 * Class Name : ECM_ContractStatusChangeBatch
 * @description: Changes the status of contract to Expired/Closed depending on conditions.
 * @history
 * VERSION    AUTHOR                    DATE              DETAIL
 * 1.1        Tanishq Banerjee       22/03/2022    ECM-5351 - Contract Status to Expired_SFDC_GLO 
 * 1.2        Anshu Prakash          22/03/2022    ECM-5357 - Contract Status to Closed_SFDC_GLO 
*/

global class ECM_ContractStatusChangeBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    String countryCode ;
    Boolean hasError = false;
    String exceptionMsg = '';
    String responseMsg = '';
    Id marketBatchJobId;
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;        
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        Id outletRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id groupRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Group').getRecordTypeId();
        String query=  'SELECT Id,RecordTypeId,Account.Country__r.code__c,Account.Country__r.name,Contract_End_Date__c,Status,Contract_UOS_Earnt__c,UOS_Target__c,UOS_Earnt__c,'
          			    + '(SELECT Id,ECM_Contract__c,ECM_Payment_Summary_Status__c FROM Payment_Summary__r) FROM Contract ' 
       				    + 'WHERE (Status=\'Active\' OR Status=\'Expired\') AND Contract_End_Date__c<TODAY AND ' 
            		    + 'Account.Country__r.code__c =: countryCode AND (RecordTypeId=:outletRecTypeId OR RecordTypeId=:groupRecTypeId)';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Contract> conRecs){        
        Map<Id,Boolean> conUpdt = new Map<Id,Boolean>();
        List<Contract> conList = new List<Contract>();
        
        for(Contract contr : conRecs){
            Boolean flag = true;
            if((System.Label.ECM_CountryCodeAU.contains(contr.Account.Country__r.code__c) && contr.UOS_Earnt__c >= contr.UOS_Target__c) 
               || !(System.Label.ECM_CountryCodeAU.contains(contr.Account.Country__r.code__c))){                   
                   for(ECM_Payment_Summary__c pas : contr.Payment_Summary__r){
                       if(pas.ECM_Payment_Summary_Status__c != 'Completed'){
                           flag = false;
                           break;
                       } 
                   }  
                   if(!flag){
                       contr.Status = 'Expired';
                   }else{
                       contr.Status = 'Closed';
                   }
                   conList.add(contr); 
               }
        }
        if(!conList.isEmpty()){                
            Database.update(conList);
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_ContractStatusChangeBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', responseMsg); 
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    } 
}