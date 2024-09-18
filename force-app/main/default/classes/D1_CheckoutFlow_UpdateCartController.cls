public with sharing class D1_CheckoutFlow_UpdateCartController {
    @InvocableMethod(label='Update Cart PO' description='')
	public static void updateCartPOnumbers(List<Id> cartIds){
        WebCart checkoutCart = [SELECT Id, PoNumber, Split_2_PO_Number__c, 
                                    Split1_Auto_PO_Number__c, Split2_Auto_PO_Number__c, Order_Split_1__c, Order_Split_2__c 
                                    FROM WebCart WHERE Id = :cartIds[0]]; 
        if(checkoutCart.Order_Split_1__c != Null && String.isBlank(checkoutCart.PoNumber)){
           checkoutCart.PoNumber = checkoutCart.Split1_Auto_PO_Number__c;  
        }
        if(checkoutCart.Order_Split_2__c !=Null && String.isBlank(checkoutCart.Split_2_PO_Number__c)){
           checkoutCart.Split_2_PO_Number__c = checkoutCart.Split2_Auto_PO_Number__c; 
        }
        update checkoutCart;

    }
}