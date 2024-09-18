public without sharing class D1_CheckoutFlow_UpdateOrderItems {
    @InvocableMethod(label='Update Order Items' description='')
	public static void updateOrderItems(List<D1_CheckoutFlow_UpdateOrderItems.cartOrderWrapper> cartOrderWrapList){
		List<orderItem> orderItemsToUpdate = new List<orderItem>();
		Map<Id, CartItem> productWithCartItemMap = new Map<Id, CartItem>();
		if(Schema.sObjectType.CartItem.isAccessible()){
		for(CartItem ci :[SELECT Id, product2Id, OrderSplit_Type__c, Portfolio_Item__c 
							FROM CartItem 
							WHERE cartId = :cartOrderWrapList[0].cartId]){
			productWithCartItemMap.put(ci.product2Id, ci);
		}
	}

	if(Schema.sObjectType.OrderItem.isAccessible()){
		for(OrderItem oItem : [SELECT Id, product2Id, OrderSplit_Type__c, Portfolio_Item__c 
								FROM OrderItem 
								WHERE OrderId = :cartOrderWrapList[0].orderId]){
			if(productWithCartItemMap.containsKey(oItem.product2Id)){
				oItem.OrderSplit_Type__c = productWithCartItemMap.get(oItem.product2Id).OrderSplit_Type__c;
				oItem.Portfolio_Item__c = productWithCartItemMap.get(oItem.product2Id).Portfolio_Item__c;
			}
			orderItemsToUpdate.add(oItem);
		}
	}
		if(!orderItemsToUpdate.isEmpty()){
			update orderItemsToUpdate;
        }
    }    

    public class CartOrderWrapper {
        @invocablevariable(Required = True) public String cartId;
        @invocablevariable(Required = True) public String orderId;
	}
}