/**********************************************************************
Name: CartItemTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for CartItem
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0         Darshi Arpitha    28/12/2020        NCP-1485
2.0			Kapil Baliyan	  16/01/2021		NCP-   
3.0         Kapil Baliyan     17/08/2022        NCP-7232
***********************************************************************/
public without sharing class CartItemTriggerHelper {
    
    //Method to update Portfolio Item & Order Split on Cart Item
    public static void updateOrdersplit(List<CartItem> newCartItems){
        
        Set<Id> accountIds = new Set<Id>(); //Set of Ids of Cart Account
        Set<Id> productIds = new Set<Id>(); //Set of Ids of CartItem Products
        Set<Id> cartIds = new Set<Id>(); // Set Of Ids of Cart
        Set<String> itemProposalSet = new Set<String>();//PartnerFunction ItemProposal Ids
        Map<Id, Portfolio_Item__c> productPortfolioMap = new Map<Id,Portfolio_Item__c>();//Map od Product and related Portfolio
        
        //loop to get CartIds and ProductIds
        for(CartItem cItem : newCartItems){
            cartIds.add(cItem.CartId);
            if(cItem.Product2Id != null){
                productIds.add(cItem.Product2Id);
            }
        }
        
        //loop to get account ids
        if(!cartIds.isEmpty()){
            // listOfWebCart = new List<WebCart>();
            if(Schema.sObjectType.WebCart.fields.AccountId.isAccessible()){ //PMD-152932
                List<WebCart> listOfWebCart = [SELECT AccountId FROM WebCart WHERE Id IN :cartIds];
                for(WebCart cart : listOfWebCart){
                    accountIds.add(cart.AccountId);
                }
            }
        }
        
        if(!accountIds.isEmpty() && !productIds.isEmpty()){
            List<PNR_Partner_Function__c> pnrPartnerFunc = new List<PNR_Partner_Function__c>();
         if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){ //PMD-152932
                pnrPartnerFunc = [SELECT Id, Item_Proposal__c, PNR_Sold_To__c FROM PNR_Partner_Function__c 
                                  WHERE PNR_Sold_To__c 
                                  IN :accountIds 
                                  AND PNR_Type__c = 'Sold-To'];
              for(PNR_Partner_Function__c partnerFunction : pnrPartnerFunc){
                //List of itemProposal 
                 if(partnerFunction.Item_Proposal__c != null && partnerFunction.Item_Proposal__c != ''){
                    itemProposalSet.add(partnerFunction.Item_Proposal__c);
                    }
                }
            }
        }
        
        //loop to map product and related portfoilo Item
        if(itemProposalSet.size()>0){
            List<Portfolio_Item__c> pfItem = new List<Portfolio_Item__c>();
         if(Schema.sObjectType.Portfolio_Item__c.isAccessible()){ //PMD-152932
                pfItem = [SELECT Id, Product__c, Order_Split__c FROM Portfolio_Item__c 
                            WHERE Product__c IN :productIds 
                            AND Portfolio_ID__c IN :itemProposalSet 
                            AND Inactive__c = FALSE];
                for(Portfolio_Item__c pItem: pfItem) //NCP-7232 Added Inactive__c check
                {
                    if(pItem!= null){
                        productPortfolioMap.put(pItem.Product__c, pItem);
                    }
                }
            }
        }
        
        //getting the related portfolioItem of the cartItem's product and mapping to cartItem portfolioItem and OrderSpilt
        for(CartItem ci : newCartItems){
            if(!productPortfolioMap.isEmpty() && productPortfolioMap.get(ci.Product2Id)!= null){
                ci.Portfolio_Item__c = productPortfolioMap.get(ci.Product2Id).Id;
                ci.OrderSplit_Type__c = productPortfolioMap.get(ci.Product2Id).Order_Split__c;
            }
        }
    }
    
    //Method to update Order Split on Cart
    //For IE we are only handling Max 2 Order Splits, once we have more order split this method needs to be updated
    public static void updateCartOrderSplit(Map<Id, SObject> newItems){
        Map<Id, Set<Id>> cartOrderSplitMap = new Map<Id, Set<Id>>();
        List<WebCart> cartList = new List<WebCart>();
        Map<Id, CartItem> cartItemMap = (Map<Id, CartItem>) newItems;
        Map<Id, Id> pItemCartMap = new Map<Id, Id>();
        Map<Id, String> cartPortfolioExtIdMap = new Map<Id, String>();
        Map<String, CommerceEntitlementPolicy> entitlementPolicyMap = new Map<String, CommerceEntitlementPolicy>();

        for(CartItem cItem : cartItemMap.values()){
            //Creating ordersplit cart map
            if(cartOrderSplitMap.containsKey(cItem.CartId)){
                cartOrderSplitMap.get(cItem.CartId).add(cItem.OrderSplit_Type__c);
            }else{
                cartOrderSplitMap.put(cItem.CartId, new Set<Id>{cItem.OrderSplit_Type__c});
            }

            //Creating Set of Portfolio Item Id
            if(cItem.Portfolio_Item__c != null){
                pItemCartMap.put(cItem.Portfolio_Item__c, cItem.CartId);
            }
        }

        if(!pItemCartMap.isEmpty()){
            //Create cart w/ Portfolio ID Map
            for(Portfolio_Item__c item : [SELECT Id, Portfolio_ID__c FROM Portfolio_Item__c WHERE Id IN :pItemCartMap.keySet()]){
                Id cartId = pItemCartMap.get(item.Id);
                cartPortfolioExtIdMap.put(cartId, item.Portfolio_ID__c);
            }

            //Create Portfolio Id w/ CommerceEntitlementPolicy Map
            List<CommerceEntitlementPolicy> commerceEntPolicy = new List<CommerceEntitlementPolicy>();
                
            commerceEntPolicy = [SELECT Id, PortfolioID__c, CanViewPrice FROM CommerceEntitlementPolicy WHERE PortfolioID__c IN :cartPortfolioExtIdMap.values()]; //NOPMD
                for(CommerceEntitlementPolicy policy : commerceEntPolicy){
                    entitlementPolicyMap.put(policy.PortfolioID__c, policy);
                }
        }
        
        if(!cartOrderSplitMap.isEmpty()){
            List<WebCart> wbCart = new List<WebCart>();
         if(Schema.sObjectType.WebCart.isUpdateable()){ //PMD-152932
                wbCart = [SELECT Id, Order_Split_1__c, Order_Split_2__c, CanViewPrice__c FROM WebCart WHERE Id IN :cartOrderSplitMap.keySet()];
                for(WebCart cart : wbCart){
                    set<Id> orderSplitIdSet = cartOrderSplitMap.get(cart.Id);
                    boolean isCartUpdate = false;
                    //Update Order Split
                    if(!orderSplitIdSet.isEmpty()){
                        for(Id orderSplitId : orderSplitIdSet){
                            //If both are null assign split 1 for order split 1
                            if(cart.Order_Split_1__c == null && cart.Order_Split_2__c == null){
                                cart.Order_Split_1__c = orderSplitId;
                                isCartUpdate = true;
                            }
                            //Check if Order Split 1 is not null && not equals to orderSplitId && Order Split 2 not equals to orderSplitId, than only update
                            else if(cart.Order_Split_1__c != null && cart.Order_Split_1__c != orderSplitId && cart.Order_Split_2__c != orderSplitId){
                                cart.Order_Split_2__c = orderSplitId;
                                isCartUpdate = true;
                            }
                            //Check if Order Split 2 is not null && not equals to orderSplitId && Order Split 1 not equals to orderSplitId, than only update
                            else if(cart.Order_Split_2__c != null && cart.Order_Split_2__c != orderSplitId && cart.Order_Split_1__c != orderSplitId){
                                cart.Order_Split_1__c = orderSplitId;
                                isCartUpdate = true;
                            }
                        }
                    }
                    //Update CanViewProce
                    if(cartPortfolioExtIdMap != null && cartPortfolioExtIdMap.containsKey(cart.Id)){
                        string portfolioID = cartPortfolioExtIdMap.get(cart.Id);
                        if(entitlementPolicyMap != null && entitlementPolicyMap.containsKey(portfolioID)){
                            CommerceEntitlementPolicy policy = entitlementPolicyMap.get(portfolioID);
                            if(cart.CanViewPrice__c != policy.CanViewPrice){
                                cart.CanViewPrice__c = policy.CanViewPrice;
                                isCartUpdate = true;
                            } 
                        }
                    }
                    //If Cart is Updated than only add to cartList for DML
                    if(isCartUpdate){
                        cartList.add(cart);
                    }
                }
            }
        }
        
        //Do DML
        if(!cartList.isEmpty()){
            update cartList;
        }
    }
    
    public static void deleteCartOrderSplit(Map<Id, SObject> oldItems){
        Map<Id, Set<Id>> cartOrderSplitMap = new Map<Id, Set<Id>>();
        Set<string> cartOrderSplitSet = new Set<string>();
        Map<String, Integer> cartItemCountMap = new Map<String, Integer>();
        List<WebCart> cartList = new List<WebCart>();
        Map<Id, CartItem> cartItemMap = (Map<Id, CartItem>) oldItems;
        
        for(CartItem cItem : cartItemMap.values()){
            //Creating ordersplit cart map
            if(cartOrderSplitMap.containsKey(cItem.CartId)){
                cartOrderSplitMap.get(cItem.CartId).add(cItem.OrderSplit_Type__c);
            }else{
                cartOrderSplitMap.put(cItem.CartId, new Set<Id>{cItem.OrderSplit_Type__c});
            }
            string key = cItem.CartId + '_' + cItem.OrderSplit_Type__c;
            cartOrderSplitSet.add(key);
        }
        
        //Get Count of CartItems
        // ctItem = new List<CartItem>();
        if(Schema.sObjectType.CartItem.isAccessible()){ //PMD-152932
            AggregateResult[] ctItem = [SELECT CartId, OrderSplit_Type__c, Count(Id)itemCount FROM CartItem WHERE CartId In :cartOrderSplitMap.keySet() Group By CartId, OrderSplit_Type__c];
                for(AggregateResult ar : ctItem)
            {
                string key = ar.get('CartId') + '_' + ar.get('OrderSplit_Type__c');
                integer itemCount = Integer.valueOf(ar.get('itemCount'));
                cartItemCountMap.put(key, itemCount);
            }
            System.debug(LoggingLevel.INFO,'@@cartItemCountMap' + cartItemCountMap); 
        }    
        
        //Update Cart
        for(WebCart cart : [SELECT Id, Order_Split_1__c, Order_Split_2__c, Split_1_Delivery_date__c, Split_2_Delivery_date__c, PoNumber, Split_2_PO_Number__c
                            FROM WebCart WHERE Id IN :cartOrderSplitMap.keySet()])
        {
            boolean isUpdate = false;
            //Check if for Order Split 1 is there any cart item, if not clear Order Split1, Split1 Delivery Date & PoNumber
            if(cart.Order_Split_1__c != null){
                string key = cart.Id + '_' + cart.Order_Split_1__c;
                if(!cartItemCountMap.containsKey(key)){
                    cart.Order_Split_1__c = null;
                    cart.Split_1_Delivery_date__c = null;
                    cart.PoNumber = '';
                    
                    isUpdate = true;
                }
            }
            
            //Check if for Order Split 2 is there any cart item, if not clear Order Split2, Split2 Delivery Date & Split 2 PoNumber
            if(cart.Order_Split_2__c != null){
                string key = cart.Id + '_' + cart.Order_Split_2__c;
                if(!cartItemCountMap.containsKey(key)){
                    cart.Order_Split_2__c = null;
                    cart.Split_2_Delivery_date__c = null;
                    cart.Split_2_PO_Number__c = '';
                    
                    isUpdate = true;
                }
            }
            
            //if cart is updated
            if(isUpdate){
                cartList.add(cart);
            }
        }
        
        //Update cart
        if(cartList.size()>0){
            update cartList;
        }
    }

}