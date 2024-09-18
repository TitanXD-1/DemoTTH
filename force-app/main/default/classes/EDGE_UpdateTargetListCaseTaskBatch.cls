/**
@name EDGE_UpdateTargetListCaseTaskBatch
@history
Version              Author                   Date            Detail
1.0              Prasanth T 	            18/01/2022       ES20-11866
**/

public class EDGE_UpdateTargetListCaseTaskBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    String waitingRemoval = 'Waiting Removal';
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        
        String queryString='';
        String countryCode = batchSetting.Country_Code__c;
        queryString = 'SELECT Id, Outlet__c, Target_List__c, Assignment_Status__c FROM Target_List_Member__c WHERE Assignment_Status__c =: waitingRemoval' 
            +' AND Target_List__r.Country__r.Code__c=:countryCode' ;
        return Database.getQueryLocator(queryString);
    }
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetListMemberList)
    {
        Map<Id, Set<Id>> deleteTargetListOutletMap = new Map<Id, Set<Id>>();
        for(Target_List_Member__c tml:targetListMemberList){
            if(tml.Assignment_Status__c == waitingRemoval){                    
                if(deleteTargetListOutletMap.containsKey(tml.Target_List__c)){
                    deleteTargetListOutletMap.get(tml.Target_List__c).add(tml.Outlet__c);
                }else{
                    deleteTargetListOutletMap.put(tml.Target_List__c, new Set<Id>{tml.Outlet__c});
                }                   
                
            }
        }
        try{
            //ES20-11866- Start
            if(deleteTargetListOutletMap != null && deleteTargetListOutletMap.Size()>0){
                EDGE_DynamicTLCaseTaskCreationHelper.updateStatusOfCaseTask(deleteTargetListOutletMap,false);
            }
            //ES20-11866- End
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UpdateTargetListMemberBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
}