/**
  * @name ContactPointAddressHandlerTest
  * @purpose This is the test class for ContactPointAddressHandler
  * @history                                                                                                                       
  * @VERSION  	AUTHOR                          DATE              DETAIL
  * 1.0       Indranil Roychowdhury         23/06/2022            Original Version
  **/

@isTest
public class ContactPointAddressHandlerTest {
    @isTest
    public static void testContactPointAddressInsert(){
        Test.startTest();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        insert new Org_Setting__c(Run_Flows__c=true, Run_Triggers__c=true, Run_Process_Builders__c=true, 
                                  Run_Validation_Rules__c=true, Run_Workflows_Rules__c=true);
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.SAP_Ship_to__c = '2345';
        testoutlet.SAP_Sold_to__c = '3248';
        insert testoutlet;
        
        ContactPointAddress a1 = new ContactPointAddress();
        a1.Name='Test name';
        a1.Source__c='Diageo One';
        a1.ParentId = testoutlet.id;
        insert a1;

        system.Assert(a1.Id != NULL, 'CPA INSERT FAILED');
        Assert.isTrue(a1.Id != NULL, 'CPA INSERT FAILED');
        
        ContactPointAddress a2 = new ContactPointAddress();
        a2.Name='Test name1';
        a2.Source__c='Diageo One'; 
        a2.Id= a1.id;
        update a2;
        
        Delete a2;
        Test.stopTest();
    }
}