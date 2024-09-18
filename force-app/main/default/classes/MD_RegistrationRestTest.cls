/**
 * @name MD_RegistrationRestTest
 * @description Test Class for MD_RegistrationRestTest
 * @history
 * VERSION     AUTHOR				DATE		DETAIL
 * 1.0		   Kapil Baliyan		23/04/2021	Original
**/
@isTest
public class MD_RegistrationRestTest {
    
    @testsetup
    public static void setup(){
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
            
            pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
            insert pickupOption;
            
            //d1settings = D1_TestDataUtility.createD1Settings(country,'GB setting','test GB','en_GB');
            d1settings = D1_TestDataUtility.createD1Settings(country);
            insert d1settings;
            
            d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1settings.Id);
            insert d1UserType;
        }
    }
    
    @isTest
    public static  void testDirectCustomerRegistration(){
        Pick_Up_Options__c pickupOption = [SELECT Id FROM Pick_Up_Options__c WHERE Type__c = 'Outlet Visit Prioritization' LIMIT 1];
        Account testoutlet = D1_TestDataUtility.getDirectCustomer();
        testoutlet.BillingStreet = 'test'; 
        testoutlet.BillingCity = 'test';
        testoutlet.BillingPostalCode = '234565';             
        insert testoutlet;
        
        Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id,'Primary');
        insert primcon1;
            
        MD_RegistrationREST.RegistrationInputs inputWrapper = new MD_RegistrationREST.RegistrationInputs();
        inputWrapper.countryCode = 'GB';
        inputWrapper.caseHandling = false;
        inputWrapper.allOrNone = false;
        inputWrapper.source = 'Diageo One';
        inputWrapper.subscriptionSource = 'FrontendApp';
        inputWrapper.userProfile = 'Primary';
        inputWrapper.languageLocaleKey='es';
        inputWrapper.subscriptionValue='Email';
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        inputWrapper.contactsMap = new Map<Id,Set<Id>>{con.Id => new Set<Id>{con.AccountId}};
        Assert.isNotNull(con,'Contact Data');
            
        Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/myDiageoRegistration/'; 
            req.requestBody = Blob.valueOf(JSON.serialize(inputWrapper));
            req.httpMethod = 'POST'; 
            RestContext.request = req;
            RestContext.response = res;
            MD_RegistrationREST.RegisterContacts();
        Test.stopTest();
    }
    
    @isTest
    public static  void testInDirectCustomerRegistration(){
        Pick_Up_Options__c pickupOption = [SELECT Id FROM Pick_Up_Options__c WHERE Type__c = 'Outlet Visit Prioritization' LIMIT 1];
        Account testoutlet = D1_TestDataUtility.getD1Customer();
        testoutlet.Direct_Customer__c = false;
        testoutlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;
        testoutlet.D1_Registration_Status__c = '';
        testoutlet.BillingStreet = 'test'; 
        testoutlet.BillingCity = 'test';
        testoutlet.BillingPostalCode = '234565';             
        insert testoutlet;
        
        Contact primcon1 = D1_TestDataUtility.getContact(testoutlet.Id,'Primary');
        insert primcon1;
            
        MD_RegistrationREST.RegistrationInputs inputWrapper = new MD_RegistrationREST.RegistrationInputs();
        inputWrapper.countryCode = 'GB';
        inputWrapper.caseHandling = false;
        inputWrapper.allOrNone = false;
        inputWrapper.source = 'Diageo One';
        inputWrapper.subscriptionSource = 'FrontendApp';
        inputWrapper.userProfile = 'Primary';
        inputWrapper.languageLocaleKey='es';
        inputWrapper.subscriptionValue='Email';
        Contact con = [SELECT Id, AccountId FROM Contact WHERE AccountId =:testoutlet.Id LIMIT 1];
        inputWrapper.contactsMap = new Map<Id,Set<Id>>{con.Id => new Set<Id>{con.AccountId}};
        Assert.isNotNull(con,'Contact Data');
            
        Test.startTest();
            RestRequest req = new RestRequest();
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/myDiageoRegistration/'; 
            req.requestBody = Blob.valueOf(JSON.serialize(inputWrapper));
            req.httpMethod = 'POST'; 
            RestContext.request = req;
            RestContext.response = res;
            MD_RegistrationREST.RegisterContacts();
        Test.stopTest();
    }
    
    @isTest
    public static  void test2(){  
        Geography__c country ;
        Pick_Up_Options__c pickupOption ;
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        country = new Geography__c(Id= countryId);
        country.isDiageoOneEnabled__c   = True;
        upsert country;  
        
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[ES]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        List<Account> accountList = new List<Account>();
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        accountList.add(testoutlet);
        insert accountList;
        
        List<Contact> contactList = new List<Contact>();
        Contact primcon1=new Contact(FirstName='fname1',
                                     LastName = 'lname',
                                     Email = 'email1@gmail.com',
                                     Phone = '12345672890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
        contactList.add(primcon1);
        system.assert(contactList.size() > 0, 'no contacts found');
        insert contactList;
        
        MD_RegistrationREST.RegistrationInputs inputWrapper = new MD_RegistrationREST.RegistrationInputs();
        inputWrapper.countryCode = 'ES';
        inputWrapper.caseHandling = false;
        inputWrapper.allOrNone = false;
        inputWrapper.source = 'MyDiageo';
        inputWrapper.subscriptionSource = 'Frontend';
        inputWrapper.userProfile = 'Secondary';
        inputWrapper.permissionList = null;
        inputWrapper.languageLocaleKey='es';
        inputWrapper.subscriptionValue='Email';
        MD_RegistrationREST.RegistrationPermissionInputs objs = new MD_RegistrationREST.RegistrationPermissionInputs();
        objs.permissionName = null;
        objs.accessLevel = null;
        Contact con = [SELECT Id, AccountId,email FROM Contact where id=:primcon1.id LIMIT 1 ];
        inputWrapper.contactsMap = new Map<Id,Set<Id>>{con.Id => new Set<Id>{con.AccountId}};
            
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/myDiageoRegistration/'; 
        req.requestBody = Blob.valueOf(JSON.serialize(inputWrapper));
        req.httpMethod = 'POST'; 
        RestContext.request = req;
        RestContext.response = res;
        MD_RegistrationREST.RegisterContacts();
        
        Contact con2 = [SELECT Id, FirstName,AccountId ,Account.Direct_Customer__c,LastName,MobilePrefix__c,Mobile__c,Email
                        FROM Contact where id=: primcon1.id  LIMIT 1];
        
        Map<Id,Map<Id,String>> responseMap = new Map<Id,Map<Id,String>>();
        responseMap.put(con2.Id, new Map<Id,String>{con2.AccountId => 'Success'});        
        MD_RegistrationREST.resolveStatusCode(responseMap);
        Test.stopTest();
    }
}