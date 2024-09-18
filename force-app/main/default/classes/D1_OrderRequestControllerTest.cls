/**
 * @name : D1_OrderRequestControllerTest
 * @description : Test Class D1_OrderRequestController
 * @history                                                                                                         
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Mukesh          15/04/2021         Initial Development
 * 2.0         Amar            07/05/2021         NCP-2679
 * 3.0			Abhishek		06/07/2021			NCP-3782
 **/
@isTest
public class D1_OrderRequestControllerTest {
    /**
     * @description setup for test data
     */    
    @testSetup
    public static void setup(){
        Test.startTest();
        account acc= D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(acc,'Direct Buyer');
         String recordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
       	order__c order = D1_TestDataUtility.createOrder(acc.Id,recordTypeId);
        insert order;
        Order_Item__c orderItem = D1_TestDataUtility.createOrderItem(order.Id);
        insert orderItem;
        Test.stopTest();
    }
    /**
     * @description test get pos orders
     */  
    @isTest
    public static void testGetPOSOrders(){
        Account deliveryAddress = [Select Id from Account limit 1]; //NOPMD
        User externalUser =  [select Id,AccountId,Effective_Account_Id__c from User where Username = 'testclassextuser1@testdomain.com'];
        //String recordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('POS Order').getRecordTypeId();

        system.runAs(externalUser){
            String requestType;
            String filterStr = '{"deliveryAddress":"13N0000000efp1XQAQ","startDate":"2020-04-07T07:23:58.000+0000","endDate":"2030-04-07T07:23:58.000+0000","requestType":["Glassware"]}';
            Test.startTest();
            D1_OrderRequestController.getCurrentUser(externalUser.id);
            List<Order__c> orderList = D1_OrderRequestController.getPOSOrders(filterStr,requestType,true,true);
            Test.stopTest();
            
            System.assert(orderList != NULL, 'order list not found');
        }
    }
    /**
     * @description test get transfer orders
     */  
    @isTest
    public static void testGetTransferOrders(){
        Account deliveryAddress = [Select Id from Account limit 1]; //NOPMD
        User externalUser =  [select Id,AccountId,Effective_Account_Id__c from User where Username = 'testclassextuser1@testdomain.com'];
 		Order__c order = [Select Id FROM Order__c limit 1];
        system.assert(order.Id!= null, 'order id not found');
        
        system.runAs(externalUser){     
            //String requestType;
            String filterStr = '{"deliveryAddress":"13N00000efp1XQAQ","startDate":"2020-04-07T07:23:58.000+0000","endDate":"2030-04-07T07:23:58.000+0000","requestType":["Glassware"]}';
            Test.startTest();
            D1_OrderRequestController.getCurrentUser(externalUser.id);
            D1_OrderRequestController.getTransferOrders(filterStr,true,true);
            D1_OrderRequestController.updateOrderStatus(order.Id);
            Test.stopTest();
            System.Assert(D1_OrderRequestController.getTransferOrders(filterStr,true,true)!= NULL, 'order Transfer not Available');              
            Assert.isTrue(D1_OrderRequestController.getTransferOrders(filterStr,true,true)!= NULL, 'order Transfer not Available'); 
        }
    }
}