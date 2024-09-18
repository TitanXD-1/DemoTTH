/*
Name: EDGE_UserNotificationTriggerHelperTest
History                                                                                                                        
VERSION		AUTHOR			DATE			DETAIL
1.0         Amar Deep       04/03/2020      Initial Development
*/
@isTest
public class EDGE_UserNotificationTriggerHelperTest {
    @isTest
    public static void userNotificationTriggerTest(){
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null);
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Notification__c notice = new Notification__c();
        notice.Start_Date__c = system.today();
        notice.End_Date__c = system.today().addDays(10);
        notice.Long_Description__c = 'test text';
        notice.Status__c = 'Draft';
        notice.Priority__c = 'Low';
        notice.Country__c = countryId;
        insert notice;
        
        User_Notification__c userNotification = new User_Notification__c();
        userNotification.Notification__c = notice.Id;
        userNotification.IsRead__c = false;
        userNotification.Status__c = 'Draft';
        userNotification.User__c = salesRep.Id;
        insert userNotification;
        userNotification.IsRead__c = True;
        update userNotification;
        delete userNotification;
        undelete userNotification;
    }

}