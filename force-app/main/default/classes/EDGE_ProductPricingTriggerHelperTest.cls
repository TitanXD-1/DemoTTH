/*
Name: EDGE_ProductPricingTriggerHelperTest
Req: 
This is the Test Class for EDGE_ProductPricingTriggerHelper  
History                                                            
VERSION   AUTHOR            DATE           DETAIL
1.0     Manikant Pr     26/08/2019     Test class for EDGE_ProductPricingTriggerHelper
1.1     Sagar Barman    16/10/2019     Start Date and Expiry Date included in Product__c
1.2		Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/

@isTest
public class EDGE_ProductPricingTriggerHelperTest {
    
    @isTest
    public static void testValidateProductRange(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Test.startTest();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        testProduct.Start_Date__c = Date.today();
        testProduct.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
        
        insert testProduct;
        
        Product_Pricing__c prodPricRec = new Product_pricing__c();
        prodPricRec.Product__c = testProduct.id;
        prodPricRec.Range_Start__c = 15;
        prodPricRec.Range_End__c = 40;
        prodPricRec.Range_Price__c = 100;
        insert prodPricRec;
        
        Product_Pricing__c prodPricRec1 = new Product_pricing__c();
        prodPricRec1.Product__c = testProduct.id;
        prodPricRec1.Range_Start__c = 41;
        
         prodPricRec1.Range_Price__c = 80;
        insert prodPricRec1;
        prodPricRec1.Range_End__c = 100;
        
        update prodPricRec1;
        delete prodPricRec1;
        undelete prodPricRec1;
        
        System.assert(prodPricRec1.id != null,'prodPricRec1 should not be null');
        
        Product_Pricing__c prodPricRec2 = new Product_pricing__c();
        prodPricRec2.Product__c = testProduct.id;
        prodPricRec2.Range_Start__c = 80;
        prodPricRec2.Range_End__c = 120;
        prodPricRec2.Range_Price__c = 40;
        
        try{
            insert prodPricRec2;
        }
        catch (Exception ex){
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
        }
        Test.stopTest();
        
        
    }
    
}