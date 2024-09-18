public without sharing class D1_CatalogueListPopup {


    /**
    * @description get initial data for wish list popup
    * @param communityId The Id of the community from which the call originated
    * @param @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
    * @return configuration
    */
    @AuraEnabled(cacheable = false)
    public static Object initWishList(
        String communityId,

        String effectiveAccountId,
        String productId

    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        
        ConnectApi.WishlistsSummary wishSummary;
        if(!Test.isRunningTest()){
        	wishSummary = ConnectApi.CommerceWishlist.getWishlistSummaries(webstoreId, effectiveAccountId, true);
        }else{
            wishSummary = new ConnectApi.WishlistsSummary();
        }
        

        List<WishListWrapper> wishlists = new List<WishListWrapper>();
        if( wishSummary.summaries != NULL ){
            for( ConnectApi.WishlistSummary ws : wishSummary.summaries ){
                wishlists.add( new WishListWrapper(ws.id, ws.name.unescapeHtml4()));
            }
        }



        String category = (!String.isBlank(productId)?[Select id,D1_Category__c from Product2 where id = :productId].D1_Category__c:null);
        
        return new Map<String, Object>{

            'wislistSummaries' => wishlists,
            'webstoreId' => webstoreId,
            'category' => category

        };
    }

    /**
    * @description get initial data for wish list popup
    * @param communityId The Id of the community from which the call originated
    * @param @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
    * @return configuration
    */
    @AuraEnabled(cacheable = false)
    public static void createWishlistWithItem(
        String webstoreId,
        String effectiveAccountId,
        String wishlistName,
        String productId
    ) {
        ConnectApi.WishlistItemInput wishlistItem = new ConnectApi.WishlistItemInput();
        wishlistItem.productId = productId;

        ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
        wishlistInput.name = wishlistName;
        wishlistInput.products = new List<ConnectApi.WishlistItemInput>{wishlistItem};
        
		if(!Test.isRunningTest()){
        	ConnectApi.CommerceWishlist.createWishlist(webstoreId, effectiveAccountId, wishlistInput);
        }
    }

    /**
    * @description get initial data for wish list popup
    * @param communityId The Id of the community from which the call originated
    * @param @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
    * @return configuration
    */
    @AuraEnabled(cacheable = false)
    public static void addWishlistItem(
        String webstoreId,
        String effectiveAccountId,
        String wishlistId,
        String productId
    ) {
        ConnectApi.WishlistItemInput wishlistItem = new ConnectApi.WishlistItemInput();
        wishlistItem.productId = productId;
		
        if(!Test.isRunningTest()){
        	ConnectApi.CommerceWishlist.addItemToWishlist(webstoreId, wishlistId, wishlistItem);
        }
    }


    public class WishListWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        
        public WishListWrapper(String id, String name){
            this.id = id;
            this.name = name;
        }
    }


    
}