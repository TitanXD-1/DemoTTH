@isTest
public class EDGE_OrderfreegoodsTest {
    @isTest
     public static void createData(){  
    	Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        mktSetting.Free_Goods_Robot_Email_Address__c = 'test@test.com';
        mktSetting.Free_Goods_SAP_Automation__c ='Robot CSV Upload to SAP';
        insert mktSetting;
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep id should not be null');
         
        EDGE_UtilityTestClass.createOrgSettings(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
       
         
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        outlet.Start_Date__c = Date.today();
        outlet.ShippingCountry='Australia';
        insert outlet;
        Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
        wholesaler.ShippingCountry='Australia';
        insert wholesaler;
        Delivery_Partner__c delPart = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert delPart;
         
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
        insert freeGoodsOrder;
         
        Order__c freeGoodsOrder1 = new Order__c();
        freeGoodsOrder1.RecordTypeId = freeGoodsOrderId;
        freeGoodsOrder1.Account__c = outlet.Id;
        freeGoodsOrder1.Delivery_Partner__c = delPart.Id;
        //freeGoodsOrder1.ReasonCode_pickup__c = pickupOption1.id;
        freeGoodsOrder1.Status__c = 'Ready For Order';
        freeGoodsOrder1.Sales_Representative__c = salesRep.Id;
        freeGoodsOrder1.Preferred_Delivery_Date__c = Date.today();
        freeGoodsOrder1.Delivery_instructions__c= 'Careful';
        insert freeGoodsOrder1;
         
        Product__c skuProduct = EDGE_UtilityTestClass.getProd();
        skuProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        skuProduct.Start_Date__c = system.today();
        insert skuProduct;
        
        String freeGoodsOrderItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order_Item__c freeGoodsOrderItem = new Order_Item__c();
        freeGoodsOrderItem.RecordTypeId = freeGoodsOrderItemId;
        freeGoodsOrderItem.Product__c = skuProduct.id;
        freeGoodsOrderItem.Order__c = freeGoodsOrder.id;
        freeGoodsOrderItem.Quantity__c = 2 ;
        freeGoodsOrderItem.Selected_UoM__c = 'BHY' ;
        freeGoodsOrderItem.Status__c = 'Ready for Order';
        insert freeGoodsOrderItem;
         
        Order_Item__c freeGoodsOrderItem1 = new Order_Item__c();
        freeGoodsOrderItem1.RecordTypeId= freeGoodsOrderItemId;
        freeGoodsOrderItem1.Product__c = skuProduct.id;
        freeGoodsOrderItem1.Order__c = freeGoodsOrder1.id;
        freeGoodsOrderItem1.Quantity__c = 30 ;
        freeGoodsOrderItem1.Selected_UoM__c = 'BHY' ;
        freeGoodsOrderItem1.Status__c = 'Ready for Order';
        insert freeGoodsOrderItem1;
         
        List<Order__c> orderList = new List<Order__c>();
        List<Order_Item__c> ordItemList = new List<Order_Item__c>();
        Map< String, List<Order_Item__c>> mapofLineitem = new Map< String, List<Order_Item__c>>();
        orderList.add(freeGoodsOrder);
        ordItemList.add(freeGoodsOrderItem);
        ordItemList.add(freeGoodsOrderItem1);
        mapofLineitem.put(freeGoodsOrder.Id, ordItemList); 
        Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_AccountName', 'EDGE_AccountAdress', 'EDGE_EmailBody','EDGE_AccountPhone','EDGE_SalesRepresentative','EDGE_ExpectedDeliveryDate','EDGE_Reason','EDGE_ProductCode','EDGE_DeliveryInstructions','EDGE_ProductDescription', 'EDGE_PrefOderDate','EGDE_ProductName','EDGE_ProductQuantity','EDGE_UOM','EDGE_OrderedProducts','EDGE_SubjectTO','EDGE_BatchSubjectTO'}, 'en_US'); //301950
        EDGE_UtilityClass.getFreeGoodsMail(orderList,mapofLineitem,'en_US',labelToTranslatedStrMap);
        EDGE_UtilityClass.getFreeGoodsMail(orderList,mapofLineitem,null,null);
         
     }
}