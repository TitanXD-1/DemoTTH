/**
Name: EDGE_OrderTriggerHelperTest


History                                                            

VERSION     AUTHOR            DATE            DETAIL
1.0         Dipanjan Das      07/02/2019      Test Class for EDGE_OrderTriggerHelper
2.0			Rajarshi Lahiri	  22/06/2022	  Added test data for ES20-12606
3.0			Rajarshi lahiri	  18/07/2022	  Added test data for ES20-12957
4.0			Rajarshi Lahiri   24/08/2022	  ES20-13259
5.0			Rajarshi Lahiri	  31/08/2022	  ES20-13264
6.0         Wribhu Bose       07/11/2022      ES20-13023
7.0			Anamika Shukla    23/05/2024      377116(Deployment issue - EDGE_OrderTriggerHelperTest)
**/

@isTest
public class EDGE_OrderTriggerHelperTest {

    /**
    Method  : testStockAttach
    Purpose : Test method of validateLineItemQuantity
    */
    @isTest
    public static void testStockAttach(){
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent'; //was commented before
        market.A_P_Threshold__c = 100.00; //100
        market.Display_Transfer_Order_Comments__c = True;
        market.POS_Time_Based_Allocation__c = TRUE;
        insert market;
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        outlet.ShippingCountry = 'Australia';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
            
        List<User> usrList=new List<User>();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        usrList.add(salesManager);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Email = 'divya.bansal@diageo.com';
        usrList.add(salesRep);
        insert usrList;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        deliveryPartner.Batch_Notification__c = true;
        insert deliveryPartner;
        
        List<Order__c> lstOrder = new List<Order__c>();
        
        Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, null);
        posOrderGroup.Total_A_P_Cost__c = 20;
        insert posOrderGroup;
        
        Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, null);
        posOrder.Order_Group__c = posOrderGroup.Id;
        posOrder.Total_A_P_Cost__c = 20;
        posOrder.Delivery_Partner__c = deliveryPartner.Id;
        lstOrder.add(posOrder);
        
        Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, null);
        posOrder1.Order_Group__c = posOrderGroup.Id;
        posOrder1.Total_A_P_Cost__c = 15;
        posOrder1.Delivery_Partner__c = deliveryPartner.Id;
        lstOrder.add(posOrder1);    
        insert lstOrder;
            
        List<Product__c> lstProduct = new List<Product__c>();
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        objProduct.Pricing_Type__c = 'By Unit';
        objProduct.Units_per_POS__c = 10.0;
        objProduct.Diageo_Cost__c = 40;
        objProduct.Outlet_Cost__c = 50;
        objProduct.Start_Date__c = Date.Today();
        objProduct.POS_Item_Short_Description__c = 'Good';
        objProduct.IsActive__c = TRUE;
        lstProduct.add(objProduct);
        
        Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
        objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct1.UPIID__c='123451';
        objProduct1.Supplier_Partner__c = deliveryPartner.Id;
        objProduct1.Pricing_Type__c = 'By Unit';
        objProduct1.Units_per_POS__c = 10.0;
        objProduct1.Diageo_Cost__c = 40;
        objProduct1.Outlet_Cost__c = 50;
        objProduct1.Start_Date__c = Date.Today();
        objProduct1.POS_Item_Short_Description__c = 'Good';
        objProduct1.IsActive__c = TRUE;
        lstProduct.add(objProduct1);
        insert lstProduct;

        List<Stock__c> lstStock = new list<Stock__c>();
        Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
        stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock.State__c = geoMap.get('State');
        stock.Start_Date__c = Date.Today();
        stock.End_Date__c = Date.Today() + 10;
        lstStock.add(stock);
        
        Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
        stock1.Unique_Key__c = 'p8uf512A';
        stock1.Sales_Rep__c = salesRep.Id;
        stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock1.Type__c = 'Segment';
        stock1.Global_Segment__c = 'Hypermarket';
        stock1.State__c = null;
        stock1.Start_Date__c = Date.Today();
        stock1.End_Date__c = Date.Today() + 10;
        lstStock.add(stock1);
        
        Stock__c stock2 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
        stock2.Unique_Key__c = 'p8uf512B';
        stock2.Sales_Rep__c = salesRep.Id;
        stock2.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock2.Type__c = 'State+Segment';
        stock2.Global_Segment__c = 'Hypermarket';
        stock2.State__c = geoMap.get('State');
        stock2.Start_Date__c = Date.Today();
        stock2.End_Date__c = Date.Today() + 10;
        lstStock.add(stock2);

        Test.startTest();
        insert lstStock;
        
        List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
        Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct1.Id, posOrder1.Id);
        orderItem1.Type__c = 'Warehouse';
        orderItem1.Quantity__c = 2;
        lstOrderItem.add(orderItem1);
        
        Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
        orderItem.Type__c = 'Warehouse';
        orderItem.Quantity__c = 2;
        lstOrderItem.add(orderItem);
        insert lstOrderItem;
            
        List<Order__c> orderListToUpdate=new List<Order__c>();
        posOrderGroup.Status__c = 'Submitted';
        orderListToUpdate.add(posOrderGroup);    
        update orderListToUpdate;
        
        Test.stopTest();
    }
    
    /**
    Method  : testPTOOrder
    Purpose : Test method of validateLineItemQuantity
    */
    @isTest
    public static void testPTOOrder(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        insert market;        
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            List<Pick_Up_Options__c> lstPickUpOption = new List<Pick_Up_Options__c>();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            lstPickUpOption.add(pickupOption);
            
            Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getProdTypePickUpOption(countryId,'Product Type');
            pickupOption1.Name = 'Uniform[AU]';
            lstPickUpOption.add(pickupOption1);
            
            insert lstPickUpOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            Test.startTest();
            //List<Order__c> lstOrder = new List<Order__c>();
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Total_A_P_Cost__c = 20;
            //posOrder.Delivery_Partner__c = deliveryPartner.Id;
            posOrder.Order_Type__c = 'Shed';
            insert posOrder;
            
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Quantity';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            objProduct.Product_Type__c = pickupOption1.Id;
            insert objProduct;
            
            Product_Variant__c prodVar = new Product_Variant__c();
            prodVar.RecordTypeId = Product_Variant__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Uniform').getRecordTypeId();
            prodVar.Product__c = objProduct.Id;
            prodVar.Gender__c = 'Male';
            prodVar.Paper_Finish__c = 'Test';
            prodVar.Size__c = 'S';
            prodVar.Colour__c = 'White';
            insert prodVar;
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem1.Type__c = 'Shed';
            orderItem1.Quantity__c = 2;
            orderItem1.Product_Variant__c = prodVar.Id;
            insert orderItem1;
            
            posOrder.Status__c = 'Submitted';
            update posOrder;
            Test.stopTest();        
        }
    }
    
    /**
    Method  : testOrderHeld
    Purpose : Test method of validateLineItemQuantity
    */
    @isTest
    public static void testOrderHeld(){
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        insert market;        
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountry = 'Australia';
            outlet.BillingCountryCode = 'AU';
            
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            List<Order__c> lstOrder = new List<Order__c>();
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            lstOrder.add(posOrder);
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Group__c = posOrderGroup.Id;
            posOrder1.Total_A_P_Cost__c = 15;
            lstOrder.add(posOrder1);        
            insert lstOrder;
            
            Order__c posOrder2 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder2.Order_Group__c = posOrderGroup.Id;
            posOrder2.Total_A_P_Cost__c = 20;
            posOrder2.Status__c = 'Approval In Progress';
            insert posOrder2;
            posOrder2.Status__c = 'Order Held';
            update posOrder2;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = False;
            insert deliveryPartner;
            
            List<Product__c> lstProduct = new List<Product__c>();
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct);
            
            Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
            objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct1.UPIID__c='123451';
            objProduct1.Pricing_Type__c = 'By Unit';
            objProduct1.Supplier_Partner__c = deliveryPartner.Id;
            objProduct1.Units_per_POS__c = 10.0;
            objProduct1.Diageo_Cost__c = 40;
            objProduct1.Outlet_Cost__c = 50;
            objProduct1.Start_Date__c = Date.Today();
            objProduct1.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct1);
            
            insert lstProduct;
            
            List<Stock__c> lstStock = new list<Stock__c>();
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.State__c = geoMap.get('State');
            lstStock.add(stock);
            
            Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
            stock1.Unique_Key__c = 'p8uf512A';
            stock1.Sales_Rep__c = salesRep.Id;
            stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock1.Type__c = 'Segment';
            stock1.Global_Segment__c = 'Hypermarket';
            stock1.State__c = null;
            
            Stock__c stock2 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
            stock2.Unique_Key__c = 'p8uf512B';
            stock2.Sales_Rep__c = salesRep.Id;
            stock2.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock2.Type__c = 'State+Segment';
            stock2.Global_Segment__c = 'Hypermarket';
            stock2.State__c = geoMap.get('State');
            test.startTest();
            lstStock.add(stock2);
            insert lstStock;
            
            List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct1.Id, posOrder1.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Quantity__c = 2;
            lstOrderItem.add(orderItem1);
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Shed';
            orderItem.Quantity__c = 2;
            lstOrderItem.add(orderItem);
            insert lstOrderItem;

            posOrderGroup.Status__c = 'Submitted';
            update posOrderGroup;
            EDGE_UtilityClass.stopTriggerToRun = false;
            test.stopTest();
        }
    }
    
    /** 
    Method  : testVerifyAPCost
    Purpose : Test method of VerifyAPCost
    */
    @isTest
    public static void testVerifyAPCost(){
        test.startTest();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');        
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            //outlet.BillingState = 'NSW';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 500;
            insert posOrderGroup;
            
            EDGE_UtilityClass.stopTriggerToRun = false;
            posOrderGroup.Status__c = 'Submitted';
            update posOrderGroup;
            test.stopTest();
        }
    }
    
    /**
    Method  : testValidateLineItemQuantity
    Purpose : Test method of validateLineItemQuantity
    */
    @isTest
    public static void testValidateLineItemQuantity(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');        
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            //outlet.BillingState = 'NSW';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;

            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            insert posOrder;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;

            test.startTest();
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            insert stock;
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            insert orderItem;
            
            EDGE_UtilityClass.stopTriggerToRun = false;
            posOrderGroup.Status__c = 'Submitted';
            system.debug(LoggingLevel.Debug,('@@'+posOrderGroup));
            update posOrderGroup;
            test.stopTest();        
        }
    }
    
    /**
    Method  : testValidateShedQuantity
    Purpose : Test method of validateLineItemQuantity
    */
    @isTest
    public static void testValidateShedQuantity(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        insert market;        
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            insert salesManager;  
            System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            insert salesRep; 
            System.assert(salesRep.Id!=null,'sales rep Id should not be null');
            
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            List<Account> lstAccount = new List<Account>();
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            //outlet.BillingState = 'NSW';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outlet.ShippingCountry = 'Australia';
            lstAccount.add(outlet);
            
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            lstAccount.add(shedAccount);
            
            insert lstAccount;
        
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = UserInfo.getUserId();
            newAccTeamMember.TeamMemberRole = 'Sales Manager';
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember; 
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Order_Type__c = 'Shed';
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;

            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Total_A_P_Cost__c = 20;
            //posOrder.Status__c = 'Ready for Order';
            posOrder.Order_Group__c = posOrderGroup.Id;
            insert posOrder;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            test.startTest();
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
            stock.Sales_Rep__c = salesRep.Id;
            stock.Shed__c = shedAccount.Id;
            insert stock;
        
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Shed';
            orderItem.Stock__c = stock.Id;
            orderItem.Quantity__c = 5;
            insert orderItem;
            
            try{
                EDGE_UtilityClass.stopTriggerToRun = false;
                posOrderGroup.Status__c = 'Submitted';
                //test.startTest();
                update posOrderGroup;
                test.stopTest();
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
                
            }
        }
    }
    
    /**
    Method  : testorderStatusHeldCancelled 
    Purpose : test method for orderStatusHeldCancelled
    */
    @isTest
    public static void testOrderStatusHeldCancelled(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10.00;
        insert marketSetting;        
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null'); 
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');

        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outlet.ShippingCountry = 'Australia';
            insert outlet;

            EDGE_UtilityTestClass.createOrgSettings();

            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            objContract.AP_Spent__c = 500;
            insert objContract;

            List<Order__c> orderList=new List<Order__c>();
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Approval In Progress';
            posOrder.Total_A_P_Cost__c = 100;
            orderList.add(posOrder);
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Type__c = 'Warehouse';
            posOrder1.Status__c = 'Ready for Order';
            posOrder1.Total_A_P_Cost__c = 100;
            orderList.add(posOrder1);
            
            Order__c posOrder2 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder2.Order_Type__c = 'Warehouse';
            posOrder2.Status__c = 'Approval In Progress';
            posOrder2.Total_A_P_Cost__c = 100;
            orderList.add(posOrder2);
            
            Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder3.Order_Type__c = 'Shed';
            posOrder3.Status__c = 'Ready for Order';
            posOrder3.Total_A_P_Cost__c = 100;
            orderList.add(posOrder3);
            insert orderList;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            
            String allocationStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            Stock__c allocationStock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            allocationStock.RecordTypeId = allocationStockRecordTypeId;
            allocationStock.Original_Stock__c = 400;
            allocationStock.Consumed_Stock__c = 100;
            insert allocationStock;

            List<Order_Item__c> oItems = new List<Order_Item__c>();
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder1.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Stock__c = allocationStock.Id;
            orderItem1.Quantity__c = 80;
            oItems.add(orderItem1); 
            
            Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder2.Id);
            orderItem2.Type__c = 'Warehouse';
            orderItem2.Stock__c = allocationStock.Id;
            orderItem2.Quantity__c = 80;
            oItems.add(orderItem2);

            insert oItems;
            
            Test.startTest();
            //Update POS Order Status
            posOrder1.Status__c = 'Cancelled';
            update posOrder1;

            posOrder2.Status__c = 'Order Held';
            update posOrder2;
            Test.stopTest();
        }
    }
    
    /**
    Method  : testDeleteOrder 
    Purpose : test method for cover delete method in handler
    */
    @isTest
    public static void testDeleteOrder(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');        
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales manager Id should not be null'); 
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'Sales Rep Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            //outlet.BillingState = 'SDF';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            objContract.AP_Spent__c = 500;
            insert objContract;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Approval In Progress';
            posOrder.Total_A_P_Cost__c = 100;
            insert posOrder;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            test.startTest();
            String allocationStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            Stock__c allocationStock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            allocationStock.RecordTypeId = allocationStockRecordTypeId;
            allocationStock.Original_Stock__c = 400;
            allocationStock.Consumed_Stock__c = 100;
            insert allocationStock;
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Stock__c = allocationStock.Id;
            orderItem1.Quantity__c = 80;
            insert orderItem1; 
            //test.startTest(); //added by juned
            posOrder.Status__c = 'Order Held';
            update posOrder;
            
            delete posOrder;
            undelete posOrder;
            
            test.stopTest();
        }
    }
    
    /**
    Method  : testsyncOrderDeliveryStatus 
    Purpose : test method to  cover syncOrderDeliveryStatus  method in handler
    */
    @isTest
    public static void testsyncOrderDeliveryStatus(){
        
        test.startTest();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
         testAdminUser.Username = 'testau230520241435@test.com';
        insert testAdminUser; 
       
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 500;
            insert posOrderGroup;
            posOrderGroup.Status__c = 'Shed to customer';
            update posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Approval In Progress';
            posOrder.Total_A_P_Cost__c = 100;
            posOrder.Order_Group__c = posOrderGroup.id;
            posOrder.Delivery_Location__c = 'Shed';
            insert posOrder;
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Type__c = 'Warehouse';
            posOrder1.Status__c = 'Ready for Order';
            posOrder1.Order_Group__c = posOrderGroup.id;
            posOrder1.Total_A_P_Cost__c = 120;
            insert posOrder1;
            posOrder1.Status__c = 'Shed to Customer';
            update posOrder1;
            
            Order__c posOrder2 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder2.Order_Type__c = 'Warehouse';
            posOrder2.Status__c = 'Approval In Progress';
            posOrder2.Order_Group__c = posOrderGroup.id;
            posOrder2.Total_A_P_Cost__c = 102;
            insert posOrder2;
            test.stopTest();
        }
    }
    
    /**
    Method  : testsyncOrderDeliveryStatus 
    Purpose : test method to  sendEmailToDelPart method in Helper
    */
    @isTest
    public static void testSendEmailToDelPart(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Attachment_Format__c = 'Excel';
        insert marketSetting; 
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            List<Order__c> posOrderGroups = new List<Order__c>();
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 500;
            posOrderGroup.Status__c = 'Ready for Order';
            posOrderGroups.add(posOrderGroup);
            
            Order__c posOrderGroup1 = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup1.Total_A_P_Cost__c = 500;
            posOrderGroup1.Status__c = 'Ready for Order';
            posOrderGroups.add(posOrderGroup1);
            
            insert posOrderGroups;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = False;
            insert deliveryPartner;
            
            ContactPointAddress conPointAdd=new ContactPointAddress();
            conPointAdd.Name='Test';
            conPointAdd.Country='Australia';
            conPointAdd.City='Brisbane';
            conPointAdd.Street='Test Street';
            conPointAdd.State='New South Wales';
            conPointAdd.PostalCode='123456';
            conPointAdd.Source__c='EDGE 365';
            insert conPointAdd;
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Type__c = 'Shed';
            posOrder1.Status__c = 'Draft';
            posOrder1.Total_A_P_Cost__c = 100;
            posOrder1.Order_Group__c = posOrderGroup1.id;
            posOrder1.Delivery_Location__c = 'Shed';
            posOrder1.Delivery_Partner__c = deliveryPartner.Id;
            insert posOrder1;

            posOrder1.Status__c = 'Order Placed';
            update posOrder1;
            
            List<Order__c> orderlist = new List<Order__c>();
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Draft';
            posOrder.Total_A_P_Cost__c = 100;
            posOrder.Order_Group__c = posOrderGroup.id;
            posOrder.Delivery_Location__c = 'Shed';
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            posOrder.Delivery_Start_Date__c = System.today();
            posOrder.Delivery_End_Date__c = posOrder.Delivery_Start_Date__c.addDays(5);
            orderlist.add(posOrder);

            Order__c posOrder2 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder2.Order_Group__c = posOrderGroup.Id;        
            posOrder2.Status__c = 'Ready for Order';
            posOrder2.Alternate_Delivery_Address__c=conPointAdd.Id;
            posOrder2.Delivery_Partner__c = deliveryPartner.Id;
            posOrder2.Delivery_Location__c = 'Other';
            posOrder2.Parent_Order__c = posOrder.Id; //ES20-13023
            orderlist.add(posOrder2);
            insert orderlist;

            Test.startTest();
            posOrder.Status__c = 'Ready for Order';
            update orderlist.get(0);
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            
            String allocationStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            Stock__c allocationStock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            allocationStock.RecordTypeId = allocationStockRecordTypeId;
            allocationStock.Original_Stock__c = 400;
            allocationStock.Consumed_Stock__c = 100;
            insert allocationStock;
            
            Product_Variant__c prodVar = new Product_Variant__c();
            prodVar.RecordTypeId = Product_Variant__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Uniform').getRecordTypeId();
            prodVar.Product__c = objProduct.Id;
            prodVar.Gender__c = 'Male';
            prodVar.Paper_Finish__c = 'Test';
            prodVar.Size__c = 'S';
            prodVar.Colour__c = 'White';
            insert prodVar;
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Product_Variant__c = prodVar.Id;
            orderItem1.Stock__c = allocationStock.Id;
            orderItem1.Quantity__c = 80;
            orderItem1.Note__c = 'Test';
            orderItem1.Text_to_Print__c = 'HiTest';
            orderItem1.Status__c = 'Ready for Order';
            
            insert orderItem1;

            EDGE_OrderTriggerHelper.getD1Setting(orderlist);
            Test.stopTest();
            system.assert(orderItem1.id!=null,'order Item1 id should not be null');
        }
    }
    
    /**
    Method  : testsyncOrderDeliveryStatus 
    Purpose : test method to  sendEmailToDelPart method in Helper - CSV code coverage
    */
    @isTest
    public static void testSendEmailToDelPartCSV(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Attachment_Format__c = 'CSV';
        insert marketSetting; 
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'Sales Rep Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            List<Order__c> posOrderGroups = new List<Order__c>();
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 500;
            posOrderGroup.Status__c = 'Ready for Order';
            posOrderGroups.add(posOrderGroup);
            
            Order__c posOrderGroup1 = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup1.Total_A_P_Cost__c = 500;
            posOrderGroup1.Status__c = 'Ready for Order';
            posOrderGroups.add(posOrderGroup1);
            
            insert posOrderGroups;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = False;
            insert deliveryPartner;
            
            ContactPointAddress conPointAdd=new ContactPointAddress();
            conPointAdd.Name='Test';
            conPointAdd.Country='Australia';
            conPointAdd.City='Brisbane';
            conPointAdd.Street='Test Street';
            conPointAdd.State='New South Wales';
            conPointAdd.PostalCode='123456';
            conPointAdd.Source__c='EDGE 365';
            insert conPointAdd;
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Type__c = 'Shed';
            posOrder1.Status__c = 'Draft';
            posOrder1.Total_A_P_Cost__c = 100;
            posOrder1.Order_Group__c = posOrderGroup1.id;
            posOrder1.Delivery_Location__c = 'Shed';
            posOrder1.Delivery_Partner__c = deliveryPartner.Id;
            insert posOrder1;

            posOrder1.Status__c = 'Order Placed';
            update posOrder1;
            
            List<Order__c> orderlist = new List<Order__c>();
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Draft';
            posOrder.Total_A_P_Cost__c = 100;
            posOrder.Order_Group__c = posOrderGroup.id;
            posOrder.Delivery_Location__c = 'Shed';
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            posOrder.Delivery_Start_Date__c = System.today();
            posOrder.Delivery_End_Date__c = posOrder.Delivery_Start_Date__c.addDays(5);
            orderlist.add(posOrder);

            Order__c posOrder2 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder2.Order_Group__c = posOrderGroup.Id;        
            posOrder2.Status__c = 'Ready for Order';
            posOrder2.Alternate_Delivery_Address__c=conPointAdd.Id;
            posOrder2.Delivery_Partner__c = deliveryPartner.Id;
            posOrder2.Delivery_Location__c = 'Other';
            posOrder2.Parent_Order__c = posOrder.Id; //ES20-13023
            orderlist.add(posOrder2);
            insert orderlist;

            Test.startTest();
            posOrder.Status__c = 'Ready for Order';
            update orderlist.get(0);
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            
            String allocationStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            Stock__c allocationStock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            allocationStock.RecordTypeId = allocationStockRecordTypeId;
            allocationStock.Original_Stock__c = 400;
            allocationStock.Consumed_Stock__c = 100;
            insert allocationStock;
            
            Product_Variant__c prodVar = new Product_Variant__c();
            prodVar.RecordTypeId = Product_Variant__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Uniform').getRecordTypeId();
            prodVar.Product__c = objProduct.Id;
            prodVar.Gender__c = 'Male';
            prodVar.Paper_Finish__c = 'Test';
            prodVar.Size__c = 'S';
            prodVar.Colour__c = 'White';
            insert prodVar;
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Product_Variant__c = prodVar.Id;
            orderItem1.Stock__c = allocationStock.Id;
            orderItem1.Quantity__c = 80;
            orderItem1.Note__c = 'Test';
            orderItem1.Text_to_Print__c = 'HiTest';
            orderItem1.Status__c = 'Ready for Order';
            
            insert orderItem1;
            EDGE_OrderTriggerHelper.getD1Setting(orderlist);
            Test.stopTest();
            system.assert(orderItem1.id!=null,'order Item1 Id should not be null');
        }
    }
    
    /**
    Method  : testGetProductDetailTemplate
    Purpose : test method to  cover EDGE_getOrderProducts 
    */
    @isTest
    public static void testGetProductDetailTemplate(){
        
        //test.startTest();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            //deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
            List<Order__c> orderlist = new List<Order__c>();
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(null, outlet.Id, null);
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Draft';
            posOrder.Total_A_P_Cost__c = 100;
            posOrder.Delivery_Partner__c = deliveryPartner.id;
            posOrder.Delivery_Location__c = 'Shed';
            
            orderlist.add(posOrder);
            insert orderlist;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Diageo_Cost__c = 100;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            test.startTest();
            String allocationStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            Stock__c allocationStock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, null);
            allocationStock.RecordTypeId = allocationStockRecordTypeId;
            allocationStock.Original_Stock__c = 400;
            allocationStock.Consumed_Stock__c = 100;
            insert allocationStock;
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Stock__c = allocationStock.Id;
            orderItem1.Quantity__c = 80;
            orderItem1.Note__c = 'Test';
            orderItem1.Text_to_Print__c = 'HiTest';
            orderItem1.Status__c = 'Ready for Order';
            insert orderItem1;
            system.assert(orderItem1.id!=null,'order Item1 Id should not be null');
            
            EDGE_getOrderProducts getorderProductCls= new EDGE_getOrderProducts ();
            getorderProductCls.targetObjectId = posOrder.id;
            getorderProductCls.getOrderDetails();
            getorderProductCls.getOrderProductItems();
            test.stopTest();
        }  
    }

    /* method : sendEmailForOrderSubmtdTest
    Purpose : to cover the sending email to Outlet,Sales Rep, Wholesaler section of order trigger helper.
    */
    @isTest
    public static void sendEmailForOrderSubmtdTestOrderPlaced(){
        //For Status = Order Placed
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Transfer_Order_Email_Batch_Settings__c = false;
        market.Display_Transfer_Order_Comments__c = True;
        insert market;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep3','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep4','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            outlet.ShippingCountry = 'Australia';
            insert outlet;
            
            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Australia';
            insert wholesaler;
            
            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
            Product__c testProduct = EDGE_UtilityTestClass.getProd();
            testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            testProduct.Supplier_Partner__c= deliveryPartner.Id;
            //testProduct.IsActive__c = True;
            testProduct.Start_Date__c = Date.today();
            testProduct.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
            testProduct.Pricing_Type__c = 'By Unit';
            testProduct.A_P_Cost__c = 100;
            insert testProduct;
            
            system.assert(testProduct.Id != null,'test Product Id should not be null');
            Test.startTest();
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=testProduct.Id);
            insert testMAP;
            
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Draft';
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Source_Application__c = 'Diageo One';
            insert trnsfrOrder;
            
            system.assert(trnsfrOrder.Id != null,'trnsfr Order id should not be null');
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(testProduct.Id, trnsfrOrder.Id);
            orderItem1.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem1.Quantity__c = 80;
            orderItem1.Delivered_Quantity__c = 10;
            orderItem1.Status__c = 'Submitted';
            //orderItem1.Selected_UoM__c = 'BTL';
            insert orderItem1;
            
            trnsfrOrder.Status__c = 'Submitted';
            Update trnsfrOrder;
            Test.stopTest();
        }
    }
    
    /* method : sendEmailForOrderSubmtdTest
    Purpose : to cover the sending email to Outlet,Sales Rep, Wholesaler section of order trigger helper.
    */
    @isTest
    public static void sendEmailForOrderSubmtdTestReadyforOrder(){
        //For Status = Ready for Order        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Transfer_Order_Email_Batch_Settings__c = true;
        insert market;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep4','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = testAdminUser.id;
        salesRep.Email = 'divya.bansal@diageo.com';
        salesRep.Mobile_Number__c = '7906904483';
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        System.runAs(testAdminUser){
            Test.startTest();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            List<Account> accountList = new List<Account>();
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            accountList.add(outlet);
            
            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Australia';
            accountList.add(wholesaler);
            insert accountList;

            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            Test.stopTest();
            Product__c testProduct = EDGE_UtilityTestClass.getProd();
            testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            testProduct.Supplier_Partner__c= deliveryPartner.Id;
            //testProduct.IsActive__c = True;
            testProduct.Start_Date__c = Date.today();
            testProduct.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
            testProduct.Pricing_Type__c = 'By Unit';
            testProduct.A_P_Cost__c = 100;
            insert testProduct;
            
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=testProduct.Id);
            insert testMAP;
            
            system.assert(testProduct.Id != null,'test Product Id should not be null');
            
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Draft';
            trnsfrOrder.Comments__c = 'hello';
            insert trnsfrOrder;
            
            system.assert(trnsfrOrder.Id != null,'trnsfr Order Id should not be null');
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(testProduct.Id, trnsfrOrder.Id);
            orderItem1.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem1.Quantity__c = 80;
            orderItem1.Delivered_Quantity__c = 10;
            orderItem1.Status__c = 'Submitted';
            //orderItem1.Selected_UoM__c = 'BTL';
            insert orderItem1;
            
            trnsfrOrder.Status__c = 'Submitted';
            Update trnsfrOrder;
            delete orderItem1;
            undelete orderItem1;
        }
    }

    public static void testTerrPromotionPrmUsed(){
        Date todays = Date.today();
        Id freeProductRecordTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Transfer_Order_Email_Batch_Settings__c = true;
        insert market;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep3','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep4','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Email = 'divya.bansal@diageo.com';
        salesRep.Mobile_Number__c = '7906904483';
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            List<Account> accList=new List<Account>();
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            accList.add(outlet);
            
            Account outlet2 = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            accList.add(outlet2);
            insert accList;
            system.assert(outlet2.Id != null,'outlet2 Id should not be null');
            
            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Australia';
            insert wholesaler;
            
            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
            Promotion_Master__c pmObj = new Promotion_Master__c();
            pmObj.Name = 'Promotion Master 1';
            pmObj.Description__c = 'Promo Desc';
            pmObj.Start_Date__c = todays.addDays(-4);
            pmObj.End_Date__c = todays.addDays(10);
            pmObj.Total_Order_quantity_for_Free_Product__c = 20;
            pmObj.RecordTypeId = freeProductRecordTypeId;
            insert pmObj;
            
            Outlet_Promotion__c outletPromotion=new Outlet_Promotion__c();
            outletPromotion.Status__c='Active';
            outletPromotion.Outlet__c=outlet.Id;
            outletPromotion.Promotion__c=pmObj.Id;
            outletPromotion.Promotion_Limit__c=100;
            //outletPromotion.Promotion_Used__c=1;
            insert outletPromotion;
            
            Test.startTest();
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            terriHierBU.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            terriHierSA.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            terriHier.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHier;
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Sales';
            territory.Region__c =terriHier.Id;
            territory.Country__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert territory;
            Outlet_Territory__c  outletTerritory  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
            outletTerritory.Active__c = 'Active';
            insert outletTerritory;
            Territory_Promotion__c territoryPromotion=new Territory_Promotion__c();
            territoryPromotion.Status__c='Active';
            territoryPromotion.Territory__c=territory.Id;
            territoryPromotion.Promotion__c=pmObj.Id;
            territoryPromotion.Promotion_Limit__c=100;
            territoryPromotion.Promotion_Used__c=1;
            insert territoryPromotion;
            
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Draft';
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder;
            
            Product__c testProduct2 = EDGE_UtilityTestClass.getProd();
            testProduct2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct2.Product_Full_Name__c=  'Baileys';
            testProduct2.UPIID__c=  '12567';
            //testProduct.IsActive__c = True;
            testProduct2.name = 'Baileys';
            testProduct2.Start_Date__c = Date.today();
            testProduct2.Expiry_Date__c = Date.today().addDays(2);
            insert testProduct2;
            
            //String purchasableId = Promotion_Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Purchasable Product').getRecordTypeId();
            Promotion_Product__c promoprod = new Promotion_Product__c();
            promoprod.Promotion__c  = pmObj.id;
            promoprod.Product__c   = testProduct2.id;
            insert promoprod;   
            
            Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(testProduct2.Id, trnsfrOrder.Id);
            orderItem3.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem3.Quantity__c = 40;
            orderItem3.Delivered_Quantity__c = 21;
            orderItem3.Status__c = 'Draft';
            //orderItem3.Selected_UoM__c = 'BTL';
            orderItem3.Promotion_Product__c = promoprod.id;
            insert orderItem3;
            
            Order__c trnsfrOrder2 = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Comments__c = 'hello';
            trnsfrOrder2.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder2;
            trnsfrOrder.Status__c = 'Submitted';
            update trnsfrOrder;
            
            trnsfrOrder2.Status__c = 'Submitted';
            update trnsfrOrder2;
            Test.stopTest();
            system.assert(trnsfrOrder.Id != null,'trnsfr Order Id should not be null');
        }
    }
    
    @isTest
    public static void testTerrPromotionPrmUsed2(){
        Date todays = Date.today();
        Id freeProductRecordTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Transfer_Order_Email_Batch_Settings__c = true;
        insert market;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep3','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep4','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Email = 'divya.bansal@diageo.com';
        salesRep.Mobile_Number__c = '7906904483';
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            List<Account> accList=new List<Account>();
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            accList.add(outlet);
            
            Account outlet2 = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            accList.add(outlet2);
            insert accList;
            system.assert(outlet2.Id != null,'outlet2 id should not be null');
            
            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Australia';
            insert wholesaler;
            
            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
            Promotion_Master__c pmObj = new Promotion_Master__c();
            pmObj.Name = 'Promotion Master 1';
            pmObj.Description__c = 'Promo Desc';
            pmObj.Start_Date__c = todays.addDays(-4);
            pmObj.End_Date__c = todays.addDays(10);
            pmObj.Total_Order_quantity_for_Free_Product__c = 20;
            pmObj.RecordTypeId = freeProductRecordTypeId;
            insert pmObj;
            
            Outlet_Promotion__c outletPromotion=new Outlet_Promotion__c();
            outletPromotion.Status__c='Active';
            outletPromotion.Outlet__c=outlet.Id;
            outletPromotion.Promotion__c=pmObj.Id;
            outletPromotion.Promotion_Limit__c=100;
            //outletPromotion.Promotion_Used__c=1;
            insert outletPromotion;
            
            Test.startTest();
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            terriHierBU.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            terriHierSA.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            terriHier.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHier;
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Sales';
            territory.Region__c =terriHier.Id;
            territory.Country__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert territory;
            Outlet_Territory__c  outletTerritory  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
            outletTerritory.Active__c = 'Active';
            insert outletTerritory;
            Territory_Promotion__c territoryPromotion=new Territory_Promotion__c();
            territoryPromotion.Status__c='Active';
            territoryPromotion.Territory__c=territory.Id;
            territoryPromotion.Promotion__c=pmObj.Id;
            territoryPromotion.Promotion_Limit__c=100;
            territoryPromotion.Promotion_Used__c=1;
            insert territoryPromotion;
            
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Submitted';
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder;
            
            Order__c trnsfrOrder2 = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Comments__c = 'hello';
            trnsfrOrder2.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder2;
            trnsfrOrder2.Status__c = 'Submitted';
            update trnsfrOrder2;
            Test.stopTest();
            system.assert(trnsfrOrder.Id != null,'trnsfr Order Id should not be null');   
        }
    }

    @isTest
    public static void testTerrPromotionPrmUsed3(){
        Date todays = Date.today();
        Id freeProductRecordTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Transfer_Order_Email_Batch_Settings__c = true;
        insert market;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep3','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep4','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Email = 'divya.bansal@diageo.com';
        salesRep.Mobile_Number__c = '7906904483';
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;

            List<Account> accList=new List<Account>();
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            accList.add(outlet);

            Account outlet2 = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            accList.add(outlet2);
            insert accList;
            system.assert(outlet2.Id != null,'outlet2 Id should not be null');

            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Australia';
            insert wholesaler;
            
            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
            Promotion_Master__c pmObj = new Promotion_Master__c();
            pmObj.Name = 'Promotion Master 1';
            pmObj.Description__c = 'Promo Desc';
            pmObj.Start_Date__c = todays.addDays(-4);
            pmObj.End_Date__c = todays.addDays(10);
            pmObj.Total_Order_quantity_for_Free_Product__c = 20;
            pmObj.RecordTypeId = freeProductRecordTypeId;
            insert pmObj;
            
            Outlet_Promotion__c outletPromotion=new Outlet_Promotion__c();
            outletPromotion.Status__c='Active';
            outletPromotion.Outlet__c=outlet.Id;
            outletPromotion.Promotion__c=pmObj.Id;
            outletPromotion.Promotion_Limit__c=100;
            outletPromotion.Promotion_Used__c=1;
            insert outletPromotion;
            
            Test.startTest();
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            terriHierBU.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            terriHierSA.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            terriHier.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHier;
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Sales';
            territory.Region__c =terriHier.Id;
            territory.Country__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert territory;
            Outlet_Territory__c  outletTerritory  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
            outletTerritory.Active__c = 'Active';
            insert outletTerritory;
            Territory_Promotion__c territoryPromotion=new Territory_Promotion__c();
            territoryPromotion.Status__c='Active';
            territoryPromotion.Territory__c=territory.Id;
            territoryPromotion.Promotion__c=pmObj.Id;
            territoryPromotion.Promotion_Limit__c=100;
            //territoryPromotion.Promotion_Used__c=1;
            insert territoryPromotion;
            
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Submitted';
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder;
            
            Order__c trnsfrOrder2 = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Comments__c = 'hello';
            trnsfrOrder2.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder2;
            trnsfrOrder2.Status__c = 'Submitted';
            update trnsfrOrder2;
            Test.stopTest();
            system.assert(trnsfrOrder.Id != null,'trnsfr Order Id should not be null');
        }
    }
    
    @isTest
    public static void testTerrPromotionPrmUsed4(){
        Date todays = Date.today();
        Id freeProductRecordTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Transfer_Order_Email_Batch_Settings__c = true;
        insert market;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep3','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep4','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Email = 'divya.bansal@diageo.com';
        salesRep.Mobile_Number__c = '7906904483';
        insert salesRep; 
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            List<Account> accList=new List<Account>();
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'Australia';
            accList.add(outlet);
            
            Account outlet2 = EDGE_UtilityTestClass.getOutletRecord(); 
            outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            accList.add(outlet2);
            insert accList;
            system.assert(outlet2.Id != null,'outlet2 id should not be null');
            
            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Australia';
            insert wholesaler;
            
            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
            Promotion_Master__c pmObj = new Promotion_Master__c();
            pmObj.Name = 'Promotion Master 1';
            pmObj.Description__c = 'Promo Desc';
            pmObj.Start_Date__c = todays.addDays(-4);
            pmObj.End_Date__c = todays.addDays(10);
            pmObj.Total_Order_quantity_for_Free_Product__c = 20;
            pmObj.RecordTypeId = FreeProductRecordTypeId;
            insert pmObj;
            
            Outlet_Promotion__c outletPromotion=new Outlet_Promotion__c();
            outletPromotion.Status__c='Active';
            outletPromotion.Outlet__c=outlet.Id;
            outletPromotion.Promotion__c=pmObj.Id;
            outletPromotion.Promotion_Limit__c=100;
            outletPromotion.Promotion_Used__c=1;
            insert outletPromotion;
            
            Test.startTest();
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            terriHierBU.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            terriHierSA.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            terriHier.Geography__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert terriHier;
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Sales';
            territory.Region__c =terriHier.Id;
            territory.Country__c=EDGE_UtilityTestClass.geoMap.get('Country');
            insert territory;
            Outlet_Territory__c  outletTerritory  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
            outletTerritory.Active__c = 'Active';
            insert outletTerritory;
            Territory_Promotion__c territoryPromotion=new Territory_Promotion__c();
            territoryPromotion.Status__c='Active';
            territoryPromotion.Territory__c=territory.Id;
            territoryPromotion.Promotion__c=pmObj.Id;
            territoryPromotion.Promotion_Limit__c=100;
            territoryPromotion.Promotion_Used__c=1;
            insert territoryPromotion;
            
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Submitted';
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder;
            
            Order__c trnsfrOrder2 = EDGE_UtilityTestClass.getTrnsfrOrder(salesRep.id, outlet.Id, wholesaler.Id);
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Comments__c = 'hello';
            trnsfrOrder2.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder2;
            trnsfrOrder2.Status__c = 'Submitted';
            update trnsfrOrder2;
            Test.stopTest();
            system.assert(trnsfrOrder.Id != null,'trnsfr Order Id should not be null');
        }
    }
    
    @isTest
    public static void sendPOSOrderNotification2(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        system.assert(testAdminUser.Id != null,'test Admin user id should not be null'); 
        
        System.runAs(testAdminUser){
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;        
            system.debug(LoggingLevel.Debug,('market '+market));
            
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            system.debug(LoggingLevel.Debug,(' @@limit -1-->'+Limits.getQueries()));
            
            List<User> usrList=new List<User>();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            usrList.add(salesManager);  
            //System.assert(salesManager.Id!=null);
            Test.startTest();
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Email = 'divya.bansal@diageo.com';
            usrList.add(salesRep); 
            //System.assert(salesRep.Id!=null);
            insert usrList;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = true;
            insert deliveryPartner;
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            posOrder.Status__c='Awaiting Approval';
            insert posOrder;
            posOrder.Status__c='Approved';
            update posOrder;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Diageo_Cost__c = 100;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;    
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            insert orderItem;
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testStockAttach2(){
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        system.assert(testAdminUser.Id != null,'test Admin User Id should not be null'); 
        
        System.runAs(testAdminUser){
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;
            
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            
            List<User> usrList=new List<User>();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            usrList.add(salesManager);  

            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Email = 'divya.bansal@diageo.com';
            usrList.add(salesRep); 
            insert usrList;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = true;
            insert deliveryPartner;
            
            List<Order__c> lstOrder = new List<Order__c>();
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder);
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Group__c = posOrderGroup.Id;
            posOrder1.Total_A_P_Cost__c = 15;
            posOrder1.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder1);        
            
            Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder3.Order_Group__c = posOrderGroup.Id;
            posOrder3.Total_A_P_Cost__c = 20;
            posOrder3.Status__c = 'Ready for Order';
            posOrder3.Order_Type__c = 'Shed';
            lstOrder.add(posOrder3);
            
            Order__c posOrder4 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder4.Order_Group__c = posOrderGroup.Id;
            posOrder4.Total_A_P_Cost__c = 20;
            posOrder4.Delivery_Partner__c= deliveryPartner.Id;
            posOrder4.Delivery_Location__c= 'Shed';
            lstOrder.add(posOrder4);

            insert lstOrder;
            
            List<Product__c> lstProduct = new List<Product__c>();
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct);
            
            Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
            objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct1.UPIID__c='123451';
            objProduct1.Supplier_Partner__c = deliveryPartner.Id;
            objProduct1.Pricing_Type__c = 'By Unit';
            objProduct1.Units_per_POS__c = 10.0;
            objProduct1.Diageo_Cost__c = 40;
            objProduct1.Outlet_Cost__c = 50;
            objProduct1.Start_Date__c = Date.Today();
            objProduct1.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct1);

            insert lstProduct;

            List<Stock__c> lstStock = new list<Stock__c>();
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.State__c = geoMap.get('State');
            lstStock.add(stock);
            
            Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
            stock1.Unique_Key__c = 'p8uf512A';
            stock1.Sales_Rep__c = salesRep.Id;
            stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock1.Type__c = 'Segment';
            stock1.Global_Segment__c = 'Hypermarket';
            stock1.State__c = null;
            lstStock.add(stock1);

            Test.startTest();
            insert lstStock;
            
            List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct1.Id, posOrder1.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Quantity__c = 2;
            lstOrderItem.add(orderItem1);
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            lstOrderItem.add(orderItem);
            insert lstOrderItem;
            
            Map<Order_Item__c,Id> orderItemMap = new Map<Order_Item__c,Id>();
            orderItemMap.put(orderItem, orderItem.Id);
            EDGE_OrderTriggerHelper.validateStockQuantity(orderItemMap);

            List<Order__c> orderListToUpdate=new List<Order__c>(); 
            EDGE_UtilityClass.stopTriggerToRun = false;
            //posOrderGroup.Status__c = 'Submitted';
            //orderListToUpdate.add(posOrderGroup);

            posOrder3.Status__c = 'Order Placed';
            orderListToUpdate.add(posOrder3);

            update orderListToUpdate;
            
            EDGE_OrderTriggerHelper.shedOrderPlace(posOrder3);
            Test.stopTest();
        }
    }
    
    
    @isTest
    public static void testStockAttach3(){
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        system.assert(testAdminUser.Id != null,'test Admin User Id should not be null'); 
        
        System.runAs(testAdminUser){
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;
            
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            
            List<User> usrList=new List<User>();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            usrList.add(salesManager);
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Email = 'divya.bansal@diageo.com';
            usrList.add(salesRep);
            insert usrList;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = true;
            insert deliveryPartner;
            
            List<Order__c> lstOrder = new List<Order__c>();
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder);
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Group__c = posOrderGroup.Id;
            posOrder1.Total_A_P_Cost__c = 15;
            posOrder1.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder1);        
            
            Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder3.Order_Group__c = posOrderGroup.Id;
            posOrder3.Total_A_P_Cost__c = 20;
            posOrder3.Status__c = 'Ready for Order';
            posOrder3.Order_Type__c = 'Shed';
            lstOrder.add(posOrder3);
            
            Order__c posOrder4 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder4.Order_Group__c = posOrderGroup.Id;
            posOrder4.Total_A_P_Cost__c = 20;
            posOrder4.Delivery_Partner__c= deliveryPartner.Id;
            posOrder4.Delivery_Location__c= 'Shed';
            lstOrder.add(posOrder4);

            insert lstOrder;
            
            List<Product__c> lstProduct = new List<Product__c>();
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct);
            
            Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
            objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct1.UPIID__c='123451';
            objProduct1.Supplier_Partner__c = deliveryPartner.Id;
            objProduct1.Pricing_Type__c = 'By Unit';
            objProduct1.Units_per_POS__c = 10.0;
            objProduct1.Diageo_Cost__c = 40;
            objProduct1.Outlet_Cost__c = 50;
            objProduct1.Start_Date__c = Date.Today();
            objProduct1.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct1);

            insert lstProduct;

            List<Stock__c> lstStock = new list<Stock__c>();
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.State__c = geoMap.get('State');
            lstStock.add(stock);
            
            Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
            stock1.Unique_Key__c = 'p8uf512A';
            stock1.Sales_Rep__c = salesRep.Id;
            stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock1.Type__c = 'Outlet';
            stock1.State__c = null;
            stock1.Outlet__c=outlet.Id;
            lstStock.add(stock1);

            Test.startTest();
            insert lstStock;

            List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct1.Id, posOrder1.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Quantity__c = 2;
            lstOrderItem.add(orderItem1);
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            lstOrderItem.add(orderItem);

            insert lstOrderItem;

            Map<Order_Item__c,Id> orderItemMap = new Map<Order_Item__c,Id>();
            orderItemMap.put(orderItem, orderItem.Id);
            EDGE_OrderTriggerHelper.validateStockQuantity(orderItemMap);
            
            List<Order__c> orderListToUpdate=new List<Order__c>(); 
            EDGE_UtilityClass.stopTriggerToRun = false;
            //posOrderGroup.Status__c = 'Submitted';
            //orderListToUpdate.add(posOrderGroup);
            
            posOrder3.Status__c = 'Order Placed';
            orderListToUpdate.add(posOrder3);
            
            update orderListToUpdate;
            
            EDGE_OrderTriggerHelper.shedOrderPlace(posOrder3);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testStockAttach4(){
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        system.assert(testAdminUser.Id != null,'test Admin User Id should not be null');
        
        System.runAs(testAdminUser){
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;
            
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            
            List<User> usrList=new List<User>();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            usrList.add(salesManager);
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Email = 'divya.bansal@diageo.com';
            usrList.add(salesRep);
            insert usrList;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = true;
            insert deliveryPartner;
            
            List<Order__c> lstOrder = new List<Order__c>();
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder);
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Group__c = posOrderGroup.Id;
            posOrder1.Total_A_P_Cost__c = 15;
            posOrder1.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder1);        
            
            Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder3.Order_Group__c = posOrderGroup.Id;
            posOrder3.Total_A_P_Cost__c = 20;
            posOrder3.Status__c = 'Ready for Order';
            posOrder3.Order_Type__c = 'Shed';
            lstOrder.add(posOrder3);
            
            Order__c posOrder4 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder4.Order_Group__c = posOrderGroup.Id;
            posOrder4.Total_A_P_Cost__c = 20;
            posOrder4.Delivery_Partner__c= deliveryPartner.Id;
            posOrder4.Delivery_Location__c= 'Shed';
            lstOrder.add(posOrder4);

            insert lstOrder;

            List<Product__c> lstProduct = new List<Product__c>();
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct);
            
            Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
            objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct1.UPIID__c='123451';
            objProduct1.Supplier_Partner__c = deliveryPartner.Id;
            objProduct1.Pricing_Type__c = 'By Unit';
            objProduct1.Units_per_POS__c = 10.0;
            objProduct1.Diageo_Cost__c = 40;
            objProduct1.Outlet_Cost__c = 50;
            objProduct1.Start_Date__c = Date.Today();
            objProduct1.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct1);

            insert lstProduct;

            List<Stock__c> lstStock = new list<Stock__c>();
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.State__c = geoMap.get('State');
            lstStock.add(stock);
            
            Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
            stock1.Unique_Key__c = 'p8uf512A';
            stock1.Sales_Rep__c = salesRep.Id;
            stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock1.Type__c = 'Outlet';
            stock1.State__c = null;
            stock1.Outlet__c=outlet.Id;
            lstStock.add(stock1);

            Test.startTest();
            insert lstStock;
            
            List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct1.Id, posOrder1.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Quantity__c = 2;
            lstOrderItem.add(orderItem1);
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            lstOrderItem.add(orderItem);
            insert lstOrderItem;
            
            Map<Order_Item__c,Id> orderItemMap = new Map<Order_Item__c,Id>();
            orderItemMap.put(orderItem, orderItem.Id);
            EDGE_OrderTriggerHelper.validateStockQuantity(orderItemMap);

            List<Order__c> orderListToUpdate=new List<Order__c>(); 
            EDGE_UtilityClass.stopTriggerToRun = false;
            //posOrderGroup.Status__c = 'Submitted';
            //orderListToUpdate.add(posOrderGroup);
            
            posOrder3.Status__c = 'Order Placed';
            orderListToUpdate.add(posOrder3);
            update orderListToUpdate;
            
            EDGE_OrderTriggerHelper.shedOrderPlace(posOrder3);
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testStockAttach5(){
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        system.assert(testAdminUser.Id != null,'test Admin User Id should not be null'); 
        
        System.runAs(testAdminUser){
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            Target_List__c targetList = EDGE_UtilityTestClass.getTargetList(countryId);
            insert targetList;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;

            EDGE_UtilityTestClass.createOrgSettings();
            Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetList.Id);
            targetLstmem.Assignment_Status__c = 'Active';
            insert targetLstmem;
            
            List<User> usrList=new List<User>();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            usrList.add(salesManager);
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Email = 'divya.bansal@diageo.com';
            usrList.add(salesRep);
            insert usrList;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = true;
            insert deliveryPartner;
            
            List<Order__c> lstOrder = new List<Order__c>();
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            posOrder.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder);
            
            Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder1.Order_Group__c = posOrderGroup.Id;
            posOrder1.Total_A_P_Cost__c = 15;
            posOrder1.Delivery_Partner__c = deliveryPartner.Id;
            lstOrder.add(posOrder1);        
            
            Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder3.Order_Group__c = posOrderGroup.Id;
            posOrder3.Total_A_P_Cost__c = 20;
            posOrder3.Status__c = 'Ready for Order';
            posOrder3.Order_Type__c = 'Shed';
            lstOrder.add(posOrder3);
            
            Order__c posOrder4 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder4.Order_Group__c = posOrderGroup.Id;
            posOrder4.Total_A_P_Cost__c = 20;
            posOrder4.Delivery_Partner__c= deliveryPartner.Id;
            posOrder4.Delivery_Location__c= 'Shed';
            lstOrder.add(posOrder4);
            insert lstOrder;
            
            List<Product__c> lstProduct = new List<Product__c>();
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct);
            
            Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
            objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct1.UPIID__c='123451';
            objProduct1.Supplier_Partner__c = deliveryPartner.Id;
            objProduct1.Pricing_Type__c = 'By Unit';
            objProduct1.Units_per_POS__c = 10.0;
            objProduct1.Diageo_Cost__c = 40;
            objProduct1.Outlet_Cost__c = 50;
            objProduct1.Start_Date__c = Date.Today();
            objProduct1.POS_Item_Short_Description__c = 'Good';
            lstProduct.add(objProduct1);
            insert lstProduct;

            List<Stock__c> lstStock = new list<Stock__c>();
            Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, salesRep.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.State__c = geoMap.get('State');
            lstStock.add(stock);
            
            Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, objProduct1.Id, salesRep.Id);
            stock1.Unique_Key__c = 'p8uf512A';
            stock1.Sales_Rep__c = salesRep.Id;
            stock1.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock1.Type__c = 'Outlet (Target List)';
            stock1.State__c = null;
            stock1.Target_List__c=targetList.Id;
            lstStock.add(stock1);

            Test.startTest();
            insert lstStock;
            
            List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct1.Id, posOrder1.Id);
            orderItem1.Type__c = 'Warehouse';
            orderItem1.Quantity__c = 2;
            lstOrderItem.add(orderItem1);
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            lstOrderItem.add(orderItem);
            insert lstOrderItem;
            
            Map<Order_Item__c,Id> orderItemMap = new Map<Order_Item__c,Id>();
            orderItemMap.put(orderItem, orderItem.Id);
            EDGE_OrderTriggerHelper.validateStockQuantity(orderItemMap);
            
            List<Order__c> orderListToUpdate=new List<Order__c>(); 
            EDGE_UtilityClass.stopTriggerToRun = false;
            //posOrderGroup.Status__c = 'Submitted';
            //orderListToUpdate.add(posOrderGroup);
            
            posOrder3.Status__c = 'Order Placed';
            orderListToUpdate.add(posOrder3);
            update orderListToUpdate;
            
            Test.stopTest();
        }
    }

    @isTest
    public static void changeOrderStatus2(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        system.assert(testAdminUser.Id != null,'test Admin User Id should not be null'); 
        //System.debug('@@limit -1-->'+Limits.getQueries());
        System.runAs(testAdminUser){
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;        
            system.debug(LoggingLevel.Debug,('market '+market));
            //System.debug('@@limit -2-->'+Limits.getQueries());
            
            EDGE_UtilityTestClass.createOrgSettings();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            //System.debug('@@limit -3-->'+Limits.getQueries());
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Australia';
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'AU';
            outlet.ShippingCountry = 'Australia';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outlet;
            
            List<User> usrList=new List<User>();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
            salesManager.Available_Countries__c = 'AU';
            usrList.add(salesManager);  
            //System.assert(salesManager.Id!=null);
            System.debug(LoggingLevel.Debug,('@@limit -5-->'+Limits.getQueries()));
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Email = 'divya.bansal@diageo.com';
            usrList.add(salesRep); 
            //System.assert(salesRep.Id!=null);
            insert usrList;
            System.debug(LoggingLevel.Debug,('@@limit -6-->'+Limits.getQueries()));
            test.startTest();
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            //System.debug('@@limit -7-->'+Limits.getQueries());
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = true;
            insert deliveryPartner;
            
            Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGroup.Total_A_P_Cost__c = 20;
            insert posOrderGroup;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGroup.Id;
            posOrder.Total_A_P_Cost__c = 20;
            posOrder.Delivery_Partner__c = null;
            posOrder.Order_Type__c=EDGE_Constant.ORDER_SHED;
            posOrder.Status__c='Awaiting Approval';
            insert posOrder;
            posOrder.Status__c='Ready For Order';
            update posOrder;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Diageo_Cost__c = 100;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct; 
            System.debug(LoggingLevel.Debug,('@@limit -12-->'+Limits.getQueries()));
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder.Id);
            orderItem.Type__c = 'Warehouse';
            orderItem.Quantity__c = 2;
            insert orderItem;
            System.debug(LoggingLevel.Debug,('@@limit -13-->'+Limits.getQueries()));
            test.stopTest();
        }
    }
    
    //ES20-13264
    @isTest
    public static void validatePromoOrderTest(){
        String userId = '';
        String outletId = '';
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'ES';
        insert testAdminUser;
        system.assert(testAdminUser.Id != null,'test Admin User Id should not be null'); 
        
        System.runAs(testAdminUser){
        
            EDGE_UtilityTestClass.createOrgSettings();
            Business_Role__c brtest1 = EDGE_UtilityTestClass.getBusinessRole();
            brtest1.Name='Sales Representative';
            brtest1.Country__c = countryId;
            brtest1.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            Insert brtest1;
            //Setup User 
            User userDetails  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
            userDetails.Available_Countries__c='ES';
            userDetails.Business_Role_Id__c = brtest1.Id;
            insert userDetails;
            userId = userDetails.id;
            
            User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(userDetails, brtest1);
            insert ubrtest1;
            
            Org_Setting__c orgSetting=[Select Id,Run_Validation_Rules__c from Org_Setting__c];
            orgSetting.Run_Validation_Rules__c=false;
            update orgSetting;
            
            //creation of custom Territory record
            Test.startTest();
            Territory__c terr = new Territory__c();
            terr.Territory_Type__c = 'Service';
            terr.Primary_Sales_Rep__c = userId;
            terr.Country__c = countryId;
            terr.RecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
            insert terr;
            
            //creation of custom Territory record
            Territory_Member__c terrMem = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(userDetails.Id,terr.Id);
            terrMem.Start_Date__c=system.today().AddDays(-1);
            insert terrMem;
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[ES]';
            insert pickupOption;
            
            //Outlet Setup
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = 'Los Blancoas Cafe';
            outlet.BillingCity = 'Madrid';
            outlet.BillingCountry = 'Spain';
            outlet.BillingState = 'Madrid';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'ES';
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert  outlet;
            
            outletId = outlet.id;
            
            Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
            wholesaler.ShippingCountry = 'Spain';
            insert wholesaler;
            
            //Outlet Member Setup
            Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, userDetails.Id, 'Primary'); 
            insert omTest;
            
            //creation of OutletTerritory Record
            Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
            outletTerritory.Territory__c = terr.id;
            outletTerritory.Outlet__c = outlet.id;
            insert outletTerritory; 
            
            List<Promotion_Master__c> promoList= new List<Promotion_Master__c>();
            
            ///Setup Of Promotion which is available for Outlet only within limit range
            String priceIncentiveId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Price Incentive Order').getRecordTypeId();
            Promotion_Master__c promo1 = EDGE_UtilityTestClass.getPromotionMasterRec(priceIncentiveId);
            promo1.name = 'PROMO 1' ;
            promoList.add(promo1);
           
            ///Setup Of Promotion which is available for Territory and outlet
            String freeProductId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
            Promotion_Master__c promo2 = EDGE_UtilityTestClass.getPromotionMasterRec(freeProductId);
            promo2.Total_Order_quantity_for_Free_Product__c=5;
            promo2.name = 'PROMO 2' ;
            promoList.add(promo2);
            
            ///Setup Of Promotion which is available for Territory & Outlet but exceeded the limit for outlet
            Promotion_Master__c promo3 = EDGE_UtilityTestClass.getPromotionMasterRec(freeProductId);
            promo3.name = 'PROMO 3' ;
            promo3.Total_Order_quantity_for_Free_Product__c=5;
            promoList.add(promo3);
            
            ///Setup Of Promotion which is available for Territory But exceeded the limit
            Promotion_Master__c promo4 = EDGE_UtilityTestClass.getPromotionMasterRec(priceIncentiveId);
            promo4.name = 'PROMO 4' ;
            promoList.add(promo4);
            
            insert promoList;
    
            List<Outlet_Promotion__c> outpromoList= new List<Outlet_Promotion__c>();
            //Creation Of Outlet Promotion 
            Outlet_Promotion__c outletPromo1 = EDGE_UtilityTestClass.getOutletPromotionRec(promo1.id, outlet.id, 8, 20);
            outpromoList.add(outletPromo1);
            
           //Creation Of Outlet Promotion 
            Outlet_Promotion__c outletPromo = EDGE_UtilityTestClass.getOutletPromotionRec(promo2.id, outlet.id, 8, 20);
            outpromoList.add(outletPromo);
            
            //Creation Of Outlet Promotion 
            Outlet_Promotion__c outletPromo2 = EDGE_UtilityTestClass.getOutletPromotionRec(promo3.id, outlet.id, 19, 20);
            outpromoList.add(outletPromo2);
            
            insert outpromoList;
            system.debug(LoggingLevel.Debug,(' @@limit -3-->'+Limits.getQueries()));
            //Creation Of Territory Promotion 
            Territory_Promotion__c terrPromo1 = EDGE_UtilityTestClass.getTerritoryPromotionRec(promo2.id, terr.id, 10, 20);
            insert terrPromo1;
             
            
            //Creation Of Territory Promotion 
            Territory_Promotion__c terrPromo2 = EDGE_UtilityTestClass.getTerritoryPromotionRec(promo3.id, terr.id, 10, 20);
            insert terrPromo2;
            
            //Creation Of Territory Promotion 
            Territory_Promotion__c terrPromo3 = EDGE_UtilityTestClass.getTerritoryPromotionRec(promo4.id, terr.id, 20, 20);
            insert terrPromo3;
    
            Order__c trnsfrOrder = EDGE_UtilityTestClass.getTrnsfrOrder(userDetails.id, outlet.Id, wholesaler.Id);
            trnsfrOrder.Status__c = 'Draft';
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder;
            
            Order__c trnsfrOrder2 = EDGE_UtilityTestClass.getTrnsfrOrder(userDetails.id, outlet.Id, wholesaler.Id);
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Comments__c = 'hello';
            trnsfrOrder2.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder2;
            
            Order__c trnsfrOrder3 = EDGE_UtilityTestClass.getTrnsfrOrder(userDetails.id, outlet.Id, wholesaler.Id);
            trnsfrOrder3.Status__c = 'Draft';
            trnsfrOrder3.Comments__c = 'hello';
            trnsfrOrder3.Is_Promo_Transfer_Order__c=true;
            insert trnsfrOrder3;
            
            List<Product__c> prodList=new List<Product__c>();
            Product__c testProduct2 = EDGE_UtilityTestClass.getProd();
            testProduct2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct2.Product_Full_Name__c=  'Baileys';
            testProduct2.UPIID__c=  '12567';
            //testProduct.IsActive__c = True;
            testProduct2.name = 'Baileys';
            testProduct2.Start_Date__c = Date.today();
            testProduct2.Expiry_Date__c = Date.today().addDays(2);
            prodList.add(testProduct2);
            
            Product__c testProduct3 = EDGE_UtilityTestClass.getProd();
            testProduct3.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct3.Product_Full_Name__c=  'JW';
            testProduct3.UPIID__c=  '12569';
            //testProduct.IsActive__c = True;
            testProduct3.name = 'JW';
            testProduct3.Start_Date__c = Date.today();
            testProduct3.Expiry_Date__c = Date.today().addDays(3);
            prodList.add(testProduct3);
            
            Product__c testProduct4 = EDGE_UtilityTestClass.getProd();
            testProduct4.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct4.Product_Full_Name__c=  'JW';
            testProduct3.UPIID__c=  '12569';
            //testProduct.IsActive__c = True;
            testProduct4.name = 'JW';
            testProduct4.Start_Date__c = Date.today();
            testProduct4.Expiry_Date__c = Date.today().addDays(3);
            prodList.add(testProduct4);
            
            insert prodList;
            
            List<Promotion_Product__c> promProdList=new List<Promotion_Product__c>();
            //String purchasableId = Promotion_Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Purchasable Product').getRecordTypeId();
            Promotion_Product__c promoprod = new Promotion_Product__c();
            promoprod.Promotion__c  = promo2.id;
            promoprod.Product__c   = testProduct2.id;
            promProdList.add(promoprod);
            
            Promotion_Product__c promoprod2 = new Promotion_Product__c();
            promoprod2.Promotion__c  = promo4.id;
            promoprod2.Product__c   = testProduct3.id;
            promProdList.add(promoprod2);
            
            Promotion_Product__c promoprod3 = new Promotion_Product__c();
            promoprod3.Promotion__c  = promo1.id;
            promoprod3.Product__c   = testProduct4.id;
            promProdList.add(promoprod3);
            
            insert promProdList;
            
            List<Order_Item__c> ordList=new List<Order_Item__c>();
            Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(testProduct2.Id, trnsfrOrder.Id);
            orderItem3.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem3.Quantity__c = 40;
            orderItem3.Delivered_Quantity__c = 21;
            orderItem3.Status__c = 'Draft';
            //orderItem3.Selected_UoM__c = 'BTL';
            orderItem3.Promotion_Product__c = promoprod.id;
            
            ordList.add(orderItem3);
            
            Order_Item__c orderItem4 = EDGE_UtilityTestClass.getOrderItem(testProduct3.Id, trnsfrOrder2.Id);
            orderItem4.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem4.Quantity__c = 40;
            orderItem4.Delivered_Quantity__c = 21;
            orderItem4.Status__c = 'Draft';
            //orderItem4.Selected_UoM__c = 'BTL';
            orderItem4.Promotion_Product__c = promoprod2.id;
            
            ordList.add(orderItem4);
            
            Order_Item__c orderItem5 = EDGE_UtilityTestClass.getOrderItem(testProduct4.Id, trnsfrOrder3.Id);
            orderItem5.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem5.Quantity__c = 40;
            orderItem5.Delivered_Quantity__c = 21;
            orderItem5.Status__c = 'Draft';
            //orderItem5.Selected_UoM__c = 'BTL';
            orderItem5.Promotion_Product__c = promoprod3.id;
            
            ordList.add(orderItem5);
            insert ordList;
    
            Test.stopTest();
            List<Order__c> ordToUpdate=new List<Order__c>();
            
            trnsfrOrder.Status__c = 'Submitted';
            ordToUpdate.add(trnsfrOrder);
    
             trnsfrOrder2.Status__c = 'Submitted';
            ordToUpdate.add(trnsfrOrder2);
            
            trnsfrOrder3.Status__c = 'Submitted';
            ordToUpdate.add(trnsfrOrder3);
            update ordToUpdate;
        }
    }
}