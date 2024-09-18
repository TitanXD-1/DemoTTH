/*
@Name: ECM_GroupContractOEHistoricKPIBatch
@Purpose: Bug ECM-6396

@History                                                          
VERSION      AUTHOR             DATE             DETAIL
1.0          Wribhu Bose        06/12/2022       Pick up OEH data for outlets having group contracts
*/

public class ECM_GroupContractOEHistoricKPIBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {

    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        
        string countryCode = batchSetting.Country_Code__c;
        Id outletRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();
        String groupContractRecordType = Label.ECM_Group_Contract_RecordType;
        List<String> activeStatusType = Label.ECM_AnniversaryContractStatus.split(',');
        String strQuery = 'SELECT Id, Contract__c, Outlet__c, Contract__r.Status, Contract__r.recordType.Name, Outlet__r.Country_Code__c, ' +
            'Outlet__r.recordTypeId, Outlet__r.Status__c, Outlet__r.Name, Outlet__r.Called_on__c FROM Outlet_Contract__c ' +
            'WHERE Contract__r.Status IN :activeStatusType AND Contract__r.recordType.Name =: groupContractRecordType AND Outlet__r.Country_Code__c  =: countryCode AND ' + 
            'Outlet__r.recordTypeId =: outletRecTypeId AND Outlet__r.Status__c IN :activeStatusType';
        
        return Database.getQueryLocator(strQuery);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Outlet_Contract__c> outletContractsList){
        
        List<String> oehUniqueIDList = new List<String>();
        Integer month = Date.today().month();
        Integer year = Date.Today().Year();
        List<Outlet_Execution_Historic__c> outletExHisListtoUpdate = new List<Outlet_Execution_Historic__c>();
        Boolean toUpdate = false;
        
        for (Outlet_Contract__c outletContractItem : outletContractsList) {
            oehUniqueIDList.add(String.valueOf(month)+String.valueOf(year)+outletContractItem.Outlet__c);
        }
        
        try {
            for (Outlet_Execution_Historic__c outletExecHistRecord: [SELECT ECM_Called_On__c,ECM_In_Contract__c,Date_of_Execution__c,Unique_Id__c FROM Outlet_Execution_Historic__c
                                                                     WHERE Unique_Id__c in :oehUniqueIDList])
            {
                if(!outletExecHistRecord.ECM_In_Contract__c) {
                    outletExecHistRecord.ECM_In_Contract__c = true;
                    toUpdate = true;
                }
                if(!outletExecHistRecord.ECM_Called_On__c) {
                    outletExecHistRecord.ECM_Called_On__c = true;
                    toUpdate = true;
                }
                if(toUpdate) {
                    outletExHisListtoUpdate.add(outletExecHistRecord);
                }
            }
            if(outletExHisListtoUpdate != null && !outletExHisListtoUpdate.isEmpty()){
                update outletExHisListtoUpdate;
            }
        } catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_GroupContractOEHistoricKPIBatch', exceptionMsg);
        } else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}