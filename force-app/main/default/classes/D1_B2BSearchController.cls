/** 
 * @name D1_B2BSearchController
 * @description This class is controller class for getting product search results
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0       Kapil Baliyan     28/12/2020        NCP-1194
 * 2.0        Ajay             15/05/2021        NCP-2857
 * 3.0        Ajay             28/09/2021        NCP-4435
 * 4.0      Rubeena            08/02/2022        NCP-6070
 * 5.0      Swagat             20/07/2022       NCP - 6941
 **/
public with sharing class D1_B2BSearchController {

    /**
     * @description get session id
     * NOTE: Used by other apex class like D1_OrderHistoryController
     * @return  `String`
     */   
    public static String getSessionId() {
        string vfContent;
        if(Test.isRunningTest()){
            vfContent=Blob.valueOf('UNIT.TEST').tostring();
        }else{
            vfContent = Page.GenerateSessionIdForLWC.getContent().toString();
        }
        
        
        Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(), 
            endP = vfContent.indexOf('End_Of_Session_Id');
        // Get the Session Id
        string sessionId = vfContent.substring(startP, endP);
        return sessionId;
    }
    
   /**
    * @description Demonstrates how to call ConnectApi.CommerceSearch.productSearch
    * @param communityId The Id of the community from which the call originated
    * @param searchQuery The search query parameters which includes searchTerm, categoryId, refinements, page and includePrices
    * @param @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
    * @return configuration
    */
    @AuraEnabled(cacheable = false)
    public static Object productSearch(
        String communityId,
        String searchQuery,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId;
        if(!Test.isRunningTest()){
            webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        }
        
        //Fetch product search
        ConnectApi.ProductSearchInput input = (ConnectApi.ProductSearchInput) JSON.deserialize(searchQuery, ConnectApi.ProductSearchInput.class);
        ConnectApi.ProductSearchResults searchResult = ConnectApi.CommerceSearch.searchProducts( webstoreId, effectiveAccountId, input);
        ConnectApi.WishlistsSummary wishlistSummary = ConnectApi.CommerceWishlist.getWishlistSummaries(webstoreId, effectiveAccountId, true);

        return new Map<String, Object>{
            'searchResult' => searchResult,
            'productMarketInfo' => getProductMarketInfo(searchResult),
            'wishListItemInfo' => getWishListItems(wishlistSummary)
        };
    }
    
    /**
     * @description Get Product market configuration
     * @param  results Product Search results
     * @return search Results + market configuration
     */
    @testVisible
    private static Object getProductMarketInfo(ConnectApi.ProductSearchResults results){
        Map<Id, Market_Product2__c> mapOfProductMarketInfo = new Map<Id, Market_Product2__c>();
        if(results?.productsPage?.products != null){
            Set<Id> productIds = new Set<Id>();
            
            for(ConnectApi.ProductSummary summary : results.productsPage.products){
                productIds.add(summary.id);
            }
            
            User currentUser = getCurrentUser();
            List<String> availableCountries = currentUser?.Available_Countries__c == null ? new List<String>() : currentUser?.Available_Countries__c.split(';'); //NCP - 6941
            for(Market_Product2__c marketProduct: [SELECT id, Product__c, toLabel(Product_Label__c), Product_Label_Background_Color__c, Product_Ribbon_Color__r.Name, 
            Product_Ribbon_Color__r.Ribbon_Color__c FROM Market_Product2__c
                                                    WHERE Product__c IN: productIds
                                                    AND Market__r.Code__c IN: availableCountries
                                                    AND isActive__c = true])
            {
                mapOfProductMarketInfo.put(marketProduct.Product__c, marketProduct);
            }
        }
        
        return mapOfProductMarketInfo;
    }
    
    /**
     * @description fetch Sort rules
     * @param  communityId community Id
     * @return sort rule info
     */ 
    @AuraEnabled(cacheable= true)
    public static Object getSortRules(String communityId){
        String webstoreId;
        if(!Test.isRunningTest()){
            webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        }

        return ConnectApi.CommerceSearch.getSortRules(webstoreId);
    }

    /**
     * @description fetch Current user information
     * @return  current user Object
     */
    public static User getCurrentUser(){
            
        List<User> users = [SELECT id, Available_Countries__c
                            FROM User
                            WHERE id=: UserInfo.getUserId()];
        if(users.isEmpty()){
            return null;
        }
        
        return users[0];
    }

    /**
     * NCP-6070
     * @description Fetch Wishlist and its items for the user
     * @param wishListSummary user's associated wishlist sumarry
     * @return Object of product and associated wishlist
     */
    
    public static Object getWishListItems(ConnectApi.WishlistsSummary wishListSummary) {
        List<Id> wishlistIds = new List<Id>();

        for(ConnectApi.WishlistSummary wish : wishListSummary.summaries){
            wishlistIds.add(wish.Id);
        }

        Map<Id, List<WishlistItem>> mapOfWishListInfo = new Map<Id, List<WishlistItem>>();

        for(WishlistItem wl : [Select Id,WishlistId,Product2Id FROM WishlistItem WHERE WishlistId IN:wishlistIds]){
            if(mapOfWishListInfo.containsKey(wl.Product2Id)){
                mapOfWishListInfo.get(wl.Product2Id).add(wl);
            }
            else{
                mapOfWishListInfo.put(wl.Product2Id,new List<WishlistItem>{wl});
            }
        }

        return mapOfWishListInfo;
        
    }
}
   

/**
Debug Helper
-------------------
System.debug( JSON.serialize(
    D1_B2BSearchController.productSearch('0DB9E0000004clI', '{"categoryId":"0ZG9E0000004DpeWAE","refinements":[],"page":0,"includePrices":true}', '0019E00001RWVQ8QAP')
));

String data= '{"categoryId":"0ZG7Z00000000VfWAI","refinements":[{"nameOrId":"D1_Category__c","type":"DistinctValue","attributeType":"Custom","values":["Beer"]},{"nameOrId":"D1_Brand__c","type":"DistinctValue","attributeType":"Custom","values":[]}],"page":0,"includePrices":true}';

*/