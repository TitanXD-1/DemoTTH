/**************************************************************************************
Apex Class Name  :  Test_MD_RegistrationREST 
Version          :  1.0
Created Date     :  02/09/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock           02/09/2019             Original Version
**************************************************************************************/ 
@isTest(seeAllData=false)
global class Test_MD_RegistrationREST{

    @testSetup public static void setup(){
        TestFactory_MD_Account.setup(true);
    }    
    
    static testMethod void registerContacts() { 

        MD_RegistrationREST.RegistrationInputs inputWrapper = new MD_RegistrationREST.RegistrationInputs();
        inputWrapper.countryCode = 'ES';
        inputWrapper.caseHandling = false;
        inputWrapper.allOrNone = false;
        inputWrapper.source = 'MyDiageo';
        inputWrapper.subscriptionSource = 'Backend';
        inputWrapper.userProfile = 'Secondary';
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
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
        
    }

    static testMethod void resolveStatusCode() { 
		Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Map<Id,Map<Id,String>> responseMap = new Map<Id,Map<Id,String>>();
        responseMap.put(con.Id, new Map<Id,String>{con.AccountId => 'Success'});        
        MD_RegistrationREST.resolveStatusCode(responseMap);
        
    }
    
}