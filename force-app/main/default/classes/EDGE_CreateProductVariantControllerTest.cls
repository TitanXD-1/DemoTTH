/**********************************************************************
Name: EDGE_CreateProductVariantControllerTest
=======================================================================
Purpose: Test class for EDGE_CreateProductVariantController
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR                    DATE              DETAIL
1.0           Anuja Chattopadhyay      24/09/2019         ES20-2232
2.0           Prasanth T               23/09/2022         ES20-13324
***********************************************************************/
@isTest
public class EDGE_CreateProductVariantControllerTest {
    
    @isTest
    public static void productVarientTest(){
        
        
        Test.startTest(); 
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(geographyId);
        insert deliveryPartner;
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Product Type');
        pickupOption.Name = 'Uniform[AU]';
        pickupOption.Status__c = 'Active';
        pickupOption.RecordTypeId= Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Type').getRecordTypeId();
        insert pickupOption;
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        testProduct.Pricing_Type__c = 'By Quantity';
        testProduct.Product_Type__c =   pickupOption.Id;
        insert testProduct;
        
        Product_Variant__c productvar=new Product_Variant__c();
        productvar.RecordTypeId = Product_Variant__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Uniform').getRecordTypeId();   
        productvar.Product__c = testProduct.id;
        productvar.Size__c= 'menu';
        insert productvar;     
        RecordType pRecordType  = EDGE_CreateProductVariantController.getProductVariantRecordType(testProduct.Id);
        //RecordType pRecordType1  = EDGE_CreateProductVariantController.getProductVariantRecordType(testProduct1.Id);
        
        system.assert(pRecordType.Id !=null,'pRecordType should not be null');
        //system.assert(pRecordType1.Id !=null);
        
        Test.stopTest();
    }
    @isTest
    public static void productVarientTestPOSVisibility(){
        
        
        Test.startTest(); 
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(geographyId);
        insert deliveryPartner;
        
        
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Product Type');
        pickupOption1.Name = 'MENU[AU]';
        pickupOption1.Status__c = 'Active';
        pickupOption1.RecordTypeId= Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Type').getRecordTypeId();
        insert pickupOption1;
        
        Product__c testProduct1 = EDGE_UtilityTestClass.getProd();
        testProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct1.Supplier_Partner__c= deliveryPartner.Id;
        testProduct1.Pricing_Type__c = 'By Size';
        testProduct1.Product_Type__c =  pickupOption1.Id;
        insert testProduct1;
        
        Product_Variant__c productvar1=new Product_Variant__c();
        productvar1.RecordTypeId = Product_Variant__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Visibility Kit').getRecordTypeId();   
        productvar1.Product__c = testProduct1.id;
        productvar1.Size__c= 'menu';
        productvar1.Unit_Price__c=20.0;
        insert productvar1;
        
        
        RecordType pRecordType1  = EDGE_CreateProductVariantController.getProductVariantRecordType(testProduct1.Id);
        
        system.assert(pRecordType1.Id !=null,'pRecordType should not be null');
        //system.assert(pRecordType1.Id !=null);
        
        Test.stopTest();
    }
}