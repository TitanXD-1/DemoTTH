/**
 
* @description : C360_InnovationExclusionTriggerTest

* @purpose : 

* @history

* Version   Developer        Date            User Story	          Purpose

*  VERSION     AUTHOR               DATE            DETAIL
	1.0         Nidhi    16/10/2023     Test Class for C360_InnovationExclusionTriggerHelper

*/
@isTest
public class C360_InnovationExclusionTriggerTest{
    
    @isTest
    public static void testTradeTermConfiguration(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        Test.startTest();
        Innovation_Exclusion_Brand__c innoConfig = new Innovation_Exclusion_Brand__c();
        innoConfig.Brand_Name__c = 'Brand 1';
        innoConfig.Product_Sub_Category__c = 'Ale';
        innoConfig.Country__c = geographyId;
        insert innoConfig; 
 
        system.assert(innoConfig.Id != null,'Innovation and Exclusion id should not be null');
        Test.stopTest();
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
        Innovation_Exclusion_Brand__c innoConfig = new Innovation_Exclusion_Brand__c();
        innoConfig.Brand_Name__c = 'Brand 1';
        innoConfig.Product_Sub_Category__c = 'Ale';
        innoConfig.Country__c = countryId;
        insert innoConfig; 

        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        innoConfig.Country__c = secCountry.Id;
               
        update innoConfig;
		system.assert(innoConfig.Id != null,'Innovation and Exclusion id should not be null');  
        delete innoConfig;
        Test.stopTest();
    }
}