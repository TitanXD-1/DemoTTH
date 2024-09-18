/**
 * @name D1_RegistrationController
 * @purpose D1_RegistrationController Class for registration page 
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0        Sudipta Nandi    08/29/20   Fetch registration Pages Configuration Details  
 * 2.0        Ajay             08/29/20   Fetch Mobile configuration (NCP-83)
 * 3.0        Ajay            11/11/20	   Google Captcha Validation Module(NCP-702)
 * 4.0        Rithika         12/07/21    Test Class Refactor(NCP-3800)
**/
@isTest
public with sharing class D1_RegistrationControllerTest {
    
    /**
     * @userStory NCP-83
	 * @description Test Get Mobile configuration 
	 */
    @isTest
    public static void testGetMobileConfig(){
        List<Geography__c> geographys = new List<Geography__c>();
        
        for(Phone_Format__mdt format: [SELECT Id,Country_Code__c,Country_Name__c,Prefix__c,Regular_Expression__c,Example__c
                                       FROM Phone_Format__mdt
                                       WHERE label='Mobile'
                                       ORDER BY Country_Name__c ASC
                                       LIMIT 2]){
                                           geographys.add(new Geography__c(Name= format.Country_Code__c, Code__c = format.Country_Code__c));
                                       }
        insert geographys;
        system.assert(geographys!=null, 'geography not found');
        List<object> returnList = D1_RegistrationController.getMobileConfig('Mobile');
        System.assert(returnList.size() > 0, 'No Mobile configuartion found');
        
    }
    /**
	 * @description testGetUserType method 
	 */
    @isTest
    public static void testGetUserType(){
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator'); 
        testAdminUser.Email = 'abc@diageo.com';
        insert testAdminUser;
        
        String common = 'Geog1_es';
        String recordTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        recordTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        String language = D1_Setting__c.Language__c.getDescribe().getPicklistValues()[0].getValue(); 
        
        Id countryId = D1_TestDataUtility.setupCountry('ES');
        Geography__c geog = new Geography__c(Id= countryId);
        upsert geog; 
       
        D1_Setting__c d1setting = D1_TestDataUtility.createD1Settings(geog);
        d1setting.Name = 'Spain';
        d1setting.Unique_ID__c = common;
        d1setting.Language__c = language;
        insert d1setting;
   
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1setting.Id);
        d1UserType.User_Type__c = D1_User_Type__c.User_Type__c.getDescribe().getPicklistValues()[0].getValue();
        upsert d1UserType;
       
        ContentVersion contentVersionInsert = D1_TestDataUtility.getContentVersion();
        insert contentVersionInsert;
        
        String outletRecTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        outletRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Account distAccount = D1_TestDataUtility.getD1Customer();
        upsert distAccount;
        
        D1_RegistrationController.AccountDetailsWrapper accountWraper = new D1_RegistrationController.AccountDetailsWrapper();
        accountWraper.id = 'abc';
        accountWraper.billingState = 'Tasmania';
       
        Test.startTest();
        List<Object> userTypeValues = D1_RegistrationController.getUserType('es','ES');
        system.assert(!userTypeValues.isEmpty(),'userTypeValues List should not be empty');
        
       	List<Object> accountValues = D1_RegistrationController.getAccountListBasedonUIN(geog.Id,'VAT_Number__c','1234',null);
        system.assert(!accountValues.isEmpty(),'accountValues List should not be empty');
        
        testValidateUIN(geog.Id);
        Test.stopTest();
    }

    /**
     * @userStory NCP-702
	 * @description testValidateUIN 
     * @param marketId 
     */    
    public static void testValidateUIN(Id marketId){
        Test.setMock(HttpCalloutMock.class, new CaptchaSuccessMock());
        List<Object> result = D1_RegistrationController.validateUIN(marketId,'VAT_Number__c','1234','1233456',null);
        System.assert(result!=NULL, 'Success validate UIN Failed');
        
        try{
            Test.setMock(HttpCalloutMock.class, new CaptchaFailMock());
        	result = D1_RegistrationController.validateUIN(marketId,'VAT_Number__c','1234','1233456',null);
        }catch(Exception ex){
            System.assert(ex!=null, 'Fail validate UIN Failed');
        }
    }
    
    class CaptchaSuccessMock implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
    class CaptchaFailMock implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":false}');
            res.setStatusCode(200);
            return res;
        }
    }
}