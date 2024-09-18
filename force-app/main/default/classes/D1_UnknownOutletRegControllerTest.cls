/**
 * @name : D1_UnknownOutletRegControllerTest
 * @description : Test Class for D1_UnknownOutletRegistrationController
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Amar Deep       20/08/2021      Initial Development (NCP-)
 */
@istest
public with sharing class D1_UnknownOutletRegControllerTest {
    
    @testsetup
    public static void setup(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id = :countryId];
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test[GB]');  
        Account outletAccount = D1_TestDataUtility.getD1Customer();//outlet record
        outletAccount.Direct_Customer__c = false;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;
		outletAccount.Current_Approval_Step__c ='';
		insert outletAccount;
        D1_TestDataUtility.setUpExternalUser(outletAccount,'Outlet/Retailers');   
        
    }

    @istest
    public static void getD1SettingDetailTest(){
        User portalUser = [select id from user where usertype='Guest'  and IsActive = true limit 1];
        
        
        System.assert(portalUser != null, 'portal user not found');
        system.runAs(portalUser){
            D1_Setting__c d1SettingRecd = D1_UnknownOutletRegistrationController.getD1Setting('GB','en_GB');
          	System.assert(d1SettingRecd != null, 'd1 setting record not found');
            
            List<D1_User_Type__c> userTypeList = D1_UnknownOutletRegistrationController.getUserType('GB','en_GB');
            System.assert(userTypeList != null, 'userTypeList not found');
            
            String outletName = 'test';
            String uin = '11111';
            String postalCode = '456789';
			string uinAPI = 'New_VAT__c';            
        	
            List<Account> accountList = D1_UnknownOutletRegistrationController.validateAccount(uinAPI,uin,outletName,postalCode );
            System.assert(accountList != null, 'accountList not found');
            try{
              List<Account> accountListnew = D1_UnknownOutletRegistrationController.validateAccount('','','','' );
                System.assert(accountListnew != null, 'accountList not found');
            }catch(Exception ex){
                system.debug(LoggingLevel.ERROR, ex);
            }
  			string leadwrapper = '{"outletName":"Outlet","street":"street","city":"city","postalCode":"232323","countryCode":"GB","countryISOCode":"GB","uin":"11111","uinAPI":"New_VAT__c","uinLabel":"VAT Number","phoneNumberPrefixImage":"/DiageoOne/sfc/servlet.shepherd/version/download/0687Z0000015qoqQAA","registrationType":"Primary","phoneNumberPrefix":"+44","phoneNumber":"2323232323","phone":"+442323232323","firstName":"test","lastName":"name","email":"test@test.com","outletRole":"Owner","mobileNumberPrefixImage":"/DiageoOne/sfc/servlet.shepherd/version/download/0687Z0000015qoqQAA","mobileNumberPrefix":"+44","mobileNumber":"3434343434","mobile":"+443434343434","selectedOutletName":"","selectedStreet":"","selectedCity":"","selectedPostalCode":"","selectedCountryCode":""}';
			string leadwrappernew = '{"outletName":"Outlet","street":"street","city":"city","postalCode":"232323","countryCode":"GB","countryISOCode":"GB","uin":"11111","uinAPI":"New_VAT__c","uinLabel":"VAT Number","phoneNumberPrefixImage":"/DiageoOne/sfc/servlet.shepherd/version/download/0687Z0000015qoqQAA","registrationType":"Primary","phoneNumberPrefix":"+44","phoneNumber":"2323232323","phone":"+442323232323","firstName":"test","lastName":"name","email":"test","outletRole":"Owner","mobileNumberPrefixImage":"/DiageoOne/sfc/servlet.shepherd/version/download/0687Z0000015qoqQAA","mobileNumberPrefix":"+44","mobileNumber":"3434343434","mobile":"+443434343434","selectedOutletName":"","selectedStreet":"","selectedCity":"","selectedPostalCode":"","selectedCountryCode":""}';
            
            D1_UserRegistrationValidator.UserValidationResultWrapper wrapperRecd = D1_UnknownOutletRegistrationController.createLead(leadwrapper);
            wrapperRecd = D1_UnknownOutletRegistrationController.createLead(leadwrapper);
            D1_UserRegistrationValidator.UserValidationResultWrapper wrapperRecd1 = D1_UnknownOutletRegistrationController.createLead(leadwrappernew);
           wrapperRecd1 = D1_UnknownOutletRegistrationController.createLead(leadwrappernew);
           
        }
    }

    @istest
    public static void getPrimaryContactTest() { 
        
        Account  outletAccount= [SELECT Id FROM Account WHERE Name = 'Test Customer Account' limit 1];
         Contact primcon1 = new Contact(FirstName='fname1',
                                         LastName = 'lname',
                                         Email = 'email1P@gmail.com',
                                         Phone = '12345672890',Contact_Type__c='Primary',AccountID=outletAccount.Id);
        D1_Setting__c d1SettingTest=[select id from D1_Setting__c limit 1];
        D1_UnknownOutletRegistrationController.getPrimaryContact(outletAccount.Id);
        D1_UserRegistrationDetailWrapper regUser = new D1_UserRegistrationDetailWrapper();
        regUser.outletName= 'outletAccount';
        regUser.street= 'test123';
        regUser.city= 'london';
        regUser.postalCode= '456754';
        regUser.firstName= 'Test12';
        regUser.lastName= 'Name';
        regUser.email= 'test@test.com';
        regUser.mobile= '2323232323';
        regUser.languageLocaleKey= 'GB_en';
        regUser.userType= 'Direct';
        regUser.userCountryCode= 'GB';
        regUser.mobileCountryCode= '+44';
        regUser.primarySalesRepEmail= '';
        regUser.userTypeId= '';
        regUser.subscriptionSource= 'Frontend';
        regUser.contactId= '';
        regUser.subscriptionValue= '';
        regUser.accountNumber= '';
        regUser.d1SettingId= d1SettingTest.Id;
        regUser.outletRole = 'Manager';
        
        D1_UnknownOutletRegistrationController.sendEmailToPrimaryContact(regUser,primcon1);
        System.assert(D1_UnknownOutletRegistrationController.sendEmailToPrimaryContact(regUser,primcon1) == NULL, 'email not sent');
    }
     /**
     * @description testEmail
     */
    
    @isTest
    public static void testEmail(){
        D1_UserRegistrationDetailWrapper myDetail = new D1_UserRegistrationDetailWrapper();
        myDetail.accountNumber ='4545';
        myDetail.firstName = 'Divya';
        myDetail.lastName = 'Kolhatkar';
        myDetail.email = 'divya.kolhatkar@diageo.com';
        myDetail.outletName ='My Account';
        myDetail.street = 'abc street';
        myDetail.city = 'abcdfd city';
        myDetail.postalCode = '123456';
        myDetail.mobile = '9874456987';
        myDetail.outletRole = 'Manager';
        
        Contact conRec = new Contact();
        conRec.FirstName = 'ABDd';
        conRec.LastName = 'Kolhatkar41';
        conRec.Email = 'divya.kolhatkar@diageo.com';
      
        
        D1_UnknownOutletRegistrationController.sendEmailToPrimaryContact(myDetail,conRec);
        System.assert(D1_UnknownOutletRegistrationController.sendEmailToPrimaryContact(myDetail,conRec) == NULL, 'email not sent');
        
    }
}