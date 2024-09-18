/**

* @Description: EDGE_QualityCaseTaskTriggerHelper

* @Purpose : Quality Trigger Helper Class for CaseTask

* @History:

* @Version     Developer             Date              Story/Purpose

*  1.1         Anand Uppalapati     9/20/2021          ES20-10764(Changing the Status of Case based on Case Task Achievement Status)
*  1.2         Saurav Paul          29/09/2021         ES20-10803(Method:createAccess,createOutletMember - Temporarily Assigned Logic)
*  1.3         Prasanth T           14/10/2021         ES20-10893(Method:sendPushNotificationCaseTask - Send push notification to assigned users for single Case Task assignment)
*  1.4         Sudipta Nandi        30/10/2021         ES20-10839(Method:createCaseTaskKPIRecords,caseTaskVsSlaKPI,caseTaskVsTotalKPI,getkpiAchievementMap - Create User KPI record for case Task)
*  1.5         Subhodeep Sarkar     01/11/2021         ES20-11213(Method:populateUserAssignedTo - Auto population of User Assigned To field in Case Task)
*  1.6		   Aparajita            23/11/2021         ES20-11513(Method:sendPushNotificationCaseTask - Send push notification to assigned users for bulk Case Task assignment)
*  1.7		   Sudipta              26/11/2021         ES20-11513(Method:sendPushNotificationCaseTask - Send push notification to assigned users for bulk Case Task assignment)
*  1.8		   Mayank				28/12/2021		   ES20-11728(Method:sendPushNotificationCaseTask - consolidate Notifications sent after to mass-assignment of case tasks to a user_SFDC_Cases and Case Tasks)
*  1.9		   Prasanth T			28/01/2022		   ES20-10698(Method:updateAssetWithCaseTaskStatus - update Last Cleaning Date field in Asset object)
*  1.10		   Supriya 				7/02/2022		   ES20-12020(Method:populateActionedWithinSLA - Update Actioned Within SLA Flag on Case Task Object)
*  1.12		   Sudipta 				7/03/2022		   ES20-12257(Method: CreateAccess - Update CreateAccess Method for Temporary Access issue for same acc and user comb)
*  1.13		   Prasanth T			27/12/2022		   ES20-13681(Method: CreateAccess - Update CreateAccess Method to avoid OM creation without account/user and creation of corresponding Account Team member records)
*  1.14        Wribhu               02/05/2023         GT-26: Implementation story for adding the filter for Quality record type for the Quality Assets instances
*  1.15		   Swagata shaw			27/05/2023		   CUS-194 (Method:populateLastModifyUserId)
*/

public with sharing class EDGE_QualityCaseTaskTriggerHelper {
    
    public static String userKPIRecTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
    final static String QualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    public static String EDGE_ACHIEVED_STATUS ='Achieved';
    public static String EDGE_NOT_ACHIEVED_STATUS ='Not Achieved';
    public static String EDGE_CANCELLED_STATUS ='Cancelled';
    public static String EDGE_NEW_WITH_OPEN_KEYWORD ='NewWithOpen';
    public static String EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD ='NewWithOutSlaAchieved';
    public static String EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD ='NewWithSlaAchieved';
    public static String EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD ='ExistingWithoutSlaAchieved';
    public static String EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD ='ExistingWithSlaAchieved';
    public static String EDGE_CASE_TASK_VS_SLA_KEYWORD ='Case Task vs SLA';
    public static String EDGE_CASE_TASK_VS_TOTAL_KEYWORD ='Case Task vs Total';
    
    public static void updateCaseStatus(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        List<Case> caseObjList = new List<Case>();
        List<Case> caseObjListToUpdate = new List<Case>();
        List<Case_Task__c> updateCaseTaskList = new List<Case_Task__c>();
        Set<Id> caseIdSet = new set<Id>();
        Map<Id,Case_Task__c> newCasetaskMap = (Map<id,Case_Task__c>)newItems;
        Map<Id,Case_Task__c> oldCaseTaskMap;
        if(oldItems!= null){
            oldCaseTaskMap = (Map<Id,Case_Task__c>)oldItems;
        }
        if(newCasetaskMap != null && newCasetaskMap.size()>0){
            for(Case_Task__c newCaseTask : newCasetaskMap.values()){
                if((oldCaseTaskMap == null)|| (oldCaseTaskMap !=null && oldCaseTaskMap.containsKey(newCaseTask.Id)
                                               && newCaseTask.Achievement_Status__c != oldCaseTaskMap.get(newCaseTask.Id).Achievement_Status__c)){
                                                   caseIdSet.add(newCaseTask.Case__c);
                                               }
            }
        }
        
        if(caseIdSet.size() > 0)
        {
            caseObjList = [SELECT Id,Status,Due_Date_Time__c,Case_SLA_Met__c, (SELECT Id,Achievement_Status__c
                                                                               FROM Case_Tasks__r) FROM Case WHERE Id IN : caseIdSet AND RecordTypeId =: QualityRecordTypeId ];
            if(caseObjList != null && caseObjList.Size()> 0){
                for(Case cse : caseObjList){
                    Boolean setToOpen = false;
                    Boolean setToOnHold = false;
                    Boolean setToClose = true;
                    for(Case_Task__c co : cse.Case_Tasks__r){
                        if(co.Achievement_Status__c == EDGE_Constant.OPEN_QUALITYCASE){
                            setToOpen = true;
                            setToClose =false;
                            setToOnHold = false;
                            break;
                        }
                        Else if(co.Achievement_Status__c == EDGE_Constant.PENDING_QUALITYCASE){
                            setToOnHold = True;
                            setToClose = false;
                        }
                    }
                    if(setToOpen){
                        cse.Status = EDGE_Constant.OPEN_QUALITYCASE;
                    }
                    if(setToOnHold){
                        cse.Status = EDGE_Constant.ONHOLD_QUALITYCASE;
                    }
                    if(setToClose){
                        cse.Status = EDGE_Constant.CLOSED_QUALITYCASE;
                    }
                    caseObjListToUpdate.add(cse);
                    
                }
            }
        }
        
        if(caseObjListToUpdate != null && caseObjListToUpdate.size() > 0){
            update caseObjListToUpdate;
        }
        
    }
    
    
    /**
* @description :Creating Temporarily Assigned Outlet Member record to provide access(ES20-10803)
* @return : Void
* @param : newList , oldMap
*/
    public static void createAccess(List<Case_Task__c> newCaseTaskList,Map<Id, SObject>oldItems){
        //Variables
        Map<Id,Case_Task__c> oldCaseTaskMap;
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> assignUserIdSet = new Set<Id>();
        Map<Id,Id> caseAccIdMap= new Map<Id,Id>();
        Map<String,Outlet_Member__c> outletMemberMap = new Map<String,Outlet_Member__c>();
        List<Case_Task__c> caseTaskList = new List<Case_Task__c>();
        MAP<String,Outlet_Member__c> outletMemInsrtLst = new MAP<String,Outlet_Member__c>();
        Map<Id,String> userBusinessRoleMap = new Map<Id,String>();
        Map<String,String> userAccountRoleMap = new Map<string,String>();
        Map<String,String> userRoleMap = new Map<String,String>();
        List<String> eligibleStatus = System.Label.EDGE_CaseTaskStatus.split(';');
        //ES20-13681
        Map<String,Id> userOutletkeyAtmIdMap= new Map<String,Id>();
        Map<String,AccountTeamMember> accountTeamMemberMap = new  Map<String,AccountTeamMember>();
        Set<String> atmUserIdAccountIdKey = new Set<String>();
        Set<Id> atmUserIdSet = new Set<Id>();
        Set<Id> atmAccountIdSet = new Set<Id>();
        Set<String> userOutletkeySet = new Set<String>();
        
        
        if(oldItems!= null){
            oldCaseTaskMap = (Map<Id,Case_Task__c>)oldItems;
        }
        for(Case_Task__c caseTaskObj :newCaseTaskList){
            
            if((oldCaseTaskMap == null && String.isNotBlank(caseTaskObj.User_Assigned_To__c) && eligibleStatus.contains(caseTaskObj.Achievement_Status__c))||
               (oldCaseTaskMap!=null && oldCaseTaskMap.containsKey(caseTaskObj.Id)
                && String.isNotBlank(caseTaskObj.User_Assigned_To__c) && caseTaskObj.User_Assigned_To__c != oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c && eligibleStatus.contains(caseTaskObj.Achievement_Status__c))){
                    caseIdSet.add(caseTaskObj.Case__c);
                    assignUserIdSet.add(caseTaskObj.User_Assigned_To__c);
                    caseTaskList.add(caseTaskObj);
                }
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
                if(cmpKey != null && String.isNotBlank(accId)){
                    if(!outletMemberMap.containsKey(cmpKey)){ 
                        Outlet_Member__c ouMember = createOutletMember(accId,taskObj.User_Assigned_To__c,userBusinessRoleMap,userRoleMap);
                        outletMemInsrtLst.put(ouMember.OutletUser__c,ouMember);
                    }else{//ES20-13681 created this block to create new accountTeamMember records if OM record exists and corresponding Atm record is missing
                        atmUserIdAccountIdKey.add(cmpKey);
                        atmUserIdSet.add(taskObj.User_Assigned_To__c);
                        atmAccountIdSet.add(accId);
                    }
                }
            }
            
            try{
                if(outletMemInsrtLst != null && !outletMemInsrtLst.values().isEmpty()){
                    Database.insert(outletMemInsrtLst.values(),false);
                }
                
            }catch(Exception ex){
                System.debug('Exception is'+ex);
            }
            //ES20-13681
            if(atmUserIdAccountIdKey != null && atmUserIdAccountIdKey.size()>0){
                //used this metadata to determine dml access of the object if true then proceed with DML
                Map<String,EDGE_Quality_Service_Object__mdt> dmlAccessMetadata = EDGE_Quality_Service_Object__mdt.getAll();
                Map<String,Boolean> apiNameAccessCheckMap = new Map<String,Boolean>();
                if(dmlAccessMetadata != null&& dmlAccessMetadata.size()>0){
                    for(EDGE_Quality_Service_Object__mdt mdtObj : dmlAccessMetadata.values()){
                        apiNameAccessCheckMap.put(mdtObj.Object_API_Name__c,mdtObj.DML_Access__c);
                    }
                }
                //checking dml access from Metadata for AccountTeamMember
                if(apiNameAccessCheckMap.containskey('AccountTeamMember') && apiNameAccessCheckMap.get('AccountTeamMember') == true){
                    //ES20-13681
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
            }
            
            try{
                //ES20-13681
                if(accountTeamMemberMap != null && !accountTeamMemberMap.values().isEmpty()){
                    Database.insert(accountTeamMemberMap.values(),false);
                }
            }catch(Exception ex){
                System.debug('Exception is'+ex);
            }
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
    
    /**
* @description : This method is used to populate User Assigned To field if Contractor checkbox is checked in Case Task record (ES20-11213) 
* @return : void
* @param : List<Case_Task__c>,Map<Id,SObject> oldMap
*/
    public static void populateUserAssignedTo(List<Case_Task__c> newItems, Map<Id,SObject> oldMap){
        Map<Id,Case_Task__c> oldCaseTaskMap = (Map<Id,Case_Task__c>)oldMap;
        set<Id> newUserId = new set<Id>();
        for(Case_Task__c caseTaskobj : newItems){
            newUserId.add(caseTaskobj.User_Assigned_To__c);
        }
        Map<Id,User> userMap = new Map<Id,User>([Select Id,Contractor__c from User where id in :newUserId]);
        
        for(Case_Task__c caseTaskobj : newItems){
            
            //for New If User_Assigned_To__c not null win User_Assigned_To__c value
            if(oldCaseTaskMap == null && caseTaskobj.User_Assigned_To__c != null){
                if(userMap.get(caseTaskobj.User_Assigned_To__c).Contractor__c)
                    caseTaskobj.Contractor_Name__c = caseTaskobj.User_Assigned_To__c;
                else
                    caseTaskobj.Contractor_Name__c = null;
            }
            //for New If User_Assigned_To__c  null but  Contractor_Name__c is there then Contractor_Name__c value win
            else if(oldCaseTaskMap == null && caseTaskobj.User_Assigned_To__c == null && caseTaskobj.Contractor_Name__c != null){
                caseTaskobj.User_Assigned_To__c = caseTaskobj.Contractor_Name__c;
            }
            //for exiting update If User_Assigned_To__c  not null and User_Assigned_To__c value changed and User_Assigned_To__c is contrator user update contractor name 
            else if(oldCaseTaskMap != null && caseTaskobj.User_Assigned_To__c != null && caseTaskobj.User_Assigned_To__c != oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c){
                if(userMap.get(caseTaskobj.User_Assigned_To__c).Contractor__c)
                    caseTaskobj.Contractor_Name__c = caseTaskobj.User_Assigned_To__c;
                else
                    caseTaskobj.Contractor_Name__c = null;
            }
            //for exiting update If User_Assigned_To__c   null and User_Assigned_To__c value changed  update contractor name as blank
            else if(oldCaseTaskMap != null && caseTaskobj.User_Assigned_To__c == null && caseTaskobj.User_Assigned_To__c != oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c){
                caseTaskobj.Contractor_Name__c = null;
            }
            //for exiting update If User_Assigned_To__c   not changed  and Contractor_Name__c value changed  with not null then update User_Assigned_To__c value
            else if(oldCaseTaskMap != null && caseTaskobj.User_Assigned_To__c == oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c && caseTaskobj.Contractor_Name__c != null && caseTaskobj.Contractor_Name__c != oldCaseTaskMap.get(caseTaskObj.Id).Contractor_Name__c){
                caseTaskobj.User_Assigned_To__c = caseTaskobj.Contractor_Name__c;
            }
            //for exiting update If User_Assigned_To__c   not changed  and Contractor_Name__c value changed  with  null then update User_Assigned_To__c value with null
            else if(oldCaseTaskMap != null && caseTaskobj.User_Assigned_To__c == oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c && caseTaskobj.Contractor_Name__c == null && caseTaskobj.Contractor_Name__c != oldCaseTaskMap.get(caseTaskObj.Id).Contractor_Name__c){
                caseTaskobj.User_Assigned_To__c = null;
            }
        }
    }
    /**
* @description :Creating CaseTask KPI Records instance(ES20-10839)
* @return : void
* @param : newCaseTaskList, oldItems
*/
    
    public static void createCaseTaskKPIRecords(List<Case_Task__c> newCaseTaskList,Map<Id, SObject>oldItems){
        //Variables
        Map<Id,Case_Task__c> oldCaseTaskMap;
        
        MAP<Id,Id> newUserWithOpenStatusMap = new MAP<Id,Id>();
        MAP<Id,Id> newUserIdWithOutSlaAchievedMap = new MAP<Id,Id>();
        MAP<Id,Id> newUserIdWithSlaAchievedMap = new MAP<Id,Id>();
        MAP<Id,Id> cancelledAndReAssignIdMap = new MAP<Id,Id>();
        MAP<Id,Id> achievedNotAchievedUserIdMap = new MAP<Id,Id>();
        MAP<Id,Id> achievedNotAchievedSlaUserIdMap = new MAP<Id,Id>();
        Map<String, Id> kpiAchivementMap = new Map<String, Id>();
        
        List<String> eligibleStatus = System.Label.EDGE_CaseTaskStatus.split(';'); 
        
        if(oldItems!= null){
            oldCaseTaskMap = (Map<Id,Case_Task__c>)oldItems;
        }
        for(Case_Task__c caseTaskObj :newCaseTaskList){
            if(oldCaseTaskMap == null && String.isNotBlank(caseTaskObj.User_Assigned_To__c)){
                if(eligibleStatus.contains(caseTaskObj.Achievement_Status__c)){
                    newUserWithOpenStatusMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                }
                else if(caseTaskObj.Achievement_Status__c == EDGE_ACHIEVED_STATUS || caseTaskObj.Achievement_Status__c == EDGE_NOT_ACHIEVED_STATUS){
                    if(caseTaskObj.Actioned_Within_SLA__c == True){
                        newUserIdWithSlaAchievedMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                    }
                    else{
                        newUserIdWithOutSlaAchievedMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                    }
                }
                
            }
            else if(oldCaseTaskMap!=null && oldCaseTaskMap.containsKey(caseTaskObj.Id)){
                if(caseTaskObj.User_Assigned_To__c != oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c ){
                    if(eligibleStatus.contains(caseTaskObj.Achievement_Status__c) || caseTaskObj.Achievement_Status__c == EDGE_CANCELLED_STATUS){
                        if(String.isNotBlank(caseTaskObj.User_Assigned_To__c)){
                            newUserWithOpenStatusMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                        }
                        if(String.isNotBlank(oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c)){
                            cancelledAndReAssignIdMap.put(caseTaskObj.Id,oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c);
                        }
                    }
                    else if(caseTaskObj.Achievement_Status__c == EDGE_ACHIEVED_STATUS || caseTaskObj.Achievement_Status__c == EDGE_NOT_ACHIEVED_STATUS){
                        
                        if(caseTaskObj.Actioned_Within_SLA__c == True && String.isNotBlank(caseTaskObj.User_Assigned_To__c)){
                            newUserIdWithSlaAchievedMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                            
                        }
                        if(String.isNotBlank(caseTaskObj.User_Assigned_To__c)){
                            newUserIdWithOutSlaAchievedMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                        }
                        if(String.isNotBlank(oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c)){
                            cancelledAndReAssignIdMap.put(caseTaskObj.Id,oldCaseTaskMap.get(caseTaskObj.Id).User_Assigned_To__c);  
                        }
                    }
                }
                else{
                    if(caseTaskObj.Achievement_Status__c != oldCaseTaskMap.get(caseTaskObj.Id).Achievement_Status__c && caseTaskObj.Achievement_Status__c == EDGE_CANCELLED_STATUS){
                        cancelledAndReAssignIdMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                    }
                    else if((caseTaskObj.Achievement_Status__c != oldCaseTaskMap.get(caseTaskObj.Id).Achievement_Status__c) && (caseTaskObj.Achievement_Status__c == EDGE_ACHIEVED_STATUS || caseTaskObj.Achievement_Status__c == EDGE_NOT_ACHIEVED_STATUS)){
                        if(caseTaskObj.Actioned_Within_SLA__c == True && caseTaskObj.Actioned_Within_SLA__c != oldCaseTaskMap.get(caseTaskObj.Id).Actioned_Within_SLA__c){
                            achievedNotAchievedSlaUserIdMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                        }
                        if(caseTaskObj.Achievement_Status__c != oldCaseTaskMap.get(caseTaskObj.Id).Achievement_Status__c){
                            achievedNotAchievedUserIdMap.put(caseTaskObj.Id,caseTaskObj.User_Assigned_To__c);
                        }
                    }
                }
            }
            
        }
        if(!newUserWithOpenStatusMap.isEmpty()){
            caseTaskVsTotalKPI(newUserWithOpenStatusMap,EDGE_NEW_WITH_OPEN_KEYWORD);
            caseTaskVsSlaKPI(newUserWithOpenStatusMap,EDGE_NEW_WITH_OPEN_KEYWORD);
        }
        if(!newUserIdWithOutSlaAchievedMap.isEmpty()){
            caseTaskVsTotalKPI(newUserIdWithOutSlaAchievedMap, EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD);
            caseTaskVsSlaKPI(newUserIdWithOutSlaAchievedMap, EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD);
        }
        if(!newUserIdWithSlaAchievedMap.isEmpty()){
            caseTaskVsTotalKPI(newUserIdWithSlaAchievedMap,EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD);
            caseTaskVsSlaKPI(newUserIdWithSlaAchievedMap,EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD);
        }
        if(!cancelledAndReAssignIdMap.isEmpty()){
            caseTaskVsTotalKPI(cancelledAndReAssignIdMap, EDGE_CANCELLED_STATUS);
            caseTaskVsSlaKPI(cancelledAndReAssignIdMap, EDGE_CANCELLED_STATUS);
        }
        if(!achievedNotAchievedUserIdMap.isEmpty()){
            caseTaskVsTotalKPI(achievedNotAchievedUserIdMap,EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD);
            //caseTaskVsSlaKPI(achievedNotAchievedUserIdMap,EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD);
        }
        if(!achievedNotAchievedSlaUserIdMap.isEmpty()){
            //caseTaskVsTotalKPI(achievedNotAchievedSlaUserIdMap,EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD);
            caseTaskVsSlaKPI(achievedNotAchievedSlaUserIdMap,EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD);
        }
        
    }
    /**
* @description :Creating CaseTask vs SLA KPI type Records (ES20-10839)
* @return : void
* @param : MAP<Id,Id>, String
*/
    public static void caseTaskVsSlaKPI(MAP<Id,Id>userMap,String State){
        Map<String, KPI_Achivement__c> kpiAchivementMap = new Map<String, KPI_Achivement__c>();
        Map<String, KPI_Achivement__c> kpiAchvMap = new Map<String, KPI_Achivement__c>();
        set<Id> userIds = new set<Id>();
        Map<Id, String> userToCountryMap = new Map<Id, String>();
        
        for(id userId : userMap.values()){
            userIds.add(userId);
        }
        userToCountryMap = EDGE_DataUtility.fetchUserCountry(userIds);
        
        kpiAchivementMap = getkpiAchievementMap(userMap);
        for(id userId : userMap.values()){
            String cmpKey = userId + '_' + EDGE_CASE_TASK_VS_SLA_KEYWORD;
            //User userRec = userMap.get(userId);
            if(kpiAchivementMap == null || (kpiAchivementMap!=null && !kpiAchivementMap.containsKey(cmpKey)))
            {
                if(userToCountryMap!=null && userToCountryMap.containsKey(userId)){
                    KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
                    kpiAchive.RecordTypeId = userKPIRecTypeId;
                    kpiAchive.KPI_Type__c = EDGE_CASE_TASK_VS_SLA_KEYWORD;
                    if(State == EDGE_NEW_WITH_OPEN_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 0;  
                        kpiAchive.Total_Denominator__c = 1;
                    }
                    else if(State == EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 0;  
                        kpiAchive.Total_Denominator__c = 1; 
                    }
                    else if(State == EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 1;  
                        kpiAchive.Total_Denominator__c = 1; 
                    }
                    else if(State == EDGE_CANCELLED_STATUS){
                        kpiAchive.Actual_Numerator__c = 0;  
                        kpiAchive.Total_Denominator__c = 0; 
                    }
                    else if(State == EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 0;  
                        kpiAchive.Total_Denominator__c = 1;  
                    }
                    else if(State == EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 1;  
                        kpiAchive.Total_Denominator__c = 1;
                    }
                    if(kpiAchive.Total_Denominator__c != 0 && kpiAchive.Total_Denominator__c != null){
                        kpiAchive.Achievement__c = (kpiAchive.Actual_Numerator__c*100/kpiAchive.Total_Denominator__c);
                    }   
                    kpiAchive.User__c = userId;
                    kpiAchvMap.put(cmpKey,kpiAchive);
                }
            }
            else{
                KPI_Achivement__c kpiAchive = kpiAchivementMap.get(cmpKey);
                if(State == EDGE_NEW_WITH_OPEN_KEYWORD){
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c !=null) ? kpiAchive.Total_Denominator__c + 1 : 1;
                }
                else if(State == EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c !=null) ? kpiAchive.Total_Denominator__c + 1 : 1;
                }
                else if(State == EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Actual_Numerator__c = (kpiAchive.Actual_Numerator__c !=null) ? kpiAchive.Actual_Numerator__c + 1 : 1;
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c !=null) ? kpiAchive.Total_Denominator__c + 1 : 1;
                }
                else if(State == EDGE_CANCELLED_STATUS){
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c == 0)?kpiAchive.Total_Denominator__c: kpiAchive.Total_Denominator__c - 1; 
                }
                else if(State == EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Actual_Numerator__c = (kpiAchive.Actual_Numerator__c !=null) ? kpiAchive.Actual_Numerator__c + 1 : 1; 
                }
                //else if(State == EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                //no increment.. as is  
                //}
                if(kpiAchive.Total_Denominator__c != 0 && kpiAchive.Total_Denominator__c != null){
                    kpiAchive.Achievement__c = (kpiAchive.Actual_Numerator__c*100/kpiAchive.Total_Denominator__c);
                }
                kpiAchvMap.put(cmpKey,kpiAchive);
            }
            
        }
        if(kpiAchvMap != null && kpiAchvMap.values().Size()>0){
            EDGE_QualityCaseTaskTriggerUtility.createKpiAchievementRecords(kpiAchvMap.values());
        }
    }
    
    /**
* @description :Creating CaseTask vs Total KPI type Records (ES20-10839)
* @return : void
* @param : MAP<Id,Id>, String
*/
    public static void caseTaskVsTotalKPI(MAP<Id,Id>userMap,String State){
        Map<String, KPI_Achivement__c> kpiAchivementMap = new Map<String, KPI_Achivement__c>();
        Map<String, KPI_Achivement__c> kpiAchvMap = new Map<String, KPI_Achivement__c>();
        
        set<Id> userIds = new set<Id>();
        Map<Id, String> userToCountryMap = new Map<Id, String>();
        
        for(id userId : userMap.values()){
            userIds.add(userId);
        }
        userToCountryMap = EDGE_DataUtility.fetchUserCountry(userIds);
        
        kpiAchivementMap = getkpiAchievementMap(userMap);
        for(id userId : userMap.values()){
            String cmpKey = userId + '_' + EDGE_CASE_TASK_VS_TOTAL_KEYWORD;
            if(kpiAchivementMap == null || (kpiAchivementMap!=null && !kpiAchivementMap.containsKey(cmpKey)))
            {
                if(userToCountryMap!=null && userToCountryMap.containsKey(userId)){
                    KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
                    kpiAchive.RecordTypeId = userKPIRecTypeId;
                    kpiAchive.KPI_Type__c = EDGE_CASE_TASK_VS_TOTAL_KEYWORD;
                    if(State == EDGE_NEW_WITH_OPEN_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 0;  
                        kpiAchive.Total_Denominator__c = 1;
                    }
                    else if(State == EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 1;  
                        kpiAchive.Total_Denominator__c = 1; 
                    }
                    else if(State == EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 1;  
                        kpiAchive.Total_Denominator__c = 1; 
                    }
                    else if(State == EDGE_CANCELLED_STATUS){
                        kpiAchive.Actual_Numerator__c = 0;  
                        kpiAchive.Total_Denominator__c = 0; 
                    }
                    else if(State == EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 1;  
                        kpiAchive.Total_Denominator__c = 1;  
                    }
                    else if(State == EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD){
                        kpiAchive.Actual_Numerator__c = 1;  
                        kpiAchive.Total_Denominator__c = 1;
                    }
                    if(kpiAchive.Total_Denominator__c != 0 && kpiAchive.Total_Denominator__c != null){
                        kpiAchive.Achievement__c = (kpiAchive.Actual_Numerator__c*100/kpiAchive.Total_Denominator__c);
                    }   
                    kpiAchive.User__c = userId;
                    kpiAchvMap.put(cmpKey,kpiAchive);
                }
            }
            else{
                KPI_Achivement__c kpiAchive = kpiAchivementMap.get(cmpKey);
                if(State == EDGE_NEW_WITH_OPEN_KEYWORD){
                    kpiAchive.Total_Denominator__c = kpiAchive.Total_Denominator__c + 1;
                }
                else if(State == EDGE_NEW_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Actual_Numerator__c = (kpiAchive.Actual_Numerator__c !=null) ? kpiAchive.Actual_Numerator__c + 1 : 1;
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c !=null) ? kpiAchive.Total_Denominator__c + 1 : 1;
                }
                else if(State == EDGE_NEW_WITH_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Actual_Numerator__c = (kpiAchive.Actual_Numerator__c !=null) ? kpiAchive.Actual_Numerator__c + 1 : 1; 
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c !=null) ? kpiAchive.Total_Denominator__c + 1 : 1;
                }
                else if(State == EDGE_CANCELLED_STATUS){
                    kpiAchive.Total_Denominator__c = (kpiAchive.Total_Denominator__c == 0 || kpiAchive.Total_Denominator__c == null)? 0: kpiAchive.Total_Denominator__c - 1; 
                }
                else if(State == EDGE_EXISTING_WITH_OUT_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Actual_Numerator__c = (kpiAchive.Actual_Numerator__c !=null) ? kpiAchive.Actual_Numerator__c + 1 : 1;
                }
                else if(State == EDGE_EXISTING_WITH_SLA_ACHIEVED_KEYWORD){
                    kpiAchive.Actual_Numerator__c = (kpiAchive.Actual_Numerator__c !=null) ? kpiAchive.Actual_Numerator__c + 1 : 1;
                }
                if(kpiAchive.Total_Denominator__c != 0 && kpiAchive.Total_Denominator__c != null){
                    kpiAchive.Achievement__c = (kpiAchive.Actual_Numerator__c*100/kpiAchive.Total_Denominator__c);
                }   
                kpiAchvMap.put(cmpKey,kpiAchive);
            }
            
        }
        if(kpiAchvMap != null && kpiAchvMap.values().Size()>0){
            EDGE_QualityCaseTaskTriggerUtility.createKpiAchievementRecords(kpiAchvMap.values());
        }
    }
    /**
* @description :fecthing existing user kpi record (ES20-10839)
* @return : Map<String, KPI_Achivement__c>
* @param : MAP<Id,Id>
*/
    public static Map<String, KPI_Achivement__c> getkpiAchievementMap(MAP<Id,Id>userMap){
        Map<String, KPI_Achivement__c> kpiAchivementMap = new Map<String, KPI_Achivement__c>();
        
        //Quering on KPI Achievement object for Upserting Records
        for(KPI_Achivement__c kpiAchive : [SELECT Id, User__c, Category__c, Volume_Category__c, KPI_Type__c,Actual_Numerator__c,Total_Denominator__c,Achievement__c FROM KPI_Achivement__c WHERE User__c IN :userMap.values() AND recordType.developerName = 'User_KPI']){
            if(kpiAchive.KPI_Type__c == EDGE_CASE_TASK_VS_TOTAL_KEYWORD || kpiAchive.KPI_Type__c == EDGE_CASE_TASK_VS_SLA_KEYWORD){
                kpiAchivementMap.put(kpiAchive.User__c + '_' + kpiAchive.KPI_Type__c, kpiAchive);                    
            }
            
        }
        return kpiAchivementMap;
    }
    
    /**
* @description : Sending single(ES20-10893->Prasanth)/bulk(ES20-11513->Aparajita) push notifications to assigned users for Case Tasks

* @return : void

* @param : Map<Id,SObject>
*/
    public static void sendPushNotificationCaseTask(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        //Initialization
        String msgForSingleNotif = System.label.EDGE_QualityCaseTaskPushNotification;
        String msgForBulkNotif = System.label.EDGE_QualityBulkCaseTaskPushNotification;
        List<Case_Task__c> newCaseTaskList = (List<Case_Task__c>)newItems.values();
        Map<Id,Case_Task__c> oldCaseTaskMap = (Map<Id,Case_Task__c>)oldItems;
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id,String> caseRecordTypeMap = new Map<Id,String>();
        String msgBody = null;
        List<String> usersToNotifyList = new List<String>();
        
        Map<String,List<Case_Task__c>> userVsCTMap = new Map<String, List<Case_Task__c>>();
        Integer noOfCaseTasks = 0;
        
        Map<Id,String> accountNameMap = new  Map<Id,String>();
        Map<String,Object> custom = new Map<String,Object>();
        
        //ES20-12672
        if(newCaseTaskList != null){
            for(Case_Task__c cTaskObj : newCaseTaskList){
                if(cTaskObj.Achievement_Status__c != null && (cTaskObj.Achievement_Status__c == EDGE_Constant.OPEN_QUALITYCASE || cTaskObj.Achievement_Status__c == EDGE_Constant.PENDING_QUALITYCASE)){    
                    if((oldCaseTaskMap == null && cTaskObj.User_Assigned_To__c != null) || (oldCaseTaskMap != null && oldCaseTaskMap.get(cTaskObj.Id).User_Assigned_To__c != cTaskObj.User_Assigned_To__c)){
                        accountIdSet.add(cTaskObj.Account__c);
                        caseIdSet.add(cTaskObj.Case__c);
                    }
                } 
            }
            
            //Fetching Account Name
            if(accountIdSet != null && accountIdSet.size()>0){
                for(Account accountObj : [Select Id, Name FROM Account WHERE Id IN :accountIdSet]){
                    accountNameMap.put(accountObj.Id,accountObj.Name);
                }
            }
            
            if(caseIdSet != null && caseIdSet.size()>0){
                
                for(Case caseObj : [Select Id,RecordTypeId FROM Case WHERE Id IN :caseIdSet AND AccountId IN : accountIdSet]){
                    caseRecordTypeMap.put(caseObj.Id,caseObj.RecordTypeId);
                }
            }
            //Sending Push-Notification
            if(newCaseTaskList != null && newCaseTaskList.Size() >0 && newCaseTaskList.Size() <= 9){
                for(Case_Task__c cTaskObj : newCaseTaskList){
                    if(cTaskObj.Achievement_Status__c != null && (cTaskObj.Achievement_Status__c == EDGE_Constant.OPEN_QUALITYCASE || cTaskObj.Achievement_Status__c == EDGE_Constant.PENDING_QUALITYCASE)){    
                        if (cTaskObj.User_Assigned_To__c != null && caseRecordTypeMap.get(cTaskObj.Case__c) == QualityRecordTypeId){
                            if(oldCaseTaskMap != null){//Update Scenario
                                if(oldCaseTaskMap.get(cTaskObj.Id).User_Assigned_To__c != cTaskObj.User_Assigned_To__c ){
                                    if(userVsCTMap.containsKey(cTaskObj.User_Assigned_To__c)){
                                        userVsCTMap.get(cTaskObj.User_Assigned_To__c).add(cTaskObj);
                                    }else{
                                        userVsCTMap.put(cTaskObj.User_Assigned_To__c, new List<Case_Task__c>{cTaskObj});    
                                    }
                                }
                            }
                            else {//Insert scenario
                                if(userVsCTMap.containsKey(cTaskObj.User_Assigned_To__c)){
                                    userVsCTMap.get(cTaskObj.User_Assigned_To__c).add(cTaskObj);
                                }else{
                                    userVsCTMap.put(cTaskObj.User_Assigned_To__c, new List<Case_Task__c>{cTaskObj});    
                                }
                            }
                        }
                    }
                }
                if(userVsCTMap!=null && userVsCTMap.size() >0){            
                    for(String userKey : userVsCTMap.keySet()){ 
                        if(userVsCTMap.get(userKey) != null){
                            usersToNotifyList.add(userKey);
                            
                            noOfCaseTasks = userVsCTMap.get(userKey).size();
                            if(noOfCaseTasks == 1){
                                msgBody = msgForSingleNotif.stripHtmlTags();
                                custom.put('Case-Task Id ', userVsCTMap.get(userKey)[0].Id);
                                custom.put('Case-Id ', userVsCTMap.get(userKey)[0].Case__c);
                                custom.put('Account Id ', userVsCTMap.get(userKey)[0].Account__c);
                                custom.put('Account-Name ', accountNameMap.get(userVsCTMap.get(userKey)[0].Account__c));
                                custom.put('Date of assignment ', userVsCTMap.get(userKey)[0].LastModifiedDate.format());
                                EDGE_QualityCaseTriggerHelper.pushNotificationMethodforCase(usersToNotifyList, msgBody, custom);
                            }
                            else if(noOfCaseTasks > 1){
                                msgBody = msgForBulkNotif.stripHtmlTags();
                                custom.put('Bulk CaseTask ', true);
                                EDGE_QualityCaseTriggerHelper.pushNotificationMethodforCase(usersToNotifyList, msgBody, custom);
                            }
                        }
                    }
                }
                
            }  
            else if(newCaseTaskList != null && newCaseTaskList.size() > 9){
                for(Case_Task__c cTaskObj : newCaseTaskList){
                    if(cTaskObj.Achievement_Status__c != null && (cTaskObj.Achievement_Status__c == EDGE_Constant.OPEN_QUALITYCASE || cTaskObj.Achievement_Status__c == EDGE_Constant.PENDING_QUALITYCASE)){    
                        if (cTaskObj.User_Assigned_To__c != null && caseRecordTypeMap.get(cTaskObj.Case__c) == QualityRecordTypeId){
                            if(oldCaseTaskMap != null){//Update Scenario
                                if(oldCaseTaskMap.get(cTaskObj.Id).User_Assigned_To__c != cTaskObj.User_Assigned_To__c ){
                                    usersToNotifyList.add(cTaskObj.User_Assigned_To__c);
                                }
                            }else{//Insert scenario
                                usersToNotifyList.add(cTaskObj.User_Assigned_To__c);
                            }
                        }
                    }
                }
                msgBody = msgForBulkNotif.stripHtmlTags();
                custom.put('Bulk CaseTask ', true);
                EDGE_QualityCaseTriggerHelper.pushNotificationMethodforCase(usersToNotifyList, msgBody, custom);
            }
        }
    }
    
    /**
* @description : This method is used to populate Suggested User (ES20-11804) 
* @return : void
* @param : List<Case_Task__c>,Map<Id,SObject> oldMap
*/
    public static void populateSuggestedUser(List<Case_Task__c> newItems, Map<Id,SObject> oldMap){
        Map<Id,Case_Task__c> oldCaseTaskMap = (Map<Id,Case_Task__c>)oldMap;
        Set<Id> accounIds = new Set<Id>();
        Set<Id> caseTaskType = new Set<Id>();
        Map<Id, Id> outeltDisRepUser = new Map<Id, Id>();
        Map<Id, String> caseTaskTypeRole = new Map<Id, String>();
        if(newItems != null && newItems.size() > 0){
            for(Case_Task__c caseTaskobj : newItems){
                
                if(caseTaskobj.Batch_Generated__c  == false){
                    if(oldCaseTaskMap == null || (oldCaseTaskMap != null && caseTaskobj.Case_Task_Type__c != oldCaseTaskMap.get(caseTaskobj.Id).Case_Task_Type__c)){
                        accounIds.add(caseTaskobj.Account__c);
                        caseTaskType.add(caseTaskobj.Case_Task_Type__c);
                    }
                    
                }
            }
        }
        if(caseTaskType.size() > 0 && !caseTaskType.isEmpty()){
            for(Quality_Case_Configuration__c caseTaskTypeName :[SELECT Id,Name,Default_Business_Role__c from Quality_Case_Configuration__c WHERE Id IN:caseTaskType]){
                caseTaskTypeRole.put(caseTaskTypeName.Id, caseTaskTypeName.Default_Business_Role__c);
            }
        }
        Map<Id,List<Id>> outletToTerritoryMap = new Map<Id,List<Id>>();
        Map<String,Id> terrToUserMap = new Map<String,Id>();
        Map<String,String> userToRoleMap = new Map<String,String>();
        Set<Id> terrIds = new Set<Id>();
        List<Id> userIds = new List<Id>();
        
        for(Outlet_Territory__c outletTerr :[SELECT Id,Name,Outlet__c, Territory__c from Outlet_Territory__c WHERE Outlet__c IN:accounIds]){
            terrIds.add(outletTerr.Territory__c);
            if(outletToTerritoryMap.containsKey(outletTerr.outlet__c)){
                outletToTerritoryMap.get(outletTerr.outlet__c).add(outletTerr.Territory__c);
            }
            else{
                outletToTerritoryMap.put(outletTerr.outlet__c, new List<Id>{outletTerr.Territory__c});
            }
        }
        
        /*for(Territory_Member__c userTerr :[SELECT Id,User__c,User__r.Business_Role__c,Type__c,User__r.name,Territory__c, from Territory_Member__c 
where Type__c = 'Primary' AND Territory__c IN :terrIds]){
terrToUserMap.put(userTerr.Territory__c, userTerr.User__c);
}*/      
        for(Territory__c terrInfo :[SELECT Id,Primary_Sales_Rep__c from Territory__c where Id IN :terrIds]){
                if(terrInfo.Primary_Sales_Rep__c !=null){
                    terrToUserMap.put(terrInfo.Id, terrInfo.Primary_Sales_Rep__c);
                }
         }
        if(terrToUserMap != null && terrToUserMap.values().size() >0){
            for(User_Business_Role__c userRole : [Select Id, User__c,Business_Role__r.Global_Equivalent__c from User_Business_Role__c 
                                                  where  User__c  IN : terrToUserMap.values()]){
                                                      userToRoleMap.put(userRole.User__c + '_' + userRole.Business_Role__r.Global_Equivalent__c, userRole.Business_Role__r.Global_Equivalent__c);
                                                  }
        }
        
        if(outletToTerritoryMap != null && terrToUserMap != null && userToRoleMap != null){
            for(Case_Task__c caseTaskobj : newItems){
                if(caseTaskobj.Batch_Generated__c == false){
                    if(oldCaseTaskMap != null && oldCaseTaskMap.containsKey(caseTaskobj.Id)){
                        if(caseTaskObj.Case_Task_Type__c != oldCaseTaskMap.get(caseTaskobj.Id).Case_Task_Type__c ){
                            //Update Scenario
                            if(outletToTerritoryMap.containsKey(caseTaskobj.Account__c) && caseTaskTypeRole.containsKey(caseTaskobj.Case_Task_Type__c)){
                                String defaultRole = caseTaskTypeRole.get(caseTaskobj.Case_Task_Type__c);
                                List<Id> territories = outletToTerritoryMap.get(caseTaskobj.Account__c);
                                for(Id ter : territories){
                                    if(terrToUserMap.containsKey(ter)){
                                        String userId = terrToUserMap.get(ter);
                                        if(userToRoleMap.containsKey(userId + '_' + defaultRole)){
                                            caseTaskobj.Suggested_User__c = userId;
                                        }
                                        else{
                                            caseTaskobj.Suggested_User__c = null;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else{
                        if(outletToTerritoryMap.containsKey(caseTaskobj.Account__c) && caseTaskTypeRole.containsKey(caseTaskobj.Case_Task_Type__c)){
                            String defaultRole = caseTaskTypeRole.get(caseTaskobj.Case_Task_Type__c);
                            List<Id> territories = outletToTerritoryMap.get(caseTaskobj.Account__c);
                            for(Id ter:territories){
                                if(terrToUserMap.containsKey(ter)){
                                    String userId = terrToUserMap.get(ter);
                                    if(userToRoleMap.containsKey(userId + '_' + defaultRole)){
                                        caseTaskobj.Suggested_User__c = userId;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
* @description (ES20-10692): This method is used to populate Last Cleaning Date in Asset Object when Case Task status changes to Achieved/Not Achieved 
* @return : void
* @param : Map<Id,Case_Task__c>,Map<Id,SObject> oldMap
*/
    public static void updateAssetWithCaseTaskStatus(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        List<Case_Task__c> newCaseTaskList = (List<Case_Task__c>)newItems.values();
        Map<Id,Case_Task__c> oldCaseTaskMap = (Map<Id,Case_Task__c>)oldItems;
        Set<Id> caseTaskTypeIdSet = new Set<Id>();
        Map<Id,Id> caseTaskAssetMap = new Map<Id,Id>();
        Map<Id,String> caseTaskTypeNameMap = new Map<Id,String>();
        Map<Id,Asset> idAssetMap = new Map<Id,Asset>();
        String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId(); //GT-26
        
        if(newCaseTaskList != null && newCaseTaskList.size()>0){
            for(Case_Task__c newCaseTask: newCaseTaskList){
                caseTaskTypeIdSet.add(newCaseTask.Case_Task_Type__c);
                if(newCaseTask.Line_Cleaning_Asset__c != null){
                    caseTaskAssetMap.put(newCaseTask.Id,newCaseTask.Line_Cleaning_Asset__c);
                }
            }
        }
        if(caseTaskTypeIdSet != null && caseTaskTypeIdSet.Size()>0){
            for(Quality_Case_Configuration__c caseTaskType : [SELECT Id,Name FROM Quality_Case_Configuration__c WHERE Id IN: caseTaskTypeIdSet AND Name = 'Clean Lines']){
                caseTaskTypeNameMap.put(caseTaskType.Id, caseTaskType.Name);
            }
        }
        for(Case_Task__c newCaseTask: newCaseTaskList){
            if(caseTaskTypeNameMap != null && caseTaskTypeNameMap.Size()>0 && caseTaskTypeNameMap.containskey(newCaseTask.Case_Task_Type__c)){
                if(caseTaskTypeNameMap.get(newCaseTask.Case_Task_Type__c) == 'Clean Lines'){
                    if(newCaseTask.Achievement_Status__c != oldCaseTaskMap.get(newCaseTask.Id).Achievement_Status__c && (newCaseTask.Achievement_Status__c == EDGE_ACHIEVED_STATUS || newCaseTask.Achievement_Status__c == EDGE_NOT_ACHIEVED_STATUS)){
                        if(newCaseTask.Line_Cleaning_Asset__c != null){
                            Asset assetObj = new Asset();
                            assetObj.Id = newCaseTask.Line_Cleaning_Asset__c;
                            assetObj.Last_Cleaning_Date__c = newCaseTask.LastModifiedDate;
                            assetObj.RecordTypeId = qualityAssetRecordTypeId;//GT-26
                            if(idAssetMap.Containskey(assetObj.Id)){
                                Asset existingAsset = idAssetMap.get(assetObj.Id);
                                if(existingAsset.Last_Cleaning_Date__c < assetObj.Last_Cleaning_Date__c ){
                                    existingAsset.Last_Cleaning_Date__c = assetObj.Last_Cleaning_Date__c;
                                    idAssetMap.put(existingAsset.Id,existingAsset);
                                }
                            }else{
                                idAssetMap.put(assetObj.Id,assetObj);
                            }
                        }
                    }
                }
            }
        }
        if(idAssetMap!= null && idAssetMap.Size()>0){
            List<Asset> updateAssetList = new List<Asset>();
            updateAssetList = idAssetMap.values();
            if(updateAssetList!= null && updateAssetList.Size()>0){
                update updateAssetList;
            }
        }
        
    }
    
    /**
* @description : This method is used to populate Actioned Within SLA on CaseTask object (ES20-12020) 
* @return : void
* @param : List<Case_Task__c>,Map<Id,SObject> oldMap
*/
    public static void populateActionedWithinSLA(List<Case_Task__c> newItems, Map<Id,SObject> oldItems){      
        List<Case_Task__c> caseTaskNewRecMap = (List<Case_Task__c>)newItems; 
        List<Case_Task__c> caseTaskToUpdate = new List<Case_Task__c>();
        Set<Id> caseIdSet = new set<Id>();       
        List<String> eligibleStatus = System.Label.EDGE_CaseTaskStatus.split(';');         
        if(caseTaskNewRecMap != null && caseTaskNewRecMap.size()>0){
            for(Case_Task__c newCaseTask : caseTaskNewRecMap){
                caseIdSet.add(newCaseTask.Case__c);
                caseTaskToUpdate.add(newCaseTask);
            }
        }        
        
        if(caseTaskToUpdate != null && caseTaskToUpdate.size() >0 ){
            for(Case_Task__c caseTask: caseTaskToUpdate){
                if(caseTask.Task_Closed_Date_Time__c <= caseTask.Due_Date_Time__c  && !eligibleStatus.contains(caseTask.Achievement_Status__c)){
                    caseTask.Actioned_Within_SLA__c = True;
                }else{
                    caseTask.Actioned_Within_SLA__c = False;                        
                }              
            }            
        }    
    }
    /**
    * @description : This method is used to populate Last actual user modified details in case task CUS-194
    * @return : void
    * @param : List<Case_Task__c>,Map<Id,SObject> oldMap
    */
    public static void populateLastModifyUserId(List<Case_Task__c> newItems, Map<Id,SObject> oldItems){      
        Map<Id,Case_Task__c> oldCaseTaskMap = new Map<Id,Case_Task__c>();
        if(oldItems!= null){
            oldCaseTaskMap = (Map<Id,Case_Task__c>)oldItems;
        }
        Case_Task__c oldRecord;
        Set<String> watchedFields = new Set<String>();
        for(Schema.FieldSetMember fsm : sObjectType.Case_Task__c.FieldSets.History_Enabled_Fields.getFields()){
            watchedFields.add(fsm.getFieldPath());
        }

        if(!watchedFields.isEmpty()){
            for(Case_Task__c cst : newItems){
                if(oldCaseTaskMap != null && oldCaseTaskMap.containsKey(cst.Id)){
                    oldRecord = oldCaseTaskMap.get(cst.Id);
                }
                for(String field : watchedFields){
                    if((oldItems == null || (oldCaseTaskMap !=null && cst.get(field) != oldRecord.get(field))) && !System.isBatch()){
                            cst.Actual_User_Last_Modified_by__c = UserInfo.getUserId();
                            cst.Actual_User_Last_Modified_date_time__c = System.now();
                            break;  
                    }
                }
            }
        }
    }
}