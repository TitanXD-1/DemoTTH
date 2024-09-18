@istest
public class EDGE_ProductvariantTriggerHelperTest {
    @istest
    public static void testactiveproduct(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Test.startTest();        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        //testProduct.IsActive__c = True;
        testProduct.Start_Date__c = Date.today();
        testProduct.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
        testProduct.Pricing_Type__c = 'By Size';
        insert testProduct;
        
        Product_Variant__c productvar=new Product_Variant__c();
        productvar.Product__c = testProduct.id;
        productvar.Size__c= 'menu';
        productvar.Unit_Price__c = 40;
        insert productvar;
        update productvar;
        delete productvar;
        undelete productvar ;
        
        
        system.assert(testProduct.IsActive__c !=true);
        Test.stopTest();
        
        
  
    }

}