/**
 * @name : D1_IpServiceControllerTest
 * @description : Test Class for D1_IpServiceController
 * @history :
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           01/09/2022      Initial Development (NCP-437)
 */
@isTest
public with sharing class D1_IpServiceControllerTest {

    @testSetup
    static void dataSetup(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [SELECT Id, RecordTypeId, Flag_Content_Document_ID__c, Flag_Content_Version_Id__c FROM Geography__c WHERE Id =:countryId];
       
        D1_Setting__c diageoOneSett = D1_TestDataUtility.createD1Settings(country);
        insert diageoOneSett;
    }
    
    @isTest static void getMyLocationTest(){
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetIpDataResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.StartTest(); 

			PageReference pageRef = Page.D1_IpServicePage; // Add your VF page Name here
			Test.setCurrentPage(pageRef);

			D1_IpServiceController ipServiceController = new D1_IpServiceController();
            ipServiceController.getMyLocation();
		Test.StopTest();

        System.assertNotEquals(null, ipServiceController.response, 'The callout returned a null response.');
    }
}