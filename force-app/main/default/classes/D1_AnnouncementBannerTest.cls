/**
 * @Name: D1_AnnouncementBannerTest
 * @discription : Test class for D1_AnnouncementBanner
 * @History                                                            
 * ---                                                            
 * VERSION     AUTHOR              DATE              DETAIL
 * 1.0         Rushikesh Bodkhe    27/04/2021        Initial Development (NCP-3705)
 **/
@isTest
public class D1_AnnouncementBannerTest { 
    //data setup
    @testSetup
    public static void createTestData() { 
        test.startTest();       
            Profile p = [SELECT Id FROM Profile WHERE Name='System administrator'];       
            User u = new User(
                Alias = 'standt',
                Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', 
                LastName='Testing', 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', 
                UserName='standarduser@testorg.comwecx'
            );
            insert u;       
            Group grp = [select id,DeveloperName from Group where DeveloperName = 'GB_Direct'];
        test.stopTest();
        System.runAs(u){
            GroupMember grpmember = new GroupMember();
            grpmember.UserOrGroupId= u.id;
            grpmember.GroupId = grp.id;
            insert grpmember;
        } 
        
        Geography__c globalRec = D1_TestDataUtility.createGeography('Country');
            globalRec.Name = 'Great Britain';
            globalRec.Code__c = 'GB';
        insert globalRec;
        
        Id recordTypeID = Schema.SObjectType.Notification__c.getRecordTypeInfosByName().get('Diageo One Announcements').getRecordTypeId();
        //create notification
        Notification__c notification = new Notification__c();
        notification.Long_Description__c ='This is for testing';
        notification.Status__c = 'Active';
        notification.Name ='Test';
        notification.Group_Name__c='GB_Direct';
        notification.Country__c= globalRec.id ;
        notification.RecordTypeId = recordTypeID;
        insert notification;
    }
    @isTest
    public static void getannouncementTest(){
        List<Notification__c> testNotif = [SELECT Id, Long_Description__c, Status__c, Name, Group_Name__c, Country__c, RecordTypeId FROM Notification__c];
        User u = [SELECT Id FROM User WHERE Alias = 'standt'];

        System.runAs(u){

            test.startTest();
                List<Notification__c> notifList = new List<Notification__c>();
                notifList = D1_AnnouncementBanner.getAnnouncement();           
            test.stopTest();  
            
			System.assert(notifList != null, 'Notification list is null');
            System.assertnotEquals(notifList, testNotif, 'notifications are not equal');
        }
    }
}