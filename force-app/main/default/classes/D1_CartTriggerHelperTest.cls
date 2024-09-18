/*
 * @name: D1_CartTriggerHelperTest
 * @description : The test class provides coverage for:
 * D1_CartTriggerHelper
 * D1_OrderdeliverdatesCntrl
 * D1_CheckoutFlow_UpdateOrderItems
 * D1_CheckoutFlow_UpdateCartController
 * @history
 * VERSION     AUTHOR         DATE               DETAIL
 * 1.0          -        		-                    -
 * 2.0			Rubeena		   01/07/2021		  Test Class Refractor [NCP-3802]
 **/
@isTest
public class D1_CartTriggerHelperTest {
    /**
     * @description 
     */    
    @testSetup 
    public static void createTestData() {
        Account dc = D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(dc, 'Direct Buyer');
        D1_TestDataUtility.insertCartAndCartItems(dc);
        
    }
    /**
     * @description 
     */    
    @isTest
    public static void testInsertCartItems() {
        
        User userObj = [select Id,AccountId,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1]; 
        D1_TestDataUtility.createOrgSettings();
        system.runAs(userObj){
            D1_TestDataUtility.b2bCommercePermissionset(userObj);
        }
        
        Account acc=[select id,Delivery_Plant__c,Salesforce_Delivery_Days_Packaged_Good__c,Delivery_Pattern__c from account where id=:userObj.AccountId];
        
        Product2 prodObj =[Select id from Product2 where name='Test P' LIMIT 1];    

        OrderSplit__c oSplit1 = [Select Id FROM OrderSplit__c WHERE Description__c ='Test1234' limit 1];
        OrderSplit__c oSplit2 = [Select Id FROM OrderSplit__c WHERE Description__c ='Test1234NK' limit 1];
        
        WebStore ws = D1_TestDataUtility.getWebStore();
        insert ws;
  
		Portfolio_Item__c pfItem = [SELECT Id FROM Portfolio_Item__c WHERE Portfolio_ID__c ='PF-1234' limit 1];

        Test.startTest();
        
        ContactPointAddress cpa = D1_TestDataUtility.insertContactPointAddress();
        cpa.ParentId = acc.Id;
        cpa.Source__c = 'Diageo One';
        insert cpa;

        WebCart webCArtObj = D1_TestDataUtility.getWebCart(ws.Id,userObj.AccountId,oSplit1.Id,oSplit2.Id);
        webCArtObj.Delivery_Address__c = cpa.Id;
        insert webCArtObj;

        D1_OrderdeliverdatesCntrl.getOrdersplits(userObj.AccountId);
        D1_OrderdeliverdatesCntrl.getDeliveryDates(oSplit1.Id, userObj.AccountId,'12345');
        D1_OrderdeliverdatesCntrl.getDeliveryDates(oSplit2.Id, userObj.AccountId,'12345');
        D1_OrderdeliverdatesCntrl.getnextDeliveryDates(oSplit1.Id, userObj.AccountId,'12345');
        D1_OrderdeliverdatesCntrl.createDateWrapper(System.today(),System.now(),'Keg');
        
        // calling checkOutflow class 
        // Start
        webCArtObj.PoNumber = '';
        webCArtObj.Split_2_PO_Number__c='';
        update webCArtObj;
        
        List<ID> cartIds = new List<ID>();            
        cartIds.add(webCArtObj.id);
        
        Order ordRec = D1_TestDataUtility.getOrder(acc.Id);          
        insert ordRec;
        
        OrderItem ordProd = D1_TestDataUtility.getOrderItem(ordRec.Id);
        ordProd.Product2Id = prodObj.id;
        ordProd.OrderSplit_Type__c = oSplit1.id;
        ordProd.Portfolio_Item__c = pfItem.id;
        insert ordProd;

        ordRec.Status = 'Activated';
        update ordRec;
        
        D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper  cartOrdWrap =  new D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper();
        cartOrdWrap.cartId = webCArtObj.id;
        cartOrdWrap.orderId = ordRec.id;
        
        List<D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper> cartOrdWrapList = new List<D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper>();
        cartOrdWrapList.add(cartOrdWrap);
        System.assert(D1_CheckoutFlow_UpdateOrderItems.updateOrderItems(cartOrdWrapList) == NULL, 'Items not updated');
        D1_CheckoutFlow_UpdateCartController.updateCartPOnumbers(cartIds);
        
        delete webCArtObj;
        
        Test.stopTest();
        
    }
    
}