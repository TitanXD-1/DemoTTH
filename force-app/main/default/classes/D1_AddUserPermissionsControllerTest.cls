/**
 * @name : D1_AddUserPermissionsControllerTest
 * @description : Test Class for D1_AddUserPermissionsController
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Kapil Baliyan   06/10/2021      Initial Development (NCP-4192)
 * 2.0          Narayana        27/01/2022 		Resend Customer Invite(NCP-5931)
 * 3.0			Rubeena			06/06/2022		NCP-6024
 * 4.0          Kapil Baliyan   16/12/2022      NCP-7681(Re-structure Complete Class)
 */
@isTest
public class D1_AddUserPermissionsControllerTest {
    //@SuppressWarnings('PMD.NcssMethodCount')
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

        //Insert Direct Customer 2
        Account directCustomer2 = D1_TestDataUtility.getDirectCustomer();
        directCustomer2.Name = 'Test Direct Account2';
        directCustomer2.KUNNR__c = '998800';
        insert directCustomer2;
        
        //Insert Partner Function
        List<PNR_Partner_Function__c> pnrList = new List<PNR_Partner_Function__c>();
        PNR_Partner_Function__c pfPayer = D1_TestDataUtility.getPartnerFunction(directCustomer,'Payer');
        pnrList.add(pfPayer);
        
        PNR_Partner_Function__c pfSoldTo = D1_TestDataUtility.getPartnerFunction(directCustomer,'Sold-to');
        pnrList.add(pfSoldTo);

        PNR_Partner_Function__c pfSoldTo2 = D1_TestDataUtility.getPartnerFunction(directCustomer2,'Sold-to');
        pnrList.add(pfSoldTo2);

        PNR_Partner_Function__c pfPayer2 = D1_TestDataUtility.getPartnerFunction(directCustomer2,'Payer');
        pnrList.add(pfPayer2);

        insert pnrList;

        //Create Pickup Option
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test');

        //Create Outlet
        Account outlet = D1_TestDataUtility.getD1Customer();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;
        outlet.Direct_Customer__c = false;
        insert outlet;

        //Create Contacts
        List<Contact> conList = new List<Contact>();
        Contact directContact = D1_TestDataUtility.getContact(directCustomer.Id,'Secondary');
        directContact.FirstName = 'Add';
        directContact.LastName = 'User1';
        directContact.Phone = '7667898876';
        directContact.Email = 'direct2.contact@testdomain.com';
        conList.add(directContact);

        Contact indirectContact = D1_TestDataUtility.getContact(outlet.Id,'Secondary');
        indirectContact.FirstName = 'Add';
        indirectContact.LastName = 'User2';
        indirectContact.Phone = '7667898877';
        indirectContact.Email = 'indirect.contact@testdomain.com';
        conList.add(indirectContact);

        Contact indirectContact2 = D1_TestDataUtility.getContact(outlet.Id,'Secondary');
        indirectContact2.FirstName = 'Add';
        indirectContact2.LastName = 'User3';
        indirectContact2.Phone = '7667898878';
        indirectContact2.Email = 'indirect2.contact@testdomain.com';
        indirectContact2.Preferred_Language__c = 'en_GB';
        conList.add(indirectContact2);

        Contact directContact2 = D1_TestDataUtility.getContact(directCustomer2.Id,'Secondary');
        directContact2.FirstName = 'Add';
        directContact2.LastName = 'User4';
        directContact2.Phone = '7667898879';
        directContact2.Email = 'direct3.contact@testdomain.com';
        conList.add(directContact2);

        insert conList;

        //Create InDirect D1 User
        User inDirectUser = D1_TestDataUtility.runAsUser('indirectExtUser', 'DiageoOne External User');
        inDirectUser.ContactId = conList[1].Id;
        inDirectUser.Effective_Account_Id__c = outlet.Id;
        inDirectUser.Email = 'indirect.contact@testdomain.com';
        inDirectUser.D1_User_Type__c = 'Outlet/Retailers';
        inDirectUser.D1_User_Type_Id__c = indirectUserType.Id;

        insert inDirectUser;

        //Update ACR
        List<AccountContactRelation> acrs = [SELECT Id, D1_Roles__c FROM AccountContactRelation WHERE (Contact.Email = 'testclassextuser1@testdomain.com' OR Contact.Email = 'indirect.contact@testdomain.com')];
        for(AccountContactRelation acr : acrs){
            acr.D1_Roles__c = 'Default Access;User Management';
            acr.D1_Active__c = True;
            acr.D1_User_Role__c = 'Primary';
        }
        update acrs;
    }

    @isTest
    static void addUserPermissionsDirectPrimaryTest(){
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId, FirstName, LastName, Email, Account.Country__c, Account.Country_Code__c FROM Contact WHERE Email = 'direct3.contact@testdomain.com' LIMIT 1];
        D1_UserRegistrationDetailWrapper userRegWrapper = getUserRegWrapper(con);

        Test.startTest();
            List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getAccountPermissions(con.Id, false);
            D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.addUserPermissions(userRegWrapper, getUserPermissionWrapper(userPermissionWrapperList), false);
        Test.stopTest();
        
        System.assertEquals(true, responseWrapper.isSuccess, 'User is not created');
    }

    @isTest
    static void addUserPermissionsDirectSecondaryTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        Contact secondaryCon = [SELECT Id, AccountId, Email, FirstName, LastName FROM Contact WHERE Email = 'direct2.contact@testdomain.com' LIMIT 1];
        D1_UserRegistrationDetailWrapper userRegWrapper = getUserRegWrapper(secondaryCon);

        System.RunAs(usr){
            Test.startTest();
                //Get Account Permission
                List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getAccountPermissions(con.Id, true);
                
                //Create D1 User
                D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.addUserPermissions(userRegWrapper, getUserPermissionWrapper(userPermissionWrapperList), true);

                //Add Order Permission
                //D1_AddUserPermissionsController.addOrderPermission(con.Id, con.AccountId);
            Test.stopTest();

            System.assertEquals(true, responseWrapper.isSuccess, 'User is not created');
        }
    }

    @isTest
    static void addUserPermissionsValidateEmailDomainTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        Contact secondaryCon = [SELECT Id, AccountId, Email, FirstName, LastName FROM Contact WHERE Email = 'direct2.contact@testdomain.com' LIMIT 1];
        secondaryCon.Email = 'direct2.contact@testdomain1.com';
        update secondaryCon;

        D1_UserRegistrationDetailWrapper userRegWrapper = getUserRegWrapper(secondaryCon);

        System.RunAs(usr){
            Test.startTest();
                //Get Account Permission
                List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getAccountPermissions(con.Id, true);
                
                //Create D1 User
                D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.addUserPermissions(userRegWrapper, getUserPermissionWrapper(userPermissionWrapperList), true);
            Test.stopTest();

            System.assertEquals(true, responseWrapper.isSuccess, 'User is not created');
        }
    }

    @isTest
    static void addUserPermissionsInDirectPrimaryTest(){
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId, FirstName, LastName, Email, Account.Country__c, Account.Country_Code__c FROM Contact WHERE Email = 'indirect2.contact@testdomain.com' LIMIT 1];
        D1_UserRegistrationDetailWrapper userRegWrapper = getUserRegWrapper(con);

        Test.startTest();
            List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getAccountPermissions(con.Id, false);
            D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.addUserPermissions(userRegWrapper, getUserPermissionWrapper(userPermissionWrapperList), false);
        Test.stopTest();
        
        System.assertEquals(true, responseWrapper.isSuccess, 'User is not created');
    }

    @isTest
    static void addUserPermissionsInDirectSecondaryTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'indirect.contact@testdomain.com' LIMIT 1];
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'indirect.contact@testdomain.com' LIMIT 1];
        Contact secondaryCon = [SELECT Id, AccountId, Email, FirstName, LastName FROM Contact WHERE Email = 'indirect2.contact@testdomain.com' LIMIT 1];
        D1_UserRegistrationDetailWrapper userRegWrapper = getUserRegWrapper(secondaryCon);

        System.RunAs(usr){
            Test.startTest();
                //Get Account Permission
                List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getAccountPermissions(con.Id, true);
                
                //Create D1 User
                D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.addUserPermissions(userRegWrapper, getUserPermissionWrapper(userPermissionWrapperList), true);
            Test.stopTest();

            System.assertEquals(true, responseWrapper.isSuccess, 'User is not created');
        }
    }

    @isTest
    static void editUserPermissionsDirectTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        Contact secondaryCon = [SELECT Id, AccountId, Email, FirstName, LastName FROM Contact WHERE Email = 'direct2.contact@testdomain.com' LIMIT 1];

        System.RunAs(usr){
            Test.startTest();
                List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getEditAccountPermissions(secondaryCon.Id, con.Id, true);
                D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.editUserPermissions(secondaryCon.Id, getUserPermissionWrapper(userPermissionWrapperList), true);
            Test.stopTest();

            System.assertEquals(true, responseWrapper.isSuccess, 'User Permission is not updated');
        }
    }

    @isTest
    static void editUserPermissionsInDirectTest(){
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId, FirstName, LastName, Email, Account.Country__c, Account.Country_Code__c FROM Contact WHERE Email = 'indirect.contact@testdomain.com' LIMIT 1];

        Test.startTest();
            List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getEditAccountPermissions(con.Id, con.Id, false);
            D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.editUserPermissions(con.Id, getUserPermissionWrapper(userPermissionWrapperList), false);
        Test.stopTest();

        System.assertEquals(true, responseWrapper.isSuccess, 'User Permission is not updated');
    }

    @isTest
    static void editUserPermissionsInDirectDeactivateTest(){
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId, FirstName, LastName, Email, Account.Country__c, Account.Country_Code__c FROM Contact WHERE Email = 'indirect.contact@testdomain.com' LIMIT 1];

        Test.startTest();
            List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getEditAccountPermissions(con.Id, con.Id, false);
            D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.editUserPermissions(con.Id, getUnselectedUserPermissionWrapper(userPermissionWrapperList), false);
        Test.stopTest();

        System.assertEquals(true, responseWrapper.isSuccess, 'User Permission is not updated');
    }

    @isTest
    static void reactivateUserTest(){
        //Get User
        User usr = [SELECT Id, IsActive FROM User WHERE Email = 'indirect.contact@testdomain.com' LIMIT 1];
        usr.IsActive = false;
        update usr;

        //Get Primary Contact
        Contact con = [SELECT Id, AccountId, FirstName, LastName, Email, Account.Country__c, Account.Country_Code__c FROM Contact WHERE Email = 'indirect.contact@testdomain.com' LIMIT 1];
        D1_UserRegistrationDetailWrapper userRegWrapper = getUserRegWrapper(con);

        Test.startTest();
            List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList = D1_AddUserPermissionsController.getAccountPermissions(con.Id, false);
            D1_AddUserPermissionsController.ResponseWrapper responseWrapper = D1_AddUserPermissionsController.addUserPermissions(userRegWrapper, getUserPermissionWrapper(userPermissionWrapperList), false);
        Test.stopTest();
        
        System.assertEquals(true, responseWrapper.isSuccess, 'User is not created');
    }

    @isTest
    static void validateUserForResendTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        //Get Primary Contact
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        System.RunAs(usr){
            Test.startTest();
                Map<String,String> checkUserForResendInviteResult = D1_AddUserPermissionsController.validateUserForResend(con.Id);
            Test.stopTest();
            System.Assert(true, checkUserForResendInviteResult != null);
        }
    }

    @isTest
    static void validateUserAccessTest(){
        Contact con = [SELECT Id, AccountId, Email, FirstName, LastName FROM Contact WHERE Email = 'direct2.contact@testdomain.com' LIMIT 1];
        Test.startTest();
            Map<String, Boolean> validateUserMap = D1_AddUserPermissionsNewController.validateUserAccess(con.Id, true);
        Test.stopTest();
        System.Assert(true, validateUserMap != null);
    }

    @isTest
    static void resendRegistrationInviteTest(){
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];

        System.RunAs(usr){
            Test.startTest();
                D1_AddUserPermissionsController.resendRegistrationInvite(usr.Id);
            Test.stopTest();
            System.Assert(true, true);
        }
    }

    @isTest
    static void validateContactTest(){
        Contact con = [SELECT Id, AccountId, FirstName, LastName, Email FROM Contact WHERE Email = 'indirect2.contact@testdomain.com' LIMIT 1];

        Test.startTest();
            Map<String,Object> result = D1_AddUserPermissionsNewController.validateContact(con.Id);
        Test.stopTest();
        System.Assert(true, result != null);
    }

    private static D1_UserRegistrationDetailWrapper getUserRegWrapper(Contact con){
        D1_UserRegistrationDetailWrapper userRegWrapper = new D1_UserRegistrationDetailWrapper();
        userRegWrapper.accountId = con.AccountId;
        userRegWrapper.contactId = con.Id;
        userRegWrapper.email = con.Email;
        userRegWrapper.firstName = con.FirstName;
        userRegWrapper.lastName = con.LastName;
        userRegWrapper.mobile = '7667898876';
        userRegWrapper.languageLocaleKey= 'en_GB';
        userRegWrapper.userCountryCode='GB';

        return userRegWrapper;
    }

    private static List<D1_AddUserPermissionsController.UserPermissionWrapper> getUserPermissionWrapper(List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList){
        for(D1_AddUserPermissionsController.AccountWrapper accWrapper : userPermissionWrapperList.get(0).accountWrapperList){
            accWrapper.isSelected = true;
            accWrapper.permissionWrapperList.get(0).isSelected = true;
        }
        return userPermissionWrapperList;
    }

    private static List<D1_AddUserPermissionsController.UserPermissionWrapper> getUnselectedUserPermissionWrapper(List<D1_AddUserPermissionsController.UserPermissionWrapper> userPermissionWrapperList){
        for(D1_AddUserPermissionsController.AccountWrapper accWrapper : userPermissionWrapperList.get(0).accountWrapperList){
            accWrapper.isSelected = false;
            accWrapper.permissionWrapperList.get(0).isSelected = false;
        }
        return userPermissionWrapperList;
    }
}