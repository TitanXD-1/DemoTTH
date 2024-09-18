/*
* Name: EDGE_DuplicateContactServiceTest
* Purpose: Req: This is the test class for EDGE_BespokeHistoryService,EDGE_BespokeHistoryController
* History                                                            

VERSION			AUTHOR					DATE				DETAIL
2.0     Prasanth T          23/09/2022      ES20-13324(Test Class Correction Due to Failure)
2.0		  Swagata Mondal     08/21/2023        144596
*/
@isTest
public class EDGE_DuplicateContactServiceTest {
	
    @isTest
    public static void testPostContactService(){
                
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        system.assert(countryId != Null);
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        Database.insert(pickupOption);
        System.assert(pickupOption.Id != Null);
        
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        Database.insert(testoutlet);
        Test.StartTest();
        system.assert(testoutlet.id != null);
        
        Contact primcon=new Contact(FirstName='fname',
                                    LastName = 'lname',
                                    Email = 'con2@se.com',
                                    Phone = '1234567890',Contact_Type__c='Primary',AccountID=testoutlet.Id); 
        Database.insert(primcon);
        String reqBody = '['+
                        '{'+
                        '"Email" : "con2@se.com",'+
                        '"FirstName" : "fname",'+
                        '"GUID__c" : "836F600E-ED2C-45F9-B837-B79C2F63848F",'+
                        '"Contact_Type__c" : "Primary",'+
                        '"LastName" : "lname",'+
                        '"Phone" : "1234567890",'+
                        '"PhonePrefix__c" : "+61",'+
                        '"Phone__c" : "77888990",'+
                        '"Salutation" : null,'+
                        '"Title" : null'+
                        '},'+
            			'{'+
                        '"Email" : "con2@secom",'+
                        '"FirstName" : "con1",'+
                        '"GUID__c" : "836F600E-ED2C-45F9-B837-B79C2F63848F",'+
                        '"Contact_Type__c" : "Primary",'+
                        '"LastName" : "rty",'+
                        '"Phone" : "+6177888991",'+
                        '"PhonePrefix__c" : "+61",'+
                        '"Phone__c" : "77888990",'+
                        '"Salutation" : null,'+
                        '"Title" : null'+
                        '}'+
                        ']';
        
        //Test.startTest();
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';//HTTP Request Type
    	req.requestBody = Blob.valueof(reqBody);
    	RestContext.request = req;
        EDGE_DuplicateContactService.doPost();
        Test.stopTest();
    }
}