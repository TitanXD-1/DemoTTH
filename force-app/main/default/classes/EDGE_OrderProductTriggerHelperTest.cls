/**
* @description: EDGE_OrderProductTriggerHelperTest

* @History:

* 1.0        Manikant Prasad      26/07/2019      Test Class for EDGE_OrderProductTriggerHelper
* 1.1		 Aparajita            22/06/2022      ES20-12674(Method:testPOSStatusSyncForOther) 
* 1.2        Joshraj Sen          08/04/2024      152305 SCA Fix
**/

@isTest
public class EDGE_OrderProductTriggerHelperTest {
    
    @isTest
    public static void testupdateParentOrderStatus(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
        marketSetting.Threshold_Format__c = 'Percent';
        insert marketSetting;
        
        EDGE_UtilityTestClass.createOrgSettings();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'User is Added');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'User is Added');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        List<Account> accList = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        accList.add(outlet);
        //insert outlet;
        
        Account shedAccount11 =  EDGE_UtilityTestClass.getShedRecord();
        accList.add(shedAccount11);
        insert accList;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;        
        
        Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
        posOrder.Order_Type__c = 'Shed';
        posOrder.Status__c = 'Approval In Progress';
        posOrder.Total_A_P_Cost__c = 100;
        posOrder.Delivery_Location__c = 'Shed';
        insert posOrder;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        insert testProduct;
        system.assert(testProduct.id != null,'Product is Added');
        
        Order_item__c ordLineItem = new Order_item__c();
        ordLineItem.Order__c = posOrder.id;
        ordLineItem.Product__c = testProduct.id;
        ordLineItem.Status__c = 'Submitted';
        ordLineItem.Quantity__c = 100;
        insert ordLineItem ;
        //ordLineItem.Status__c = ' Item Missing';
        //update ordLineItem ;
        
        Test.startTest();
        
        
        Id freeGoodOrderTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c freeGoodOrder = new Order__C();
        freeGoodOrder.Order_Type__c = 'Shed';
        freeGoodOrder.Account__c = outlet.id;
        freeGoodOrder.Status__c = 'Draft';
        freeGoodOrder.Total_A_P_Cost__c = 100;
        freeGoodOrder.Delivery_Location__c = 'Shed';
        freeGoodOrder.RecordTypeId = freeGoodOrderTypeId;
        freeGoodOrder.Shed__c = shedAccount11.id;
        insert freeGoodOrder;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=testProduct.Id;
        marketassort.Market_Assortment__c=countryId;
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        //Insert shed stock record 
        Id shedStockRecTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        Stock__c stockRec = new Stock__c();
        stockRec.RecordTypeId = shedStockRecTypeId;
        stockRec.Allocated__c = 15.0;
        stockRec.Consumed_Stock__c = 10.0;
        stockRec.Country__c = countryId;
        stockRec.Product__c = testProduct.id;
        //stockRec.Unique_Key__c = '12345-78978';
        stockRec.Shed__c = shedAccount11.id;
        stockRec.Market_Assortment_Product__c = marketassort.id;
        insert stockRec;
        stockRec.Allocated__c = 25.0;
        update stockRec;
        
        
        Id freeGoodOrderRecTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order_item__c ordLineItem3 = new Order_item__c();
        ordLineItem3.Order__c = freeGoodOrder.id;
        ordLineItem3.Product__c = testProduct.id;
        ordLineItem3.Status__c = 'Draft';
        ordLineItem3.Quantity__c = 100;
        ordLineItem3.RecordTypeId = freeGoodOrderRecTypeId;
        insert ordLineItem3 ;
        
        freeGoodOrder.Status__c = 'Delivered to Customer';
        update freeGoodOrder;
        ordLineItem3.Status__c = 'Delivered to Customer';
        update ordLineItem3 ;
        
        
        Order_item__c ordLineItem4 = new Order_item__c();
        ordLineItem4.Order__c = posOrder.id;
        ordLineItem4.Product__c = testProduct.id;
        ordLineItem4.Status__c = 'Delivered to Customer';
        ordLineItem4.Quantity__c = 100;
        ordLineItem4.RecordTypeId = freeGoodOrderRecTypeId;
        insert ordLineItem4 ;
        ordLineItem4.Status__c = 'Cancelled';
        update ordLineItem4 ;
        
        
        Order_item__c ordLineItem1 = new Order_item__c();
        ordLineItem1.Order__c = posOrder.id;
        ordLineItem1.Product__c = testProduct.id;
        ordLineItem1.Status__c = 'Delivered to Customer';
        ordLineItem1.Quantity__c = 100;
        insert ordLineItem1 ;
        ordLineItem1.Status__c = 'Delivered to customer';
        update ordLineItem1;
        
        delete ordLineItem;
        Test.stopTest();
    }
    
    
    @isTest
    public static void testupdateStockAllocation(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        /* Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
marketSetting.Threshold_Format__c = 'Percent';
insert marketSetting;*/
        
        EDGE_UtilityTestClass.createOrgSettings();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'User is Added');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'User is Added');
        
        /* Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
pickupOption.Name = 'Gold[AU]';
insert pickupOption;

Account outlet = EDGE_UtilityTestClass.getOutletRecord();
outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
insert outlet;*/
        Account shedAccount =  EDGE_UtilityTestClass.getShedRecord();
        insert shedAccount;
        
        /*String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
insert objContract;*/
        Id stockAdjOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        Id stockAdjOrderItemTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        
        Order__c stockAdjustmentOrder = new Order__c();
        stockAdjustmentOrder.RecordTypeId = stockAdjOrderRecTypeId;
        stockAdjustmentOrder.Account__c = shedAccount.Id;
        stockAdjustmentOrder.Sales_Representative__c = salesRep.Id;
        stockAdjustmentOrder.Status__c = 'Draft';
        stockAdjustmentOrder.Order_Type__c = 'Shed';
        insert stockAdjustmentOrder;
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        insert testProduct;
        system.assert(testProduct.id != null,'Product is Added');
        
        
        Test.startTest();
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=testProduct.Id;
        marketassort.Market_Assortment__c=countryId;
        marketassort.ECM_INTO_Material__c = 9;
        insert marketassort;
        
        //Insert shed stock record 
        Id shedStockRecTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        Stock__c stockRec = new Stock__c();
        stockRec.RecordTypeId = shedStockRecTypeId;
        stockRec.Allocated__c = 15.0;
        stockRec.Consumed_Stock__c = 10.0;
        stockRec.Country__c = countryId;
        stockRec.Shed__c = shedAccount.id;
        stockRec.Market_Assortment_Product__c = marketassort.id;
        insert stockRec;
        stockRec.Allocated__c = 25.0;
        update stockRec;
        
        Order_item__c ordLineItem3 = new Order_item__c();
        ordLineItem3.Order__c = stockAdjustmentOrder.id;
        ordLineItem3.Product__c = testProduct.id;
        ordLineItem3.Status__c = 'Draft';
        ordLineItem3.Quantity__c = 100;
        ordLineItem3.RecordTypeId = stockAdjOrderItemTypeId;
        insert ordLineItem3 ;
        
        stockAdjustmentOrder.Status__c = 'Stock Adjustment Reported';
        update stockAdjustmentOrder;
        
        Test.stopTest();
    }
    
    @isTest
    public static void testPOSStatusSyncForOther(){
        
        
        User admin = EDGE_UtilityTestClass.runAsUser('admin','System Administrator');
        admin.Available_Countries__c = 'AU';
        insert admin;  
        
        System.runAs(admin){
            Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
            Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
            marketSetting.Threshold_Format__c = 'Percent';
            insert marketSetting;
            
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = admin.id;
            insert salesRep; 
            System.assert(salesRep.Id!=null,'User is Added');
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            System.debug(LoggingLevel.Debug,'@@@'+limits.getQueries());
            
            List<Account> accList = new List<Account>();
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            accList.add(outlet);
            //insert outlet;
            
            Account shedAccount =  EDGE_UtilityTestClass.getShedRecord();
            accList.add(shedAccount);
            insert accList;
            EDGE_UtilityTestClass.createOrgSettings();

            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            insert objContract;
            
            Order__c posOrderGrp = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
            posOrderGrp.Order_Type__c = 'Shed';
            posOrderGrp.Status__c = 'Order Placed';
            posOrderGrp.Total_A_P_Cost__c = 100;
            posOrderGrp.Delivery_Location__c = 'Other';
            insert posOrderGrp;
            
            Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
            posOrder.Order_Group__c = posOrderGrp.Id;
            posOrder.Order_Type__c = 'Shed';
            posOrder.Status__c = 'Order Placed';
            posOrder.Total_A_P_Cost__c = 100;
            posOrder.Delivery_Location__c = 'Other';
            insert posOrder;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            insert deliveryPartner;
            
            Product__c testProduct = EDGE_UtilityTestClass.getProd();
            testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            testProduct.Supplier_Partner__c= deliveryPartner.Id;
            testProduct.Delivery_Partner__c = deliveryPartner.Id;
            insert testProduct;
            
            Order_item__c ordLineItem = new Order_item__c();
            ordLineItem.Order__c = posOrder.id;
            ordLineItem.Product__c = testProduct.id;
            ordLineItem.Status__c = 'Order Placed';
            ordLineItem.Quantity__c = 100;
            insert ordLineItem ;
            
            ordLineItem.Status__c = 'Delivered to Customer';
            update ordLineItem;
            System.debug(LoggingLevel.Debug,'@@@'+limits.getQueries());
            
        }
    }
}