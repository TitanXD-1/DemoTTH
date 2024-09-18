/**
 * @name D1_OrderTriggerHelperTest
 * @purpose Test Class for D1_OrderTriggerHelper
 * @description Covers coverage for D1_OrderTriggerHelper
 * @history                                                                                                                      
 * VERSION   AUTHOR              DATE              DETAIL
 * 1.0       Rubeena Naaz      30/07/2021        NCP-3874,NCP-3826,NCP-3818
**/
@isTest
public class D1_OrderTriggerHelperTest {
    /**
      * @description Test setup data for D1_OrderTriggerHelperTest
      **/
    @testSetup
    public static void testSetup(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id = :countryId];
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test[GB]');  
        Account outletAccount = D1_TestDataUtility.getD1Customer();//outlet record
        outletAccount.Direct_Customer__c = false;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;

        D1_TestDataUtility.setUpExternalUser(outletAccount,'Outlet/Retailers');
        Id posOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
		Order__c order = D1_TestDataUtility.createOrder(outletAccount.Id, posOrderRecTypeId);
        order.Request_Type__c = 'Equipment';
        order.Status__c = 'Draft';
        insert order;
        
        List<AccountContactRelation> acrs = [select id, D1_Roles__c from AccountContactRelation];
        for(AccountContactRelation acr :acrs){
            acr.D1_Roles__c='POS & Equipment Ordering;Transfer Orders';
            acr.D1_Active__c = True;
            acr.D1_User_Role__c = 'Primary';
        }
        update acrs;
        
    }
    /**
      * @description testPOSOrderNotification method
      **/
    @isTest
    public static void testPOSOrderNotification(){
        D1_TestDataUtility.createOrgSettings();
        //User externalUser= [Select id from User where Email ='testclassextuser1@testdomain.com' limit 1];
        Order__c order = [Select Id,Status__c ,Name,Delivery_Address__c,Request_Type__c,RecordTypeId,Source_Application__c,Account__c,Record_Type_Name__c from Order__c WHERE Request_Type__c='Equipment' limit 1];
                
        Test.startTest();
            order.Status__c = 'Approved';
            update order;
        Test.stopTest();
        System.assertEquals('Approved', order.Status__c, 'Order Status is ' + order.Status__c);
    }
    /**
      * @description testTransferOrderNotification method
      **/
    @isTest
    public static void testTransferOrderNotification(){
        D1_TestDataUtility.createOrgSettings();
        List<Order__c> orderList = new List<Order__c>();
        User externalUser= [Select id from User where Email ='testclassextuser1@testdomain.com' limit 1];
        Account  outletAccount= [SELECT Id FROM Account WHERE Name = 'Test Customer Account' limit 1];
        Id transferOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        Order__c order2 = D1_TestDataUtility.createOrder(outletAccount.Id, transferOrderRecTypeId);
        order2.Status__c = 'Submitted';
        orderList.add(order2);
        insert orderList;
        
        Order__c orderRec = [Select id,Status__c,Name,Delivery_Address__c,Request_Type__c,RecordTypeId,Source_Application__c,Account__c from Order__c where Id = :order2.Id];
        
        System.runAs(externalUser){
            Test.startTest();
            D1_OrderTriggerHelper.transferOrderNotification(new List<Order__c>{orderRec});
            Test.stopTest();
            System.assertEquals('Submitted', orderList[0].Status__c, 'Order status is ' + orderList[0].Status__c);
        }
        
    }
    @isTest
    public static void testupdatePOSOrderDate(){
        D1_TestDataUtility.createOrgSettings();
        Order__c order = [Select Id,Status__c ,Name,Delivery_Address__c,Request_Type__c,RecordTypeId,Source_Application__c,Account__c,Record_Type_Name__c from Order__c WHERE Request_Type__c='Equipment' limit 1];
        Map<ID, Order__c> oldItem = new Map<ID, Order__c>([Select Id,Status__c ,Name,Source_Application__c,Account__c,Record_Type_Name__c from Order__c WHERE Request_Type__c='Equipment' limit 1]);
        
        order.Status__c = 'Approved';
        update order;
        
        Map<ID, Order__c> newItem = new Map<ID, Order__c>([Select Id,Status__c ,Name,Source_Application__c,Account__c,Record_Type_Name__c from Order__c WHERE Request_Type__c='Equipment' limit 1]);
		
        Test.startTest();
        D1_OrderTriggerHelper.updatePOSOrderDate(newItem, oldItem);
        Test.stopTest();
        Account acc = [Select Id, Last_POS_Order_Date__c from Account where Id =: order.Account__c];
        
        System.Assert(acc!=null,'POS Order Date update Failed');
    }
}