/**********************************************************************
Name: EDGE_ProductTriggerHelperTest
=======================================================================
Purpose: Trigger Helper Class for ProductTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-2624
1.1       Sagar Barman         16/10/2019        ES20-4312 (Start Date and Expiry Date included in Product__c)
1.2       Swaraj Samanta       05/09/2022        ES20-13284 (Test Class Correction Due to Failure)
***********************************************************************/
@isTest
public class EDGE_ProductTriggerHelperTest {
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        //System.debug('Condition 1 '+Limits.getQueries());
        String supplierRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliverPartner = new Delivery_Partner__c();
        deliverPartner.Name ='testPartner';
        deliverPartner.DP_Id__c = '12sdefr';
        deliverPartner.Email__c = 'abc@xyz.com';
        deliverPartner.Vendor_Number__c = 1234;
        deliverPartner.Country__c = countryId;
        deliverPartner.Street__c = 'Burns bay';
        deliverPartner.City__c = 'Sydney';
        deliverPartner.Postal_Code__c = '6003';
        deliverPartner.RecordTypeId=supplierRecordTypeId;
        insert deliverPartner;
         //System.debug('Condition 2 '+Limits.getQueries());
         //Creating Business Role Record
        String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name = 'Test Product';
        product.Supplier_Partner__c = deliverPartner.Id;
        product.Product_Code__c = 'Test1123';
        product.Diageo_Cost__c = 12;
        product.A_P_Cost__c = 14;
        product.POS_Related_Brand__c ='test';
        product.Units_per_POS__c =12;
        product.Limit_Per_Order__c = 12;
        product.Outlet_Cost__c = 12;
        product.POS_Related_Item__c = 'test';
        product.SAP_IO_Number__c = 'test'; 
        product.Pricing_Type__c = 'By Unit';
        product.Country__c = countryId;
        product.RecordTypeId = posRecordTypeId;
        product.POS_Item_Short_Description__c = 'test';
        product.Start_Date__c =  Date.today();
        //product.Expiry_Date__c =  Date.today();
        insert product;
         //System.debug('Condition 3 '+Limits.getQueries());
      
        Product_variant__c prodvar=new Product_variant__c();
        prodvar.Product__c=product.id;
        prodvar.Unit_Price__c=40;
        insert prodvar ;
         //System.debug('Condition 4 '+Limits.getQueries());
        Product_Pricing__c prodprice=new Product_Pricing__c ();
        prodprice.Product__c=product.Id;
        prodprice.Range_Price__c=50;
       insert prodprice;
         //System.debug('Condition 5 '+Limits.getQueries());
        system.assert(product.Id != null);
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = geoMap.get('Cluster');
        insert secCountry;        
         //System.debug('Condition 6 '+Limits.getQueries());
        Test.startTest();
        product.Country__c =  secCountry.Id;
        product.Pricing_Type__c = 'By Size';
        update product;  
        
         //System.debug('Condition 7 '+Limits.getQueries());
        product.Pricing_Type__c = 'By Quantity';
        update product;
         //System.debug('Condition 8 '+Limits.getQueries());
        product.Pricing_Type__c = 'By Unit';
        update product;
         ///System.debug('Condition 9 '+Limits.getQueries());
        delete product;
         //System.debug('Condition 10 '+Limits.getQueries());
        undelete product;
         //System.debug('Condition 11 '+Limits.getQueries());
        Test.stopTest();
    }
    

}