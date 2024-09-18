/**
 * @name D1_UserRegistrationValidatorTest
 * @description Test Class for D1_UserRegistrationValidator Class.
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Manikant p
 * 2.0         Rithika         12/07/2021  Test Class Refactor
**/
@isTest
public class D1_UserRegistrationValidatorTest {  
    
    /**
     * @description testValidateUser
     */    
    @isTest
    public static void testValidateUser(){
        
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        D1_User_Type__c d1UserType;
        D1_Setting__c d1settings;
        
        System.runAs(thisUser){            
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser; 
            
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            country = new Geography__c(Id= countryId);
            
            pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
            insert pickupOption;
            
            d1settings = D1_TestDataUtility.createD1Settings(country);
            d1settings.Name = 'GB setting';
            d1settings.Unique_ID__c = 'test GB';
            d1settings.Language__c = 'en_GB';
            insert d1settings;
            
            d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1settings.Id);
            insert d1UserType;
		            
            D1_User_Type__c userRegValidator = D1_UserRegistrationValidator.getD1UserTypeById(d1UserType.Id);
            system.assert(userRegValidator!=null,'getD1UserTypeById method failed');
            
        }  
        system.runAs(testAdminUser){
            //String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
            
            D1_Setting__c d1setting = [SELECT Id,CS_Notification_email__c, Hide_Registration_First_Screen__c FROM D1_Setting__c LIMIT 1];
         
            Account testoutlet = D1_TestDataUtility.getDirectCustomer();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.BillingStreet = 'test'; 
            testoutlet.BillingCity='test';
            testoutlet.BillingPostalCode='234565';
            testoutlet.D1_Registration_Status__c = '';
            testoutlet.Current_Approval_Step__c ='';
            testoutlet.Status__c='';
            insert testoutlet;
        	Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id,'Primary');
        	insert primcon1;     
            List<Contact> conList=[select id from Contact where accountId=:testoutlet.Id ];
            system.assert(conList.size() > 0, 'contact list empty');
            
            AccountContactRelation acr = [SELECT ID,Contact_Type__c,ContactID,IsDirect FROM AccountContactRelation WHERE ContactId =:primcon1.Id AND AccountId =:testoutlet.Id];
            acr.D1_User_Role__c = 'Primary';
            acr.D1_Active__c=true;
            update acr;
            
          	D1_Setting__c d1SettigMethod = D1_UserRegistrationValidator.getD1Setting('GB', 'en_GB');
          	system.assert(d1SettigMethod!=null,'method getD1Setting failed');
            
			D1_UserRegistrationDetailWrapper userWrapper = new D1_UserRegistrationDetailWrapper();
            userWrapper.accountId = testoutlet.id;
            userWrapper.outletName= 'outletAccount';
            userWrapper.street= 'test123';
            userWrapper.city= 'london';
            userWrapper.postalCode= '456754';
            userWrapper.email = 'email1@gmail.com';
            userWrapper.firstName = 'John';
            userWrapper.lastName = 'Da';
            userWrapper.mobile = '7895448';            
            userWrapper.languageLocaleKey= 'en_GB';
            userWrapper.userCountryCode = 'GB';
            userWrapper.subscriptionSource = 'Frontend';
            userWrapper.contactId = primcon1.id;
            userWrapper.userTypeId = d1UserType.id;
            userWrapper.d1SettingId = d1setting.id;
			userWrapper.subscriptionValue = 'Email';
            userWrapper.accountNumber = '98798798';           
             
            Test.startTest();
            D1_UserRegistrationValidator.UserValidationResultWrapper validateUserReturn = D1_UserRegistrationValidator.validateUser(userWrapper);

            D1_UserRegistrationValidator.getD1UserType(String.valueOf(d1setting.Id),'Direct Buyer','On Trade');
			            
            Id profile = D1_UserRegistrationValidator.getProfileId('DiageoOne External User');
            
            
            D1_UserRegistrationValidator.createUser(userWrapper,primcon1.id);

            D1_UserRegistrationValidator.updateRegistrationFields(userWrapper,'AppInvited');
            
            D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapperReturn = D1_UserRegistrationValidator.createCase(userWrapper);

            //D1_Setting__c d1SettingReturn = D1_UserRegistrationValidator.getD1SettingsByCountry(null,null);
            //system.assert(d1SettingReturn==null, 'd1 setting not null');

            D1_Setting__c d1SettingReturn1 = D1_UserRegistrationValidator.getD1SettingsByCountry('GB','en_GB');
			
            EmailTemplate temp = D1_UserRegistrationValidator.getEmailTemplate('D1_ReInvite_Email_to_Customers_Registration');
            Test.stopTest();

            system.assert(validateUserReturn!=null, 'Failed to validate the userWrapper');

            system.assert(profile!=null,'getProfileId failed');

            Account accUpdate = [SELECT id,D1_Registration_Status__c FROM Account];
            system.assertEquals(accUpdate.id,userWrapper.accountId, 'account id not equal');

            system.assert(userResultWrapperReturn!=null, 'user result not found');
            system.assertEquals(d1SettingReturn1.Id,d1setting.id, 'd1 setting id does not match');
            system.assert(temp!=null, 'No Email template returned');
        }
    }
    
    /**
     * @description testValidateUser2
     */    
    @isTest
    public static void testValidateUser2(){
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];        
        
        System.runAs(thisUser){            
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser; 
            system.assert(testAdminUser!=null, 'admin user not found');  
        }    
        
        System.runAs(testAdminUser){
        
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        //Geography__c country = new Geography__c(Id= countryId);
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
        insert pickupOption; 
        
        Account testoutlet=D1_TestDataUtility.getDirectCustomer();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        testoutlet.D1_Registration_Status__c = 'AppSubscribed';
        testoutlet.BillingStreet = 'test'; 
        testoutlet.BillingCity='test';
        testoutlet.BillingPostalCode='234565';
        insert testoutlet;
        
        Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id,'Primary');
        primcon1.Email = 'test.test1403@gmail.com';
        insert primcon1;
        
        D1_UserRegistrationDetailWrapper userWrapper = new D1_UserRegistrationDetailWrapper();
            userWrapper.accountId = testoutlet.id;
            userWrapper.outletName= 'outletAccount';
            userWrapper.street= 'test123';
            userWrapper.city= 'london';
            userWrapper.postalCode= '456754';
            userWrapper.email = 'email1@gmail.com';
            userWrapper.firstName = 'John';
            userWrapper.lastName = 'Dath';
            userWrapper.mobile = '7895448';            
            userWrapper.languageLocaleKey= 'en_US';
            userWrapper.userCountryCode = 'GB';
            userWrapper.subscriptionSource = 'FrontendApp';
            userWrapper.contactId = primcon1.id;
			userWrapper.subscriptionValue = 'Email';
            userWrapper.accountNumber = '98798798';
        
        D1_UserRegistrationDetailWrapper userWrap = new D1_UserRegistrationDetailWrapper();
            userWrap.accountId = testoutlet.id;
            userWrap.outletName= 'outletAccount';
            userWrap.street= 'test12345';
            userWrap.city= 'london';
            userWrap.postalCode= '456475';
            userWrap.email = 'email1testy@gmail.com';
            userWrap.firstName = 'John';
            userWrap.lastName = 'Da';
            userWrap.mobile = '7895448333';            
            userWrap.languageLocaleKey= 'en_US';
            userWrap.userCountryCode = 'GB';
            userWrap.subscriptionSource = 'Backend';            
			userWrap.subscriptionValue = 'Email';
            userWrap.accountNumber = '98798798';
        
        User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
        externalUser1.Username = 'email123ex1d@example3213.com';
        externalUser1.Email='email1@gmail.com';
        externalUser1.CommunityNickname = 'Mania.Test';
        externalUser1.Available_Countries__c = 'GB';
        externalUser1.ContactId = primcon1.id; 
        externalUser1.isActive = True;
        insert externalUser1;
    
        AccountContactRelation acr = [SELECT ID,Contact_Type__c,Account.Name, 
                                      Account.BillingStreet,Account.BillingCity,Account.BillingState,
                                      Account.BillingPostalCode,Account.BillingCountry,D1_User_Role__c
                                      FROM AccountContactRelation WHERE ContactID =:primcon1.Id 
                                      AND AccountId =: testoutlet.Id];
        acr.D1_User_Role__c = 'Primary';
        acr.D1_Active__c = True;
        update acr;

        Test.startTest();
        D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapper = D1_TestDataUtility.getUserResultWrapper();
        D1_UserRegistrationValidator.ContactWrapper conWrap = D1_TestDataUtility.getContactWrapper(primcon1.id);
        
        D1_UserRegistrationValidator.UserValidationResultWrapper validateUserReturn1 = D1_UserRegistrationValidator.validateUser(userWrapper);
        D1_UserRegistrationValidator.UserValidationResultWrapper validateUserReturn2 = D1_UserRegistrationValidator.validateUser(userWrap);
        D1_UserRegistrationValidator.updateACRReInvite(userWrap,externalUser1);
        userWrapper.email = 'test.test1403@gmail.com';
        D1_UserRegistrationValidator.createUser(userWrapper,primcon1.id);
        List<Contact> contactList = new List<Contact>();
        contactList = D1_UserRegistrationValidator.getContact(primcon1.Email,testoutlet.Id);
        D1_UserRegistrationValidator.updateAccountContact(acr,'Primary',userWrapper);
        D1_UserRegistrationValidator.sendEmailToUser(userWrap,externalUser1, conWrap);
        D1_UserRegistrationValidator.sendEmailToUser(userWrap,null, conWrap);   
        D1_UserRegistrationValidator.createUser(userWrap,primcon1.id);
        Test.stopTest(); 
        system.assert(validateUserReturn1!=null, 'Failed to validate the userWrapper');
        system.assert(validateUserReturn2!=null, 'Failed to validate the userWrapper');
        System.assert(contactList != NULL, 'contact not present');
        system.assert(userResultWrapper!=null,'Getting User result wrapper data failed');
    }
    }
    
    /**
     * @description testValidateUser3
     */
    @isTest
    public static void testValidateUser3(){
        
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        Geography__c country ;
        
        System.runAs(thisUser){            
            UserRole ur = [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            insert testAdminUser; 
            system.assert(testAdminUser!=null, 'admin user not found');  
        }    
        
        System.runAs(testAdminUser){
            Id countryId = D1_TestDataUtility.setupCountry('GB');
        	country = new Geography__c(Id= countryId);
        
        	Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
        	insert pickupOption;
            
            Account testoutlet=D1_TestDataUtility.getDirectCustomer();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert testoutlet;
            
            Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id,'Primary');
            primcon1.Email = 'email1@gmail.com';
        	insert primcon1; 
            
            List<Contact> conList=[select id from Contact where accountId=:testoutlet.Id ];
            system.assert(conList.size() > 0, 'contact list empty');
            
            User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            externalUser1.Username = 'email1@gmail.com';
            externalUser1.Email='email12@gmail.com';
            externalUser1.Available_Countries__c = 'GB';
            externalUser1.ContactId = primcon1.id; 
            externalUser1.isActive = True;
            insert externalUser1;
            
            D1_UserRegistrationDetailWrapper userWrapper = new D1_UserRegistrationDetailWrapper();
            userWrapper.accountId = testoutlet.id;
            userWrapper.subscriptionSource = 'FrontEnd';
            userWrapper.email = 'email1@gmail.com';
            userWrapper.firstName = 'John';
            userWrapper.lastName = 'Dario';
            userWrapper.mobile = '7895448';
            userWrapper.contactId = primcon1.id;
            
            Test.startTest();
            D1_UserRegistrationValidator.UserValidationResultWrapper validateUserReturn2 = D1_UserRegistrationValidator.validateUser(userWrapper);
            D1_UserRegistrationValidator.updateUser(new List<Id>{externalUser1.Id});
            Test.stopTest(); 
            system.assert(validateUserReturn2!=null, 'Failed to validate the userWrapper');
            system.assertEquals(validateUserReturn2.isNoPrimaryContact,null, 'primary contact not found');
        } 
    }
}