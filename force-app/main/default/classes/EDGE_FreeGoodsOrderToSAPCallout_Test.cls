/*
@Name: EDGE_FreeGoodsOrderToSAPCallout_Test
@Description: This  test class is to have code coverage for EDGE_FreeGoodsOrderToSAPCallout
@History                                                            

VERSION			AUTHOR					DATE				DETAIL
1.0			Saurav Prasad			07/11/2023			Initial Development: 147473 - Salesforce Attribute mapping with corresponding Mulesoft Attribute in JSON file for sending Free Goods Order to SAP
1.1			Doman/Shivam			30/11/2023			147971/148542
*/

@isTest
public class EDGE_FreeGoodsOrderToSAPCallout_Test {
    @isTest
    public static void freeGoodOrdStatusTest(){
        createData();
        
        order__c order = [Select Status__c,Total_A_P_Cost__c From Order__c  Limit 1];
        order.Status__c = 'Ready for Order';
        update order;
        
        system.assertEquals('Ready for Order', order.Status__c,'Ready for order should match');
        order.Total_A_P_Cost__c = 110;
        update order;
    }
    
    @isTest
    public static void freeGoodsOrdErrorEmailEngTest(){
        createData();
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreationError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        order__c order = [Select Status__c,Total_A_P_Cost__c From Order__c  Limit 1];
        order.Status__c = 'Ready for Order';
        update order;
        
        system.assert(order.id != null,'Order id should not be null');
    }
    
    @isTest
    public static void freeGoodsOrdErrorEmailMrktLangTest(){
        createData();
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreationError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Market_Setting__c mrkt = [Select Send_SAP_Order_Failure_Email__c from Market_Setting__c limit 1];
        mrkt.Language__c = 'de';
        update mrkt;
        system.assert(mrkt.Language__c != null,'Language should be present');
            
        order__c order = [Select Status__c,Total_A_P_Cost__c From Order__c  Limit 1];
        order.Status__c = 'Ready for Order';
        update order;
    }
    
    @isTest
    public static void freeGoodOrdStatusSuccessTest(){
        createData();
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreation');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        order__c order = [Select Status__c,Total_A_P_Cost__c From Order__c Limit 1];
        order.Status__c = 'Ready for Order';
        update order;
       
        system.assertEquals('Ready for Order', order.Status__c,'Ready for order should match');
        order.Total_A_P_Cost__c = 110;
        update order;
        
    }
    
    @isTest
    public static void freeGoodOrdStatusFailureTest(){
        createData();
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('SalesOrderCreation');
        mock.setStatusCode(404);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        order__c order = [Select Status__c,Total_A_P_Cost__c From Order__c Limit 1];
        order.Status__c = 'Ready for Order';
        update order;
        
        system.assertEquals('Ready for Order', order.Status__c,'Ready for order should match');
        order.Total_A_P_Cost__c = 110;
        update order;
        
    }
    
    @isTest
    public static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.Send_SAP_Order_Failure_Email__c = true;
        marketSetting.SAP_Free_Goods_Order_Type__c = '';
        //marketSetting.Language__c = 'en_US';
        insert marketSetting;
        
        //Insert SalesRep
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1', 'Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesRep.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null,'salesRep should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        //Insert Pick_Up_Options__c
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        
        //Insert Account (outlet)
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        outlet.Primary_Sales_Rep__c = salesRep.Id;
        insert outlet;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Test.startTest();
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHierRegion.Parent_BU__c = terriHierSA.Id;
        insert terriHierRegion;
        
        //Insert Territory
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'service';
        territory.Business_Unit__c=terriHierBU.Id;
        Insert territory;
        
        //Insert Territory Budget
        Territory_Budget__c territoryBudget = new Territory_Budget__c();
        territoryBudget.Territory__c = territory.Id;
        territoryBudget.Start_Date__c = Date.newInstance(2020, 01, 01);
        territoryBudget.End_Date__c = Date.newInstance(2020, 01, 22);
        territoryBudget.Initial_Amount__c = 100;
        territoryBudget.Spent_Amount__c = 10;
        territoryBudget.ECM_Territory_Hierarchy__c=terriHierBU.Id;
        insert territoryBudget;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        deliveryPartner.Batch_Notification__c = true;
        deliveryPartner.Allow_Free_Goods_Order_to_SAP__c = true;
        insert deliveryPartner;
        
        //Insert products
        List<Product__c> lstProduct = new List<Product__c>();
        
        for(integer i=0;i<2;i++){
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.UPIID__c='12345'+i;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct);
        }
        insert lstProduct;
        
        
        List<Stock__c> lstStock = new list<Stock__c>();
        
        for(integer i=0;i<2;i++){
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, lstProduct[i].Id, salesRep.Id);
            stock.Unique_Key__c = 'p8uf512B'+i;
            stock.Sales_Rep__c = salesRep.Id;
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.Type__c = 'State+Segment';
            stock.Global_Segment__c = 'Hypermarket';
            stock.State__c = geoMap.get('State');
            
            lstStock.add(stock);
        }
        
        insert lstStock;
        
        //Insert Order__c
        String orderRecordtype = Order__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c order = new Order__c();
        order.Account__c = outlet.Id;
        order.Contract__c = objContract.Id;
        order.Budget_ID__c = territoryBudget.Id;
        order.Sales_Representative__c = salesRep.Id;
        order.RecordTypeId = orderRecordtype;
        order.Delivery_Start_Date__c = date.newInstance(2020, 01, 30);
        order.Free_Goods_A_P_Cost__c = 10;
        order.Total_A_P_Cost__c = 22; 
        order.SAP_Order_Transmission_Status__c = '';
        order.Status__c = 'Draft';
        order.Delivery_Partner__c = deliveryPartner.Id;
        insert order;
        
        //Order line items
        List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
        for(integer i=0;i<2;i++){
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(lstProduct[i].Id, order.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            lstOrderItem.add(orderItem);
        }
        
        insert lstOrderItem;
        
        Test.stopTest();
    }
    
}