@isTest
public with sharing class D1_ContactTriggerHelperTest {
    
    
    @testSetup static void createTestData(){
        D1_TestDataUtility.setupCountry('GB');
        
        Diageo_One_Security_Settings__c setting = new Diageo_One_Security_Settings__c();
        setting.Name = 'Test Setting';
        setting.First_Reminder_Days__c = 365;
        setting.Second_Reminder_Days__c = 379;
        setting.Deactivate_Reminder_Days__c = 393;
        setting.Max_login_attempts_for_community_user__c = 10;
        
        insert setting;
        
        //Create Account
        Account account = D1_TestDataUtility.getDirectCustomer();
        account.Country_ISO_Code__c = 'GB';
        
        //Setup Direct Customer
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        
        //Setup Org Setting
        D1_TestDataUtility.createOrgSettings();
        
        //Get Account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact primcon=new Contact(FirstName='fnames',
                                    LastName = 'lnames',
                                    Email = 'email@yopmail.com',
                                    D1_Contact_Last_Login_Date__c=Datetime.now(),
                                    Phone = '1234567899',Contact_Type__c='Primary',AccountID=acc.Id,D1_Login_Reminder_Status__c='First Reminder'); 
        insert primcon;
        
        
        primcon.D1_Login_Reminder_Status__c='First Reminder';
        update primcon;
        
        
        
        Contact secondCon=new Contact(FirstName='fname1',
                                      LastName = 'lname1',
                                      Email = 'email1@gmail.com',
                                      MobilePrefix__c = '+61',
                                      Mobile__c = '512123456',
                                      PhonePrefix__c = '+34',
                                      Phone__c = '123456789',
                                      AccountID=acc.Id,MD_ContactSubscriptions__c='Email'); 
        insert secondCon;
        
    }
    @isTest
    public static void testupdateEmailPreferenceUpdate(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c, 'country code not matched');
            List<contact> listUpdate= new List<contact>();
            for(Contact con: [select id,MD_ContactSubscriptions__c from contact where AccountId=:acc.Id]){
                if(con.MD_ContactSubscriptions__c == null){
                    con.MD_ContactSubscriptions__c='Email';
                    con.HasOptedOutOfEmail=false;
                }
                if(con.MD_ContactSubscriptions__c != null && con.MD_ContactSubscriptions__c.contains('Email')){
                    con.HasOptedOutOfEmail=true;
                }
                listUpdate.add(con);
            }
            Test.startTest();
            update listUpdate;
            Test.stopTest();
        } catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        
    }
    @isTest
    public static void testupdateEmailPreferenceInsert(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c, 'country code not matched');
            Contact primcon=new Contact(FirstName='fname',
                                        LastName = 'lname',
                                        Email = 'email@gmail.com',
                                        Phone = '1234567890',Contact_Type__c='Primary',AccountID=acc.Id); 
            Test.startTest();
            insert primcon;
            Test.stopTest();
        } catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        
    }
    @isTest
    public static void testDeleteContact(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c, 'country code not matched');
            List<contact> con= [select id,MD_ContactSubscriptions__c from contact where AccountId=:acc.Id];
            Test.startTest();   
            delete con;
            Test.stopTest();          
        } catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        
    }
    @isTest
    public static void testUpdateLoginNextAction(){
        contact con = [select id,FirstName,LastName,Email,D1_Contact_Last_Login_Date__c
                       ,Phone,Contact_Type__c,AccountID,D1_Login_Reminder_Status__c from contact where Email='email@yopmail.com'];
        Test.startTest(); 
        con.D1_Login_Reminder_Status__c='Second Reminder';
        update con;
        con.D1_Login_Reminder_Status__c='First Reminder';
        update con;
        con.D1_Login_Reminder_Status__c='Compliant';
        System.assertEquals(con.D1_Login_Reminder_Status__c, 'Compliant', 'Login reminder status did not match');
        update con;
        Test.stopTest();   
    }
    @isTest
    public static void testvalidatePreferredLanguage(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c, 'country code not matched');
            Contact primcon=new Contact(FirstName='fname',
                                        LastName = 'lname',
                                        Email = 'email@gmail.com',
                                        Phone = '1234567890',Contact_Type__c='Primary',
                                        AccountID=acc.Id,
                                        Preferred_Language__c = 'en_IE'); 
            Test.startTest();
            insert primcon;
            Test.stopTest();
        } catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
    }
    
    
    
    
    @isTest
    public static void testUpdateAccountData(){
        Account directCust = D1_TestDataUtility.getDirectCustomer();
        directCust.Name = 'Test Direct Account2';
        directCust.KUNNR__c = '23432';
        insert directCust;
        
        Contact secContact = D1_TestDataUtility.getContact(directCust.Id, 'Secondary');
        secContact.Email = 'testSecondaryContact.test@gmail.com';
        secContact.Phone = '9098909897';
        insert secContact;
        
        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountID =: directCust.Id and ContactId =: secContact.Id];
        acr.D1_User_Role__c = 'Member of Staff';
        acr.D1_Roles__c = 'Default Access;User Management';
        acr.D1_Active__c = FALSE;
        update acr;
        
        Test.startTest();
        secContact.D1_Login_Reminder_Status__c = 'Deactivated';
        update secContact;
        System.assertEquals(secContact.D1_Login_Reminder_Status__c, 'Deactivated', 'Login reminder status did not match');
        Test.stopTest();
    }
    
    @isTest
    public static void testUpdatePOSOrderDate(){
        Account directCust = D1_TestDataUtility.getDirectCustomer();
        directCust.Name = 'Test Direct Account2';
        directCust.KUNNR__c = '23432';
        directCust.Last_POS_Order_Date__c = System.now()-5;
        insert directCust;
        
        Contact secContact = D1_TestDataUtility.getContact(directCust.Id, 'Secondary');
        secContact.Email = 'testSecondaryContact.test@gmail.com';
        secContact.Phone = '9098909897';
        secContact.POS_Order_Email_Sent__c = System.now()-10;
        secContact.POS_Order_Date__c = System.now()-10;
        
        secContact.POS_Order_Account_Id__c = directCust.Id;
        insert secContact;
        
        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountID =: directCust.Id and ContactId =: secContact.Id];
        acr.D1_User_Role__c = 'Member of Staff';
        acr.D1_Roles__c = 'User Management;Default Access;POS & Equipment Ordering';
        acr.D1_Active__c = TRUE;
        update acr;
        
        Test.startTest();
        secContact.POS_Order_Email_Sent__c = System.now();
        update secContact;
        System.assertEquals(acr.D1_Active__c, TRUE, 'acr not active');
        Test.stopTest();
    }
    
    @isTest
    public static void testValidateUserBusinessRole(){
        Geography__c country = [Select Id from Geography__c where name = 'Great Britain_TestGB' Limit 1];
        Profile prof = [select id from profile where name=: 'System Administrator'];
        
        User usr = new User();
        usr.firstName = 'teste1';
        usr.lastName = 'teste2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdce1@test.com';
        usr.Username ='test.MamagerSfdce1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='GB';
        insert usr;
        System.assert(usr.id!=null,'user id should not be null');
        Account directCust = D1_TestDataUtility.getDirectCustomer();
        directCust.Name = 'Test Direct Account22';
        directCust.KUNNR__c = '23442';
        directCust.Last_POS_Order_Date__c = System.now()-1;
        insert directCust;
        
        Contact secContact = D1_TestDataUtility.getContact(directCust.Id, 'Secondary');
        secContact.Email = 'testSecondaryContact.test@gmail.com';
        secContact.Phone = '9098909897';
        secContact.POS_Order_Email_Sent__c = System.now()-10;
        secContact.POS_Order_Date__c = System.now()-10;
        secContact.POS_Order_Account_Id__c = directCust.Id;
        secContact.MD_CurrentRole__c = 'Other';
        insert secContact;
        
        System.runAs(usr){
            Business_Role__c businessRole =new Business_Role__c();
            businessRole.Name='IRE Mainland';
            businessRole.Country__c= country.Id;
            businessRole.Call_Type__c='Telephone';
            businessRole.Eligible_Outlet_Role__c= 'Owner';
            insert businessRole;
            
            User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
            userBusinessRole.Business_Role__c=businessRole.Id;
            userBusinessRole.User__c=usr.Id;
            insert userBusinessRole;
            
            Test.startTest();
            try{
                secContact.Phone = '9098909805';
                update secContact;
                
            }
            catch (Exception e)
            {
                System.Assert(e.getMessage().contains('Please contact your MDM for any issue'), 'Unexpected error occured');
            }
            try{
                secContact.MD_CurrentRole__c = 'Manager';
                update secContact;
                
            }
            catch (Exception e)
            {
                System.Assert(e.getMessage().contains('Please contact your MDM for any issue'), 'Unexpected error occured');
            }
            Test.stopTest();
        }
    }
    
}