/*
Name: EDGE_OrderFreeGoodRoboExcelControlTest

Req: Test class of EDGE_OrderFreeGoodsRoboExcelController

History                                                            
-------                                                            
VERSION    AUTHOR             DATE          DETAIL
1.0      Sudipta Nandy        10/07/2024    Initial Development
2.0      Sagnik Sanyal        11/07/2024    Initial Development
*/
@isTest
public class EDGE_OrderFreeGoodRoboExcelControlTest {
    // public static Id producttypeRecTypeId = mapPickupoptionRecordTypes.get('Product Type').getRecordTypeId();
    
    @isTest
    public static void processOrdersTest(){
        createData();
        Set<Id> ordIdSet = new Set<Id>();
        for (Order__c orderList:[select id from Order__c]){
            ordIdSet.add(orderList.Id);
        }
        EDGE_OrderFreeGoodsRoboExcelController.processOrders(ordIdSet);
    }
     
    public static void createData(){
      //  Test.startTest();
        Date todays = Date.today();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        //Create Account
        List<Account> accLst = new List<Account>();        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Name = 'Test Outlet Melbourne 1514';
        outlet1.BillingStreet = '95 Melbourne Airway 1';
        outlet1.Sales_Org__c = 'AU01';
        accLst.add(outlet1);        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();       
        outlet2.Name = 'test Outlet 1515';
        outlet2.BillingStreet = '17 Adelade Highway 45';
        outlet2.Sales_Org__c = 'AU01';
        accLst.add(outlet2);
        insert accLst;
        // Create Shed
        Account shed1 =  EDGE_UtilityTestClass.getShedRecord();
        shed1.Name = 'Test Shed1';
        shed1.BillingStreet = '11 Sydney Street';
        shed1.Sales_Org__c = 'AU01';
        insert shed1;
        //create Sales Representative User
        List<User> usrLst = new List<User>();
        User slrep = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
        slrep.Business_Role__c = 'Sales Representative';
        slrep.trax_user__c=true;
        usrLst.add(slrep);
        insert usrLst;
        
        //Create Delivery Partner Ware house 
        Delivery_Partner__c delpartwh = getDeliveryPartnerWh(countryId); 
        delpartwh.name = 'Warehouse DP';
        delpartwh.SAP_Ship_To__c = '123454';
        delpartwh.SAP_Sold_To__c = '232357';
        delpartwh.Batch_Notification__c = false ;
        insert delpartwh;
        
         Delivery_Partner__c delpartsh = getDeliveryPartnerSP(countryId);
         delpartsh.Batch_Notification__c = false ;
         delpartsh.name = 'Supplier DP';
         insert delpartsh;
        
        //Create Budget
        Pick_Up_Options__c budget1 = getBudgetType(countryId);
        insert budget1;
        
        //Create Banner
        Pick_Up_Options__c banner1 = getBanner(countryId);
        insert banner1;
        
        // Create Products
        List<Product__c> prods = new List<Product__c>();  
        for(integer i=1; i<=6; i++){
            Product__c testProduct = EDGE_UtilityTestClass.getProd();
            testProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
            testProduct.name = 'Product '+ i;
            testProduct.UPIID__c = '1234'+ i;
            testProduct.Product_2_ID__c = '4321'+ i;
            prods.add(testProduct);  
        }
        insert prods;
        
        //Create Internal Order
        List<ECM_Internal_Order__c> intOrds = new List<ECM_Internal_Order__c>();
        for(Integer i = 0; i < prods.size(); i++){
            ECM_Internal_Order__c testIO =  getInternalOrder( budget1.Id,countryId,prods[i].Id, banner1.Id);
            intOrds.add(testIO); 
        }
        insert intOrds;
        
        //Create Reason Code
        List<Pick_Up_Options__c> reasCodes = new List<Pick_Up_Options__c>();
        for(Integer i = 0; i < intOrds.size(); i++){
            Pick_Up_Options__c testRC =  getReasonCode(intOrds[i].Id, countryId);
            reasCodes.add(testRC); 
        }
        insert reasCodes;
        
        //create MAPs
        List<Market_Assortment_Product__c> maps = new List<Market_Assortment_Product__c>();
        for(Integer i = 0; i < prods.size(); i++){
            Market_Assortment_Product__c testMAP = getMaps(prods[i].Id,countryId);
            maps.add(testMAP); 
        }   
        insert maps;
        
        //Create Order
        List<Order__c> ordList = new List<Order__c>();
        Order__c ord1 =  getFreeGoodsOrder(slrep.id,accLst[0].id, delpartwh.id,null);
        ordList.add(ord1);
        Order__c ord2 =  getFreeGoodsOrder(slrep.id,accLst[1].id, delpartwh.id,shed1.id);
        ordList.add(ord2);
        insert ordList;
        //Set<Order__C> orders = new Set<Order__c>();
        //orders.add(ord1);
        
        // Create Market Setting
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        market.Free_Goods_SAP_Automation__c = 'Robot CSV Upload to SAP';
        insert market;
        
        // Create Order Items
        List<Order_Item__c> ordItems = new List<Order_Item__c>();
        Order_Item__c ordItem1 = getOrderItem(prods[0].Id,ord1.id);
        ordItems.add(ordItem1);
        Order_Item__c ordItem2 = getOrderItem(prods[1].Id,ord1.id);
        ordItems.add(ordItem2);
        Order_Item__c ordItem3 = getOrderItem(prods[2].Id,ord1.id);
        ordItems.add(ordItem3);
        Order_Item__c ordItem4 = getOrderItem(prods[3].Id,ord2.id);
        ordItems.add(ordItem4);
        Order_Item__c ordItem5 = getOrderItem(prods[4].Id,ord2.id);
        ordItems.add(ordItem5);
        Order_Item__c ordItem6 = getOrderItem(prods[5].Id,ord2.id);
        ordItems.add(ordItem6);
        insert ordItems;
       // Test.stopTest();
        String csvVal;
        String csvHeaderVal = '"Outlet Id",Target Member Id\n';
        csvVal = accLst[0].Id + ',' + ordList[0].Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_OrderFreeGoodRoboExcelControlTest.encode64Data(csvVal);
        Test.startTest();
        //EDGE_OrderFreeGoodsRoboExcelController.processCsvMetadata(ord1);
        Test.stopTest();
    }
    
    public static Order__c getFreeGoodsOrder(String salesRepId, Id accountId, String DelPartner, Id shedId){
        String freegdsid = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c freeGoods = new Order__c();
        freeGoods.RecordTypeId = freegdsid;
        freeGoods.Account__c = accountId;
        freeGoods.Sales_Representative__c = salesRepId;
        freeGoods.Status__c = 'Draft';
        freeGoods.Shed__c = shedId;
        freeGoods.Delivery_instructions__c = 'Test Order';
        freeGoods.Source_Application__c = 'EDGE 365';
        freeGoods.Requested_Delivery_Date__c = date.today();        
        freeGoods.Delivery_Partner__c = DelPartner;
        return freeGoods; 
    } 
    
    public static Order_Item__c getOrderItem(String productId, Id orderId){
        Id frgdOrderItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.Order__c = orderId;
        orderItem.Product__c = productId;
        orderItem.Base_Price__c = 567;
        orderItem.Quantity__c = 6;
        orderItem.Selected_UoM__c = 'BTL';
        orderItem.Type__c = 'Shed';
        return orderItem;
    }
    
    public static Market_Assortment_Product__c getMaps(String productId, String countryId){
        Market_Assortment_Product__c maps = new Market_Assortment_Product__c();
        maps.Market_Assortment__c = countryId;
        maps.Product__c = productId;
        maps.Base_UoM__c = 'BTL';
        //maps.Reason_Code__c = rescodId;
        maps.Free_Good__c = 'On Trade';
        maps.Used_UoM__c = 'BTL';
        maps.ECM_INTO_Material__c = 2345;
        return maps;
    }
    public static Pick_Up_Options__c getBudgetType(String countryId){
        String budgettypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Pick_Up_Options__c budgettype = new Pick_Up_Options__c();
        budgettype.RecordTypeId = budgettypeId;
        budgettype.Name = 'Budget 1';
        budgettype.Status__c = 'Active';
        budgettype.Geography__c = countryId;
        return budgettype;
    }
    public static Pick_Up_Options__c getBanner(String countryId){
        String bannertypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        Pick_Up_Options__c baner = new Pick_Up_Options__c();
        baner.Name = 'Banner 1';
        baner.RecordTypeId = bannertypeId;
        baner.ECM_Banner_Value__c = '1234';
        baner.Status__c = 'Active';
        baner.Geography__c = countryId;
        return baner;
    }
    public static ECM_Internal_Order__c  getInternalOrder(String budgetId,String countryId,String prodId, String bannerId){
        String internalOrderId = ECM_Internal_Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('CST Internal Order').getRecordTypeId();
        ECM_Internal_Order__c intord = new ECM_Internal_Order__c();
        intord.RecordTypeId = internalOrderId;
        intord.ECM_Budget_Amount__c  = 1234;
        intord.ECM_Geography__c = countryId;
        intord.ECM_Product__c = prodId;
        intord.ECM_Fiscal_Year__c = 'FY24/FY25';
        intord.ECM_Start_Date__c = system.today()-1;
        intord.ECM_Budget_Type_Pickup_Option__c = budgetId;
        intord.ECM_Banner__c = bannerId;
        return intord;
    }
    
    public static Pick_Up_Options__c  getReasonCode(String ioId, string countryId){
        String reasonCodeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods Reason Codes').getRecordTypeId();
        Pick_Up_Options__c reasonCode = new Pick_Up_Options__c();
        reasonCode.Name= 'Test Reason Code';
        reasonCode.Status__c = 'Active';
        reasonCode.Geography__c= countryId;
        reasonCode.Internal_Order__c= ioId;
        return reasonCode;
    }
    
    public static Delivery_Partner__c getDeliveryPartnerWh( Id countryId){
        String warehsId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        Delivery_Partner__c  deliveryPartner = new Delivery_Partner__c();
        deliveryPartner.RecordTypeId = warehsId;
        deliveryPartner.Name = 'TestDeliveryPartner';
        deliveryPartner.DP_Id__c = 'Aus1';
        deliveryPartner.Country__c = countryId;
        deliveryPartner.Email__c = 'test@asd.com';
        deliveryPartner.Vendor_Number__c = 30;
        deliveryPartner.City__c = 'Sydney';
        deliveryPartner.Postal_Code__c = '456987';
        deliveryPartner.Street__c = 'George Street';
        return deliveryPartner ;
    }
    public static Delivery_Partner__c getDeliveryPartnerSP( Id countryId){
        String supPartId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c  deliveryPartnersp = new Delivery_Partner__c();
        deliveryPartnersp.RecordTypeId = supPartId;
        deliveryPartnersp.Name = 'TestDeliveryPartner';
        deliveryPartnersp.DP_Id__c = 'Aus2';
        deliveryPartnersp.Country__c = countryId;
        deliveryPartnersp.Email__c = 'test1@asd.com';
        deliveryPartnersp.Vendor_Number__c = 35;
        deliveryPartnersp.City__c = 'Melbourne';
        deliveryPartnersp.Postal_Code__c = '4569871';
        deliveryPartnersp.Street__c = 'Melbourne Street';
        return deliveryPartnersp ;
    }
    public static String encode64Data(String csvString){
        Blob blobCSVVal = Blob.valueOf(csvString);
        string base64value = EncodingUtil.base64Encode(blobCSVVal);
        return base64value;
    }
}