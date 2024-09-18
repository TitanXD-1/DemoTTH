/**
 * @name D1_B2BGetInfo
 * @description This class is controller class for adding cart item, getcartsummary
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0       Kapil Baliyan     28/12/2020        NCP-1194
 **/
public without sharing class D1_B2BGetInfo {
    /**
     * @description 
     * @param communityId 
     * @param effectiveAccountId 
     * @return  `ConnectApi.CartSummary`
     */      
    @AuraEnabled
    public static ConnectApi.CartSummary getCartSummary(String communityId, String effectiveAccountId) {
        // Lookup the webstore ID associated with the community
        String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        
        //'current' is available in version 50.0 and later and indicates a cart with a status that isn’t Closed or PendingDelete
        //This is important for the product detail page since we are using the cart summary to check if the status is "Processing" or "Checkout"
        String activeCartOrId = 'current';
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
        return ConnectApi.CommerceCart.getCartSummary(
            webstoreId,
            effectiveAccountId,
            activeCartOrId
        );
    }
    /**
     * @description 
     * @param communityId 
     * @param productId 
     * @param quantity 
     * @param effectiveAccountId 
     * @return  `ConnectApi.CartItem`
     */    
    @AuraEnabled
    public static ConnectApi.CartItem addToCart(String communityId,String productId,String quantity,String effectiveAccountId) {
        
        try{
            // Lookup the webstore ID associated with the community
            String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
            
            ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
            cartInput.productId = productId;
            cartInput.quantity = quantity;
            cartInput.type = ConnectApi.CartItemType.PRODUCT;
            
            // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm#apex_ConnectAPI_CommerceCart_static_methods
            ConnectApi.CartItem cItem = ConnectApi.CommerceCart.addItemToCart(
                webstoreId,
                effectiveAccountId,
                'active',
                cartInput
            );
            return cItem;
        }catch(exception ex){
            throw ex;
        }
    }
    /**
     * @description 
     * @param communityId 
     * @param effectiveAccountId 
     * @param productId 
     * @return  `Boolean`
     */    
    @AuraEnabled
    public static Boolean checkUniqueProduct(String communityId, String effectiveAccountId, String productId){
        Set<String> cartProdIds = new Set<String>();
        String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        String activeCartOrId = 'Current';
        ConnectApi.CartSummary cartSummary = ConnectApi.CommerceCart.getCartSummary(webstoreId, effectiveAccountId,activeCartOrId);
        WebCart userCart = [Select Id , UniqueProductCount, Sales_Area__r.Max_Order_Line_Items__c, Maximum_Limit_Reached__c From WebCart where Id =:cartSummary.cartId LIMIT 1];
        if(userCart.UniqueProductCount >= userCart.Sales_Area__r.Max_Order_Line_Items__c){
            ConnectApi.CartItemCollection cartItemResponse =  ConnectApi.CommerceCart.getCartItems(webstoreId, effectiveAccountId, activeCartOrId);            
            for (ConnectApi.CartItemResult cartItemResult : cartItemResponse.cartItems ){
                cartProdIds.add(cartItemResult.cartItem.productId);
            }
            return cartProdIds.contains(productId);
        }else{
            return true; 
        }
    }
}