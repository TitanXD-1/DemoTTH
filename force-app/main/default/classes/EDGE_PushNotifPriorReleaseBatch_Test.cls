/**
* @Name: EDGE_PushNotifPriorReleaseBatch_Test
* @Req: Test class for EDGE_PushNotificationPriorReleaseBatch
* @User Story : ES20-13542
* @History                                                            
* @VERSION   AUTHOR                   DATE              DETAIL
*  1.0       Wribhu Bose              09/01/2022        Initial development: test class for EDGE_PushNotificationPriorReleaseBatch
*/

@isTest
public class EDGE_PushNotifPriorReleaseBatch_Test {
    
    @isTest
    public static void sendNotificationTest() {
        Test.startTest();
        User testUser1 = createData();
        insert testUser1;
        System.assert(testUser1.Id != null, 'User inserted');
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'EDGE_PushNotificationPriorReleaseBatch'
                                                  AND Country_Code__c ='GB' ];
        String className = batchSetting.Batch_Class__c;
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,2000);
        Test.stopTest();
    }
    
    @isTest
    public static void sendNotificationTest2() {
        Test.startTest();
        User testUser2 = createData2();
        insert testUser2;
        System.assert(testUser2.Id != null, 'User inserted');
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'EDGE_PushNotificationPriorReleaseBatch'
                                                  AND Country_Code__c ='GB' ];
        String className = batchSetting.Batch_Class__c;
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,2000);
        Test.stopTest();
    }
    
    @isTest
    public static void sendNotificationTest3() {
        Test.startTest();
        User testUser3 = createData3();
        insert testUser3;
        System.assert(testUser3.Id != null, 'User inserted');
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'EDGE_PushNotificationPriorReleaseBatch'
                                                  AND Country_Code__c ='GB' ];
        String className = batchSetting.Batch_Class__c;
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,2000);
        Test.stopTest();
    }
    
    @isTest
    public static void sendNotificationTest4() {
        Test.startTest();
        User testUser4 = createData4();
        insert testUser4;
        System.assert(testUser4.Id != null, 'User inserted');
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, 
                                                  Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  FROM Market_Batch_Setting__mdt 
                                                  WHERE Batch_Class__c = 'EDGE_PushNotificationPriorReleaseBatch'
                                                  AND Country_Code__c ='GB' ];
        String className = batchSetting.Batch_Class__c;
        Type t  = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,2000);
        Test.stopTest();
    }
    
    public static User createData() {
        User user1 = createUser();
        createNotificationRecord(System.today().addDays(45), 3.0, false);
        return user1;
    }
    
    public static User createData2() {
        User user2 = createUser();
        createNotificationRecord(System.today().addDays(4), 5.0, false);
        return user2;
    }
    
    public static User createData3() {
        User user3 = createUser();
        createNotificationRecord(System.today().addDays(4), 5.0, true);
        return user3;
    }
    
    public static User createData4() {
        User user4 = createUser();
        createNotificationRecord(System.today().addDays(-1), null, true);
        return user4;
    }
    
    public static User createUser() {
        Profile prof = [SELECT Id FROM Profile WHERE Name =: 'Sales Representative'];
        User testUser = new User();
        testUser.firstName = 'TestUser';
        testUser.lastName = 'ForNotification';
        testUser.profileId = prof.Id;        
        testUser.email = 'testuser@testdomain.com';
        testUser.Username ='testuser@fornotification.com';
        testUser.Alias='test';
        testUser.Timezonesidkey='America/Los_Angeles';
        testUser.LocaleSidKey='en_US';
        testUser.LanguageLocaleKey='en_US';
        testUser.EmailEncodingKey='UTF-8';
        testUser.Available_Countries__c='GB';
        testUser.Title='Legal';
        return testUser;
    }
    
    public static void createNotificationRecord(Date endDate, Decimal interval, Boolean completed) {
        String edge365ReleaseNotifRecType = Label.EDGE_ReleaseNotificationRecordType;
        String edge365ReleaseNotifRecTypeId = Notification__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(edge365ReleaseNotifRecType).getRecordTypeId();
        Id country = EDGE_UtilityTestClass.setupCountryGB('GB');
        
        Notification__c notifRecord = new Notification__c();
        notifRecord.RecordTypeId = edge365ReleaseNotifRecTypeId;
        notifRecord.Name = 'New Test Notification 001';
        notifRecord.Country__c = country;
        notifRecord.Start_Date__c = System.today();
        notifRecord.End_Date__c = endDate;
        notifRecord.Duration_Interval__c = interval;
        notifRecord.Short_Description__c = 'Test Short Notification Description';
        notifRecord.Release_Completed__c = completed;
        notifRecord.Post_Release__c = 'Test Post Release message';
        insert notifRecord;
    }
}