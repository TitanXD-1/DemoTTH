/**
* @name : C360_CustomerServiceNotificationTest
* @description : Test Class for C360_CustomerServiceNotificationHelper
* @history
* VERSION      AUTHOR          DATE            DETAIL
* 1.0          Suvendu Roy     22/08/2023      Initial Dev
*/

@isTest
public class C360_CustomerServiceNotificationTest {
    @testSetup
    public static void setup(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('NIR');
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.C360_Case_Notification_Enabled__c = true;
        insert mktSetting;
        Account outletAccount1 = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount1.IsOperator__c=true;
        outletAccount1.Account_Type__c = 'Ship-To';
        outletAccount1.SAP_Sold_to__c='398402';
        outletAccount1.ECM_Legal_Name__c='Legal';
        outletAccount1.Email_for_contracts_payments__c='manikandan.t@diageo.com.test';
        outletAccount1.VAT_Number__c='TAXID13';
        outletAccount1.Name ='Test_Outlet_C360Acc';
        outletAccount1.Phone__c ='9090999090';
        insert outletAccount1;
    }

        
    @isTest
    public static void testMethod1(){
        Profile prof = [select id from profile where name= 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE;NIR;GB';
        insert usr;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof.id;        
        usr1.email = 'test.MamagerSfdc12@test.com';
        usr1.Username ='test.MamagerSfdc12@test.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='IE;NIR;GB';
        insert usr1;
        
        Id caseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        Account accountId = [Select Id,Country__c,Country_Code__c from Account where Name ='Test_Outlet_C360Acc' limit 1 ];
        Outlet_Member__c outMem = new Outlet_Member__c();
        outMem.Outlet__c = accountId.Id;
        outMem.User__c = usr.Id;
        outMem.Outlet_Role__c= 'Dispense Rep';
        insert OutMem;
        Test.startTest();
        D1_TestDataUtility.createOrgSettings();
        Case caseRecd1 = D1_TestDataUtility.createCase(caseRecTypeId,'Kegs Collection', 'Request empties keg collection', 'Testing Description', 'Open');
        caseRecd1.accountId = accountId.Id;
        caseRecd1.Origin = 'Diageo One';
        caseRecd1.OwnerId = usr.Id;
        insert caseRecd1;
        EntitySubscription es = new EntitySubscription();
        es.ParentId = caseRecd1.Id;
        es.SubscriberId = usr1.Id;
        insert es;
        caseRecd1.Status = 'In Progress';
        update caseRecd1;
        System.assertEquals(usr.Id, caseRecd1.OwnerId,'OK');
        Test.stopTest();
    }
    
    
    @isTest
    public static void testMethod2(){
        Profile prof = [select id from profile where name= 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE;NIR;GB';
        insert usr;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof.id;        
        usr1.email = 'test.MamagerSfdc12@test.com';
        usr1.Username ='test.MamagerSfdc12@test.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='IE;NIR;GB';
        insert usr1;

        Id caseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        Account accountId = [Select Id,Country__c,Country_Code__c from Account where Name ='Test_Outlet_C360Acc' limit 1 ];
        Outlet_Member__c outMem = new Outlet_Member__c();
        outMem.Outlet__c = accountId.Id;
        outMem.User__c = usr.Id;
        outMem.Outlet_Role__c= 'Primary';
        insert OutMem;
        Test.startTest();
        D1_TestDataUtility.createOrgSettings();
        Case caseRecd1 = D1_TestDataUtility.createCase(caseRecTypeId,'Contracts', 'Contract terms', 'Testing Description', 'Open');
        caseRecd1.accountId = accountId.Id;
        caseRecd1.Origin = 'Diageo One';
        caseRecd1.OwnerId = usr.Id;
        insert caseRecd1;
        EntitySubscription es = new EntitySubscription();
        es.ParentId = caseRecd1.Id;
        es.SubscriberId = usr1.Id;
        insert es;
        FeedItem feed = new FeedItem();
        feed.Body = 'Test feed comment';
        feed.ParentId = caseRecd1.id;
        insert feed;
        System.assertEquals(usr.Id, caseRecd1.OwnerId,'OK');
        Test.stopTest();
    }
    
}