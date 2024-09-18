/**

* @Description: EDGE_RemoveOldUserAccessForCTBatch

* @Purpose: Removes the older User-assigned to Case-tasks or Temporary User's Access from the account

* @VERSION     AUTHOR          DATE            DETAIL

*   1.1       Aparajita     25/01/2022       ES20-11892

*/ 

public class EDGE_RemoveOldUserAccessForCTBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass 
{
    DateTime batchRundate = system.now();
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting)
    {
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String query = '';
        string countryCode = batchSetting.Country_Code__c;
        query = 'SELECT Id, Outlet__c, User__c from Outlet_Member__c WHERE Temporary_Assigned__c=TRUE AND Outlet__r.Country_Code__c=:countryCode';
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Outlet_Member__c> outletMemberList)
    {
        //Assignment
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Set<String> uniqKeySet = new Set<String>();
        Set<String> accUserKeyToDeleteSet = new Set<String>();
        List<String> eligibleCTStatus = System.Label.EDGE_CaseTaskStatus.split(';');
        List<Outlet_Member__c> outletMemToDeleteList = new List<Outlet_Member__c>();
        List<AccountTeamMember> atmToDeleteList = new List<AccountTeamMember>();
        Map<String,List<String>> uniqueKeyVsCaseTaskMap = new Map<String,List<String>>();
        Map<String,Outlet_Member__c> uniqueKeyVsOutletMemMap = new Map<String,Outlet_Member__c>();
        
        try{           
            //Mapping unique-key of format 'accId_userId' with OutletMembers
            //Creating sets of userIds and accIds from scope 
            if(outletMemberList != null && outletMemberList.size() > 0)
            {   
                for(Outlet_Member__c outletMem : outletMemberList){
                    String uniqKey = outletMem.Outlet__c + '_' + outletMem.User__c;
                    if(!uniqueKeyVsOutletMemMap.containsKey(uniqKey)){
                        uniqueKeyVsOutletMemMap.put(uniqKey,outletMem);           
                    }
                    outletIdSet.add(outletMem.Outlet__c);
                    userIdSet.add(outletMem.User__c);   
                }     
            }
            
            //Creating a set of unique-keys of format 'accId_userId' for CTs having status open/pending
            if(outletIdSet!=null && outletIdSet.size()>0 && userIdSet!=null && userIdSet.size()> 0){
                for(Case_Task__c caseTaskObj : [SELECT Id, Achievement_Status__c, Case__c, Case__r.AccountId, User_Assigned_To__c 
                                                FROM Case_Task__c WHERE User_Assigned_To__c!=NULL AND Case__r.AccountId!=NULL 
                                                AND Achievement_Status__c IN : eligibleCTStatus AND Case__r.AccountId IN : outletIdSet 
												AND User_Assigned_To__c IN : userIdSet])
                {
                    String uniqKey = caseTaskObj.Case__r.AccountId + '_' + caseTaskObj.User_Assigned_To__c;
                    uniqKeySet.add(uniqKey);
                }
            }
            
            //Creating a list to delete those OutletMembers having unique-keys that doesn't have any open/pending CTs 
            //Creating a set to store those unique-keys whose OutletMembers will be deleted
            if(uniqueKeyVsOutletMemMap!=null && uniqueKeyVsOutletMemMap.size()>0){
                for(String uniqKey : uniqueKeyVsOutletMemMap.keySet()){
                    if(uniqKeySet!=null && uniqKeySet.size()>0 && !uniqKeySet.contains(uniqKey)){
                        outletMemToDeleteList.add(uniqueKeyVsOutletMemMap.get(uniqKey));
                        accUserKeyToDeleteSet.add(uniqKey);
                    }
                }
            }
            
            //Creating a list to store the AccountTeamMembers to be deleted 
            if(outletIdSet!=null && outletIdSet.size()>0 && userIdSet!=null && userIdSet.size()>0){
                for(AccountTeamMember atm : [SELECT Id, AccountId, UserId FROM AccountTeamMember 
                                             WHERE AccountId IN : outletIdSet AND UserId IN : userIdSet])
                {
                    String uniqKey = atm.AccountId + '_' + atm.UserId;
                    if(accUserKeyToDeleteSet!=null && accUserKeyToDeleteSet.size()>0 && accUserKeyToDeleteSet.contains(uniqKey)){
                        atmToDeleteList.add(atm);
                    }        
                }
            }
            
            //Calling the utility-class to delete OutletMembers and AccountTeamMembers 
            if(outletMemToDeleteList!=null && outletMemToDeleteList.size()>0){
                delete outletMemToDeleteList;
            }
            if(atmToDeleteList!=null && atmToDeleteList.size()>0){
                delete atmToDeleteList;
            }
                        
        }catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';  
        }  
    }
    
    //Finish Method 
    public void finish(Database.BatchableContext bc)
    {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed')
            hasError = true;
        
        //Update Batch Job Status
        if(hasError)
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_RemoveOldUserAccessForCTBatch', exceptionMsg);
        else
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest())
           EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}