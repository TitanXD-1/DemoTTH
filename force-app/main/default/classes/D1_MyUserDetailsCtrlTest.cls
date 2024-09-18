/**
 * @name D1_MyUserDetailsCtrlTest
 * @description Test class for D1_MyUserDetailsCtrl 
 * @history
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Rubeena Naaz            06/07/2021      NCP-3781 (Refactoring)
 * 2.0              Kapil Baliyan           21/12/2022      NCP-7681 (Refactoring) 
 */
@isTest
public without sharing class D1_MyUserDetailsCtrlTest {

    @testSetup
    public static void datasetup(){
        //Direct Setup
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        //Insert External User
        D1_TestDataUtility.setUpExternalUser(directCustomer, 'Direct Buyer'); //testclassextuser1@testdomain.com

        //Get Country
        Geography__c country = [SELECT Id, Name, Code__c FROM Geography__c WHERE RecordType.Name='Country' LIMIT 1];

        //Get D1 Setting
        D1_Setting__c d1Setting = [SELECT Id, Language__c, Default__c, Market__c FROM D1_Setting__c LIMIT 1];

        //Get Direct Buyer User Type
        D1_User_Type__c userType = [SELECT Id,Name FROM D1_User_Type__c WHERE User_Type__c='Direct Buyer' LIMIT 1];

        //Create InDirect User Type
        D1_User_Type__c indirectUserType = D1_TestDataUtility.getD1UserType(country.Name, 'Outlet/Retailers', d1Setting.Id);
        indirectUserType.Email_Domain_Check__c = false;
        insert indirectUserType;

        //Create User Role
        List<D1_User_Role__c> userRoleList = new List<D1_User_Role__c>();
        D1_User_Role__c userRole = D1_TestDataUtility.getD1UserRole('Default Access');
        userRoleList.add(userRole);

        D1_User_Role__c userRole1 = D1_TestDataUtility.getD1UserRole('User Management');
        userRoleList.add(userRole1);

        D1_User_Role__c userRole2 = D1_TestDataUtility.getD1UserRole('Ordering');
        userRoleList.add(userRole2);

        insert userRoleList;
        
        //Create User Type Role
        List<D1_User_Types_Role__c> userTypeRoleList = new List<D1_User_Types_Role__c>();
        D1_User_Types_Role__c userTypeRole = D1_TestDataUtility.getD1UserTypeRole(userType, userRoleList[0]);
        userTypeRoleList.add(userTypeRole);

        D1_User_Types_Role__c userTypeRole1 = D1_TestDataUtility.getD1UserTypeRole(userType, userRoleList[1]);
        userTypeRoleList.add(userTypeRole1);

        D1_User_Types_Role__c userTypeRole2 = D1_TestDataUtility.getD1UserTypeRole(userType, userRoleList[2]);
        userTypeRoleList.add(userTypeRole2);

        D1_User_Types_Role__c userTypeRole3 = D1_TestDataUtility.getD1UserTypeRole(indirectUserType, userRoleList[0]);
        userTypeRoleList.add(userTypeRole3);

        D1_User_Types_Role__c userTypeRole4 = D1_TestDataUtility.getD1UserTypeRole(indirectUserType, userRoleList[1]);
        userTypeRoleList.add(userTypeRole4);

        insert userTypeRoleList;
        
        //Insert Partner Function
        List<PNR_Partner_Function__c> pnrList = new List<PNR_Partner_Function__c>();
        PNR_Partner_Function__c pfPayer = D1_TestDataUtility.getPartnerFunction(directCustomer,'Payer');
        pnrList.add(pfPayer);
        
        PNR_Partner_Function__c pfSoldTo = D1_TestDataUtility.getPartnerFunction(directCustomer,'Sold-to');
        pnrList.add(pfSoldTo);

        insert pnrList;

        //Create Contacts
        List<Contact> conList = new List<Contact>();
        Contact directContact = D1_TestDataUtility.getContact(directCustomer.Id,'Secondary');
        directContact.FirstName = 'Add';
        directContact.LastName = 'User1';
        directContact.Phone = '7667898876';
        directContact.Email = 'direct2.contact@testdomain.com';
        conList.add(directContact);

        insert conList;

        //Create Direct D1 User
        User directUser = D1_TestDataUtility.runAsUser('directExtUser', 'DiageoOne External User');
        directUser.ContactId = conList[0].Id;
        directUser.Effective_Account_Id__c = directCustomer.Id;
        directUser.Email = 'direct2.contact@testdomain.com';
        directUser.D1_User_Type__c = 'Direct Buyer';
        directUser.D1_User_Type_Id__c = userType.Id;

        insert directUser;

        //Update ACR
        List<AccountContactRelation> acrs = [SELECT Id, D1_Roles__c, Contact.Email FROM AccountContactRelation WHERE (Contact.Email = 'testclassextuser1@testdomain.com' OR Contact.Email = 'direct2.contact@testdomain.com')];
        for(AccountContactRelation acr : acrs){
            acr.D1_Roles__c = 'Default Access;User Management';
            acr.D1_Active__c = True;
            acr.D1_User_Role__c = acr.Contact.Email == 'testclassextuser1@testdomain.com' ? 'Primary' : 'Member Of Staff';
        }
        update acrs;
    }

    @isTest
    static void getmyuserdetailsTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];

        System.RunAs(usr){
            Test.startTest();
                List<AccountContactRelation> acrList = D1_MyUserDetailsCtrl.getmyuserdetails();
            Test.stopTest();

            System.assertEquals(true, acrList != null, 'No User Found');
            Assert.isNotNull(acrList,'No User Found');
        }
    }

    @isTest
    static void getExistingContactTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        string conEmail = 'testclassextuser1@testdomain.com';
        System.RunAs(usr){
            Test.startTest();
                Boolean isUserExist = D1_MyUserDetailsCtrl.getExistingContact(conEmail);
            Test.stopTest();
            System.assertEquals(true, isUserExist, 'User dont exist');
            Assert.isTrue(isUserExist, 'User dont exist');
        }
    }

    @isTest
    static void getUserRoleFromUserTest(){
        //Get Contact
        Contact con = [SELECT Id, Email FROM Contact WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];

        Test.startTest();
            Map<String, D1_User_Types_Role__c> userRolesMap = D1_MyUserDetailsCtrl.getUserRoleFromUser(con.Id, true);
        Test.stopTest();

        System.assertEquals(true, userRolesMap!=null, 'User Role Map is Empty');
        Assert.isNotNull(userRolesMap, 'User Role Map is Empty');
    }

    @isTest
    static void getUserRoleFromUser1Test(){
        //Get Contact
        Contact con = [SELECT Id, Email FROM Contact WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];

        Test.startTest();
            Map<String, D1_User_Types_Role__c> userRolesMap = D1_MyUserDetailsCtrl.getUserRoleFromUser(con.Id, false);
        Test.stopTest();

        System.assertEquals(true, userRolesMap!=null, 'User Role Map is Empty');
        Assert.isNotNull(userRolesMap, 'User Role Map is Empty');
    }

    @isTest
    static void deactivateUsersTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];

        //Get Contact
        Contact con = [SELECT Id, Email FROM Contact WHERE Email = 'direct2.contact@testdomain.com' LIMIT 1];
        List<Id> conIdSet = new List<Id>{con.Id};
        
        System.RunAs(usr){
            Test.startTest();
                D1_MyUserDetailsCtrl.ResponseWrapper resWrapper = D1_MyUserDetailsCtrl.deactivateUsers(conIdSet);
            Test.stopTest();
            System.assertEquals(true, resWrapper!=null, 'User Role Map is Empty');
            Assert.isNotNull(resWrapper, 'User Role Map is Empty');
        }
    }

    @isTest
    static void getEffectiveAccountTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        System.RunAs(usr){
            Test.startTest();
                Account acc = D1_MyUserDetailsCtrl.getEffectiveAccount();
            Test.stopTest();
            System.assertEquals(true, acc!=null, 'Account is Empty');
            Assert.isNotNull(acc, 'Account is Empty');
        }
    }

    @isTest
    static void getLogInUserDetailsTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        System.RunAs(usr){
            Test.startTest();
                Contact con = D1_MyUserDetailsCtrl.getLogInUserDetails();
            Test.stopTest();
            System.assertEquals(true, con!=null, 'Contact is Empty');
            Assert.isNotNull(con, 'Contact is Empty');
        }
    }

    @isTest
    static void getUserPermissionSetTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        System.RunAs(usr){
            Test.startTest();
                Object obj = D1_MyUserDetailsCtrl.getUserPermissionSet();
            Test.stopTest();
            System.assertEquals(true, obj!=null, 'Contact is Empty');
            Assert.isNotNull(obj, 'Contact is Empty');
        }
    }
    
    @isTest
    static void getUserTypeTest(){
        String contryCode= 'GB';
        String language = 'en_GB';
        String userType = 'Outlet/Retailers';
        String channel = 'Off Trade';
        D1_User_Type__c userTypeId = D1_MyUserDetailsCtrl.getUserType(contryCode,language,userType,channel);
        Assert.isNotNull(userTypeId,'User Type returned');
    }
    
	//143282
    @isTest
    static void getmynonregcontactdetails(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        System.RunAs(usr){
            Test.startTest();
            List<Contact> contactList = D1_MyUserDetailsCtrl.getmynonregcontactdetails();
            Test.stopTest();
            System.assertEquals(true, contactList!=null, 'Contact is Empty');
            Assert.isNotNull(contactList, 'Contact is Empty');
        }
    }
}