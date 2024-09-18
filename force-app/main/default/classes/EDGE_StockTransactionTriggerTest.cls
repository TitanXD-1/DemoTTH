/*
Name: EDGE_StockTransactionTriggerTest
Purpose: Trigger Helper Class for StockTransactionTrigger
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       16/06/2019        ES20-2232
1.1		  Shivam Chauhan	   18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
1.2       Joshraj Sen          08/04/2024       152305 Static Code Violation Fixed
*/

@isTest
public class EDGE_StockTransactionTriggerTest {
    
    /*
CheckAndGenerateSharing
*/
    @isTest
    public static void checkAndGenerateSharingTest(){
        //Creating Org Setting
        EDGE_UtilityTestClass.createOrgSettings();//To Activate  the trigger
        
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');        
        Market_Setting__c marSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marSetting.Warehouse_Level__c = true;
        marSetting.Threshold_Format__c = 'Percent';
        insert marSetting;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Product__c' and isActive=true];
        Map<String,String> productRecordTypes = new Map<String,String>{};
            for(RecordType rt: rtypes){
                productRecordTypes.put(rt.Name,rt.Id);
            }
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        testProduct.RecordTypeId = productRecordTypes.get('POS');
        insert testProduct;
        
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id areaRecTypeId= mapGeographyRecordTypes.get('Area').getRecordTypeId();
        Id countryRecTypeId= mapGeographyRecordTypes.get('Country').getRecordTypeId();
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId1 = geoMap.get('Country');
        Geography__c area = createGeography('Area');
        area.Name = 'Australia1';
        area.Code__c = 'AUT1';
        area.Parent_Geography__c = countryId1;
        area.RecordTypeId=areaRecTypeId;
        insert area;
        
        Geography__c country = new Geography__c();
        country.Name = 'Aus Olymp';
        country.Code__c = 'AO';
        country.Parent_Geography__c = geoMap.get('Cluster');
        country.RecordTypeId=countryRecTypeId;
        insert country;
        
        Geography__c area1 = createGeography('Area');
        area1.Name = 'Ausrlia';
        area1.Code__c = 'AUA';
        area1.Parent_Geography__c = country.Id;
        Test.startTest();
        insert area1;
                
        Stock_Transaction__c stockTransaction = new Stock_Transaction__c();
        stockTransaction.Country__c = countryId;
        stockTransaction.Product__c = testProduct.Id;
        stockTransaction.Area__c = area.Id;
        stockTransaction.PO_Number__c = 1212;
        stockTransaction.Quantity__c = 10;
        stockTransaction.SAP_IO_Code__c = '121';
        stockTransaction.Unique_Key__c = 'key';        
        
        insert stockTransaction;
        system.assert(stockTransaction.Id != null,'stockTransaction should not be null');
        stockTransaction.Country__c = country.id;
        stockTransaction.Area__c = area1.Id;
        update stockTransaction;
                       
        Stock_Transaction__c stockTransaction1 = new Stock_Transaction__c();
        stockTransaction1.Country__c = countryId;
        stockTransaction1.Product__c = testProduct.Id;
        //stockTransaction1.Area__c = area.Id;
        stockTransaction1.PO_Number__c = 1212;
        stockTransaction1.Quantity__c = 10;
        stockTransaction1.SAP_IO_Code__c = '121';
        stockTransaction1.Unique_Key__c = 'key';
        try{
            insert stockTransaction1;
        }catch(Exception e){
            System.debug(LoggingLevel.Debug,'excption::::'+e.getMessage());
        }
        Test.stopTest(); 
    }
    
    /*
Method  : checkSharingTest
Purpose : To check the sharing of object
*/
    /*
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Product__c' and isActive=true];
        Map<String,String> productRecordTypes = new Map<String,String>{};
            for(RecordType rt: rtypes){
                productRecordTypes.put(rt.Name,rt.Id);
            }
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.UPIID__c='12345';
        testProduct.RecordTypeId=productRecordTypes.get('POS');
        
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        testProduct.POS_Item_Short_Description__c='This is good item';
        insert testProduct;
        System.Debug(LoggingLevel.Debug '@@testProduct' +testProduct);
        Stock_Transaction__c stockTrans = new Stock_Transaction__c();
        stockTrans.Country__c = countryId;
        stockTrans.Product__c = testProduct.Id;
        stockTrans.Quantity__c = 10;
        stockTrans.Unique_Key__c ='2356';
        stockTrans.PO_Number__c=45;
        Test.startTest();
        insert stockTrans ;
        system.assert(stockTrans.Id != null);
        
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id countryRecTypeId = mapGeographyRecordTypes.get('Country').getRecordTypeId();
        Id clusterId = geoMap.get('Cluster');
        Geography__c country = createGeography('Country');
        country.Name = 'Australia1';
        country.Code__c = 'AUT1';
        country.Parent_Geography__c = clusterId;
        country.RecordTypeId=CountryRecTypeId;
        insert country;
        
        stockTrans.Country__c = geoMap.get('Country');
        stockTrans.Country__c = country.Id ;
        update stockTrans;        
        delete stockTrans ;
        undelete stockTrans ;
        Test.stopTest();
    }*/
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
}