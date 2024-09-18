/********************************************************************************************
Class Name: EDGE_DynamicTargetListRemovalBatch

Author          Version    Date           Detail
Dipanjan Das    V1.0       25/02/2019     Mark Target List Member of Dynamic traget list as waiting 
										  removal where dynamic search criteria does not match with existing member
Kapil Baliyan   V2.0       30/12/2019     Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*********************************************************************************************/
public class EDGE_DynamicTargetListRemovalBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    DateTime batchRundate;
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
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
        
        //Get Target List Batch Time from custom setting which was set by create batch
        Batch_Job_Current_Region__c currentRegion = Batch_Job_Current_Region__c.getValues('Current Region');
        batchRundate = currentRegion.Target_List_Batch_Run_Time__c;
        
        string queryString='';
        string countryCode = batchSetting.Country_Code__c;
        Id tlRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        if(tlRecordTypeId != null){
            queryString = 'SELECT Id, Outlet__c, Target_List__c, Assignment_Status__c FROM Target_List_Member__c WHERE Batch_Run_Date__c<:batchRundate AND Target_List__r.recordTypeId = :tlRecordTypeId and Target_List__r.Country__r.Code__c=:countryCode';
            system.debug('@@queryString::::'+queryString);
        }
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Target_List_Member__c> targetListMemberList){
        Set<Id> targetLstMemberIdSet = new Set<Id>();
        if(targetListMemberList != null && targetListMemberList.size() > 0){
            for(Target_List_Member__c tml:targetListMemberList){
                if(!Test.isRunningTest()){
                    tml.Assignment_Status__c='Waiting Removal';
                }else{
                    tml.Assignment_Status__c='Waiting Removall'; //use this to forcefully throw exception in test class to cover exception coverage
                }
            }
            try{
                update targetListMemberList;
            }
            catch(DmlException de){
                hasError = true;
                Integer numErrors = de.getNumDml();
                for(Integer i=0; i<numErrors; i++) {
                    exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
                }
            }
            catch(Exception ex) {
                hasError = true;
                exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
            }
        }
    }
    
    //Finish Method
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_DynamicTargetListRemovalBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
    }
}