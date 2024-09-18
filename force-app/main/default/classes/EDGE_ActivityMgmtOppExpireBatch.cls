/**********************************************************************
Name: EDGE_ActivityMgmtOppExpireBatch
=======================================================================
Req: Opportunities are associated with Opportunity Template. If Opportunity 
    template end date is less than today then related opportunities will be
    expired.
User Story : ES20-880
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Sagar Barman        16/04/2019      Initial Development
1.1     Kapil Baliyan       30/12/2019      Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
***********************************************************************/
public class EDGE_ActivityMgmtOppExpireBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    String exceptionMsg = ''; 
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    /** Start Method **/ 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594        
        String countryCode = batchSetting.Country_Code__c;
        String strQuery;
        strQuery = 'SELECT Id, StageName, Opportunity_Template__c FROM Opportunity WHERE StageName NOT IN  (\'Closed\', \'Expired\') AND Opportunity_Template__r.End_Date__c<today AND Opportunity.Account.Country__r.Code__c =:countryCode';
        return Database.getQueryLocator(strQuery);
    }
    
    /** Execute Method **/ 
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        try{
            List<Activity_Target_List__c> activityTargetList = new List<Activity_Target_List__c>();
            Set<Id> oppTemplateIdSet = new Set<Id>();
            for(Opportunity opp : scope){                
                opp.StageName = 'Expired';
                oppTemplateIdSet.add(opp.Opportunity_Template__c);
            } 
            activityTargetList = [SELECT Id,Status__c FROM Activity_Target_List__c WHERE Opportunity_Template__c IN : oppTemplateIdSet];
            for(Activity_Target_List__c atl : activityTargetList){
            	atl.Status__c = 'Waiting Removal';    
            }
            //update the scope with expire status            
            if(!scope.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){
                 Database.update(scope,false);
            }
            if(!activityTargetList.isEmpty() && Schema.sObjectType.Activity_Target_List__c.isUpdateable()){
            	Database.update(activityTargetList,false);    
            }
        }
        catch(Exception ex) {            
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    /** Finish Method **/
    public void finish(Database.BatchableContext bc) {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ActivityMgmtOppExpireBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}