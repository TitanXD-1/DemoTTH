/*
* Class Name : EDGE_FeedItemTriggerHelper
* @description: The requirement is to keep the Operator Notes Present checkbox true
or false if there is any operator notes present or not
User Story : ES20-8463
* @history
* VERSION    AUTHOR                DATE              DETAIL
* 1.0 -    Sandip Ghosh 	   19/08/2020      Initial Development
* 2.0      Amar Deep           11/02/2021      ES20-9704(sendPushNotification)
* 3.0      Swagat Shaw         09/03/2023      CUS - 115
* 4.0      Suvendu Roy         09/03/2023      144402
* 5.0      Joshraj Sen         15/02/2023      150716
*/


public class EDGE_FeedItemTriggerHelper {
    
    final static String operatorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
    
    /**
* @method markOperatorNotesPresent
* @description The below method checks if there is any operator notes present
& yes then sets the Operator Notes Present checkbox true.
* @return void
* @param map
*/   
    
    public static void markOperatorNotesPresent(Map<Id, SObject> newItems){
        Set<Id> operatorIdsToUpdate = new Set<Id>();
        Set<Id> operatorIdsQuery = new Set<Id>();
        Set<Account> operatorsToUpdate = new Set<Account>();
        Set<Id> operatorAssocFeedIds = new Set<Id>();
        Map<Id,Id> feedItemIdToOperatorId = new Map<Id,Id>();
        Map<Id,Account> opIdtoOperatorRecMap = new Map<Id,Account>();
        
        if(newItems!=null){
            for(SObject newItem : newItems.values()){
                FeedItem feedItemRec = (FeedItem)newItem;
                if(feedItemRec.ParentId != null){
                    operatorIdsQuery.add(feedItemRec.ParentId);
                } 
            }
        }
        
        if(operatorIdsQuery != null && operatorIdsQuery.size() > 0){
            for(Account operator : [Select Id,Operator_Notes_Present__c,RecordTypeId,IsOperator__c from Account where RecordTypeId = :operatorRecordTypeId
                                    AND Id in :operatorIdsQuery])
            {
                opIdtoOperatorRecMap.put(operator.Id, operator);
            }
        }
        
        if(newItems!=null){
            for(SObject newItem : newItems.values()){
                FeedItem feedItemRec = (FeedItem)newItem;
                if(feedItemRec.ParentId != null){
                    Account accRec = opIdtoOperatorRecMap.get(feedItemRec.ParentId);
                    if(accRec != null && accRec.RecordTypeId == operatorRecordTypeId 
                       && accRec.IsOperator__c /*&& feedItemRec.RelatedRecordId != null*/){
                           accRec.Operator_Notes_Present__c = true;
                           operatorsToUpdate.add(accRec);
                       }
                }
            }
        }
        
        if(operatorsToUpdate != null && operatorsToUpdate.size() > 0){
            List<Account> operatorsListToUpdate = new List<Account>();
            operatorsListToUpdate.addAll(operatorsToUpdate);
            Database.update(operatorsListToUpdate, false);
        }
        
    }
    /**
* @method markOperatorNotesPresent
* @description The below method checks if there is not a single operator 
notes present & yes then clears the Operator Notes Present checkbox true
* @return void
* @param map
*/
    
    public static void unCheckOperatorNotesPresent(Map<Id, SObject> oldItems){
        Set<Id> operatorIdsToUpdate = new Set<Id>();
        Set<Id> operatorIdsToQuery = new Set<Id>();
        Set<Account> operatorsToUpdate = new Set<Account>();
        Map<Id,Account> opIdtoOperatorRecMap = new Map<Id,Account>();
        Map<Id,Integer> opIdtoNotesCountMap = new Map<Id,Integer>();
        Map<Id, FeedItem> oldFeedItemsMap = (Map<Id, FeedItem>)oldItems;
        
        if(oldItems != null){
            for(SObject newItem : oldItems.values()){
                FeedItem feedItemRec = (FeedItem)newItem;
                if(feedItemRec.ParentId != null){
                    operatorIdsToQuery.add(feedItemRec.ParentId);
                } 
            }
        }
        
        if(operatorIdsToQuery != null && operatorIdsToQuery.size() > 0){
            for(Account operator : [Select Id,Operator_Notes_Present__c from Account where RecordTypeId = :operatorRecordTypeId
                                    AND Id in :operatorIdsToQuery])
            {
                opIdtoOperatorRecMap.put(operator.Id, operator);
                opIdtoNotesCountMap.put(operator.Id,0);
            }
            if(oldFeedItemsMap != null){
                for(FeedItem objFeedItem : [SELECT Id, RelatedRecordId, ParentId FROM FeedItem where ParentId in :operatorIdsToQuery])
                {
                    Id operatorId = objFeedItem.ParentId;
                    if(operatorId != null && opIdtoOperatorRecMap.containsKey(operatorId)){
                        Account operator = opIdtoOperatorRecMap.get(operatorId);
                        if(!oldFeedItemsMap.containsKey(objFeedItem.Id) /*&& objFeedItem.RelatedRecordId != null*/){
                            Integer notesCount = opIdtoNotesCountMap.get(operatorId);
                            opIdtoNotesCountMap.put(operatorId, ++notesCount);                            
                        }                   
                    }
                }
            }
        }
        
        if(opIdtoNotesCountMap != null && opIdtoNotesCountMap.keySet().size()>0){
            for(Id opId : opIdtoNotesCountMap.keySet()){
                if(opIdtoNotesCountMap.get(opId) == 0){
                    Account operator = opIdtoOperatorRecMap.get(opId);
                    operator.Operator_Notes_Present__c = false;
                    operatorsToUpdate.add(operator);
                }
            }
        }
        
        if(operatorsToUpdate != null && operatorsToUpdate.size() > 0){
            List<Account> operatorsListToUpdate = new List<Account>();
            operatorsListToUpdate.addAll(operatorsToUpdate);
            Database.update(operatorsListToUpdate, false);
        }
        
    }
    /**
* @method sendPushNotification
* @description for sending the Mobile Push notifications  sent to a specific user 
* @return void
* @param map
*/
    
    
    public static void sendPushNotification(Map<Id, SObject> newItems){
        Map<Id,FeedItem> newRecordMap = (Map<Id,FeedItem> )newItems;
        Map<String, Object> custom = new Map<String, Object>();
        String accountPrefix = Account.sObjectType.getDescribe().getKeyPrefix();
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        Map<Id,Account> accountMap;
        Map<Id,User> userMap;
        List<FeedItem> feedItemList = new List<FeedItem>();
        
        if(newRecordMap!=null){
            for(FeedItem newFeedRec : newRecordMap.values()){
                String parentId = newFeedRec.parentId;
                if(parentId.startsWith(accountPrefix)){                    
                    feedItemList.add(newFeedRec);
                    accIdSet.add(newFeedRec.ParentId);
                    userIdSet.add(newFeedRec.CreatedById);
                }
            }
            if(!accIdSet.isEmpty()){
                accountMap = new Map<Id,Account>([SELECT Id,Name from Account where Id IN: accIdSet]);
            }
            if(!userIdSet.isEmpty()){
                userMap = new Map<Id,User>([SELECT Id,Name from User where Id IN: userIdSet]); 
            }
            accIdSet.clear();
            userIdSet.clear();
            if(!feedItemList.isEmpty()){
                for(FeedItem feedItemObj : feedItemList){
                    if(accountMap != null && accountMap.size()>0 && userMap != null && userMap.size()>0){
                        if(accountMap.containsKey(feedItemObj.ParentId) && userMap.containsKey(feedItemObj.CreatedById)){
                            String accName = accountMap.get(feedItemObj.ParentId).Name;
                            String chatterStr = userMap.get(feedItemObj.CreatedById).Name + ' ' + System.label.Edge_user_mention_outlet + ' ' + accName;
                            String chatterBodyStr = chatterStr.replaceAll('<[^>]+>','');
                            
                            custom.put('OutletId',feedItemObj.ParentId);
                            custom.put('OutletName',accName);
                            //custom.put('CommentId',newFeedRec.Id);
                            custom.put('ChatterId',feedItemObj.Id);
                            
                            String communityId = null;
                            String feedItemId = feedItemObj.Id;
                            
                            if(!Test.isRunningTest()){
                                ConnectApi.FeedElement feedElem = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedItemId);
                                if(feedElem != null && feedElem.body != null){
                                    List<ConnectApi.MessageSegment> messageSegments = feedElem.body.messageSegments;
                                    EDGE_PushNotificationHelper.pushNotificationMethod(messageSegments, chatterBodyStr, custom);
                                }
                            }
                        }
                    } 
                }
            }
        }
    }
    
    /*
* @description : While Deleing the Chatter post on claim, its not allowed.
* @return : void
* @param : Map
*/   
    public static void deleteingOrEditingChatterPostOnClaim(Map<Id, SObject> FeedItems){
        Map<Id,FeedItem> Items = (Map<Id, FeedItem>)FeedItems;
        Map<string,string> mapOfClaimtofeed = new Map<string,string>();
        for(FeedItem objFeedRecord :[Select Id, ParentId, Status, Body FROM FeedItem   
                                     WHERE Id IN :Items.keySet()]) {
                                         if(objFeedRecord.ParentId != null && (objFeedRecord.ParentId.getSObjectType() == CST_Claim__c.sObjectType)){       
                                             mapOfClaimtofeed.put(objFeedRecord.ParentId,objFeedRecord.Id);   
                                         }
                                     }
        
        for(CST_Claim__c objClaims : [select id,CST_Status__c from CST_Claim__c where id IN :mapOfClaimtofeed.keyset()]){           
            if(mapOfClaimtofeed.containskey(objClaims.id) && Items.containskey(mapOfClaimtofeed.get(objClaims.id))){
                Items.get(mapOfClaimtofeed.get(objClaims.id)).addError(System.label.CST_ChatterPost_Edit_Delete);
            }
        } 
    }
    
    /*
* @description : While Inserting the Chatter post on claim, when claim is approved/rejected,system is not allowed the same.
* @return : void
* @param : List
*/   
    public static void insertingChatterPostOnClaim(List<FeedItem> newItems){
        Set<Id> cstClaimId = new Set<Id>();
        Map<string,FeedItem> mapClaimtoFeed = new Map<string,FeedItem>();
        
        for(FeedItem objFeedRec : newItems) {
            if(objFeedRec.ParentId != null && 
               (objFeedRec.ParentId.getSObjectType() == CST_Claim__c.sObjectType)           
              ){
                  cstClaimId.add(objFeedRec.ParentId);
                  mapClaimtoFeed.put(objFeedRec.ParentId,objFeedRec);
              }
        }
        
        for(CST_Claim__c objClaims : [select id,CST_Status__c from CST_Claim__c where id IN :cstClaimId]){
            if(objClaims.CST_Status__c == 'Approved' || objClaims.CST_Status__c == 'Rejected'){
                if(mapClaimtoFeed.containskey(objClaims.id)){
                    mapClaimtoFeed.get(objClaims.id).addError(System.label.CST_ChatterPost_Insert);
                } 
            }
        }
        
    }
    /*CUS-115
* @description : Cannot comment on feed when case is closed.
* @return : void
* @param : List
*/   
    public static void preventPostingOnFeedCaseClosed(List<FeedItem> newItems){
        String curUserProfile = [Select name from Profile where Id = :UserInfo.getProfileId() LIMIT 1].Name;
        Map<String, FeedItem> toCheck = new Map<String, FeedItem>();
        List<String> countryCodes=Label.C360_Ireland_Country_Codes.split(';');
        for(FeedItem fc : newItems){
            if(fc.ParentId != null && 
               (fc.ParentId.getSObjectType() == Case.sObjectType)           
              ){
                  toCheck.put(fc.ParentId, fc);
              }
        }
        
        if(featuremanagement.checkpermission('C360_Logistics_rep') || featuremanagement.checkpermission('C360_Service_Team') || featuremanagement.checkpermission('C360_Credit_Team_Leader') ||
           curUserProfile == 'Sales Representative' || curUserProfile == 'Quality Representative' ){
               for(Case c : [SELECT Id, C360_Record_Type_Name__c, Account.Country_Code__c FROM Case WHERE Id in :toCheck.keySet() 
                             AND C360_Record_Type_Name__c = 'Diageo One Cases' AND Account.Country_Code__c in :countryCodes AND Status = 'Closed'])
               {
                   if(toCheck.containsKey(c.Id)){
                       toCheck.get(c.Id).addError(Label.Case_Comment_Error_Message);
                   }
               }
               
           }
    }
    /**
    * @description : 144402/sendCustomerCasePushNotification - Sends push notification to the applicable users upon new FeedItem on Case Object
    * @return : void
    * @param : newMap<Id,SObject>
    */
    public static void sendCustomerCasePushNotification(Map<Id, SObject> newItems){
        Map<Id,FeedItem> newRecordMap = (Map<Id,FeedItem> )newItems;
        String casePrefix = Case.sObjectType.getDescribe().getKeyPrefix();
        Set<Id> caseIdSet = new Set<Id>();
        Id diageoOneCasesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        List<Case> filteredCase = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> mapAccountDetails = new Map<Id, Account>();
        Set<String> countryCodes = new Set<String>();
        Map<String,Boolean> countryMapWithConfig = new Map<String,Boolean>();
        Map<Id,List<String>> mapCaseWithUser = new Map<Id,List<String>>();
        Set<String> usersToNotifyList;
        Map<String,Object> custom = new Map<String,Object>();//150716
        if(newRecordMap!=null){
            for(FeedItem newFeedRec : newRecordMap.values()){
                String parentId = newFeedRec.parentId;
                if(parentId.startsWith(casePrefix)){                    
                    caseIdSet.add(newFeedRec.ParentId);
                }
            }
            if(!caseIdSet.isEmpty() && (Schema.sObjectType.Case.isAccessible() ||Schema.sObjectType.Account.isAccessible() || Schema.sObjectType.EntitySubscription.isAccessible() || Schema.sObjectType.Market_Setting__c.isAccessible())){
                List<Case> caseList = new List<Case>([SELECT Id,AccountId,CaseNumber,Country__c,RecordTypeId,C360_Record_Type_Name__c from Case where Id IN: caseIdSet]);//150716
                for(Case cs : caseList){
                    if(cs.RecordTypeId == diageoOneCasesRecordTypeId  && cs.AccountId != null){
                        accountIds.add(cs.AccountId);
                        countryCodes.add(cs.Country__c);
                        filteredCase.add(cs);
                    }
                }
                if (accountIds != null && accountIds.Size()>0){
                    for(Account acc : [Select Id, Country__c, Name from Account where Id IN: accountIds]){
                        mapAccountDetails.put(acc.Id,acc);
                    }
                    for(Market_Setting__c msRec : [Select Id, C360_Case_Notification_Enabled__c,Geography__c,Geography__r.Code__c from Market_Setting__c where Geography__r.Code__c IN: countryCodes]){
                        countryMapWithConfig.put(msRec.Geography__r.Code__c,msRec.C360_Case_Notification_Enabled__c);
                    }
                    for(EntitySubscription entituSubs : [Select id,ParentId, SubscriberId from EntitySubscription where ParentId IN: filteredCase]){
                        if(mapCaseWithUser.containsKey(entituSubs.ParentId) && mapCaseWithUser.get(entituSubs.ParentId)!=null){
                            mapCaseWithUser.get(entituSubs.ParentId).add(entituSubs.SubscriberId);
                        }else{
                            mapCaseWithUser.put(entituSubs.ParentId, new List<String>{entituSubs.SubscriberId}); 
                        }
                    }
                    //Sending Push-Notification
                    for(Case caseObj : filteredCase){
                        if(mapAccountDetails.containsKey(caseObj.AccountId)  && mapCaseWithUser.containsKey(caseObj.Id) 
                           && countryMapWithConfig.containsKey(caseObj.Country__c) && countryMapWithConfig.get(caseObj.Country__c)){
                            String msgToPush = 'Case '+caseObj.CaseNumber+' for '+mapAccountDetails.get(caseObj.AccountId).Name+' New Post on Case';
                            custom=C360_CustomerServiceNotificationHelper.generateKeyValueParameters(caseObj);////150716
                            usersToNotifyList = new Set<String>(mapCaseWithUser.get(caseObj.Id));
                            usersToNotifyList.remove(null);
                            if(usersToNotifyList != null && usersToNotifyList.size()>0){
                                C360_CustomerServiceNotificationHelper.pushNotificationMethodforCase(usersToNotifyList, msgToPush,custom);//150716
                            }
                        }
                    }
                }
            }
        }
    }
    
}