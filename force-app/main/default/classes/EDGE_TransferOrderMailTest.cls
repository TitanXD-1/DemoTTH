/*
* @Description: EDGE_TransferOrderMailTest

* @Purpose: Test class of EDGE_TransferOrderStatusHelper

* @History:                                                         

* @VERSION   	AUTHOR                DATE              DETAIL
	1.0			Doman Murmu			10/07/2023			301191
**/

@isTest
public class EDGE_TransferOrderMailTest {
    
    
    @isTest
    public static void testGetTransferOrderDetails(){
        
        List<User> userList = new List<User>();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesMan1','Sales Manager');
        salesManager.Available_Countries__c = 'ES';
        userList.add(salesManager) ;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'ES';
        salesRep.Email = 'swaraj.samantal@diageo.com';
        userList.add(salesRep);
        
        
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'ES';
        userList.add(testAdminUser);
        insert userList;
        salesRep.ManagerId = salesManager.id;
        update salesRep;
        System.assert(salesRep.ManagerId!=Null, 'Sales Manager');
        
        System.runAs(testAdminUser){
            EDGE_UtilityTestClass.createOrgSettings();
			Id countryId= EDGE_UtilityTestClass.setupCountrySpain('ES');
            Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
            orgSetting.Run_Triggers__c=false;
        	update orgSetting;
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[ES]';
            insert pickupOption;
             System.debug(LoggingLevel.Debug,'0.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            Test.startTest(); 
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;
            
            
            List<Account> accList = new List<Account>();
         
            System.debug(LoggingLevel.Debug,'1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
           
           Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
             accList.add(wholesaler);
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Spain';
            outlet.BillingState = 'Madrid';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'ES';
            outlet.Country__c = countryId;
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            accList.add(outlet);
            insert accList;
           	Map<Id, Account> shedToOrderMap = new Map<Id, Account>();
            shedToOrderMap.put(salesRep.id,outlet);
            
           	System.debug(LoggingLevel.Debug,'2.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            deliveryPartner.Batch_Notification__c = false ;
            insert deliveryPartner;
            
 
            List<Product__c> productList = new List<Product__c>();
            Product__c testProduct = EDGE_UtilityTestClass.getProd();
            testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            testProduct.Supplier_Partner__c= deliveryPartner.Id;
            testProduct.Start_Date__c = Date.today();
            testProduct.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
            testProduct.Pricing_Type__c = 'By Size';
            productList.add(testProduct);
            
            System.debug(LoggingLevel.Debug,'3.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            Product__c testProduct2 = EDGE_UtilityTestClass.getProd();
            testProduct2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct2.Product_Full_Name__c=  'Baileys';
            testProduct2.UPIID__c=  '12567';
            testProduct2.name = 'Baileys';
            testProduct2.Start_Date__c = Date.today();
            testProduct2.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
            productList.add(testProduct2);
            
            Product__c testProduct3 = EDGE_UtilityTestClass.getProd();
            testProduct3.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct3.Product_Full_Name__c=  'Baileys gold';
            testProduct3.UPIID__c=  '1256337';
            testProduct3.name = 'Baileys gold';
            testProduct3.Start_Date__c = Date.today();
            testProduct3.Expiry_Date__c = testProduct.Start_Date__c.addDays(2);
            productList.add(testProduct3);
            insert productList;
            
            List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c> ();
            Market_Assortment_Product__c map1 = new Market_Assortment_Product__c();
            map1.Product__c = testProduct.id;
            map1.Market_Assortment__c = countryId;
            mapList.add(map1);
            
            Market_Assortment_Product__c map2 = new Market_Assortment_Product__c();
            map2.Product__c = testProduct2.id;
            map2.Market_Assortment__c = countryId;
            mapList.add(map2);
            
            Market_Assortment_Product__c map3 = new Market_Assortment_Product__c();
            map3.Product__c = testProduct3.id;
            map3.Market_Assortment__c = countryId;
            mapList.add(map3);
            insert mapList;
           
            String trnsfrId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();        
           	Set<Id> orderIdSet = new Set<Id>();
            System.debug(LoggingLevel.Debug,'4.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            List<Order__c> orderList = new List<Order__c>();
            Order__c trnsfrOrder = new Order__c();
            trnsfrOrder.RecordTypeId = trnsfrId;
            trnsfrOrder.Account__c = outlet.id;
            trnsfrOrder.Sales_Representative__c = salesRep.id;
            trnsfrOrder.Status__c = 'Draft';
            trnsfrOrder.Wholesaler__c = wholesaler.id;
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Source_Application__c = 'EDGE 365';
            trnsfrOrder.Signature_Image_Version_Id__c = '3432vddfdffs424';
            trnsfrOrder.Next_Delivery_Date__c = true;
            orderList.add(trnsfrOrder);
            
            
            Order__c trnsfrOrder2 = new Order__c();
            trnsfrOrder2.RecordTypeId = trnsfrId;
            trnsfrOrder2.Account__c = outlet.id;
            trnsfrOrder2.Sales_Representative__c = salesRep.id;
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Wholesaler__c = wholesaler.id;
            trnsfrOrder2.Comments__c = 'Hii';
            trnsfrOrder2.Source_Application__c = 'Diageo One';
            trnsfrOrder2.Is_Promo_Transfer_Order__c = true;
            orderList.add(trnsfrOrder2);
            
            System.debug(LoggingLevel.Debug,'5.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            String freeGoodsOrderId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
            Order__c freeGoodsOrder = new Order__c();
            freeGoodsOrder.RecordTypeId = freeGoodsOrderId;
            freeGoodsOrder.Account__c = outlet.Id;
            freeGoodsOrder.Wholesaler__c =wholesaler.id;
            //freeGoodsOrder.ReasonCode_pickup__c = pickupOption1.id;
            freeGoodsOrder.Status__c = 'Ready For Order';
            freeGoodsOrder.Sales_Representative__c = salesRep.Id;
            freeGoodsOrder.Preferred_Delivery_Date__c = Date.today();
            freeGoodsOrder.Delivery_instructions__c= 'Careful';
            freeGoodsOrder.Delivery_Location__c = 'Shed';
            orderList.add(freeGoodsOrder);
            insert orderList;
           
            orderIdSet.add(trnsfrOrder.id);  
            orderIdSet.add(trnsfrOrder2.id);
            
            List<Order_Item__c> orditem = new List<Order_Item__c>();
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(testProduct.Id, freeGoodsOrder.Id);
            orderItem.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
            orderItem.Quantity__c = 80;
            orderItem.Delivered_Quantity__c = 10;
            orderItem.Status__c = 'Submitted';
            //orderItem.Selected_UoM__c = 'BTL';
            orditem.add(orderItem);
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(testProduct.Id, trnsfrOrder.Id);
            orderItem1.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem1.Quantity__c = 80;
            orderItem1.Delivered_Quantity__c = 10;
            orderItem1.Status__c = 'Submitted';
            //orderItem1.Selected_UoM__c = 'BTL';
            orditem.add(orderItem1);
            
            Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(testProduct.Id, trnsfrOrder2.Id);
            orderItem2.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem2.Quantity__c = 40;
            orderItem2.Delivered_Quantity__c = 21;
            orderItem2.Status__c = 'Submitted';
            //orderItem2.Selected_UoM__c = 'BTL';
            orditem.add(orderItem2);
            
            
            ///Setup Of Promotion which is available for Outlet only within limit range
            String priceIncentiveId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Price Incentive Order').getRecordTypeId();
            Promotion_Master__c promo1 = EDGE_UtilityTestClass.getPromotionMasterRec(priceIncentiveId);
            promo1.name = 'PROMO 1' ;
            promo1.Discount_for_promotion__c = 20;
            promo1.Discount_type__c = 'Discount in amount';
            promo1.Country__c = countryId;
            insert promo1;
            
            List<Promotion_Product__c> promoprodList = new List<Promotion_Product__c>();
            ///Setup Of Promotion which is available for Outlet only within limit range
            //String purchasableId = Promotion_Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Purchasable Product').getRecordTypeId();
            Promotion_Product__c promoprod = new Promotion_Product__c();
            promoprod.Promotion__c  = promo1.id;
            promoprod.Product__c   = testProduct2.id;
            promoprodList.add(promoprod);
            //insert promoprod;
            Promotion_Product__c promoprod1 = new Promotion_Product__c();
            promoprod1.Promotion__c  = promo1.id;
            promoprod1.Product__c   = testProduct3.id;
            promoprodList.add(promoprod1);
            insert promoprodList;
            System.debug(LoggingLevel.Debug,'6.Number of Queries used in this apex code so far: ' + Limits.getQueries());

            Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(testProduct.Id, trnsfrOrder2.Id);
            orderItem3.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem3.Quantity__c = 40;
            orderItem3.Delivered_Quantity__c = 21;
            orderItem3.Status__c = 'Draft';
            //orderItem3.Selected_UoM__c = 'BTL';
            orderItem3.Promotion_Product__c = promoprod.id;
            orditem.add(orderItem3);
            
            Order_Item__c orderItem4 = EDGE_UtilityTestClass.getOrderItem(testProduct3.Id, trnsfrOrder2.Id);
            orderItem4.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem4.Quantity__c = 47;
            orderItem4.Delivered_Quantity__c = 22;
            orderItem4.Status__c = 'Draft';
            //orderItem4.Selected_UoM__c = 'BTL';
            orderItem4.Promotion_Product__c = promoprod1.id;
            orditem.add(orderItem4);

            Order_Item__c orderItem5 = EDGE_UtilityTestClass.getOrderItem(testProduct2.Id, trnsfrOrder2.Id);
            orderItem5.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem5.Quantity__c = 87;
            orderItem5.Delivered_Quantity__c = 82;
            orderItem5.Status__c = 'Draft';
            //orderItem5.Selected_UoM__c = 'BTL';
            orderItem5.Promotion_Product__c = promoprod.id;
            orditem.add(orderItem5);
            
            System.debug(LoggingLevel.Debug,'7.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            insert orditem;
         
            System.debug(LoggingLevel.Debug,'8.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            List<Order__c> updatedtransferOrderList = new List<Order__c>();
            trnsfrOrder2.Status__c = 'Submitted';
            trnsfrOrder.Status__c = 'Submitted';
            updatedtransferOrderList.add(trnsfrOrder2);
            updatedtransferOrderList.add(trnsfrOrder);
            Test.stopTest();
            update updatedtransferOrderList;
            //update trnsfrOrder;
          
            orderIdSet.add(freeGoodsOrder.id);
            EDGE_TransferOrderStatusHelper.setOrderDetails(orderIdSet,false,null);
             System.debug(LoggingLevel.Debug,'9.Number of Queries used in this apex code so far: ' + Limits.getQueries());
           
            EDGE_TransferOrderStatusHelper.setOrderDetails(orderIdSet,true,'en_us');
            
            System.debug(LoggingLevel.Debug,'10.Number of Queries used in this apex code so far: ' + Limits.getQueries());
             
            List<Order__C> transferorderList = new List<Order__c>();
            Map<string,List<Order_Item__C>> mapofLineitem = new Map<string,List<Order_Item__C>>();
            transferorderList.add(trnsfrOrder);  
            transferorderList.add(trnsfrOrder2); 
            
             mapofLineitem.put(freeGoodsOrder.id,new List<Order_item__C>{orderItem});
            mapofLineitem.put(trnsfrOrder.id,new List<Order_item__C>{orderItem1});
            mapofLineitem.put(trnsfrOrder2.id,new List<Order_item__C>{orderItem2});
            mapofLineitem.put(trnsfrOrder2.id,new List<Order_item__C>{orderItem3});
            
            System.debug(LoggingLevel.Debug,'11.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_ClientCode', 'EDGE_OutletID','EDGE_OutletName','EDGE_SalesRepName','EDGE_SalesRepMobile','EDGE_SalesRepEmail','EDGE_ToDelivery',
                'EDGE_Address','EDGE_City','EDGE_State','EDGE_PostalCode','EDGE_Country','EDGE_OrderNumber','EDGE_ProductCode','EDGE_Quantity','EDGE_Notes',
                'EDGE_TextToPrint','EDGE_Size','EDGE_Gender','EDGE_Colour','EDGE_PaperFinish','EDGE_FreeProductsYesNo','EDGE_Promotion_Name','EDGE_Promotion_Type','EDGE_Discount_for_Promotion'}, 'en_US');
            
            
            EDGE_TransferOrderMail.getTransferOrderDetails(orderList, mapofLineitem, 'en_US', labelToTranslatedStrMap, shedToOrderMap,True);
            EDGE_TransferOrderMail.getTransferOrderDetails(orderList, mapofLineitem, 'en_US', labelToTranslatedStrMap, shedToOrderMap,false);
            EDGE_TransferOrderMail.headervalue = null;
            EDGE_TransferOrderMail.wholeOrder = null;
            System.debug(LoggingLevel.Debug,'12.Number of Queries used in this apex code so far: ' + Limits.getQueries());
  
            
        }
    }
    
    @isTest
    public static void testTransferOrderStatus(){
        
        List<User> userList = new List<User>();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesMan1','Sales Manager');
        salesManager.Available_Countries__c = 'ES';
        userList.add(salesManager) ;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'ES';
        salesRep.Email = 'swaraj.samantal@diageo.com';
        userList.add(salesRep);
        
        
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'ES';
        userList.add(testAdminUser);
        insert userList;
        salesRep.ManagerId = salesManager.id;
        update salesRep;
        System.assert(salesRep.ManagerId!=Null, 'Sales Manager');
        
        System.runAs(testAdminUser){
            EDGE_UtilityTestClass.createOrgSettings();
			Id countryId= EDGE_UtilityTestClass.setupCountrySpain('ES');
            Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
            orgSetting.Run_Triggers__c=false;
        	update orgSetting;
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[ES]';
            insert pickupOption;
             System.debug(LoggingLevel.Debug,'0.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            orgSetting.Run_Triggers__c=true;
        	update orgSetting;
            
            Test.startTest(); 
            Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
            market.Threshold_Format__c = 'Percent'; //was commented before
            market.A_P_Threshold__c = 100.00; //100
            market.Display_Transfer_Order_Comments__c = True;
            insert market;
            
            
            List<Account> accList = new List<Account>();
         
            System.debug(LoggingLevel.Debug,'1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
           
           Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
             accList.add(wholesaler);
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Tasmania';
            outlet.BillingCountry = 'Spain';
            outlet.BillingState = 'Madrid';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountryCode = 'ES';
            outlet.Country__c = countryId;
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            accList.add(outlet);
            insert accList;
           	Map<Id, Account> shedToOrderMap = new Map<Id, Account>();
            shedToOrderMap.put(salesRep.id,outlet);
            
           	System.debug(LoggingLevel.Debug,'2.Number of Queries used in this apex code so far: ' + Limits.getQueries());
           
            List<Product__c> productList = new List<Product__c>();
            
            System.debug(LoggingLevel.Debug,'3.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            Product__c testProduct2 = EDGE_UtilityTestClass.getProd();
            testProduct2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct2.Product_Full_Name__c=  'Baileys';
            testProduct2.UPIID__c=  '12567';
            testProduct2.name = 'Baileys';
            testProduct2.Start_Date__c = Date.today();
            productList.add(testProduct2);
            
            Product__c testProduct3 = EDGE_UtilityTestClass.getProd();
            testProduct3.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct3.Product_Full_Name__c=  'Baileys gold';
            testProduct3.UPIID__c=  '1256337';
            testProduct3.name = 'Baileys gold';
            testProduct3.Start_Date__c = Date.today();
            productList.add(testProduct3);
            insert productList;
            
            List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c> ();
            
            Market_Assortment_Product__c map2 = new Market_Assortment_Product__c();
            map2.Product__c = testProduct2.id;
            map2.Market_Assortment__c = countryId;
            mapList.add(map2);
            
            Market_Assortment_Product__c map3 = new Market_Assortment_Product__c();
            map3.Product__c = testProduct3.id;
            map3.Market_Assortment__c = countryId;
            mapList.add(map3);
            insert mapList;
           
            String trnsfrId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();        
           	Set<Id> orderIdSet = new Set<Id>();
            System.debug(LoggingLevel.Debug,'4.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            List<Order__c> orderList = new List<Order__c>();
            Order__c trnsfrOrder = new Order__c();
            trnsfrOrder.RecordTypeId = trnsfrId;
            trnsfrOrder.Account__c = outlet.id;
            trnsfrOrder.Sales_Representative__c = salesRep.id;
            trnsfrOrder.Status__c = 'Draft';
            trnsfrOrder.Wholesaler__c = wholesaler.id;
            trnsfrOrder.Comments__c = 'hello';
            trnsfrOrder.Source_Application__c = 'EDGE 365';
            trnsfrOrder.Signature_Image_Version_Id__c = '3432vddfdffs424';
            trnsfrOrder.Next_Delivery_Date__c = true;
            orderList.add(trnsfrOrder);
            
            
            Order__c trnsfrOrder2 = new Order__c();
            trnsfrOrder2.RecordTypeId = trnsfrId;
            trnsfrOrder2.Account__c = outlet.id;
            trnsfrOrder2.Sales_Representative__c = salesRep.id;
            trnsfrOrder2.Status__c = 'Draft';
            trnsfrOrder2.Wholesaler__c = wholesaler.id;
            trnsfrOrder2.Comments__c = 'Hii';
            trnsfrOrder2.Source_Application__c = 'Diageo One';
            trnsfrOrder2.Is_Promo_Transfer_Order__c = false;
            orderList.add(trnsfrOrder2);
            
            System.debug(LoggingLevel.Debug,'5.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            
            insert orderList;
           
            orderIdSet.add(trnsfrOrder.id);  
            orderIdSet.add(trnsfrOrder2.id);
            
            List<Order_Item__c> orditem = new List<Order_Item__c>();
            
            Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(testProduct2.Id, trnsfrOrder.Id);
            orderItem1.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem1.Quantity__c = 80;
            orderItem1.Delivered_Quantity__c = 10;
            orderItem1.Status__c = 'Submitted';
            //orderItem1.Selected_UoM__c = 'BTL';
            orditem.add(orderItem1);
            
            Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(testProduct3.Id, trnsfrOrder2.Id);
            orderItem2.RecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
            orderItem2.Quantity__c = 40;
            orderItem2.Delivered_Quantity__c = 21;
            orderItem2.Status__c = 'Submitted';
            //orderItem2.Selected_UoM__c = 'BTL';
            orditem.add(orderItem2);
            
            System.debug(LoggingLevel.Debug,'7.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            insert orditem;
         
            System.debug(LoggingLevel.Debug,'8.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            List<Order__c> updatedtransferOrderList = new List<Order__c>();
            trnsfrOrder2.Status__c = 'Submitted';
            trnsfrOrder.Status__c = 'Submitted';
            //updatedtransferOrderList.add(trnsfrOrder2);
            updatedtransferOrderList.add(trnsfrOrder);
            Test.stopTest();
            update updatedtransferOrderList;
            //update trnsfrOrder;
          
            EDGE_TransferOrderStatusHelper.setOrderDetails(orderIdSet,false,null);
             System.debug(LoggingLevel.Debug,'9.Number of Queries used in this apex code so far: ' + Limits.getQueries());
           
            EDGE_TransferOrderStatusHelper.setOrderDetails(orderIdSet,true,'en_us');
            
            System.debug(LoggingLevel.Debug,'10.Number of Queries used in this apex code so far: ' + Limits.getQueries());
             
            List<Order__C> transferorderList = new List<Order__c>();
            Map<string,List<Order_Item__C>> mapofLineitem = new Map<string,List<Order_Item__C>>();
            transferorderList.add(trnsfrOrder);  
            transferorderList.add(trnsfrOrder2); 
            
            mapofLineitem.put(trnsfrOrder.id,new List<Order_item__C>{orderItem1});
            mapofLineitem.put(trnsfrOrder2.id,new List<Order_item__C>{orderItem2});
            
            System.debug(LoggingLevel.Debug,'11.Number of Queries used in this apex code so far: ' + Limits.getQueries());
            Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_ClientCode', 'EDGE_OutletID','EDGE_OutletName','EDGE_SalesRepName','EDGE_SalesRepMobile','EDGE_SalesRepEmail','EDGE_ToDelivery',
                'EDGE_Address','EDGE_City','EDGE_State','EDGE_PostalCode','EDGE_Country','EDGE_OrderNumber','EDGE_ProductCode','EDGE_Quantity','EDGE_Notes',
                'EDGE_TextToPrint','EDGE_Size','EDGE_Gender','EDGE_Colour','EDGE_PaperFinish','EDGE_FreeProductsYesNo','EDGE_Promotion_Name','EDGE_Promotion_Type','EDGE_Discount_for_Promotion'}, 'en_US');
            
            
            EDGE_TransferOrderMail.getTransferOrderDetails(orderList, mapofLineitem, 'en_US', labelToTranslatedStrMap, shedToOrderMap,True);
            EDGE_TransferOrderMail.getTransferOrderDetails(orderList, mapofLineitem, 'en_US', labelToTranslatedStrMap, shedToOrderMap,false);
            EDGE_TransferOrderMail.headervalue = null;
            EDGE_TransferOrderMail.wholeOrder = null;
            System.debug(LoggingLevel.Debug,'12.Number of Queries used in this apex code so far: ' + Limits.getQueries());
  
            
        }
    }
}