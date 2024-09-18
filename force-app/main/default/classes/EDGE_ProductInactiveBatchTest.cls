/**********************************************************************
Name: EDGE_ProductInactiveBatchTest
=======================================================================
Req: This is the test class for EDGE_ProductInactiveBatch
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0          Sagar Barman    17/10/2019      Initial Development
***********************************************************************/
@isTest
public class EDGE_ProductInactiveBatchTest {

 		@isTest
    public static void testProductInactiveBatch(){
         Test.startTest(); 
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_ProductInactiveBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
    public static void createData(){  
    	Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
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
        
        //for 'By Unit'
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
        product.Start_Date__c = System.today();
        product.Expiry_Date__c =  product.Start_Date__c.addDays(5);
        insert product;
        
        system.assert(product.Id != null);
        
        //for 'By Size'
        Product__c productS = EDGE_UtilityTestClass.getProd();
        productS.Name = 'Test Product_Size';
        productS.Supplier_Partner__c = deliverPartner.Id;
        productS.Product_Code__c = 'Test112';
        productS.Diageo_Cost__c = 12;
        productS.A_P_Cost__c = 14;
        productS.POS_Related_Brand__c ='test';
        productS.Units_per_POS__c =12;
        productS.Limit_Per_Order__c = 12;
        productS.Outlet_Cost__c = 12;
        productS.POS_Related_Item__c = 'test';
        productS.SAP_IO_Number__c = 'test'; 
        productS.Pricing_Type__c = 'By Size';
        productS.Country__c = countryId;
        productS.RecordTypeId = posRecordTypeId;
        productS.POS_Item_Short_Description__c = 'test';
        productS.Start_Date__c =  System.today();
        productS.Expiry_Date__c =  productS.Start_Date__c.addDays(5);
        productS.UPIID__c = '54321';
        insert productS;
        
        system.assert(productS.Id != null);
        
        //for 'By Quantity'
        Product__c productq = EDGE_UtilityTestClass.getProd();
        productq.Name = 'Test Product_Quantity';
        productq.Supplier_Partner__c = deliverPartner.Id;
        productq.Product_Code__c = 'Test11';
        productq.Diageo_Cost__c = 12;
        productq.A_P_Cost__c = 14;
        productq.POS_Related_Brand__c ='test';
        productq.Units_per_POS__c =12;
        productq.Limit_Per_Order__c = 12;
        productq.Outlet_Cost__c = 12;
        productq.POS_Related_Item__c = 'test';
        productq.SAP_IO_Number__c = 'test'; 
        productq.Pricing_Type__c = 'By Quantity';
        productq.Country__c = countryId;
        productq.RecordTypeId = posRecordTypeId;
        productq.POS_Item_Short_Description__c = 'test';
        productq.Start_Date__c =  System.today();
        productq.Expiry_Date__c =   productq.Start_Date__c.adddays(2);
        productq.UPIID__c = '45321';
        insert productq;
        /*Product_variant__c prodvar=new Product_variant__c();
        prodvar.Product__c=product.id;
        prodvar.Unit_Price__c=40;
        insert prodvar ;*/
        
        /*Product_Pricing__c prodprice=new Product_Pricing__c();
        prodprice.Product__c=product.Id;
        prodprice.Range_Price__c=50;
        insert prodprice;*/
        
        system.assert(productq.Id != null);
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = geoMap.get('Cluster');
        insert secCountry;        
        
        //product.Country__c =  secCountry.Id;
        Product_variant__c prodvar=new Product_variant__c();
        prodvar.Product__c=productS.id;
        prodvar.Unit_Price__c=40;
        insert prodvar ;
        productS.Pricing_Type__c = 'By Size';
        update productS; 
        
        Product_Pricing__c prodprice=new Product_Pricing__c();
        prodprice.Product__c=productq.Id;
        prodprice.Range_Price__c=50;
        insert prodprice;
        productq.Pricing_Type__c = 'By Quantity';
        update productq;
        
        product.IsActive__c = true;
        product.Expiry_Date__c = System.today();
        product.Pricing_Type__c = 'By Unit';
        update product;
        
    }
}