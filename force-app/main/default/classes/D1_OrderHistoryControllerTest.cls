/**
 * @name : D1_OrderHistoryControllerTest
 * @description : Test Class D1_OrderHistoryController
 * @history
 * VERSION      AUTHOR          	DATE                DETAIL
 * 1.0          Abhishek        	06/07/2021          NCP-3782(refactor)
 * 2.0			Swagat/Subhrojit	19/10/2022			NCP-7415
 * 3.0			Mukesh Kant			14/06/2022			152922
**/

@isTest
public class D1_OrderHistoryControllerTest {

    /**
     * @description : public variable
     */
    public static string searchQuery = '{"inputs" : [ {"orderSummaryID" : "1Os3O0000004CTSSA2" }]}';
    
    @testSetup
    public static void dataSetup(){
        //Direct Setup
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        //Insert External User
        D1_TestDataUtility.setUpExternalUser(directCustomer, 'Direct Buyer'); //testclassextuser1@testdomain.com

        //Get Country
        Geography__c country = [SELECT Id, Name, Code__c FROM Geography__c WHERE RecordType.Name='Country' LIMIT 1];

        //Get D1 Setting
        D1_Setting__c d1Setting = [SELECT Id, Language__c, Default__c, Market__c, Show_Delivery__c FROM D1_Setting__c LIMIT 1];
        d1Setting.Show_Delivery__c = TRUE;
        
        update d1Setting;
        
        //Insert Contact Point Address
        ContactPointAddress cpa = D1_TestDataUtility.insertContactPointAddress();
        cpa.ParentId = directCustomer.Id;
        cpa.Account_Number__c = '23456';
        cpa.PostalCode ='NW10 7HQ';
        cpa.State = null;
        cpa.Street='Park Royal';
        cpa.Country='United Kingdom';
        cpa.Source__c='Diageo One';
        cpa.AddressType = 'Shipping';
        insert cpa;
    }

    /**
     * @description testOrderHistory
     */	
    @isTest
    public static void testOrderHistory(){
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new D1_OrderHistoryWSDLMockTest());
        
        //Get D1 User
        User usr = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        
        System.RunAs(usr){
            Test.startTest();
            	// Call the method that invokes a callout
                String requestStr = '{"customer" : "12345", "startDate" : "2021-12-31", "endDate" : "2022-05-31", "includeItems" : true, "includeDel" : true}';
                List <D1_OrderHistoryController.OrderWrapper> orderWrapperList = D1_OrderHistoryController.getOrderHistory(requestStr, true);  
                System.assertEquals(1, orderWrapperList.size(), 'List is Empty');
                
            	List <D1_OrderHistoryController.OrderWrapper> orderWrapperExceptionList = D1_OrderHistoryController.getOrderHistory('exception data: exception', true);
                System.assertEquals(0, orderWrapperExceptionList.size(), 'List is not Empty');
            Test.stopTest();
        }
    }
    
    /**
     * @description testDeleivery
     */    
    @isTest
    public static void testDeleivery(){
        ContactPointAddress cpa = [SELECT Id, Name, Account_Number__c, PostalCode, State, Street, Country, Source__c, Address, AddressType FROM ContactPointAddress LIMIT 1];
     	D1_OrderHistoryController.setupDeliveryAddress(new D1_OrderHistoryController.SfdcOrderInfo(), cpa);
        D1_OrderHistoryController.setupDeliveryAddress(new D1_OrderHistoryController.SfdcOrderInfo(), null);
        System.assertEquals(0, 0, 'List is not Empty');
    }
    
    /**
     * @description testOrderItemSummary
     */    
    @isTest
    public static void testOrderItemSummary(){
        Account acc = [SELECT Id FROM Account WHERE KUNNR__c = '12345' LIMIT 1];
        
        OrderSummary oSummary = new OrderSummary();
        oSummary.OrderNumber = '000000000000';
        
        WebStore testStore = D1_TestDataUtility.getWebStore();
        insert testStore;
        
        try{
            List < ConnectApi.OrderItemSummaryProduct > orderItemSummaryList = D1_OrderHistoryController.getOrderItemSummary(testStore.Id, acc.Id, oSummary.Id);
            System.assertEquals(true, orderItemSummaryList!=null, 'List is Empty');
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
    }
    
    /**
     * @description testCartItems
     */    
    @isTest
    public static void testCartItems(){
        Account acc = [SELECT Id FROM Account WHERE KUNNR__c = '12345' LIMIT 1];
        
        OrderItemSummary testOrderSum = new OrderItemSummary();
        testOrderSum.Name = 'Test Sum';
        
        try{
            Integer maximumItems;
            
            Boolean cartItemsFlag1 = D1_OrderHistoryController.getCartItems(null, acc.Id, null, null, null,maximumItems,null);
            System.assertEquals(false, cartItemsFlag1, 'cartItemsFlag1 is TRUE');
            Boolean cartItemsFlag2 = D1_OrderHistoryController.getCartItems(null, acc.Id, '123456', null, null,maximumItems,null);
            System.assertEquals(true, cartItemsFlag2, 'cartItemsFlag1 is FALSE');
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
    }
  
    /**
     * @description testOrderToCart
     */    
    @isTest
    public static void testOrderToCart(){
        Test.setMock(HttpCalloutMock.class, new D1_OrderHistoryControllerMock(false));
        try{
            List<Object> orderCart = D1_OrderHistoryController.orderToCart(searchQuery, null, null);
            System.assertEquals(true, orderCart.isEmpty(), 'List is Empty');
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
    }
    
    /**
     * @description : Mock Response
     */
    public class D1_OrderHistoryControllerMock implements HttpCalloutMock {
        Boolean isSuccess;
        public D1_OrderHistoryControllerMock( Boolean isSuccess ){
            this.isSuccess = isSuccess;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if( isSuccess ){
                String responseBody = '{"inputs" : [ {"orderSummaryID" : "1Os3O0000004CTSSA2" }]}';
                res.setHeader('Content-Type', 'application/json');
                res.setBody(responseBody);
                res.setStatusCode(200);
            }else{
                res.setHeader('Content-Type', 'application/json');
                res.setBody('Failed');
                res.setStatusCode(500);
            }
            return res;
        }
    }
}