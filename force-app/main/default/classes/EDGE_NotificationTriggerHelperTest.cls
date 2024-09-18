/** @Name: EDGE_NotificationTriggerHelperTest
 *  @Purpose: Test class for EDGE_NotificationTriggerHelper
 *  @History
 *  -------   
 *  @VERSION		AUTHOR			DATE			DETAIL
 *  @1.0         Shahbaz Khan    16/03/2020      Initial Development
 *  @2.0		 	Sayan		 17/06/2021		   NCP-3195
 **/ 

@isTest
public class EDGE_NotificationTriggerHelperTest {
    @isTest
    public static void externalLinksTriggerTest(){
        Id countryid= EDGE_UtilityTestClass.setupCountry('AU');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id clusterId = geoMap.get('Cluster');
        Geography__c country = createGeography('Country');
        country.Name = 'Australia1';
        country.Code__c = 'AUT1';
        country.Parent_Geography__c = clusterId;
        insert country;
        
        EDGE_UtilityTestClass.createOrgSettings();
        Notification__c notif = new Notification__c();
        notif.Country__c = countryid;
        notif.Start_Date__c = system.today();
        notif.End_Date__c = system.today().addDays(5);
        notif.Short_Description__c = 'This on';
        insert notif;
        system.assert(notif.Id != null);
        
        notif.Country__c = country.Id;
        update notif;
        delete notif;
        undelete notif;
    }
    @isTest
    public static void checkOverlappingNotificationTest(){
        Id countryid= EDGE_UtilityTestClass.setupCountry('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        Id diageoOneAnnouncementRecordTypeId = Schema.SObjectType.Notification__c.getRecordTypeInfosByName().get('Diageo One Announcements').getRecordTypeId();
        Notification__c notification = new Notification__c();
        notification.Country__c = countryId;
        notification.RecordTypeId = diageoOneAnnouncementRecordTypeId;
        notification.Start_Date__c = system.today();
        notification.End_Date__c = system.today().addDays(4);
        notification.Long_Description__c = 'Long';
        notification.Group_Name__c = 'GB_Direct';
        notification.Language__c = 'en_GB';
        insert notification;
        system.assert(notification.Id != null);
    }
    
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
}