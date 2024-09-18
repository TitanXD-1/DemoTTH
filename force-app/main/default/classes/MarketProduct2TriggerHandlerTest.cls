/**********************************************************************
Name: MarketProduct2TriggerHandlerTest
======================================================
Purpose: MarketProduct2TriggerHandler test
======================================================
History
-------
VERSION     AUTHOR         DATE             DETAIL
1.0         Ajay           20/05/21         Initial Development
***********************************************************************/
@isTest
public class MarketProduct2TriggerHandlerTest {
	@isTest
    public static void testMarketProduct2CRUD(){
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        Id countryIdES = EDGE_UtilityTestClass.setupCountry('ES');
        Id countryIdGB = createCountry(countryIdES,'GB');
        Product__c product = new Product__c(Name = 'Asset');
        
        Market_Product2__c marketProduct = new Market_Product2__c();
        
        marketProduct.Market__c = countryIdES;
        marketProduct.Product__c = product.id;
        
        Test.startTest();
        //Insert
        insert marketProduct;
        
        //Update
        marketProduct.Market__c = countryIdGB;
        update marketProduct;
        
        Test.stopTest();
        
        Market_Product2__c mProd = [SELECT Id, Market__c, Product__c From Market_Product2__c where Product__c =: product.id];
        
        System.assertEquals(marketProduct.Id, mProd.Id, 'Insert Failed');
        System.assert(marketProduct.Market__c == countryIdGB, 'Update operation failed');
        
        //Delete
        delete marketProduct;
        
        //Un delete
        undelete marketProduct;
        
        
    }
   
    public static Id createCountry(Id geographyId, String countryCode){
        
        Geography__c georaphy = [select Parent_Geography__c from Geography__c where id=:geographyId];
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Australia2';
        country.Code__c = countryCode;
        country.Parent_Geography__c = georaphy.Parent_Geography__c;
        country.Extended_Country_Code__c = 'AU-AU'+ countryCode;
        insert country;
        
        return country.id;
        
        
    }
}