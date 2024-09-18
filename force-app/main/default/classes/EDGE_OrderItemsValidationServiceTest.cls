/*
Name: EDGE_OrderItemsValidationServiceTest
Req: 
History                                                                                                                        
VERSION   AUTHOR            DATE              DETAIL
1.0       Manikant Prasad   31/07/2019      Initial Development
2.0       Preyanka Ghosh    31/07/2019      Added extra method
3.0       Joshraj Sen       08/04/2024      152305
*/
@isTest
public class EDGE_OrderItemsValidationServiceTest {
    
    /*
    Method  : validateOrderItemsShedTest
    Purpose : This is used to cover validateOrderItems method
    */    
    @isTest
    public static void validateOrderItemsShedTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        User salesRep  = EDGE_UtilityTestClass.runAsUser('SalesRep','Master Data Manager');
        insert salesRep;
        
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/OrderItemsValidationService?userid=';
        requri = requri+ String.valueOf(salesRep.Id);
        req.requestUri =requri;
        req.params.put('userid', salesRep.Id);            
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        List<EDGE_OrderProductWrapper> orderItemList = new List<EDGE_OrderProductWrapper> ();
        EDGE_OrderItemsValidationService.validateOrderItems(orderItemList);
        List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
        //Map<Order_Item__c,Id> orderItemMap = new Map<Order_Item__c,Id>();
        //Map<Order_Item__c,Id> salesRepItemMap = new Map<Order_Item__c,Id>(); 
        
        
        
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
        system.assert(testProduct.id != null,'Product is Added');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUS]';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Id contractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract contractRec = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        contractRec.Opening_AP_Balance__c = 50;
        contractRec.AP_Spent__c = 500;
        insert contractRec;
        system.assert(contractRec.id != null,'Contract is Added');
        
        Order__c orderRec1 = new Order__c();
        orderRec1.Contract__c = contractRec.Id;
        orderRec1.Account__c = outlet.Id;
        orderRec1.Sales_Representative__c = userinfo.getuserId();
        orderRec1.Status__c = 'Ready for Order';
        orderRec1.Total_A_P_Cost__c = 100;   
        orderRec1.Delivery_Location__c = 'Shed';
        orderRec1.Order_Type__c = 'Shed';
        insert orderRec1;
        
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.Product__c = testProduct.id;
        orderItem.Order__c = orderRec1.id;
        orderItem.Quantity__c = 15 ;
        orderItem.Type__c = 'Shed' ;
        orderItem.GUID__c = 'abs6353';
        lstOrderItem.add(orderItem);
        insert orderItem;
        
        EDGE_OrderProductWrapper eOP = new EDGE_OrderProductWrapper();
        eOP.product = testProduct.Id;
        eop.guid = 'hjkhdfk7878';
        eop.orderType = 'Shed';
        eop.quantity = 212;
        eop.recordTypeName = 'Shed Item';
        eop.salesRep = salesRep.id;
        
        String jsonMsg=JSON.serialize(eOP);
        System.debug(LoggingLevel.Debug,'--JsonMsg'+jsonMsg);
        String finalJsonString = '{"orderItemList": ['+jsonMsg+']}' ;
        System.debug(LoggingLevel.Debug,'--finalJsonString'+finalJsonString);
        req.requestBody = Blob.valueof(finalJsonString);
        
        RestContext.request = req;
        RestContext.response= res;
        
        List<EDGE_OrderProductWrapper> orderProductWrapperList = new List<EDGE_OrderProductWrapper>(); 
        orderProductWrapperList.add(eOP);
        
        EDGE_OrderItemsValidationService.validateOrderItems(orderProductWrapperList);
        
        Test.stopTest();    
    }
    
    /*******************************************************************
    Method  : validateOrderItemsWareTest
    Purpose : This is used to cover validateOrderItems method
    ********************************************************************/    
    @isTest
    public static void validateOrderItemsWareTest(){
        List<Stock__c> stockList = new List<Stock__c>();
        List<Product__c> productList = new List<Product__c>();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        User salesRep  = EDGE_UtilityTestClass.runAsUser('SalesRep','Master Data Manager');
        insert salesRep;
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        insert deliveryPartner;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        productList.add(objProduct);
        
        Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
        objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct1.UPIID__c='123451';
        objProduct1.Supplier_Partner__c = deliveryPartner.Id;
        productList.add(objProduct1);

        insert productList;
        Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
        stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stockList.add(stock);
        
        Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
        stock1.Unique_Key__c = 'p8uf512A';
        stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock1.Type__c = 'Segment';
        stock1.Global_Segment__c = 'Hypermarket';
        stock1.State__c = null;
        stockList.add(stock1);
        insert stockList;
        system.assert(stockList != null,'No stock to insert');
        
        List<EDGE_OrderProductWrapper> lstOrderProductWrapper = new List<EDGE_OrderProductWrapper>();
        
        EDGE_OrderProductWrapper orderLineItem = new EDGE_OrderProductWrapper();
        orderLineItem.product = objProduct1.Id;
        orderLineItem.guid = 'hjkhdfk1234';
        orderLineItem.orderType = 'Warehouse';
        orderLineItem.quantity = 2;
        orderLineItem.accountId = outlet.Id;
        orderLineItem.recordTypeName = 'POS Item';
        lstOrderProductWrapper.add(orderLineItem);
        
        EDGE_OrderProductWrapper eOP = new EDGE_OrderProductWrapper();
        eOP.product = objProduct.Id;
        eop.guid = 'hjkhdfk7878';
        eop.orderType = 'Warehouse';
        eop.quantity = 12;
        eop.recordTypeName = 'POS Item';
        lstOrderProductWrapper.add(eop);
        
        Test.startTest();
        EDGE_OrderItemsValidationService.validateOrderItems(lstOrderProductWrapper);
        Test.stopTest();
        
    }
    
    /*******************************************************************
    Method  : validateShedFailTest
    Purpose : This is used to cover validateOrderItems method
    ********************************************************************/    
    @isTest
    public static void validateShedFailTest(){        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        User salesRep  = EDGE_UtilityTestClass.runAsUser('SalesRep','Master Data Manager');
        insert salesRep;
        System.assert(salesRep.id != null,'User is Added');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        insert deliveryPartner;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        insert objProduct;
        
        Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
        stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock.Sales_Rep__c = salesRep.Id;
        stock.Original_Stock__c = 15;
        stock.Consumed_Stock__c = 10;
        insert stock;
        
        List<EDGE_OrderProductWrapper> lstOrderProductWrapper = new List<EDGE_OrderProductWrapper>();
        EDGE_OrderProductWrapper orderLineItem = new EDGE_OrderProductWrapper();
        orderLineItem.product = objProduct.Id;
        orderLineItem.guid = 'hjkhdfk1234';
        orderLineItem.orderType = 'Shed';
        orderLineItem.quantity = 8;
        orderLineItem.salesRep = salesRep.Id;
        orderLineItem.recordTypeName = 'Shed Item';
        lstOrderProductWrapper.add(orderLineItem);
        
        
        Test.startTest();
        EDGE_OrderItemsValidationService.validateOrderItems(lstOrderProductWrapper);
        Test.stopTest();
        
    }
    /*******************************************************************
    Method  : validateShedStockMovementFailTest
    Purpose : This is used to cover validateOrderItems method
    ********************************************************************/    
    @isTest
    public static void validateShedStockMovementFailTest(){
		List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Id orderRecordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        Id orderItemRecordTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUS]';
        insert pickupOption;
        
        User salesRep  = EDGE_UtilityTestClass.runAsUser('SalesRep','Master Data Manager');
        salesRep.Available_Countries__c = 'AU';
        salesRep.Business_Role__c = 'businessRole';
        insert salesRep;
        System.assert(salesRep.id != null,'User is Added');
        
        Territory_Hierarchy__c businessUnit = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId,'Business Unit');
        insert businessUnit ;
        
        Territory_Hierarchy__c salesArea = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId,'Sales Area');
        salesArea.Parent_BU__c = businessUnit.Id;
        insert salesArea;
        
        Territory_Hierarchy__c region = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId,'Region');
        region.Parent_BU__c = salesArea.Id;
        insert region;
        
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Country__c = countryId; 
        territory.Region__c = region.Id;
        insert territory;
        
        Territory_Member__c terrMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRep.Id, territory.Id);
        insert terrMember;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        insert deliveryPartner;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        insert objProduct;
        
        Stock__c stock = new Stock__c();
        stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock.Country__c = countryId;
        stock.Product__c = objProduct.Id;
        stock.Sales_Rep__c = salesRep.Id;
        stock.Unique_Key__c = 'p8uf5';
        stock.Type__c = 'Territory/Rep';
        stock.Territory__c = territory.Id;
        stock.Original_Stock__c = 15;
        stock.Consumed_Stock__c = 10;
        insert stock;
        
        Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
        shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert shedAccount;
        
        EDGE_UtilityTestClass.createOrgSettings();
        Order__c orderRec1 = new Order__c();
        orderRec1.RecordTypeId = orderRecordTypeId;
        orderRec1.Account__c = shedAccount.Id;
        orderRec1.Sales_Representative__c = salesRep.Id;
        orderRec1.Status__c = 'Ready for Order';
        orderRec1.Total_A_P_Cost__c = 100;   
        orderRec1.Delivery_Location__c = 'Shed';
        orderRec1.Order_Type__c = 'Shed';
        insert orderRec1;
        
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.RecordTypeId = orderItemRecordTypeId;
        orderItem.Product__c = objProduct.id;
        orderItem.Order__c = orderRec1.id;
        orderItem.Quantity__c = 8 ;
        orderItem.Type__c = 'Shed' ;
        orderItem.GUID__c = 'ab3s6353';
        lstOrderItem.add(orderItem);
        insert orderItem;
        
        
        List<EDGE_OrderProductWrapper> lstOrderProductWrapper = new List<EDGE_OrderProductWrapper>();
        EDGE_OrderProductWrapper orderLineItem = new EDGE_OrderProductWrapper();
        orderLineItem.product = objProduct.Id;
        orderLineItem.guid = 'hzkhdfk1234';
        orderLineItem.orderType = 'Shed';
        orderLineItem.quantity = 8;
        orderLineItem.salesRep = salesRep.Id;
        orderLineItem.recordTypeName = 'Shed Item';
        lstOrderProductWrapper.add(orderLineItem);
        
        
        Test.startTest();
        EDGE_OrderItemsValidationService.validateOrderItems(lstOrderProductWrapper);
        Test.stopTest();
        
    }
    
}