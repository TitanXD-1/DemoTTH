/**
Name: EDGE_StockTriggerTest

Purpose: Trigger Helper Class for StockTrigger
History                                                                                                                       
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       16/06/2019        ES20-2232
2.0			Prasanth T		 28/02/2022		   ES20-12144
3.0         Joshraj Sen      08/04/2024        152305
**/
@isTest
public class EDGE_StockTriggerTest {
    
    // final static String SalesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    /**
Method  : checkSharingTest
Purpose : To check the sharing of object
**/
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        
        
        Market_Setting__c mars = EDGE_UtilityTestClass.getMarketSetting(countryId);
        mars.Warehouse_Level__c = true;
        mars.Threshold_Format__c = 'Percent';
        insert mars;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        
        List<RecordType> rtypes = [Select Name, Id From RecordType 
                                   where sObjectType='Product__c' and isActive=true];
        Map<String,String> productRecordTypes = new Map<String,String>{};
            for(RecordType rt: rtypes){
                productRecordTypes.put(rt.Name,rt.Id);
            }
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId=productRecordTypes.get('POS');
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        insert testProduct;
        
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id areaRecTypeId= mapGeographyRecordTypes.get('Area').getRecordTypeId();
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        
        Id countryId1 = geoMap.get('Country');
        Geography__c area = createGeography('Area');
        area.Name = 'Australia1';
        area.Code__c = 'AUT1';
        area.Parent_Geography__c = countryId1;
        area.RecordTypeId=areaRecTypeId;
        insert area;
        //Creating Stock Record
        Stock__c stock = new Stock__c();
        stock.Country__c = countryId;
        stock.Product__c = testProduct.Id;
        stock.Area__c = area.Id;
        
        //stock.Unique_Key__c = 'unq123';
        Test.startTest();
        insert stock;
        system.assert(stock.Id != null,'Stock is Added');
        
        stock.Country__c = geoMap.get('Country');
        update stock;        
        delete stock;
        undelete stock;
        Test.stopTest();
    }
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
    
    @isTest
    public static void testStockMethod (){
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        List<RecordType> rtypes1 = [Select Name, Id From RecordType 
                                    where sObjectType='Stock__c' and isActive=true];
        Map<String,String> stockRecordTypes = new Map<String,String>{};
            for(RecordType rt1: rtypes1){
                stockRecordTypes.put(rt1.Name,rt1.Id);
            }
        
        //Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Market_Setting__c marSet = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marSet.Warehouse_Level__c = true;
        marSet.Threshold_Format__c = 'Percent';
        insert marSet;        
        Target_List__c tarList = EDGE_UtilityTestClass.getTargetList(countryId);
        insert tarList;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        insert testProduct;
        
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id areaRecTypeId= mapGeographyRecordTypes.get('Area').getRecordTypeId();
        Id countryId1 = geoMap.get('Country');
        Geography__c area = createGeography('Area');
        area.Name = 'Australia1';
        area.Code__c = 'AUT1';
        area.Parent_Geography__c = countryId1;
        area.RecordTypeId=areaRecTypeId;
        insert area;
        Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id defRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();        
        Test.startTest();
        list<Pick_Up_Options__c> picklist = new list<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUS]';
        pickupOption.Type__c = 'Local-Segment2';
        pickupOption.Status__c = 'Active';
        pickupOption.RecordTypeId = defRecTypeId;
        picklist.add(pickupOption);
        
        Pick_Up_Options__c pckObj1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        pckObj1.Name = 'Local [AUS]';
        pckObj1.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        picklist.add(pckObj1);
        
        insert picklist;
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHierRegion.Parent_BU__c = terriHierSA.Id;
        insert terriHierRegion;
        
        Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.Sales_Area__c = terriHierSA.Id;
        territory.Region__c = terriHierRegion.Id;
        //territory.RecordTypeId = SalesRecordTypeId;
        territory.Territory_Type__c = 'Sales';
        territory.Status__c = 'Active';
        insert territory; 
        List<Stock__c> stockList = new List<Stock__c>();
        
        Stock__c stock1 = new Stock__c();
        stock1.RecordTypeId = stockRecordTypes.get('Allocation');
        stock1.Allocated__c = 16.0;
        stock1.Consumed_Stock__c = 11.0;
        stock1.Country__c = countryId;
        stock1.Area__c = area.Id;
        stock1.Product__c = testProduct.id;
        stock1.Type__c = 'State+Segment';
        stock1.State__c = geoMap.get('State');
        stock1.Global_Segment__c = 'Hypermarket';
        
        Stock__c stock3 = new Stock__c();
        stock3.RecordTypeId = stockRecordTypes.get('Allocation');
        stock3.Allocated__c = 17.0;
        stock3.Consumed_Stock__c = 12.0;
        stock3.Country__c = countryId;
        stock3.Area__c = area.Id;
        stock3.Product__c = testProduct.id;
        stock3.Type__c = 'Segment';
        stock3.Local_Outlet_Segment1__c=pckObj1.Id;
        stock3.Global_Segment__c = 'HyperMarket';
        
        Stock__c stock2 = new Stock__c();
        stock2.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        stock2.Allocated__c = 18.0;
        stock2.Consumed_Stock__c = 13.0;
        stock2.Country__c = countryId;
        stock2.Area__c = area.Id;
        stock2.Type__c = 'Segment';
        stock2.Global_Segment__c = 'Bar';
        stock2.Product__c = testProduct.id;
        stock2.Local_Outlet_Segment1__c =pckObj1.Id;
        stock2.Original_Stock__c = 50 ;
        
        Stock__c stock4 = new Stock__c();
        stock4.RecordTypeId = stockRecordTypes.get('Allocation');
        stock4.Allocated__c = 19.0;
        stock4.Consumed_Stock__c = 14.0;
        stock4.Country__c = countryId;
        stock4.Area__c = area.Id;
        stock4.Product__c = testProduct.id;
        stock4.Type__c = 'State';
        stock4.State__c = geoMap.get('State');
        
        Stock__c stock5 = new Stock__c();
        stock5.RecordTypeId = stockRecordTypes.get('Allocation');
        stock5.Allocated__c = 20.0;
        stock5.Consumed_Stock__c = 15.0;
        stock5.Country__c = countryId;
        stock5.Area__c = area.Id;
        stock5.Product__c = testProduct.id;
        stock5.Type__c = 'Outlet (Target List)';
        stock5.Target_List__c = tarList.id;
        
        Stock__c stock6 = new Stock__c();
        stock6.RecordTypeId = stockRecordTypes.get('Allocation');
        stock6.Allocated__c = 21.0;
        stock6.Consumed_Stock__c = 16.0;
        stock6.Country__c = countryId;
        stock6.Area__c = area.Id;
        stock6.Territory__c=territory.Id;
        stock6.Product__c = testProduct.id;
        stock6.Type__c = 'Territory/Rep';
        
        Stock__c stock8 = new Stock__c();
        stock8.RecordTypeId = stockRecordTypes.get('Allocation');
        stock8.Allocated__c = 22.0;
        stock8.Consumed_Stock__c = 17.0;
        stock8.Country__c = countryId;
        stock8.Area__c = area.Id;
        stock8.Product__c = testProduct.id;
        stock8.Type__c = 'Segment';
        stock8.Local_Outlet_Segment1__c=pckObj1.Id;
        stock8.Global_Segment__c = '';
        
        Stock__c stock7 = new Stock__c();
        stock7.RecordTypeId = stockRecordTypes.get('Allocation');
        stock7.Allocated__c = 23.0;
        stock7.Consumed_Stock__c = 18.0;
        stock7.Country__c = countryId;
        stock7.Area__c = area.Id;
        stock7.Product__c = testProduct.id;
        stock7.Type__c = 'Outlet';
        stock7.Target_List__c = tarList.id;  
        
        stockList.add(stock1);
        stockList.add(stock2);
        stockList.add(stock3);
        stockList.add(stock4);
        stockList.add(stock5);
        stockList.add(stock6);
        stockList.add(stock7);
        stockList.add(stock8);
        
        
        
        database.insert(stockList,false);
        EDGE_StockTriggerHelper.validateAllocationType(stockList);
        Test.stopTest(); 
        
        
        
        system.assert(stock4.Product__c!=null,'Product is Present');   
    }     
    @isTest
    public static void testShedStock(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        System.assert(countryId!=null,'Country is Added');
        Test.startTest(); 
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        //list<Pick_Up_Options__c> picklist = new list<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUS]';
        pickupOption.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        pickupOption.Type__c = 'Outlet Visit Prioritization';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        insert testProduct;
        
        Market_Assortment_Product__c marketproduct= new Market_Assortment_Product__c();
        marketproduct.Product__c=testProduct.id;
        marketproduct.Market_Assortment__c = countryId;
        marketProduct.ECM_Pickup_Option__c = pickupOption.Id;
        insert marketproduct;     
        
        Stock__c stockRec = new Stock__c();
        stockRec.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        stockRec.Allocated__c = 15.0;
        stockRec.Consumed_Stock__c = 10.0;
        stockRec.Country__c = countryId;
        //stockRec.Area__c = area.Id;
        stockRec.Market_Assortment_Product__c = marketproduct.id;
        system.debug(LoggingLevel.Debug,'MAP ID TEST -- '+marketproduct.id);
        stockRec.Unique_Key__c = '12345-78978';
        insert stockRec;
        List<Stock__C> stckInsertList = new List<Stock__C>();
        stckInsertList.add(stockRec);
        EDGE_StockTriggerHelper.populateProductField(stckInsertList,null); 
        stockRec.Market_Assortment_Product__c = null;
        stockRec.Allocated__c = 25.0;
        stockRec.Start_Date__c = Date.newInstance(2023, 11, 3);
        stockRec.End_Date__c = Date.newInstance(2023, 11, 8);
        update stockRec;
        List<Stock__C> stckList = new List<Stock__C>();
        stckList.add(stockRec);
        
       
        
        Test.stopTest(); 
        
        
        
        Map<Id, Stock__c> mapOldItems = new Map<Id, Stock__c>();
        mapOldItems.put(stockRec.id,stockRec);
        EDGE_StockTriggerHelper.validateAndReGenerateD1Sharing(stckList, mapOldItems);
        EDGE_StockTriggerHelper.checkAndGenerateD1Sharing(stckList);
        EDGE_StockTriggerHelper.populateProductField(stckList,mapOldItems);               
        EDGE_StockTriggerHelper.insertStockDateValidation(stockRec.Start_Date__c,stockRec.End_Date__c,Date.newInstance(2023, 11, 8));
        EDGE_StockTriggerHelper.updateStockDateValidation(stockRec, mapOldItems, Date.newInstance(2023, 11, 8));
    }    
    
}