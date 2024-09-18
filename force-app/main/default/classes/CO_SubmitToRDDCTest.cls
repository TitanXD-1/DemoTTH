/*
@Name : CO_SubmitToRDDCTest
@Purpose : This is the test class for CO_SubmitToRDDC && CO_SendToSAPRequest
@History                                                            
@VERSION    AUTHOR                   DATE              DETAIL
*  1.0      Abhishek Shudhalwar      12-01-2022        Initial Development
*  2.0		Jayashree R				 24-01-2023		   CONS-355
*/
@isTest
public class CO_SubmitToRDDCTest {
    @testSetup static void setup() {
        //EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Sales_Organisation__c sOrg = CO_TestDataUtility.createSalesOrg(countryId);
        insert sOrg;
        
        List<Pick_Up_Options__c> listOfOptions = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c channelOption = CO_TestDataUtility.createPickUpOption('Channel', countryId, sOrg.Id);
        listOfOptions.add(channelOption);
        
        Pick_Up_Options__c salesOfficeOption = CO_TestDataUtility.createPickUpOption('Sales office', countryId, sOrg.Id);
        listOfOptions.add(salesOfficeOption);
       
        Pick_Up_Options__c deliveringPlantOption = CO_TestDataUtility.createPickUpOption('Delivering Plant', countryId, sOrg.Id);
        listOfOptions.add(deliveringPlantOption);
      
        upsert listOfOptions;
    
        Customer_Request__c cr = CO_TestDataUtility.createCustomerRequest(sOrg.Id, listOfOptions);
        
        User usr = CO_TestDataUtility.runAsUser('System Administrator');
        usr.Assigned_Markets__c = 'Europe and Turkey';
        insert usr ;
        
        System.runAs(usr){
            insert cr;
        }
    }
    
    @isTest
    public static void customerRequestSubmitToRDDCTest(){
        Customer_Request__c cr = [Select Id FROM Customer_Request__c WHERE CO_Customer_Name__c='Test Customer'][0];
        Test.startTest();

        SubmitToRDDCHttpCalloutMockImpl(200, 'RDDCSuccessResponse');
        
        List<CO_SubmitToRDDC.Results> output = new List<CO_SubmitToRDDC.Results>();
        List<Id> listOfIds = new List<Id>();
        listOfIds.add(cr.Id);
        output = CO_SubmitToRDDC.sendDataToRDDC(listOfIds);
        Test.stopTest(); 
        Boolean isValid = output[0].isValid;
        system.assertEquals(True, isValid, 'sendDataToRDDC Succeeded');
        
    }
    
  @isTest
    public static void customerRequestSubmitToRDDCFailureTest1(){
        Customer_Request__c cr = [Select Id FROM Customer_Request__c WHERE CO_Customer_Name__c='Test Customer'][0];
        Test.startTest();

        SubmitToRDDCHttpCalloutMockImpl(500, 'RDDCFailureResponse');
        
        List<CO_SubmitToRDDC.Results> output = new List<CO_SubmitToRDDC.Results>();
        List<Id> listOfIds = new List<Id>();
        listOfIds.add(cr.Id);
        output = CO_SubmitToRDDC.sendDataToRDDC(listOfIds);
        Test.stopTest(); 
        
        Boolean isValid = output[0].isValid;
        system.assertEquals(False, isValid, 'sendDataToRDDC Failed');
    }
    
    @isTest
    public static void customerRequestSubmitToRDDCFailureTest2(){
        Customer_Request__c cr = [Select Id FROM Customer_Request__c WHERE CO_Customer_Name__c='Test Customer'][0];
        Test.startTest();
		 
        SubmitToRDDCHttpCalloutMockImpl(200, 'RDDCDataError');
       
        List<CO_SubmitToRDDC.Results> output = new List<CO_SubmitToRDDC.Results>();
        List<Id> listOfIds = new List<Id>();
        listOfIds.add(cr.Id);
        output = CO_SubmitToRDDC.sendDataToRDDC(listOfIds);
        
		Test.stopTest(); 
        
        Boolean isValid = output[0].isValid;
        system.assertEquals(false, isValid, 'sendDataToRDDC Failed');
    }
    
     public static void submitToRDDCHttpCalloutMockImpl(Integer statusCode, String response) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(response);
        mock.setStatusCode(StatusCode);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
     }
}