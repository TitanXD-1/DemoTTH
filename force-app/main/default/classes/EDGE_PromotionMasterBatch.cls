/**
* @Name: EDGE_PromotionMasterBatch
* @Req: 
* @History                                                            
* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Prasanth T		15/07/2022		ES20-12982
**/
public class EDGE_PromotionMasterBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass {
    Market_Batch_Setting__mdt batchSetting;
    string countryCode = '';
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId;
	ID countryRecord;
    string queryString='';
    Date yesterdayDate;
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        countryCode = batchSetting.Country_Code__c;
        countryRecord =[Select ID From Geography__c where code__c=:countryCode LIMIT 1][0].Id;
        yesterdayDate=System.today().addDays(-1);       
        queryString = 'SELECT Id From Promotion_Master__c where End_Date__c = :yesterdayDate and Country__c =:countryRecord';
        return Database.getQueryLocator(queryString);    
    }
    //execute method
    public void execute(Database.BatchableContext bc, List<Promotion_Master__c> promotionMasterList){   
        
        try{
            if(promotionMasterList!=null && promotionMasterList.size()>0)
            {
                List<Territory_Promotion__c> territoryPromotions=[Select Id,Status__c From Territory_Promotion__c where Status__c = 'Active' AND Promotion__c in :promotionMasterList];
                if(territoryPromotions!=null && territoryPromotions.size()>0)
                {
                    for(Territory_Promotion__c territoryPromotion:territoryPromotions)
                    {
                       if(territoryPromotion.Status__c=='Active')
                        territoryPromotion.Status__c='Inactive';
                    }      
                    Database.update(territoryPromotions,false);
                }
                List<Outlet_Promotion__c> outletPromotions=[Select Id,Status__c From Outlet_Promotion__c where Status__c = 'Active' AND Promotion__c in :promotionMasterList];
                if(outletPromotions!=null && outletPromotions.size()>0)
                {
                    for(Outlet_Promotion__c outletPromotion:outletPromotions)
                    {
                        if(outletPromotion.Status__c=='Active')
                        outletPromotion.Status__c='Inactive';                       
                    }
                    Database.update(outletPromotions,false);
                }       
            }
           
        }
        catch(DmlException de){
            System.debug('DML Exception Stack Trace'+ de.getStackTraceString());
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UserVisitsKPIBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}