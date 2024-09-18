/********************************************************************************************
Class Name: EDGE_DynamicTargetListCreateBatch

Author          Version    Date           Detail
Dipanjan Das    V1.0       25/02/2019     Batch class for adding new outlet as 'waiting Activation'
										  status in Target List Member for Dynamic target list.
Kapil Baliyan	V2.0	   30/12/2019	  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*********************************************************************************************/
public class EDGE_DynamicTargetListCreateBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    DateTime batchRundate = system.now();
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Update Target List Batch Time in custom setting, it will help in Target List Delete Batch
        Batch_Job_Current_Region__c currentRegion = Batch_Job_Current_Region__c.getValues('Current Region');
        currentRegion.Target_List_Batch_Run_Time__c = batchRundate;
        update currentRegion;
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        String query = '';
        string countryCode = batchSetting.Country_Code__c;
        Id tlRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        if(tlRecordTypeId != null){
            query = 'SELECT Id, Name, Country__c, Dynamic_Query__c FROM Target_List__c WHERE Active__c = True AND recordTypeId = :tlRecordTypeId and Country__r.Code__c=:countryCode';
        }
        system.debug('@@queryString::::'+query);
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Target_List__c> targetLstList){
        if(targetLstList != null && targetLstList.size() > 0){
            Target_List__c targetLst = targetLstList[0];
            List<Account> outletList = new List<Account>();
            Set<Id> outletIdSet = new Set<Id>();
            List<Target_List_Member__c> targetLstMembertoUpsert = new List<Target_List_Member__c>();
            Map<String, Target_List_Member__c> tlMemberExWithIdMap = new Map<String, Target_List_Member__c>();
            
            for(Target_List_Member__c tlMember : [select Id, Name, Outlet__c, Target_List__c, External_Id__c,Assignment_Status__c FROM Target_List_Member__c WHERE Target_List__c = :targetLst.Id]){
                tlMemberExWithIdMap.put(tlMember.External_Id__c, tlMember);
            }
            
            if(targetLst.Dynamic_Query__c != null && targetLst.Dynamic_Query__c != '') {
                try{
                    outletList = (List<Account>)Database.query(targetLst.Dynamic_Query__c);
                    
                    if(outletList != null && outletList.size() > 0){
                        for(Account outlet : outletList){
                            Target_List_Member__c targetLstMem = new Target_List_Member__c();
                            String externalId = String.ValueOf(targetLst.Id) + String.ValueOf(outlet.Id);
                            if(tlMemberExWithIdMap.containsKey(externalId)){
                                if(tlMemberExWithIdMap.get(externalId).Assignment_Status__c=='Active'){
                                    targetLstMem.Id = tlMemberExWithIdMap.get(externalId).id;
                                }
                            }else{
                                targetLstMem.Assignment_Status__c = 'Waiting Activation';
                            }
                            targetLstMem.Outlet__c = outlet.Id;
                            targetLstMem.Target_List__c = targetLst.Id;
                            targetLstMem.Batch_Run_Date__c = batchRundate;
                            targetLstMembertoUpsert.add(targetLstMem);
                        }
                    }
                    
                    //Upsert Target List Member
                    if(targetLstMembertoUpsert != null && targetLstMembertoUpsert.size()>0){
                        upsert targetLstMembertoUpsert;
                    }
                }catch(DmlException de){
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_DynamicTargetListCreateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }

        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}