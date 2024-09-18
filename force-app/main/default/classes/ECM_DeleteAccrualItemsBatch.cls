/*
* Class Name: ECM_DeleteAccrualItemsBatch
* Test Class: ECM_DeleteAccrualItemsBatchTest
* Author: 
* Brief Description: 
* Created Date: 07-Jun-2024
* History: 
* VERSION			AUTHOR				        DATE				DETAIL
* 1.0               Sagnik/Suvendu         07-Jun-2024          Initial Development : 153434
*/ 

public class ECM_DeleteAccrualItemsBatch implements Database.Batchable<SObject>,Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    Market_Batch_Setting__mdt batchSetting; 
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    String budget='';
    Market_Setting__c marketSetting;
    Boolean isAccrualCreationChanged;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    /**
* @description : start - start method for the Batch
* @return : Database.QueryLocator
* @param : Database.BatchableContext
*/
    public Database.QueryLocator start(Database.BatchableContext bc){  
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        
        String contractGroupRecordtypeId = Contract.sobjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        String contractOutletRecordtypeId = Contract.sobjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();      
        marketSetting = [Select Id,ECM_Budget_Type_for_Volume_Based_PS__c,Accrual_Creation__c,ECM_Change_in_Accrual_Logic__c from Market_Setting__c where Geography__r.Code__c=:countryCode Limit 1];
        String strQuery='';
        System.debug(LoggingLevel.DEBUG,contractGroupRecordtypeId+contractOutletRecordtypeId);
        System.debug(LoggingLevel.DEBUG,'8888->'+marketSetting);
        if(marketSetting.ECM_Change_in_Accrual_Logic__c){ 
            strQuery ='Select Id, ECM_Fiscal_Year__c, ECM_Period__c,CreatedDate,ECM_Contract__r.Account.country__r.code__c,ECM_Contract__c FROM ECM_Accrual__c WHERE (ECM_Contract__r.RecordTypeid=: contractOutletRecordtypeId OR ECM_Contract__r.RecordTypeid=: contractGroupRecordtypeId) '+
                'AND ECM_Contract__r.Account.country__r.code__c =: countryCode AND ECM_Contract__r.Status = \'Active\' ORDER BY LastModifiedDate DESC';
        }else{
            strQuery='SELECT Id FROM ECM_Accrual__c LIMIT 0';
        }
        
        
        return Database.getQueryLocator(strQuery);
    }
    
    /**
* @description : execute - execute method for the Batch
* @return : void
* @param : Database.BatchableContext, List<Contract> 
*/
    public void execute(Database.BatchableContext bc, List<ECM_Accrual__c> scope){
        System.debug(LoggingLevel.DEBUG,scope.size()+'->'+scope);
        List<ECM_Accrual__c> oldAccrualsListToBeDeleted = new List<ECM_Accrual__c>();
        //Deletion Extra Accruals & AccrualsItems
        if(marketSetting.Accrual_Creation__c== 'Whole Numbers'){
            oldAccrualsListToBeDeleted = ECM_AccrualforAnP_TI_RetroBatchHelper.deleteExtraAccrualsNewtoOld(scope, countryCode);
        }
        System.debug(LoggingLevel.DEBUG,oldAccrualsListToBeDeleted.size()+'->'+oldAccrualsListToBeDeleted);
        if (Schema.sObjectType.ECM_Accrual__c.isDeletable() && !oldAccrualsListToBeDeleted.isEmpty()) {
            Database.delete(oldAccrualsListToBeDeleted, false);
        }
    }
    
    /**
* @description : finish - Finish method for the Batch
* @return : void
* @param : Database.BatchableContext - Batchable Context
*/  
    public void finish(Database.BatchableContext bc){  
        //Updating Market Settings 
        if (marketSetting.ECM_Change_in_Accrual_Logic__c && Schema.sObjectType.Market_Setting__c.isUpdateable()) {
            marketSetting.ECM_Change_in_Accrual_Logic__c = false;
            Update marketSetting;
        }
        
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        String reducedExceptionMsg = '';
        hasError = !hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed';
        
        if(hasError){ //Update Batch Job Status
            reducedExceptionMsg = (exceptionMsg != null  && exceptionMsg.length() >= 32768)? exceptionMsg.substring(0, 32768): exceptionMsg; 
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_DeleteAccrualItemsBatch', reducedExceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
            //Updating Market Settings - 153434
                if (marketSetting.ECM_Change_in_Accrual_Logic__c && Schema.sObjectType.Market_Setting__c.isUpdateable()) {
                    marketSetting.ECM_Change_in_Accrual_Logic__c = false;
                    Database.update(marketSetting, false);
                }
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }
    
}