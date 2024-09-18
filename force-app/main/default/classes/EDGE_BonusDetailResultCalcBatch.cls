/**********************************************************************
Name: EDGE_BonusDetailResultCalcBatch
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan D          21/01/2020        ES20-4587 : Set the result of MPA, MAS, OES into KPI Result Detail object.
2.0         Swaraj Samanta      06/09/2022        ES20-13284: Include the !Test.isRunningTest() for scheduling the next batch
***********************************************************************/
public class EDGE_BonusDetailResultCalcBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    string countryCode = '';
    String activeStatus='Active';
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode= batchSetting.Country_Code__c;
        String queryString='SELECT Id, Country__c, Max_Cap_total_Bonus__c FROM Bonus_Header__c WHERE Country__r.Code__c =:countryCode AND Status__c =:activeStatus';        
        return Database.getQueryLocator(queryString);   
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Bonus_Header__c> scope){
        if(scope != null && scope.size()>0){
            EDGE_BonusDetailResultOperations.populateBonusDetailResults(scope);            
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_BonusDetailResultCalcBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }

        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }   

}