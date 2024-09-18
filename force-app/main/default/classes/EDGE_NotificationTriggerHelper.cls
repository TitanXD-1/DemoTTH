/**
 * @Name: EDGE_NotificationTriggerHelper
 * @Purpose: This is to handle External Links Trigger Handler Events
 * @History
 * --------
 * VERSION		AUTHOR			DATE			DETAIL
 * 1.0         Shahbaz Khan    16/03/2020      Initial Development [ES20-7587]
 * 2.0		 	Sayan			17/06/2021		NCP-3195
 * 3.0		 	Sayan			25/04/2022		NCP-6457
 * */

public with sharing class EDGE_NotificationTriggerHelper {
    /**
     * @Method  : checkAndGenerateSharing
     * @Purpose : To create sharing record on Insert
     **/
    public static void checkAndGenerateSharing(List<Notification__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /**
     * @Method  : validateAndReGenerateSharing
     * @Purpose : Modify, Validate sharing record on update
     **/
    public static void validateAndReGenerateSharing(List<Notification__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Notification__c> mapOldItems;
        List<Notification__c> lstNewChangeGeography = new List<Notification__c>();
        List<Notification__c> lstOldChangeGeography = new List<Notification__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Notification__c>)oldItems;
        }
        
        for(Notification__c notifObj : newItems){
            if(mapOldItems.containsKey(notifObj.Id) && notifObj.Country__c != mapOldItems.get(notifObj.Id).Country__c){
                lstNewChangeGeography.add(notifObj);
                lstOldChangeGeography.add(mapOldItems.get(notifObj.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
    
    /**
     * @Method  : checkAndGenerateD1Sharing (NCP-3195)
     * @Purpose : To create sharing record on Insert for D1 External User
     **/
    public static void checkAndGenerateD1Sharing(List<Notification__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Read'); 
    }
   
    /**
     * @Method  : validateAndReGenerateD1Sharing (NCP-3195)
     * @Purpose : Modify, Validate sharing record on update for D1
     **/
    public static void validateAndReGenerateD1Sharing(List<Notification__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Notification__c> mapOldItems = new Map<Id, Notification__c>();
        List<Notification__c> lstNewChangeGeography = new List<Notification__c>();
        List<Notification__c> lstOldChangeGeography = new List<Notification__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Notification__c>)oldItems;
        }
        
        for(Notification__c objMAP : newItems){
            if(mapOldItems.containsKey(objMAP.Id) && objMAP.Country__c != mapOldItems.get(objMAP.Id).Country__c){
                lstNewChangeGeography.add(objMAP);
                lstOldChangeGeography.add(mapOldItems.get(objMAP.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Read');
        }       
    }
    
    /**
     * @Method  : checkOverlappingNotification (NCP-3195)
     * @Purpose : Validate Notification Records so that we always have one active record in 1 time frame for 1 group
     **/
    public static void checkOverlappingNotification(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id, Notification__c> mapOldItems;
        List<Notification__c> notificationList = new List<Notification__c>();
    	Set<String> publicGroupNameSet = new Set<String>();
        Set<String> languageSet = new Set<String>();//NCP-6457
        Set<Id> notificationIdSet = new Set<Id>();
        Set<String> statusOfNotification = new Set<String>{'Draft', 'Active'};
        Map<String, List<Notification__c>> groupNotificationMap = new Map<String, List<Notification__c>>();
        Id diageoOneAnnouncementRecordTypeId = Schema.SObjectType.Notification__c.getRecordTypeInfosByName().get('Diageo One Announcements').getRecordTypeId();
        if(oldItems != null){
            mapOldItems = (Map<Id, Notification__c>) oldItems;
        }
        
        //Identify which Notification are D1 Related to proceed further
        for(sObject newObject : newItems){
            Notification__c newNotification = (Notification__c)newObject;
            if(newNotification.RecordTypeId == diageoOneAnnouncementRecordTypeId && 
               (mapOldItems == null || (mapOldItems != null && (mapOldItems.get(newNotification.Id).Start_Date__c != newNotification.Start_Date__c) || 
                                       							mapOldItems.get(newNotification.Id).End_Date__c != newNotification.End_Date__c)))
            {
                notificationList.add(newNotification);
                notificationIdSet.add(newNotification.Id);
                if(string.isNotBlank(newNotification.Group_Name__c)){
                    publicGroupNameSet.add(newNotification.Group_Name__c);    
                }
                if(string.isNotBlank(newNotification.Language__c)){//NCP-6457
                    languageSet.add(newNotification.Language__c);
                }
            }
        }
		//Get Existing Notification
        if(!publicGroupNameSet.isEmpty() && !languageSet.isEmpty()){
            for(Notification__c existingNotification : [SELECT Id, Start_Date__c, End_Date__c, Group_Name__c, Language__c, RecordTypeId, Status__c, Short_Description__c 
                                                        FROM Notification__c 
                                                        WHERE Group_Name__c IN :publicGroupNameSet AND Language__c IN :languageSet
                                                        AND RecordTypeId =:diageoOneAnnouncementRecordTypeId 
                                                        AND Status__c IN :statusOfNotification AND Id NOT IN :notificationIdSet 
                                                        ORDER BY Group_Name__c, End_Date__c DESC]){   
                if(groupNotificationMap.containsKey(existingNotification.Group_Name__c)){
                    groupNotificationMap.get(existingNotification.Group_Name__c).add(existingNotification);
                }
                else{
                	groupNotificationMap.put(existingNotification.Group_Name__c, new List<Notification__c>{existingNotification});
                }
            }
        }        
        
        //Iterate over new notification & existing notification to check whether we have any existing notification exist with same time frame or not
        if(!groupNotificationMap.isEmpty() && !notificationList.isEmpty()){
            for(Notification__c newNotification : notificationList){
                if(groupNotificationMap.containsKey(newNotification.Group_Name__c)){
                    List<Notification__c> existingNotificationList = groupNotificationMap.get(newNotification.Group_Name__c);
                    for(Notification__c existingNotification : existingNotificationList){
                        if((existingNotification.Start_Date__c >= newNotification.Start_Date__c && existingNotification.Start_Date__c <= newNotification.End_Date__c) ||
    						(existingNotification.End_Date__c >= newNotification.Start_Date__c && existingNotification.End_Date__c <= newNotification.Start_Date__c) ||
                   			(existingNotification.Start_Date__c <= newNotification.Start_Date__c  && existingNotification.End_Date__c  >= newNotification.End_Date__c))
                        {	
                            newNotification.addError(label.D1_Notification_Time_Frame_Error);
                            break;
                        }
                    }
                }
            }
        }
    }
}