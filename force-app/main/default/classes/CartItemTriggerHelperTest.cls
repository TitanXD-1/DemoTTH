/**
 * @name : CartItemTriggerHelperTest
 * @description : Test class for CartItemTriggerHelper
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0         D1 Dev team
 * 2.0			Rubeena		   01/07/2021		  Test Class Refractor [NCP-3763]
**/
@isTest
public class CartItemTriggerHelperTest {
    /**
    * @name : setupData
    * @description : This method is used to set up test data
    */
    @testSetup
    public static void setupData(){
        Account account = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        
        WebStore webstoreObj = D1_TestDataUtility.getWebStore();
        insert webstoreObj;

        Sales_Area__c sa = [SELECT Id FROM Sales_Area__c LIMIT 1];

        Product2 prodObj = D1_TestDataUtility.getProduct();
        insert prodObj;
  
        OrderSplit__c oSpilt = D1_TestDataUtility.insertOrderSplit(sa.Id);
        insert oSpilt;
        
        Portfolio_Item__c portItem = D1_TestDataUtility.getPortfolioItem(prodObj.Id,oSpilt.Id);
        portItem.Portfolio_ID__c = '223344';
        insert portItem;
        
        CommerceEntitlementPolicy entPolicyObj = D1_TestDataUtility.getCommerceEntitlementPolicy('TestPolicy','223344');
        insert entPolicyObj;
         
        WebCart webCArtObj = D1_TestDataUtility.getWebCart(webstoreObj.Id,account.Id,oSpilt.Id,oSpilt.Id);
        insert webCArtObj;
        
        CartDeliveryGroup cartDeliveryGroup = D1_TestDataUtility.getCartDeliveryGroup(webCArtObj.Id);
        insert cartDeliveryGroup;
    }
    /**
    * @name : testInsertCartItems
    * @description : This method is used to test helper methods of Cartitemtrigger
    */
    @isTest
    public static void testInsertCartItems() {
        WebCart webCArtObj = [SELECT Id, CanViewPrice__c FROM WebCart LIMIT 1]; 

        List<cartItem> cartItems = new List<CartItem>();
        CartItem cartItem = D1_TestDataUtility.getCartItem(webCArtObj.Id);
        cartItem.Product2Id = [SELECT Id FROM Product2 LIMIT 1].Id;
        cartItem.CartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup LIMIT 1].Id;
        cartItems.add(cartItem);

        Test.startTest();
            //Create Org Setting to test Trigger
            D1_TestDataUtility.createOrgSettings();

            //Insert cartItem
            insert cartItems;
            System.assert(cartItems.size()>0,'Cart insertion failed');
            
            //Update webcart & cartItem
            webCArtObj.CanViewPrice__c = false;
            update webCArtObj;

            cartItem.Sku = 'sku_test2';
            update cartItem;
            
            //Delete cartItem
            delete cartitem;
        Test.stopTest();
    }
}