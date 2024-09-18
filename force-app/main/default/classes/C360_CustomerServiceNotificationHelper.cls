/*
* @Name: C360_CustomerServiceNotificationHelper
* @description: This class is to push notification for the cases created for C360 project from case management console/D1
* @History                                                            

VERSION         AUTHOR                  DATE                    DETAIL
1.0             Swagat Shaw             18/08/2023              Initial development- 144408
2.0             Suvendu Roy             20/08/2023              sendPushNotificationForStatusChange for 144402
3.0             Swagat Shaw             05/09/2023              autoFollowOnCaseCreation(144667)
4.0             Joshraj Sen            15/02/2024               150716
*/ 


public without sharing class C360_CustomerServiceNotificationHelper {
    Static Id diageoOneCasesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
    Static Map<Id,List<String>> mapCaseWithUser = new Map<Id,List<String>>();
    Static Map<Id, Account> mapAccountDetails = new Map<Id, Account>();
    Static Map<String,Boolean> countryMapWithConfig = new Map<String,Boolean>();
    
    /* @description :  - Following newly created cases when created by SR/QR
    * @return : void
    * @param : List<Case>
    */
    public static void autoFollowOnCaseCreation(List<SObject> newItems){
        List<case> caseList = (List<Case>) newItems;
        Set<Id> userIdList = new Set<Id>();
        Set<Id> validUserIds = new Set<Id>();
        List<Case> validCaseList = new List<Case>();
        for(Case cs : caseList){
            if(cs.Origin == System.Label.C360_CaseOriginName  && cs.RecordTypeId == diageoOneCasesRecordTypeId){
                userIdList.add(cs.CreatedById);
                validCaseList.add(cs);
            }
        }
        if(!userIdList.isEmpty() && Schema.sObjectType.PermissionSetAssignment.isAccessible()){
            for(PermissionSetAssignment access:[SELECT  AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.name =: System.Label.C360_SalesRep_QualityRep_PermissionSet AND AssigneeId IN:userIdList]){
                validUserIds.add(access.AssigneeId); 
            }
        }
        for(Case cs : validCaseList){
            if(validUserIds.contains(cs.CreatedById)){
                ConnectApi.ChatterUsers.follow(null, cs.CreatedById, cs.Id);
            }
        }
    }
    
    /**
    * @description : sendPushNotificationForStatusChange - Sends push notification to the applicable users upon case status update
    * @return : void
    * @param : newMap<Id,SObject>, oldMap<Id,SObject>
    */
    public static void sendPushNotificationForStatusChange(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
        Map<Id, Case> newCaseRecordMap = (Map<Id, Case>)newItems;
        Map<Id, Case> oldCaseRecordMap = (Map<Id, Case>)oldItems;
        List<Case> filteredCase = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> countryCodes = new Set<String>();
        for(Case cs : newCaseRecordMap.values()){
            if(oldCaseRecordMap != null && cs.RecordTypeId == diageoOneCasesRecordTypeId && cs.Status != oldCaseRecordMap.get(cs.Id).Status && cs.AccountId != null){
                accountIds.add(cs.AccountId);
                countryCodes.add(cs.Country__c);
                filteredCase.add(cs);
            }
        }
        if(accountIds.Size()>0){
            userMapWithEntitySubscription(accountIds, countryCodes, filteredCase);
        }
        
        for(Case caseObj : filteredCase){   
            validatingPushNotification(caseObj);
         }
    }
    public static void userMapWithEntitySubscription(Set<Id> accountIds, Set<String> countryCodes, List<Case> filteredCase ){
        if ((Schema.sObjectType.Account.isAccessible() || Schema.sObjectType.EntitySubscription.isAccessible() || Schema.sObjectType.Market_Setting__c.isAccessible())){
            for(Account acc : [SELECT Id, Country__c, Name FROM Account WHERE Id IN: accountIds AND Account_Type__c INCLUDES ('Ship-To')]){
                mapAccountDetails.put(acc.Id,acc);
            }
            for(Market_Setting__c msRec : [SELECT Id, C360_Case_Notification_Enabled__c,Geography__c,Geography__r.Code__c FROM Market_Setting__c WHERE Geography__r.Code__c IN: countryCodes]){
                countryMapWithConfig.put(msRec.Geography__r.Code__c,msRec.C360_Case_Notification_Enabled__c);
            }
            for(EntitySubscription entituSubs : [SELECT id,ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN: filteredCase]){
                if(mapCaseWithUser.containsKey(entituSubs.ParentId) && mapCaseWithUser.get(entituSubs.ParentId)!=null){
                    mapCaseWithUser.get(entituSubs.ParentId).add(entituSubs.SubscriberId);
                }else{
                    mapCaseWithUser.put(entituSubs.ParentId, new List<String>{entituSubs.SubscriberId}); 
                }
            }
        }
    }
    /**
    * @description : validatingPushNotification - Sends push notification to the applicable users
    * @return : void
    * @param : Case
    */
    public static void validatingPushNotification(Case caseObj){
        String msgToPush = System.label.C360_MsgForCaseStatusPushNotification;
        Map<String,Object> custom = new Map<String,Object>();//150716
        Set<String> usersToNotifyList;
        if(mapAccountDetails.containsKey(caseObj.AccountId) && mapCaseWithUser.containsKey(caseObj.Id) && countryMapWithConfig.containsKey(caseObj.Country__c) && countryMapWithConfig.get(caseObj.Country__c)){
            msgToPush = System.label.C360_MsgForCaseStatusPushNotification.replace('@@', caseObj.CaseNumber).replace('##', mapAccountDetails.get(caseObj.AccountId).Name).replace('$$', caseObj.Status);
            custom=generateKeyValueParameters(caseObj);//150716
            usersToNotifyList = new Set<String>(mapCaseWithUser.get(caseObj.Id));
            usersToNotifyList.remove(null);
        }
        if(usersToNotifyList != null && usersToNotifyList.size()>0){
            pushNotificationMethodforCase(usersToNotifyList, msgToPush,custom);//150716
        }
    }
    
    /**
    * @description : pushNotificationMethodforCase - Sends push notification to the applicable users
    * @return : void
    * @param : List<String>, String, Map<String, Object>
    */
    public static void pushNotificationMethodforCase(Set<String> users, String msgBody, Map<String, Object> custom){
        final String edgeConnectedApp = System.Label.EDGE_ConnectedApp;
        Messaging.PushNotification msg = new Messaging.PushNotification();
        Map<String, Object> payload = Messaging.PushNotificationPayload.apple(msgBody,null,null,custom);//150716
        msg.setPayload(payload);
        if(!Test.isRunningTest()){
            msg.send(edgeConnectedApp, users);
        }
    }
    /**
    * @description : generateKeyValueParameters - Sends key-value parameters to the applicable users
    * @return : void
    * @param : Case
    */
    public static Map<String,Object> generateKeyValueParameters(Case caseObj)//150716
    {
        Map<String,Object> custom = new Map<String,Object>();//150716
        custom.put('caseId',caseObj.Id);//150716
        custom.put('recordTypeName',caseObj.C360_Record_Type_Name__c);//150716
        custom.put('accountId',caseObj.AccountId);//150716
        return custom;        
    }
}