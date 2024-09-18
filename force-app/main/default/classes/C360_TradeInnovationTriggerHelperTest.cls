/**
 
* @description : C360_TradeInnovationTriggerHelperTest

* @purpose : 

* @history

* Version   Developer        Date            User Story	          Purpose

*  VERSION     AUTHOR               DATE            DETAIL
	1.0         Nidhi    16/10/2023     Test Class for C360_TradeTermBandDetailTriggerHelper

*/
@isTest
public class C360_TradeInnovationTriggerHelperTest{
    
    @isTest
    public static void testTradeTermConfiguration(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        Test.startTest();
        Trade_Term_Band_Detail__c tradeConfig = new Trade_Term_Band_Detail__c();
        tradeConfig.Name = 'Test Trade Configuration';
        tradeConfig.Product_Sub_Category__c = 'Ale';
        tradeConfig.Band_Number__c = 1;
        tradeConfig.Country__c = geographyId;
        tradeConfig.Calcuation_Logic__c = 'Progressive';
        tradeConfig.Unit_Min__c = 0;
        tradeConfig.Unit_Max__c = 50;
        tradeConfig.Rebate__c = 0;
        insert tradeConfig;  
        system.assert(tradeConfig.Id != null,'Trade Term Id should not be null');
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
        Trade_Term_Band_Detail__c tradeConfig = new Trade_Term_Band_Detail__c();
        tradeConfig.Name = 'Test Trade Configuration';
        tradeConfig.Product_Sub_Category__c = 'Ale';
        tradeConfig.Band_Number__c = 1;
        tradeConfig.Country__c = countryId;
        tradeConfig.Calcuation_Logic__c = 'Progressive';
        tradeConfig.Unit_Min__c = 0;
        tradeConfig.Unit_Max__c = 50;
        tradeConfig.Rebate__c = 0;
        tradeConfig.CurrencyIsoCode = 'AUD';
        insert tradeConfig; 
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        tradeConfig.Country__c = secCountry.Id;
               
        update tradeConfig;
		system.assert(tradeConfig.Id != null,'Trade term config id should not be null');  
        delete tradeConfig;
        Test.stopTest();
    }
}