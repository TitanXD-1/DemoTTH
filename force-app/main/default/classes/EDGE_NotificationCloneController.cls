/**********************************************************************
Name: EDGE_NotificationCloneController
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan D          17/03/2020        ES20-3447
***********************************************************************/
public without sharing class EDGE_NotificationCloneController {
	
    @AuraEnabled 
    public static Id cloneNotification(Id notificationId){
        Notification__c newNotification = new Notification__c();
        String queryString = 'SELECT Id ';
        Schema.DescribeSObjectResult describeResult = Notification__c.sObjectType.getDescribe();
        Map<String,Schema.SObjectField> fieldsMap = describeResult.fields.getMap();         
        for(String fieldName : fieldsMap.keySet()) {
            if(fieldsMap.get(fieldName).getDescribe().isUpdateable() && fieldName != 'OwnerId') {
                queryString += ', ' + fieldName; 
            }
        }
        queryString += ' FROM Notification__c WHERE Id=\''+ notificationId + '\'';
        Notification__c notification = Database.query(queryString);
        newNotification = notification.clone(false);
        newNotification.Start_Date__c = null;
        newNotification.End_Date__c = null;
        newNotification.Status__c = 'Draft';   
        insert newNotification;
        return newNotification.Id;        
    }

    @AuraEnabled 
    public static void cloneUserNotification(Id notificationId, Id newNotificationId){
        List<User_Notification__c> newUsrNotifyList = new List<User_Notification__c>();
        String queryString = 'SELECT Id ';
        Schema.DescribeSObjectResult describeResult = User_Notification__c.sObjectType.getDescribe();
        Map<String,Schema.SObjectField> fieldsMap = describeResult.fields.getMap();         
        for(String fieldName : fieldsMap.keySet()) {
            if(fieldsMap.get(fieldName).getDescribe().isUpdateable() && fieldName != 'OwnerId' && fieldName != 'GUID__c') {
                queryString += ', ' + fieldName; 
            }
        }
        queryString += ' FROM User_Notification__c WHERE Notification__c = \''+ notificationId + '\'';
        //List<User_Notification__c> UsrNotifyList = Database.query(queryString);
        for(User_Notification__c userNotify : Database.query(queryString)){
            User_Notification__c newUserNotify = userNotify.clone(false);
            newUserNotify.Notification__c = newNotificationId;
            newUsrNotifyList.add(newUserNotify);
        }
        insert newUsrNotifyList;
    }
    
    @AuraEnabled 
    public static void cloneNotificaionFile(Id notificationId, Id newNotificationId){
        List<ContentDocumentLink> newContentDocLinkList = new List<ContentDocumentLink>();
        for( ContentDocumentLink contentDocLink : [SELECT ContentDocumentId,Id,LinkedEntityId,ShareType,Visibility FROM ContentDocumentLink WHERE LinkedEntityId =:notificationId]){
            ContentDocumentLink newContentDocLink = contentDocLink.clone(false);
            newContentDocLink.LinkedEntityId = newNotificationId; 
            newContentDocLinkList.add(newContentDocLink);
        }

        insert newContentDocLinkList;        
    }    
    
}