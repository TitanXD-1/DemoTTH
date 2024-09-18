/*
 * @name: D1_BulkOrderRetrievalSAPTest
 * @description : Test Class for D1_BulkOrderRetrievalSAP && D1_CheckoutFlow_CreateSalesOrder 
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0        Manikant        09/00/2021 
 **/
@isTest
public class D1_BulkOrderRetrievalSAPTest {
    // See ALl data is required because we are calling here connectApi method //
    
   
    /**
     * @description 
     */ 
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seealldata=true)
    public static void testOrderItemsBySalesArea(){
        Org_Setting__c orgSetting = Org_Setting__c.getInstance();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        upsert orgSetting;
        
        Account testoutlet=D1_TestDataUtility.getDirectCustomer();
        insert testoutlet;

        Product2 prodObj = new Product2();
        prodObj.Name = 'Test P';
        insert prodObj;
        
        Order ordRec = new Order();
        ordRec.AccountId = testoutlet.id;
        ordRec.EffectiveDate = date.today();
        ordRec.Status = 'Draft';            
        insert ordRec;
        
        OrderDeliveryMethod ordDelMethRec = new OrderDeliveryMethod();
        ordDelMethRec.Description = 'Test desc';
        ordDelMethRec.IsActive = True;
        ordDelMethRec.Name = 'Test Delivery Method';
        insert ordDelMethRec;
        
        OrderDeliveryGroup ordDelGrpRec = new OrderDeliveryGroup();
        ordDelGrpRec.OrderDeliveryMethodId = ordDelMethRec.id;
        ordDelGrpRec.OrderId = ordRec.id;
        ordDelGrpRec.DeliverToName = 'Test Delivery Grp';
        insert ordDelGrpRec ;
        
        OrderItem ordProd = new OrderItem();
        ordProd.Product2Id = prodObj.id;
        ordProd.UnitPrice = 55.00;
        ordProd.Quantity = 5;
        ordProd.OrderId = ordRec.id;
        ordProd.ListPrice = 10;
        ordProd.OrderDeliveryGroupId = ordDelGrpRec.id;
        ordProd.TotalLineAmount = 200;
        insert ordProd; 
        ordRec.Status = 'Activated';
        update ordRec;
            
        Sales_Area__c sa= new Sales_Area__c();
        sa.Max_Order_Line_Items__c = 2;
        sa.Name ='Test Sales Area 123';
        sa.Sales_Area_ID__c = '123456789qwertyuio12';
        insert sa;
        
        OrderSplit__c oSpilt = new OrderSplit__c();
        oSpilt.Sales_Area__c = sa.Id;
        oSpilt.Description__c ='Test1234';
        oSpilt.Market_Description__c='Keg';
        oSpilt.Delivery_Day_Series__c=2;
        oSpilt.Max_future_order_days__c=56;
        insert oSpilt;
        
        OrderSplit__c oSpilt2 = new OrderSplit__c();
        oSpilt2.Sales_Area__c = sa.Id;
        oSpilt2.Description__c ='Test1234';
        oSpilt2.Market_Description__c='Keg';
        oSpilt2.Delivery_Day_Series__c=1;
        oSpilt2.Max_future_order_days__c=56;
        insert oSpilt2;
        
        // Calling ConnectApi  method 
        ConnectApi.OrderSummaryInputRepresentation ordSummInput = new ConnectApi.OrderSummaryInputRepresentation();
        ordSummInput.orderId = ordRec.id;
        ConnectApi.OrderSummaryOutputRepresentation ordSummOutput = ConnectApi.OrderSummaryCreation.createOrderSummary(ordSummInput); 
            
            
        List<OrderSummary> orderSummaryList = [Select id,Order_Split_1__c,Order_Split_2__c,CurrencyIsoCode,Split_2_PO_Number__c,
                                                Split_2_Delivery_date__c,BillingEmailAddress,Split_1_PO_Number__c,Split_1_Delivery_date__c,
                                                Sales_Area__c,Sales_Area__r.Sales_Area_ID__c, Soldto_Party__c, Shipto_Party__c                                                   
                                                from OrderSummary where id =:ordSummOutput.orderSummaryId] ;
        orderSummaryList[0].Order_Split_1__c = oSpilt.id;
        orderSummaryList[0].Order_Split_2__c = oSpilt2.id;
        orderSummaryList[0].Sales_Area__c= sa.id;
        update orderSummaryList[0];
        D1_CheckoutFlow_CreateSalesOrder.createSalesOrder(orderSummaryList);
            
            
        Sales_Order__c salesOrdRec =  new Sales_Order__c();
        salesOrdRec.Order_Status__c = 'new';
        salesOrdRec.Order_Summary__c = orderSummaryList[0].id;
        insert salesOrdRec;
        System.assert(salesOrdRec!=null, true);
        
        List<OrderItemSummary> ordItemSumm = [Select id , Name from OrderItemSummary where OrderSummaryId =:orderSummaryList[0].Id ];
        ordItemSumm[0].Sales_Order__c = salesOrdRec.id;
        update ordItemSumm;
        
        String salesAreaId  = [Select id , Sales_Area_ID__c from Sales_Area__c where id =: sa.id].Sales_Area_ID__c;
        D1_BulkOrderRetrievalSAP.findOrderItemsBySalesArea(salesAreaId, 1);
    }
    
}