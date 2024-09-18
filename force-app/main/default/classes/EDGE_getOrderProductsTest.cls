@istest
public class EDGE_getOrderProductsTest {
 
 @istest
    public static void testgetProdTestMethod(){
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null);
     
        Account shed1 = EDGE_UtilityTestClass.getShedRecord();
        insert shed1;
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        
        Product__c testProduct1 = EDGE_UtilityTestClass.getProd();
        testProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        testProduct1.Supplier_Partner__c= deliveryPartner.Id;
        insert testProduct1;
        system.assert(testProduct1.id != null);
        
        String shedRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, testProduct1.Id, salesRep.Id);
        stock1.RecordTypeId = shedRecordTypeId;
        stock1.Shed__c =shed1.Id;
        insert stock1;
        Test.startTest();
        String stockAdjRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        Order__c stockAdjustorder = new Order__c();
        stockAdjustorder.RecordTypeId= stockAdjRecordTypeId;
        stockAdjustorder.Account__c = shed1.id;
        stockAdjustorder.Delivery_Location__c = 'Shed';
        stockAdjustorder.Order_Type__c = 'Shed';
        stockAdjustorder.Sales_Representative__c = salesRep.Id;
        stockAdjustorder.Status__c= 'Draft';
        insert stockAdjustorder;
        
       String posOrderItemRecType = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Item').getRecordTypeId();
        Order_Item__c posOderItem = new Order_Item__c();
        posOderItem.RecordTypeId = posOrderItemRecType;
        posOderItem.Type__c = 'Shed';
        posOderItem.Product__c = testProduct1.id;
        posOderItem.Order__c = stockAdjustorder.id;
        posOderItem.Stock__c = stock1.id;
        posOderItem.Quantity__c = 10;
        posOderItem.Reported_Reason__c = 'Item Missing';
        posOderItem.Delivered_Quantity__c = 10;
        insert posOderItem;
        EDGE_getOrderProducts  getProdCls= new EDGE_getOrderProducts ();
        getProdCls.targetObjectId=stockAdjustorder.id;
        getProdCls.getOrderProductItems();
        getProdCls.getOrderDetails();
        getProdCls.getRecordUrl();
        
        test.stopTest();
    }
   }