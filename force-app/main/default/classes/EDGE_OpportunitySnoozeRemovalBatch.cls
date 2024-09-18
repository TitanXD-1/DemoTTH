/**********************************************************************
Name: EDGE_OpportunitySnoozeRemovalBatch
=======================================================================
Req: If Opportunities Snooze date is less than current date THEN snooze flag 
     in opportunity object will be updated automatically and snooze will be removed.

User Story : ES20-3969
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Sagar Barman        09/12/2019      Initial Development
2.0	    Kapil Baliyan		30/12/2019		Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
3.0     Monalisa Halder     28/05/2021      ES20-10171
***********************************************************************/
public class EDGE_OpportunitySnoozeRemovalBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
   
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
        strQuery = 'SELECT Id, Snooze_Flag__c,Snooze_date__c,Snooze_reason__c,Snooze_Approval_Status__c, StageName FROM Opportunity'+
                   ' WHERE ((Snooze_date__c < today AND Snooze_Approval_Status__c != \'Rejected\')OR (Snooze_Approval_Status__c = \'Rejected\' AND Snooze_date__c != null) )  AND Opportunity.Account.Country__r.Code__c =:countryCode AND Snooze_Approval_Status__c != null'+
                   ' AND StageName NOT IN (\'Closed\',\'Expired\',\'Not Achieved\')';
        return Database.getQueryLocator(strQuery);
    }
    
    /** Execute Method **/ 
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        List<Id> opportunityIdList = new List<Id>();
        List<Opportunity> opportunityList = new List<Opportunity>();
        try{
            //make the snooze things null or False
            for(Opportunity opp : scope){
                if(opp.Snooze_Approval_Status__c == 'Pending'){
                    opportunityIdList.add(opp.Id);
                }
                opp.Snooze_Flag__c = false;
                opp.Snooze_date__c = null;
                opp.Snooze_Approval_Status__c = ''; 
                opp.Snooze_reason__c = '';
                
            }
            if(opportunityIdList !=null && opportunityIdList.size() >0){
            	EDGE_OpportunitySnoozeHelper.unlockOpportunityRecords(opportunityIdList);    
            }
            
          
            if(!scope.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){
                 Database.update(scope,false);
            }
        }catch(Exception ex) {            
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OpportunitySnoozeRemovalBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}