/**

* @Description: Edge_AccountAccessChecksForTask

* @Purpose: Assigned User's Access Checks for case Task

* @VERSION     AUTHOR          DATE            DETAIL

*   1.1       Sudipta     25/01/2022          ES20-13681

*/ 

public class Edge_AccountAccessChecksForTask implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass 
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
        List<String> eligibleCTStatus = System.Label.EDGE_CaseTaskStatus.split(';');
        query = 'SELECT Id, Achievement_Status__c, Case__c, Case__r.AccountId, User_Assigned_To__c  FROM Case_Task__c WHERE User_Assigned_To__c !=NULL AND Account__c !=NULL' 
            + ' AND Achievement_Status__c IN : eligibleCTStatus AND Account__r.Country_Code__c=:countryCode';
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Case_Task__c> caseTaskList)
    {
        //Assignment
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> assignUserIdSet = new Set<Id>();
        Map<Id,Id> caseAccIdMap= new Map<Id,Id>();
        Map<String,Outlet_Member__c> outletMemberMap = new Map<String,Outlet_Member__c>();
        MAP<String,Outlet_Member__c> outletMemInsrtLst = new MAP<String,Outlet_Member__c>();
        Map<Id,String> userBusinessRoleMap = new Map<Id,String>();
        Map<String,String> userAccountRoleMap = new Map<string,String>();
        Map<String,String> userRoleMap = new Map<String,String>();
        Map<String,Id> userOutletkeyAtmIdMap= new Map<String,Id>();
        Map<String,AccountTeamMember> accountTeamMemberMap = new  Map<String,AccountTeamMember>();
        Set<String> atmUserIdAccountIdKey = new Set<String>();
        Set<Id> atmUserIdSet = new Set<Id>();
        Set<Id> atmAccountIdSet = new Set<Id>();
        Set<String> userOutletkeySet = new Set<String>();
        try{
            for(Case_Task__c caseTaskObj :caseTaskList){
                caseIdSet.add(caseTaskObj.Case__c);
                assignUserIdSet.add(caseTaskObj.User_Assigned_To__c);
            }
            
            if(!caseIdSet.isEmpty()){
                for(Case caseObj : [SELECT Id,AccountId FROM Case WHERE Id IN : caseIdSet]){
                    if(caseObj.AccountId != null){
                        caseAccIdMap.put(caseObj.Id,caseObj.AccountId);
                    }
                }
                caseIdSet.clear();
                if(!caseAccIdMap.isEmpty()){
                    for(Outlet_Member__c outltMemObj : [SELECT Id,Outlet__c,User__c 
                                                        FROM Outlet_Member__c 
                                                        WHERE Outlet__c IN : caseAccIdMap.values()
                                                        AND User__c IN : assignUserIdSet]){
                                                            String cmpKey = outltMemObj.User__c+'_'+outltMemObj.Outlet__c;
                                                            outletMemberMap.put(cmpKey,outltMemObj);
                                                        }
                    for(User_Business_Role__c userRole : [SELECT Id, User__c, Business_Role__c,
                                                          Business_Role__r.Global_Equivalent__c 
                                                          FROM User_Business_Role__c 
                                                          WHERE User__c IN:assignUserIdSet]){
                                                              if(!userBusinessRoleMap.containsKey(userRole.User__c)){
                                                                  if(userRole.Business_Role__c != null){
                                                                      userBusinessRoleMap.put(userRole.User__c,userRole.Business_Role__r.Global_Equivalent__c);
                                                                  }
                                                              }
                                                          }
                    assignUserIdSet.clear();
                    for(Mapping_Account_Team_and_Outlet_Member__mdt cusData : [SELECT Id,Account_Team_Role__c,
                                                                               Global_Equivalent_Role__c, Outlet_Member_Role__c 
                                                                               FROM Mapping_Account_Team_and_Outlet_Member__mdt] ){
                                                                                   if(!userRoleMap.containsKey(cusData.Global_Equivalent_Role__c)){
                                                                                       userRoleMap.put(cusData.Global_Equivalent_Role__c,cusData.Outlet_Member_Role__c);
                                                                                       userAccountRoleMap.put(cusData.Global_Equivalent_Role__c, cusData.Account_Team_Role__c);
                                                                                   }
                                                                               }      
                }
                for(Case_Task__c taskObj: caseTaskList){
                    String cmpKey;
                    String accId = (caseAccIdMap!=null && caseAccIdMap.containsKey(taskObj.case__c))? caseAccIdMap.get(taskObj.case__c):null;                
                    if (accId != null && taskObj.User_Assigned_To__c != null){
                        cmpKey = taskObj.User_Assigned_To__c+'_'+accId;    
                    }
                    System.debug(LoggingLevel.DEBUG,'cmpKey==>'+cmpKey);
                    System.debug(LoggingLevel.DEBUG,'outletMemberMap==>'+outletMemberMap);
                    if(cmpKey != null && String.isNotBlank(accId)){
                        if(!outletMemberMap.containsKey(cmpKey)){ 
                            Outlet_Member__c ouMember = createOutletMember(accId,taskObj.User_Assigned_To__c,userBusinessRoleMap,userRoleMap);
                            outletMemInsrtLst.put(ouMember.OutletUser__c,ouMember);
                        }else{
                            atmUserIdAccountIdKey.add(cmpKey);
                            atmUserIdSet.add(taskObj.User_Assigned_To__c);
                            atmAccountIdSet.add(accId);
                        }
                    }
                }
                if(atmUserIdAccountIdKey != null && atmUserIdAccountIdKey.size()>0){
                    if(atmAccountIdSet != null && atmAccountIdSet.size()>0 && atmUserIdSet != null && atmUserIdSet.size()>0){
                        for(AccountTeamMember atmUserOutlet: [SELECT id,AccountId,UserId FROM AccountTeamMember WHERE AccountId IN :atmAccountIdSet
                                                              AND UserId IN : atmUserIdSet]){
                                                                  if(atmUserOutlet.UserId != null && atmUserOutlet.AccountId != null){
                                                                      String userIdOutletIdKey = atmUserOutlet.UserId+'_'+atmUserOutlet.AccountId;
                                                                      userOutletkeyAtmIdMap.put(userIdOutletIdKey,atmUserOutlet.Id);
                                                                      userOutletkeySet.add(userIdOutletIdKey);
                                                                  }
                                                              }
                    }
                    
                    for(String atmkey: atmUserIdAccountIdKey){
                        if(!userOutletkeySet.contains(atmkey)){
                            List<String> keySplit = atmkey.Split('_');
                            String userId = keySplit[0];
                            String accountId = keySplit[1];
                            accountTeamMember atmObj = createAccountTeamMember(accountId,userId,userBusinessRoleMap,userRoleMap,userAccountRoleMap);
                            accountTeamMemberMap.put(atmkey,atmObj);
                        }
                    }
                }
                
                if(outletMemInsrtLst != null && !outletMemInsrtLst.values().isEmpty()){
                    Database.insert(outletMemInsrtLst.values(),false);
                }
                if(accountTeamMemberMap != null && !accountTeamMemberMap.values().isEmpty()){
                    Database.insert(accountTeamMemberMap.values(),false);
                }
            }
        } 
        catch(Exception ex){
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
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_RemoveOldUserAccessForCTBatch', exceptionMsg);
        }
        else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
     /**
    * @description :Creating Outlet_Member instance(ES20-10803)
    * @return : Outlet_Member__c
    * @param : AccountId, UserId
    */
    public static Outlet_Member__c createOutletMember(Id accId,Id userId,Map<Id,String> userBusinessRoleMap,Map<String,String> userRoleMap){
        
        Outlet_Member__c outletMemberRec = new Outlet_Member__c();
        outletMemberRec.Outlet__c = accId;
        outletMemberRec.User__c = userId;
        if(userBusinessRoleMap!= null && userBusinessRoleMap.containsKey(userId)){
            
            if( userRoleMap!=null && userRoleMap.containsKey(userBusinessRoleMap.get(userId))){
                outletMemberRec.Outlet_Role__c = userRoleMap.get(userBusinessRoleMap.get(userId));
            }
            
        }
        outletMemberRec.OutletUser__c = userId + '-' + accId;
        
        outletMemberRec.Temporary_Assigned__c = true;
        return outletMemberRec;
    }
    
    /**
    * @description :Creating createAccountTeamMember instance(ES20-13681)
    * @return : AccountTeamMember
    * @param : AccountId, UserId ,userBusinessRoleMap=userId-GBR,userRoleMap=GBR-OutletRole,userAccountRoleMap = GBE-AccountRole
    */
    public static AccountTeamMember createAccountTeamMember(Id accId,Id userId,Map<Id,String> userBusinessRoleMap,Map<String,String> userRoleMap,Map<String,String> userAccountRoleMap){
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        if(accId != null  && userId != null){
            newAccTeamMember.AccountId = accId;
            newAccTeamMember.UserId = userId;
        }
        if(userAccountRoleMap != null && userBusinessRoleMap != null && userBusinessRoleMap.containskey(userId) && userAccountRoleMap.containsKey(userBusinessRoleMap.get(userId))){
            newAccTeamMember.TeamMemberRole = userAccountRoleMap.get(userBusinessRoleMap.get(userId));
        }else{
            if(userRoleMap != null && userRoleMap.containskey(userId)){
                newAccTeamMember.TeamMemberRole = userRoleMap.get(userBusinessRoleMap.get(userId));
            }
        }
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        return newAccTeamMember;
    }
    
}