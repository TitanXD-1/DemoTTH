/**********************************************************************
Name: EDGE_OutletTemporaryStatusUpdateBatch
=======================================================================
Req: 
User Story : ES20-6121
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Dipanjan D        25/11/2019        Outlet should change status automatically based Temporary closed start & end date
1.1       Kapil Baliyan     30/12/2019        Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
***********************************************************************/
public class EDGE_OutletTemporaryStatusUpdateBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = ''; 
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594      
        String queryString='';
        String countryCode = batchSetting.Country_Code__c;                     
        Date todaysDate = system.today();
        queryString='SELECT Id, Start_Date__c, End_Date__c , Status__c FROM Account WHERE Country__r.Code__c = :countryCode AND (Start_Date__c = :todaysDate OR End_Date__c < :todaysDate)';
        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> scope){ 
        List<Account> outletsToUpdate = new List<Account>();
        for(Account outlet : scope){
            if(outlet.Status__c == 'Active' && outlet.Start_Date__c != null && outlet.Start_Date__c == system.today()){
                outlet.Status__c = 'Temporarily Closed';
            }
            if(outlet.Status__c == 'Temporarily Closed' && outlet.End_Date__c != null && outlet.End_Date__c < system.today()){
                outlet.Status__c = 'Active';
            }
            outletsToUpdate.add(outlet);
        }
        if(outletsToUpdate != null && outletsToUpdate.size() > 0){
            database.update(outletsToUpdate, false);
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletTemporaryStatusUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}