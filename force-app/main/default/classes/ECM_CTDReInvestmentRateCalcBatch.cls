/*
@Name: ECM_CTDReInvestmentRateCalcBatch
@Purpose: This class is to Calculate the CTD Reinvestment Rate of Contract KPI

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Subhodeep Sarkar     30/05/2022        Initial Development (ECM-5354)

*/

public class  ECM_CTDReInvestmentRateCalcBatch implements Database.Batchable<sObject>, Database.Stateful, BatchJobManagementInterfaceClass{
    String exceptionMsg = '';
    Boolean hasError = false ;
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        String countryCode = batchSetting.Country_Code__c;
        String queryString = '';
        List<String> statusValuesAU = Label.ECM_ContractStatusKpiCalcAU.split(',');//Active,Lost,Won,Cancelled
        List<String> statusValuesEU = Label.ECM_ContractStatusForActualVolumeYTDBatch.split(','); //Active,Expired,Closed
        List<String> conRecordTypeNames = Label.ECM_ActualVolumeYTDBatchConRecordType.split(','); //Outlet,Group
        String query1 = 'SELECT Id, AccountId,Account.country__r.Code__c,AP_Spent__c, Rebate_Paid__c, ECM_Contract_SKU_Specific_Rebate_Paid__c, ECM_Contract_Other_Spent__c, ECM_Contract_Payment_Spent__c, ECM_Upfront_Payment_Spent__c';
        String nestedqueryPaymentSummary = '(SELECT ECM_Start_Period__c,ECM_End_Period__c FROM Payment_Summary__r WHERE ECM_Type__c = \'Volume-Based\' AND'
            +'(ECM_Payment_Summary_Status__c = \'Approved\' OR ECM_Payment_Summary_Status__c = \'Completed\'))';
        String queryEnd = 'FROM Contract WHERE Status IN: statusValuesAU AND Account.country__r.Code__c =: countryCode AND RecordType.Name IN: conRecordTypeNames';
        queryString = query1 +','+ nestedqueryPaymentSummary + queryEnd;
        return Database.getQueryLocator(queryString);
    }
    //can we get all contact recs with payment summary is Approved
    
    
    //EXECUTE METHOD
    public void execute(Database.BatchableContext BC, List<Contract> contractList){
        if (contractList!=null && contractList.size()>0)
            //AU KPI Calculation Logic
            if(Label.ECM_CountryCodeAU.contains(contractList[0].Account.country__r.Code__c)){
                ECM_ContractKpiHelper.calculateCTDInvestmentRate(contractList);
            }
    }
    
    public void finish(Database.BatchableContext BC){
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){ //Check whether Batch Job has been updated by Batch Platform Event or Not
            hasError = true;
        }
        if(hasError){ //Update Batch Job Status
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_DepletionVolumeUpdateOnConItemsBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class 
        }     
    }
}