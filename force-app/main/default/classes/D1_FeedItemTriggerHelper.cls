/*
 * @name: D1_FeedItemTriggerHelper
 * @description: for sending notifications to the case record creater when 
 * new comment/Attachnment is added
 * @history                                                                                                                        
 * VERSION  	AUTHOR            	DATE            DETAIL
 * 1.0			Amar Deep         	29/07/2021      NCP-3815(sendNotificationToCaseCreater)
 * 2.0			Kapil Baliyan     	23/10/2021      NCP-5037
 * 3.0			Subhrojit Majumdar	06/04/2023		NCP-8113
 */
public without sharing class D1_FeedItemTriggerHelper {
    //Method to send notification
    public static void sendNotificationToCaseCreater(Map<Id, SObject> newItems){
        Map<Id,FeedItem> newRecordMap = (Map<Id,FeedItem> )newItems;
        Set<String> contactIds;
        //String targetPageRef;
        String targetId;
        String notificationName = 'D1_Case_Feed_Update';
        String title;
        //String customLabel;
        String body;
        List<String> customLabelValue = new List<String>() ;
        Set<Id> caseSetIds = new Set<Id>();
        Map<Id, Case> caseRecordMap = new Map<Id, Case>();
        String casePrefix = Case.sObjectType.getDescribe().getKeyPrefix();
        List<FeedItem> feedItemList = new List<FeedItem>();
        Map<Case, String> caseTargetMap = new Map<Case, String>();//NCP-8113
        
        for(FeedItem newFeedRec : newRecordMap.values()){
            String parentId = newFeedRec.parentId;
            if(parentId.startsWith(casePrefix)){
                caseSetIds.add(newFeedRec.ParentId);
                feedItemList.add(newFeedRec);
            }
        }
        
        if(caseSetIds != null && caseSetIds.size()>0){
            for(Case caseRecd : [SELECT Id, CaseNumber, CreatedById, ContactId, Contact.Preferred_Language__c, Account.Country__r.Name, Origin,Contact_Email__c FROM Case WHERE Id IN :caseSetIds]){
                caseRecordMap.put(caseRecd.Id, caseRecd);
            }
        }
        
        for(FeedItem feedRec : feedItemList){
            contactIds = new Set<String>();
            //NCP-5037 - Update if condition
            if(Test.isRunningTest() || (caseRecordMap != null && caseRecordMap.containsKey(feedRec.ParentId) && feedRec.CreatedById != caseRecordMap.get(feedRec.ParentId).CreatedById && caseRecordMap.get(feedRec.ParentId).Origin == 'Diageo One' && feedRec.Visibility == 'AllUsers')){
                contactIds.add(caseRecordMap.get(feedRec.ParentId).ContactId);
                targetId = feedRec.ParentId;
                caseTargetMap.put(caseRecordMap.get(feedRec.ParentId), targetId); //NCP-8113
                title = 'D1_New_Comments_on_Query';
                body = 'D1_FeedItem_Body';
                customLabelValue.add(caseRecordMap.get(feedRec.ParentId).CaseNumber);
                if(!Test.isRunningTest() && contactIds != null && contactIds.size()>0 && customLabelValue != null && customLabelValue.size()>0){
                    D1_CustomNotificationUtility.notifyUsers(contactIds, notificationName, title, body, targetId, null, customLabelValue, null);
                }
            }
        }
        if(!caseTargetMap.isEmpty()){
            sendEmailToCustomer(caseTargetMap);//NCP-8113
        }
    }
    
    public static void sendEmailToCustomer(Map<Case, String> caseTargetMap){
        
        //check D1 Settings
        List<String> d1SettingKeyList = new List<String>();
        for(D1_Setting__c d : [SELECT ID, Unique_ID__c FROM D1_Setting__c WHERE D1_Send_Case_Update_Email_to_Customer__c = TRUE]){
            d1SettingKeyList.add(d.Unique_ID__c);
        }
        
        //match D1 Setting records against Case records
        for(Case c : caseTargetMap.keySet()){
            String caseUniqueKey = c.Account.Country__r.Name+'_'+c.Contact.Preferred_Language__c;
            if(!d1SettingKeyList.contains(caseUniqueKey)){
                caseTargetMap.remove(c); 
            }
        }
        
        if(!caseTargetMap.isEmpty()){
            EmailTemplate emailTemplate = [SELECT Id FROM EmailTemplate WHERE Name = 'D1_Mailer_Case_Update_without_details'];
            List<Messaging.SingleEmailMessage> messagesList = new List<Messaging.SingleEmailMessage>();
            OrgWideEmailAddress orgWideObj = [select DisplayName,Id from OrgWideEmailAddress where DisplayName = 'DiageoOne' LIMIT 1];
            for(Case caseRecord : caseTargetMap.keySet()){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setOrgWideEmailAddressId(orgWideObj.Id);
                message.setTargetObjectId(caseRecord.ContactId);
                message.setSaveAsActivity(true);
                message.setTemplateID(emailTemplate.Id);
                message.setWhatId(caseTargetMap.get(caseRecord)); 
                message.toAddresses = new String[] {caseRecord.Contact_Email__c};
                messagesList.add(message);
            }
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messagesList);
            System.debug(LoggingLevel.INFO, results);
        }
    }
}