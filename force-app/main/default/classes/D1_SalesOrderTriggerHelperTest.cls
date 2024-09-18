/**
 * @name D1_SalesOrderTriggerHelperTest
 * @description Test class for SalesOrderTrigger
 * @history                                                                                                                       
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0       Saurav Paul       23/12/2020      Initial Development
 * 2.0       Sayan Samaddar    16/07/2021       Test Class Refractor [NCP-3801]
 * 3.0       Ajay              06/12/2021       testSaleOrderValidation[NCP-5366]
 **/
@isTest
public with sharing class D1_SalesOrderTriggerHelperTest {
    // See ALl data is required because we are calling here connectApi method
    
    /**
     * @description updateSalesOrderStatusTest
     */    
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @IsTest(SeeAllData=true)
    public static void updateSalesOrderStatusTest(){
        Org_Setting__c orgSetting = Org_Setting__c.getInstance();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.D1_EDGE_Customer__c =true;
        testoutlet.Name='testcart Outlet';
        testoutlet.Salesforce_Delivery_Days_Packaged_Good__c='1;2;3;4;5;6;7';
        testoutlet.Salesforce_Delivery_Days_Keg__c='1;2;3;4;5;6;7';
        testoutlet.Delivery_Pattern__c='0';
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
        
        Test.startTest();
        
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
        
        salesOrdRec.Status_Queued_Action__c = 'Fire Trigger';
        update salesOrdRec;

        testSaleOrderValidation(orderSummaryList[0].id, sa.Id);
        Test.stopTest();
        
        List<Sales_Order__c> salesOdrList = new List<Sales_Order__c>();
        salesOdrList = [SELECT Id,Order_Number__c,Name FROM Sales_Order__c WHERE Id =: salesOrdRec.Id];
        System.assertEquals(salesOdrList[0].Order_Number__c,salesOdrList[0].Name, 'Order Number is Empty');
    }
    
    public static void testSaleOrderValidation(Id orderSummaryId, Id salesAreaId){
        Sales_Order__c salesOrderMaster =  new Sales_Order__c(
            Order_Summary__c = orderSummaryId,
            Purchase_Order_Number__c ='PO-1',
            Soldto_Party__c = 'Sold-1',
            Shipto_Party__c = 'Ship-1',
            Sales_Area__c = salesAreaId
        );
        insert salesOrderMaster;

        //Success
        try{
            Sales_Order__c salesOrder = new Sales_Order__c(
                Id = salesOrderMaster.Id,
                SAP_Order_Number__c = 'Order-1', //Change
                Purchase_Order_Number__c ='PO-1',
                Soldto_Party__c = 'Sold-1',
                Shipto_Party__c = 'Ship-1',
                Sales_Area__c = salesAreaId
            );

            update salesOrder;
            System.assert(true, 'Sales order update failed, with SAP_Order_Number__c change');
        }catch(Exception ex){
            System.assert(false, 'Sales order update failed, with SAP_Order_Number__c change');
        }

        //Failure

        //1. Purchase_Order_Number__c mismatch
        try{
            Sales_Order__c salesOrder = new Sales_Order__c(
                Id = salesOrderMaster.Id,
                SAP_Order_Number__c = 'Order-2', //Change
                //Purchase_Order_Number__c ='PO-12',//Change
                Soldto_Party__c = 'Sold-11',//Change
                Shipto_Party__c = 'Ship-1',
                Sales_Area__c = salesAreaId
            );

            update salesOrder;
            System.assert(false, 'Sales order update failed, with SAP_Order_Number__c,Purchase_Order_Number__c  change');
        }catch(Exception ex){
            System.assert(true, 'Sales order update failed, with SAP_Order_Number__c,Purchase_Order_Number__c  change');
        }

        //2. Soldto_Party__c mismatch
        try{
            Sales_Order__c salesOrder = new Sales_Order__c(
                Id = salesOrderMaster.Id,
                SAP_Order_Number__c = 'Order-3', //Change
                Purchase_Order_Number__c ='PO-1',
                Soldto_Party__c = 'Sold-12',//Change
                Shipto_Party__c = 'Ship-1',
                Sales_Area__c = salesAreaId
            );

            update salesOrder;
            System.assert(false, 'Sales order update failed, with SAP_Order_Number__c,Soldto_Party__c  change');
        }catch(Exception ex){
            System.assert(true, 'Sales order update failed, with SAP_Order_Number__c,Soldto_Party__c  change');
        }

        //3. Shipto_Party__c mismatch
        try{
            Sales_Order__c salesOrder = new Sales_Order__c(
                Id = salesOrderMaster.Id,
                SAP_Order_Number__c = 'Order-4', //Change
                Purchase_Order_Number__c ='PO-1',
                Soldto_Party__c = 'Sold-1',
                Shipto_Party__c = 'Ship-12',//Change
                Sales_Area__c = salesAreaId
            );

            update salesOrder;
            System.assert(false, 'Sales order update failed, with SAP_Order_Number__c,Shipto_Party__c  change');
        }catch(Exception ex){
            System.assert(true, 'Sales order update failed, with SAP_Order_Number__c,Shipto_Party__c  change');
        }

        //4. Sales_Area__c mismatch
        try{
            Sales_Order__c salesOrder = new Sales_Order__c(
                Id = salesOrderMaster.Id,
                SAP_Order_Number__c = 'Order-5', //Change
                Purchase_Order_Number__c ='PO-1',
                Soldto_Party__c = 'Sold-1',
                Shipto_Party__c = 'Ship-1',
                Sales_Area__c = null //Change
            );

            update salesOrder;
            System.assert(false, 'Sales order update failed, with SAP_Order_Number__c,Sales_Area__c  change');
        }catch(Exception ex){
            System.assert(true, 'Sales order update failed, with SAP_Order_Number__c,Sales_Area__c  change');
        }
    }
}