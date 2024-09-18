/**********************************************************************
Name: OpportunityTriggerHandlerTest
=======================================================================
Purpose: Trigger Handler Class for OpportunityTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0      Sagar Barman           23/03/2019        Initial Development
***********************************************************************/
@isTest
public class OpportunityTriggerHandlerTest {
    
    @isTest
    public static void testOpportunity(){ 
      Boolean guidNotNull = false;
        EDGE_UtilityTestClass.createOrgSettings(); 
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
     
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        
      	Account accObj = EDGE_UtilityTestClass.getOutletRecord(); 
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
       	insert accObj; 
 
        Opportunity oppRec = EDGE_UtilityTestClass.getOpportunity(accObj.Id);
        oppRec.CloseDate = System.today().addDays(10);
        oppRec.StageName = 'Open';
        oppRec.Type = 'MAS'; 
        oppRec.AccountId = accObj.Id;
        insert oppRec;
        Opportunity oppRec1 = [SELECT Id,GUID__c FROM Opportunity WHERE ID =: oppRec.Id];
        // test if guid is getting populated
        if(oppRec1.GUID__c != null){
          guidNotNull = true;      
        }
        System.assert(guidNotNull, true);
        Test.startTest();
        //update the record
        update oppRec;
        //delete oppRec
        delete oppRec;
        //undelete oppRec;
        undelete oppRec;
        Test.stopTest();
    }
}