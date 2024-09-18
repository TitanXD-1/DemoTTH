/**
* @name : D1_OrderCheckoutControllerTest
* @description : This provides test coverage to following controller:
* D1_SAPOrderSimulator
* D1_OrderSimulationController
* D1_OrderCheckoutController
* D1_CheckoutSimulation
* AsyncD1_OrderSimulationController
* @history
* VERSION     AUTHOR         DATE               DETAIL
* 1.0          -        		-                    -
* 2.0			Rubeena		   01/07/2021		  Test Class Refractor [NCP-3802]
**/

@isTest
public class D1_OrderCheckoutControllerTest {
    
    @isTest
    /**
     * @description doAsyncCalloutTest
     */    
    public static void doAsyncCalloutTest(){
        Account account = D1_TestDataUtility.getDirectCustomer();
        //insert account;
        
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        
        D1_TestDataUtility.insertCartAndCartItems(account);
        
        User extUSer = [SELECT Id,Effective_Account_Id__c from User where email='testclassextuser1@testdomain.com' limit 1];
        
        WebStore webstoreObj = [SELECT Id from WebStore limit 1];
        webstoreObj.Name = 'Shop';
        update webstoreObj; 
        
        WebCart webCArtObj = [SELECT Id from WebCart where Name='TestCart'];
        webCArtObj.Split_1_Delivery_date__c = system.today();
        webCArtObj.Split_2_Delivery_date__c= system.today();
        update webCArtObj;
        
        webcart webCArtObjRec = [SELECT Id, Status, PoNumber, Split_2_PO_Number__c, WebStoreId, accountId, 
                                 Sales_Area__r.Distribution_Channel_Code__c, Sales_Area__r.Division_Code__c, Sales_Area__r.Sales_Organisation_Code__c, 
                                 Soldto_Party__c, Shipto_Party__c, Delivery_Instructions__c, Customer_Service_Instruction__c, 
                                 Order_Split_1__r.Description__c , Order_Split_1__r.Market_Description__c, Order_Split_2__r.Description__c, 
                                 Order_Split_2__r.Market_Description__c, Split_1_Delivery_date__c, Split_2_Delivery_date__c,
                                 createdDate, createdBy.Name, createdBy.Email, Order_Split_1__c, Order_Split_2__c,Payment_Term_Code__c from webcart  where name = 'TestCart']; 
        
        List<D1_OrderCheckoutController.OrderCheckoutRequest> obj = new List<D1_OrderCheckoutController.OrderCheckoutRequest>();
        
        D1_OrderCheckoutController.OrderCheckoutRequest objRec = new D1_OrderCheckoutController.OrderCheckoutRequest();
        objRec.cartId = webCArtObjRec.id;
        objRec.interfaceName = 'Order_Simulation_Split1';
        objRec.cartItems =[SELECT Id, Name, Sku, Product2Id, Product2.Name, Product2.Base_Unit_of_Measure__c, UOM__c,
                           Product2.SAP_Material_Id__c, Product2.D1_Size__c, ListPrice, Quantity, 
                           OrderSplit_Type__r.Name, OrderSplit_Type__r.Description__c, CurrencyIsoCode,
                           Product2.Product_Card_Title__c, OrderSplit_Type__c, Product2.D1_Brand__c, Product2.Packaging_Details__c from CartItem where cartId =: webCArtObjRec.id ];
        
        objRec.userCart = webCArtObjRec; 
        
        D1_OrderCheckoutController.OrderCheckoutRequest objRec1 = new D1_OrderCheckoutController.OrderCheckoutRequest();
        objRec1.cartId = webCArtObjRec.id;
        objRec1.interfaceName = 'Order_Simulation_Split2';
        objRec1.cartItems =[SELECT Id, Name, Sku, Product2Id, Product2.Name, Product2.Base_Unit_of_Measure__c, UOM__c, Portfolio_Item__r.Ordering_UoM_Override__c,
                            Product2.SAP_Material_Id__c, Product2.D1_Size__c, ListPrice, Quantity, 
                            OrderSplit_Type__r.Name, OrderSplit_Type__r.Description__c, CurrencyIsoCode,
                            Product2.Product_Card_Title__c, OrderSplit_Type__c, Product2.D1_Brand__c, Product2.Packaging_Details__c from CartItem where cartId =: webCArtObjRec.id ];
        
        objRec1.userCart = webCArtObjRec;
        obj.add(objRec);
        obj.add(objRec1);
        
        Test.startTest();            
        	Test.setMock(WebServiceMock.class, new D1_SAPOrderSimulatorCalloutMockTest());
            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request requestHeader = D1_SAPOrderSimulator.generateRequest(objRec1.cartItems[0].OrderSplit_Type__c, webCArtObjRec, objRec1.cartItems);                       
            D1_OrderSimulationController.HTTPS_Port simulationReq = new D1_OrderSimulationController.HTTPS_Port();
            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 simResponse = simulationReq.SI_SalesOrderSimulate_Sync_Out_D1(webCArtObjRec.id,true,requestHeader);   
        	D1_SAPOrderSimulator.processItemResponse(simResponse.ITEMS, objRec1.cartItems, webCArtObjRec);
            D1_OrderCheckoutController.doAsyncCallout(webCArtObjRec.Id);
            D1_OrderCheckoutController.processAllResponses(obj);  
            D1_OrderCheckoutController.getCurrencySymbol(extUser.Id);
            String jSONStr = '[{"productId":"01t3W0000001rxhQAA", "itemTax":"28.72", "itemPrice":"143.62"}]';
            D1_OrderCheckoutController.updateCartItems(JSONStr, webCArtObjRec.Id);
            System.assert(simResponse != null, 'simResponse not found');
        Test.stopTest();
    }
}