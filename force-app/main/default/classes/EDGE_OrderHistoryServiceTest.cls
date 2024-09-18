/*
Name: EDGE_OrderHistoryServiceTest

Req: This is the test class for EDGE_OrderHistoryService,EDGE_OrderHistoryController,EDGE_OrderHistoryWrapper
History                                                                                                                        
VERSION   AUTHOR              DATE            DETAIL
1.0	   Swaraj Samanta		  26/08/2022	  ES20-10280 - Existing Custom Service to send Order History along with Promotion Product detailsto Mobile

*/
@isTest
public class EDGE_OrderHistoryServiceTest {
    @isTest
    public static void testOrderHistoryService(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        string ordertype =('POS');
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/OrderHistoryService?userid=';
        
        requri = requri+ String.valueOf(u.Id);
        requri = requri+ '&ordertype='+ordertype;
        req.requestUri =requri;
        req.params.put('userid', u.Id); 
        req.params.put('ordertype',ordertype); 
        
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        createData(u);
        EDGE_OrderHistoryService.doGet();
        List<EDGE_OrderHistoryWrapper> orderHistoryWrapper = EDGE_OrderHistoryService.doGet();
        system.assert(orderHistoryWrapper != null,'order History Wrapper should not be null');
        
        Test.stopTest();     
    }
    
    public static void createData(User usrObj){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        insert  outlet;
        
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, usrObj.Id, 'Primary'); 
        insert omTest;
        
        Market_Setting__c marketSettingRec = EDGE_UtilityTestClass.getMarketSetting(countryId); 
        marketSettingRec.Order_History_Number__c = 3;
        marketSettingRec.Transfer_Order_History_Number__c = 2;
        marketSettingRec.Free_Goods_History_Number__c = 2;
        insert marketSettingRec;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(usrObj.Id, outlet.Id, objContract.Id);
        posOrderGroup.Total_A_P_Cost__c = 500;
        posOrderGroup.RecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order Group').getRecordTypeId();
        posOrderGroup.Status__c = 'Shed to customer';
        insert posOrderGroup;
             
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        insert deliveryPartner;
        
        Order__c posOrderChildNonSplit = EDGE_UtilityTestClass.getPOSOrder(usrObj.Id, outlet.Id, objContract.Id);
        posOrderChildNonSplit.Order_Type__c = 'Shed';
        posOrderChildNonSplit.Status__c = 'Shed to customer';
        posOrderChildNonSplit.Total_A_P_Cost__c = 100;
        //posOrderParent.Order_Group__c = posOrderGroup.id;
        posOrderChildNonSplit.Delivery_Location__c = 'Shed';
        posOrderChildNonSplit.RecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        insert posOrderChildNonSplit;
        
        Order__c posOrderChildSplit = EDGE_UtilityTestClass.getPOSOrder(usrObj.Id, outlet.Id, objContract.Id);
        posOrderChildSplit.Order_Type__c = 'Shed';
        posOrderChildSplit.Status__c = 'Shed to customer';
        posOrderChildSplit.Total_A_P_Cost__c = 100;
        posOrderChildSplit.Delivery_Location__c = 'Shed';
        posOrderChildSplit.Order_Group__c = posOrderGroup.Id;
        posOrderChildSplit.RecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        insert posOrderChildSplit;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        insert objProduct;
        
        Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrderChildSplit.Id);
        orderItem1.Type__c = 'Warehouse';
        orderItem1.Quantity__c = 80;
        insert orderItem1; 
        
        Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrderChildNonSplit.Id);
        orderItem2.Type__c = 'Warehouse';
        orderItem2.Quantity__c = 80;
        insert orderItem2;
        
        Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrderChildNonSplit.Id);
        orderItem3.Type__c = 'Warehouse';
        orderItem3.Quantity__c = 80;
        insert orderItem3;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
              
    }
    @isTest
    public static void testOrderHistoryServiceForFreeGoods(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        string ordertype =('Free Goods');
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/OrderHistoryService?userid=';
        
        requri = requri+ String.valueOf(u.Id);
        requri = requri+ '&ordertype='+ordertype;
        req.requestUri =requri;
        req.params.put('userid', u.Id); 
        req.params.put('ordertype',ordertype); 
        
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        createData1(u);
        EDGE_OrderHistoryService.doGet();
        List<EDGE_OrderHistoryWrapper> orderHistoryWrapper = EDGE_OrderHistoryService.doGet();
        system.assert(orderHistoryWrapper != null,'order History Wrapper should not be null');
        
        Test.stopTest();     
    } 
    
    public static void createData1(User usrObj){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        insert  outlet;
        
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, usrObj.Id, 'Primary'); 
        insert omTest;
        
        Market_Setting__c marketSettingRec = EDGE_UtilityTestClass.getMarketSetting(countryId); 
        marketSettingRec.Order_History_Number__c = 3;
        marketSettingRec.Transfer_Order_History_Number__c = 2;
        marketSettingRec.Free_Goods_History_Number__c = 2;
        insert marketSettingRec;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        insert deliveryPartner;
        

        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        insert objProduct;
        
        Order__c freeGoodsOrder = new Order__c();
		String freeGoodsRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();         
        freeGoodsOrder.RecordTypeId = freeGoodsRecordTypeId;
        freeGoodsOrder.Account__c = outlet.Id;
        freeGoodsOrder.Total_A_P_Cost__c = 100;
        freeGoodsOrder.Status__c = 'Order Placed';
        freeGoodsOrder.Total_Freight_Cost__c = 1000;
        freeGoodsOrder.Delivery_Partner__c =deliveryPartner.Id;
        
        insert freeGoodsOrder;
        
        Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, freeGoodsOrder.Id);
        orderItem1.Type__c = 'Warehouse';
        orderItem1.Quantity__c = 80;
        insert orderItem1; 
        
        Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, freeGoodsOrder.Id);
        orderItem2.Type__c = 'Warehouse';
        orderItem2.Quantity__c = 80;
        insert orderItem2;
        
        Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, freeGoodsOrder.Id);
        orderItem3.Type__c = 'Warehouse';
        orderItem3.Quantity__c = 80;
        insert orderItem3;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
        
       
    } 
     @isTest
    public static void testOrderHistoryServiceForTransferOrder(){
        
        User user  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert user;
        string ordertype =('Transfer Order');
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/OrderHistoryService?userid=';
        
        requri = requri+ String.valueOf(user.Id);
        requri = requri+ '&ordertype='+ordertype;
        req.requestUri =requri;
        req.params.put('userid', user.Id); 
        req.params.put('ordertype',ordertype); 
        
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        createDataForTransferOrder(user);
        EDGE_OrderHistoryService.doGet();
        List<EDGE_OrderHistoryWrapper> orderHistoryWrapper = EDGE_OrderHistoryService.doGet();
        system.assert(orderHistoryWrapper != null,'order History Wrapper should not be null');
        
        Test.stopTest();     
    }
    
    public static void createDataForTransferOrder(User usrObj){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        insert  outlet;
        
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, usrObj.Id, 'Primary'); 
        insert omTest;
        
        Market_Setting__c marketSettingRec = EDGE_UtilityTestClass.getMarketSetting(countryId); 
        marketSettingRec.Order_History_Number__c = 3;
        marketSettingRec.Transfer_Order_History_Number__c = 2;
        marketSettingRec.Free_Goods_History_Number__c = 2;
        insert marketSettingRec;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        insert deliveryPartner;
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        insert objProduct;
        
        Order__c transferOrder = new Order__c();
		String transferOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();         
        transferOrder.RecordTypeId = transferOrderRecordTypeId;
        transferOrder.Account__c = outlet.Id;
        transferOrder.Total_A_P_Cost__c = 100;
        transferOrder.Status__c = 'Order Placed';
        transferOrder.Total_Freight_Cost__c = 1000;
        transferOrder.Delivery_Partner__c =deliveryPartner.Id;
        insert transferOrder;
        
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();
        Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, transferOrder.Id);
        orderItem1.Type__c = 'Warehouse';
        orderItem1.Quantity__c = 80;
        orderItemList.add(orderItem1);
        
        Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, transferOrder.Id);
        orderItem2.Type__c = 'Warehouse';
        orderItem2.Quantity__c = 80;
        orderItemList.add(orderItem2);
        
        Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, transferOrder.Id);
        orderItem3.Type__c = 'Warehouse';
        orderItem3.Quantity__c = 80;
        orderItemList.add(orderItem3);
        insert orderItemList;
        

        Order__c transferOrder1 = new Order__c();
        transferOrder1.RecordTypeId = transferOrderRecordTypeId;
        transferOrder1.Account__c = outlet.Id;
        transferOrder1.Total_A_P_Cost__c = 100;
        transferOrder1.Status__c = 'Order Placed';
        transferOrder1.Total_Freight_Cost__c = 1000;
        transferOrder1.Delivery_Partner__c =deliveryPartner.Id;
        transferOrder1.Is_Promo_Transfer_Order__c = true;
        insert transferOrder1;
        
        List<Product__c> productList = new List<Product__c>();
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        testProduct.Supplier_Partner__c= deliveryPartner.Id;
        testProduct.Start_Date__c = Date.today();
        testProduct.UPIID__c = '3213';
        testProduct.Product_Code__c='test1234';
        testProduct.SAP_IO_Number__c='Sample product';
        testProduct.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
        productList.add(testProduct);       
        
        Product__c testProduct2 = EDGE_UtilityTestClass.getProd();
        testProduct2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        testProduct2.Product_Full_Name__c=  'Baileys';
        testProduct2.UPIID__c=  '12567';
        testProduct2.name = 'Baileys';
        testProduct2.Start_Date__c = Date.today();
        testProduct2.Expiry_Date__c = testProduct2.Start_Date__c.addDays(2);
        testProduct2.UPIID__c = '32132';
        testProduct2.Product_Code__c='test12345';
        testProduct2.SAP_IO_Number__c='Sample product1';
        productList.add(testProduct2);
        insert productList;
        
        
          ///Setup Of Promotion which is available for Outlet only within limit range
        String priceIncentiveId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Price Incentive Order').getRecordTypeId();
        Promotion_Master__c promo1 = EDGE_UtilityTestClass.getPromotionMasterRec(priceIncentiveId);
        promo1.name = 'PROMO 1' ;
        insert promo1;
        
        
         String purchasableId = Promotion_Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Purchasable Product').getRecordTypeId();
         ///Setup Of Promotion which is available for Outlet only within limit range
        List<Promotion_Product__c> promoprodList = new List<Promotion_Product__c>();
        Promotion_Product__c promoprod = new Promotion_Product__c();
        promoprod.Promotion__c  = promo1.id;
        promoprod.Product__c   = testProduct.id;
        promoprod.RecordTypeId = purchasableId;
        promoprodList.add(promoprod);
        
        Promotion_Product__c promoprod1 = new Promotion_Product__c();
        promoprod1.Promotion__c  = promo1.id;
        promoprod1.Product__c   = testProduct2.id;
        promoprod1.RecordTypeId = purchasableId;
        promoprodList.add(promoprod1);
        insert promoprodList;
        
        orderItemList.clear();
        Order_Item__c orderItempromo1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, transferOrder1.Id);
        orderItempromo1.Type__c = 'Warehouse';
        orderItempromo1.Quantity__c = 80;
        orderItempromo1.Promotion_Product__c = promoprod.id;
        orderItempromo1.Product__c = testProduct.id;
        orderItemList.add(orderItempromo1);
        
        Order_Item__c orderItempromo2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, transferOrder1.Id);
        orderItempromo2.Type__c = 'Warehouse';
        orderItempromo2.Quantity__c = 80;
        orderItempromo2.Promotion_Product__c = promoprod1.id;
        orderItempromo2.Product__c = testProduct2.id;
        orderItemList.add(orderItempromo2);
        insert orderItemList;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
    }
}