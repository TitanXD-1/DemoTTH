/**
 * @Name: D1_POSOrderEmailToCustomerVFContTest
 * 
 * @Description: Test class for D1_POSOrderEmailToCustomerVFController
 * 
 * @History
 * VERSION     AUTHOR         DATE               DETAIL
 * 
 **/

@isTest
public with sharing class D1_POSOrderEmailToCustomerVFContTest {
    
    /**
     * @Name : setup
	 * @description : This method is used to create dummy test data for D1_POSOrderEmailToCustomerVFContTest class
	 */   
    @testSetup
    public static void setup(){
        
        Account acc= D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(acc,'Direct Buyer');
        
        User externalUser =  [SELECT Id,AccountId,Effective_Account_Id__c FROM User WHERE Username = 'testclassextuser1@testdomain.com'];
        String recordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
       	
        Order__c order = D1_TestDataUtility.createOrder(acc.Id,recordTypeId);
        order.Request_Type__c = 'Point Of Sale';
        order.Status__c = 'Draft';
        order.Sales_Representative__c  = externalUser.Id;
        order.Delivery_Location__c = 'Outlet';
        order.Order_Type__c = 'Warehouse';
        insert order;
        
        Order_Item__c orderItem = D1_TestDataUtility.createOrderItem(order.Id);
        insert orderItem;
    }

    /**
     * @Name : testSetOrderId
	 * @description : This method is used to set and get order ID from D1_POSOrderEmailToCustomerVFController
	 */    
    @isTest
    public static void testSetOrderId(){
        
        User externalUser =  [SELECT Id,AccountId,Effective_Account_Id__c FROM User WHERE Username = 'testclassextuser1@testdomain.com'];
        
        System.runAs(externalUser){
            D1_OrderRequestController.getCurrentUser(externalUser.id);
            Order__c order = [SELECT Id FROM Order__c limit 1];
            
            Test.startTest();
            D1_POSOrderEmailToCustomerVFController ctrl = new D1_POSOrderEmailToCustomerVFController();
            // Set order ID
            ctrl.setOrderId(order.Id);
            // Get order ID
            Id orderId = ctrl.getOrderId();
            Test.stopTest();
            
            // Assertions
            System.assert(orderId != NULL, 'Order Id not found');
            Assert.isNotNull(orderId, 'Order Id not found'); 
        }
    }
}