/*

*   @Name: EDGE_ContactShareService

*   @Purpose: Apex Test Class for EDGE_ContactShareService

*   @History

*   VERSION   AUTHOR            DATE              DETAIL
    1.0       Sandip Ghosh      05/11/2020        ES20-7921
    2.0       Prasanth T        23/09/2022        ES20-13324(Test Class Correction Due to Failure)
*/
@isTest
public class EDGE_ContactShareServiceTest {

    @isTest
    public static void testPostContactShareService(){
                
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        system.assert(countryId != Null,'countryId should not be null');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        Database.insert(pickupOption);
        System.assert(pickupOption.Id != Null,'pickupOption should not be null');
        
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        Database.insert(testoutlet);
        Test.startTest();
        system.assert(testoutlet.id != null,'testoutlet should not be null');
        
        List<Contact> contacts = new List<Contact>();
        
        Contact primcon1 = new Contact(FirstName='fname1',
                                    LastName = 'lname1',
                                    Email = 'con11@se.com',
                                    Phone = '1234567890',Contact_Type__c='Primary',AccountID=testoutlet.Id);
        
        Contact primcon2 = new Contact(FirstName='fname2',
                                    LastName = 'lname2',
                                    Email = 'con22@se.com',
                                    Phone = '1234567891',Contact_Type__c='Primary',AccountID=testoutlet.Id);
        
        contacts.add(primcon1);
        contacts.add(primcon2);
        
        Database.insert(contacts);
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep;
               
        
        String reqBody = '['+
                            '{'+
                                '"ContactId" : "'+primcon1.Id+'",'+
                                '"UserOrGroupId" : "'+salesRep.Id+'"'+
                            '},'+
                            '{'+
                                '"ContactId" : "'+primcon2.Id+'",'+
                                '"UserOrGroupId" : "'+salesRep.Id+'"'+
                            '}'+
                        ']';
        
        
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';//HTTP Request Type
    	req.requestBody = Blob.valueof(reqBody);
    	RestContext.request = req;
        EDGE_ContactShareService.doPost();
        
        EDGE_ContactShareServiceWrapper conWrapper = new EDGE_ContactShareServiceWrapper();
        conWrapper.errorMessage = '';
		Test.stopTest();
		        
    }
}