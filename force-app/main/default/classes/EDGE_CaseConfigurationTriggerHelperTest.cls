/**
 
* @description : EDGE_CaseConfigurationTriggerHelperTest

* @purpose : 

* @history

* Version   Developer        Date            User Story	          Purpose

*  VERSION     AUTHOR               DATE            DETAIL
	1.0         Sudipta Nandi     07/28/2021     Test Class for EDGE_CaseConfigurationTriggerHelper

*/
@isTest
public class EDGE_CaseConfigurationTriggerHelperTest{
    
    @isTest
    public static void testCaseConfiguration(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'pick up Option Id should not be null');
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert outlet;
        system.assert(outlet.Id != null,'outlet Id should not be null');
        
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        insert caseConfig;  
        
        
        update caseConfig;        
        
        system.assert(caseConfig.Id != null,'case Config Id should not be null');
    }

    /**
* @description checkSharingTest : To check the sharing of object
* @return void
* @param 
*/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.Country__c = countryId;
        insert caseConfig;  
       
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        caseConfig.Country__c = secCountry.Id;
               
        update caseConfig;        
        system.assert(caseConfig.Id != null,'case config id should not be null');  
        delete caseConfig;
        undelete caseConfig;
        Test.stopTest();
    }
}