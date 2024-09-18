/**
* @name D1_SAPOrderSimulatorTest
* @description Test class for D1_SAPOrderSimulator
* @history                                                                                                                       
* VERSION   AUTHOR            DATE              DETAIL
* 1.0       -       			 -					-
* 2.0		  Sayan Samaddar	16/07/2021		Test Class Refractor [NCP-3801]
**/

@isTest
public class D1_SAPOrderSimulatorTest {
    
    public static Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    
    /**
* @description testCallout
*/    
    @isTest
    static void testCallout(){
        
        //Test.setMock(WebServiceMock.class, new D1_SAPOrderSimulatorCalloutMock());
        List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1> salesOrderItemResponseList = D1_TestDataUtility.getSalesOrderItemResponseList();
        D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 salesOrderResponseList = D1_TestDataUtility.getSalesOrderItemResponse();
        
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
        insert pickupOption;
        
        Account testoutlet=D1_TestDataUtility.getD1Customer();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert testoutlet;
        
        Sales_Area__c salesArea = D1_TestDataUtility.salesAreaData();
        insert salesArea;
        
        WebStore ws = D1_TestDataUtility.getWebStore();
        insert ws;
        
        OrderSplit__c orderSplit = D1_TestDataUtility.insertOrderSplit(salesArea.ID);
        insert orderSplit;
        
        OrderSplit__c orderSplit2 = D1_TestDataUtility.insertOrderSplit(salesArea.ID);
        orderSplit2.SAP_OrderSplit_ID__c = '445567';
        insert orderSplit2;
        
        WebCart cart = D1_TestDataUtility.getWebCart(ws.id, testoutlet.id, orderSplit.Id, orderSplit2.Id);
        insert cart;
        
        Product2 p = D1_TestDataUtility.getProduct();
        p.SAP_Material_Id__c = '00012332';
        insert p;
        
        Product2 p1 = D1_TestDataUtility.getProduct();
        p1.SAP_Material_Id__c = '00012323';
        insert p1;
        
        List<Id> productList = new List<Id>();
        productList.add(p.Id);
        productList.add(p1.Id);
        
        
        List<CartItem> cartItemList= new List<CartItem>();
        List<CartItem> cartItemmList= new List<CartItem>();
        
        CartDeliveryGroup cartDeliveryGroup1 =  D1_TestDataUtility.getCartDeliveryGroup(cart.Id);
        insert cartDeliveryGroup1;
        
        CartItem c = D1_TestDataUtility.getCartItem(cart.Id);
        c.OrderSplit_Type__c = orderSplit.Id;
        c.Product2Id = p.Id;
        c.CartDeliveryGroupId = cartDeliveryGroup1.Id;
        insert c;
        
        cartItemList.add(c);
        
        CartItem c2 = D1_TestDataUtility.getCartItem(cart.Id);
        c2.OrderSplit_Type__c = orderSplit2.Id;
        c2.Product2Id = p1.Id;
        c2.CartDeliveryGroupId = cartDeliveryGroup1.Id;
        insert c2;
        
        D1_Setting__c d1setting = new D1_Setting__c();
        d1setting.Name = 'GB';
        d1setting.Unique_ID__c = 'test ES';
        d1setting.Language__c = 'en_GB';
        d1setting.Market__c = countryId;
        d1setting.Default__c = true;
        d1setting.Calculate_Tax_On_Simulation__c = true;
        insert d1setting;
        
        
        cartItemList.add(c2);
        cartItemmList = [SELECT Id,Name,CartId,Sku,SalesPrice,Quantity,Type,OrderSplit_Type__c,Product2Id,CartDeliveryGroupId,Product2.SAP_Material_Id__c FROM CartItem WHERE Product2Id IN:productList];
        Test.startTest();        
        try{            
            List<D1_CheckoutSimulation.CartItemWrapper> pItemResponse = D1_SAPOrderSimulator.processItemResponse(salesOrderItemResponseList,cartItemList,cart);
            List<D1_CheckoutSimulation.CartItemWrapper> pItemResNull = D1_SAPOrderSimulator.processItemResponse(null,cartItemList,cart);
            System.assertEquals(pItemResponse.size(),1, 'response size not equal');
            System.assertEquals(pItemResponse[0].itemPrice,salesOrderItemResponseList[0].PRICE,'sales order response list not equal');
            
            
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage()+' '+ex.getLineNumber());
        }
        
        try{
            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request req = D1_SAPOrderSimulator.generateRequest(cartItemList[0].OrderSplit_Type__c,cart,cartItemList);
            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request reqq = D1_SAPOrderSimulator.generateRequest(cartItemList[0].OrderSplit_Type__c,cart,cartItemmList);
            System.assert(req!=null, 'request not found');
            System.assertEquals(req.STATUS, cart.Status, 'request status not equal');
            
            
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage()+' '+ex.getLineNumber());
        }
        
        try{            
                D1_CheckoutSimulation.cartWrapper simulatedCartWrapper = D1_SAPOrderSimulator.processSimulationResponse(salesOrderResponseList,cart,cartItemList,cartItemList[0].OrderSplit_Type__c,true,null);
                D1_CheckoutSimulation.cartWrapper simCartWrper = D1_SAPOrderSimulator.processSimulationResponse(salesOrderResponseList,cart,cartItemList,cartItemList[0].OrderSplit_Type__c,false,null);
                System.assert(simulatedCartWrapper!=null, 'sales response not found');
                System.assertEquals(simulatedCartWrapper.CartId, cart.id, 'sales response');
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage()+' '+ex.getLineNumber());
        }
        
        Test.stopTest();   	
    }
}