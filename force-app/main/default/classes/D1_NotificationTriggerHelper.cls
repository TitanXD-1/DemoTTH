/*
Name: D1_NotificationTriggerHelper
Purpose: 
History                                                            
-------                                                            
VERSION		AUTHOR			DATE			DETAIL
1.0         Narayana    22/04/2022      Initial Development [NCP-6450]
*/
public with sharing class D1_NotificationTriggerHelper {

    //NCP-6450: Method to validate Language for Markets
    public static void validatePreferredLanguage(List<sObject> newItems){
        Id diageoOneAnnouncementRecordTypeId = Schema.SObjectType.Notification__c.getRecordTypeInfosByDeveloperName().get('Diageo_One_Announcements').getRecordTypeId();
        List<sObject> newItemsList = new List<sObject>();

        //filter Notifications related to D1
        for(sObject newItem : newItems){
            if(newItem.get('RecordTypeId') == diageoOneAnnouncementRecordTypeId){
                newItemsList.add(newItem);
            }
        }

        //Pass newItemsList to generic validate language method for further processing
        if(newItemsList != null && newItemsList.size()>0){
            D1_UtilityClass.validatePreferredLanguage(newItemsList,'Country__c','Language__c');
        }
    }
}