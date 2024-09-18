/**********************************************************************
Name: EDGE_NotificationCloneControllerTest
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan D          17/03/2020        ES20-3447
***********************************************************************/
@isTest
public class EDGE_NotificationCloneControllerTest {
    @isTest
    public static void testNotificationCloneController(){
        User user = EDGE_UtilityTestClass.runAsUser('Identity', 'Master Data manager');
        insert user;
        Id countryid= EDGE_UtilityTestClass.setupCountry('AU');
        Notification__c notif = new Notification__c();
        notif.Country__c = countryid;
        notif.Start_Date__c  = system.today();
        notif.End_Date__c = system.today().addDays(6);
        notif.Short_Description__c = 'Just a notice';
        insert notif;
        
        User_Notification__c userNot = new User_Notification__c();
        userNot.Notification__c = notif.id;
        userNot.User__c = user.id;
        insert userNot;
        Id newNotifId= EDGE_NotificationCloneController.cloneNotification(notif.id);
        system.assert(newNotifId!=null);
        EDGE_NotificationCloneController.cloneUserNotification(notif.id, newNotifId);
        EDGE_NotificationCloneController.cloneNotificaionFile(notif.id, newNotifId);
    }

}