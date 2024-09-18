/**
 * @name D1_ProductRecommendationController
 * @description Controller class for Product Recommendation
 * @history
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           21/02/2023      Initial Development(NCP-) 
 */
public without sharing class D1_ProductRecommendationController {
    
    /**
     * @description Method to get Recommended Products
     * @param recordId 
     * @return  `List<String>`
     * @exception 
     */
    @AuraEnabled
    public static List<String> getRecommendedProducts(Id recordId, Id effectiveAccountId){
        try {
            List<String> skuList = new List<String>();
            if(String.isBlank(recordId)){
                return null;
            }else{
                User usr = getUser(UserInfo.getUserId());
                String sObjectName = recordId.getSobjectType().getDescribe().getName();

                switch on sObjectName {
                    when 'Product2' {
                        Set<Id> prodIdSet = new Set<Id>{recordId};
                        skuList = getRecommendedProductsForProduct(prodIdSet, usr.Available_Countries__c);
                    }
                    when 'WebCart' {
                        skuList = getRecommendedProductsForWebCart(recordId, usr.Available_Countries__c);
                    }
                    when 'ProductCategory' {
                        skuList = getRecommendedProductsForProductCategory(usr, effectiveAccountId);
                    }
                    when else {
                        System.debug(LoggingLevel.INFO, skuList);
                    }
                }

                return skuList;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Method to get Recommended Product Based on Product
     * @param prodIdSet 
     * @param countryCode 
     * @return  `List<String>`
     */
    public static List<String> getRecommendedProductsForProduct(Set<Id> prodIdSet, string countryCode){
        Set<String> skuSet = new Set<String>();

        //Get Recommended Product SKUs
        if(Schema.sObjectType.D1_Product_Recommendation__c.isAccessible()){
        for(D1_Product_Recommendation__c prodRecommended : [SELECT Id, Recommended_Product__c, Recommended_Product__r.StockKeepingUnit FROM D1_Product_Recommendation__c 
                                                            WHERE Master_Product__c IN :prodIdSet AND Is_Active__c = TRUE AND Country__r.Code__c =:countryCode AND Recommended_Product__r.IsActive = TRUE 
                                                            AND Recommended_Product__r.StockKeepingUnit != NULL ORDER BY LastModifiedDate DESC])
        {
            skuSet.add(prodRecommended.Recommended_Product__r.StockKeepingUnit);
        }
    }
        List<String> skuList = !skuSet.isEmpty() ? new List<String>(skuSet) : new List<String>();

        return skuList;
    }

    /**
     * @description Method to get Recommended Product Based on Cart
     * @param recordId 
     * @param countryCode 
     * @return  `List<String>`
     */
    public static List<String> getRecommendedProductsForWebCart(string recordId, string countryCode){
        List<String> skuList = new List<String>();
        Set<Id> prodIdSet = new Set<Id>();
        //Create ProductId Set which are added to Cart
        for(CartItem ci : [SELECT Id, Product2Id FROM CartItem WHERE CartId =:recordId WITH SECURITY_ENFORCED]){
            prodIdSet.add(ci.Product2Id);
        }

        if(!prodIdSet.isEmpty()){
            skuList = getRecommendedProductsForProduct(prodIdSet, countryCode);
        }

        return skuList;
    }

    /**
     * @description Method to get Recommended Product Based on Product Catalog
     * @param usr 
     * @return  `List<String>`
     */
    public static List<String> getRecommendedProductsForProductCategory(User usr, Id effectiveAccountId){
        List<String> skuList = new List<String>();

        //Get Cart Id
        B2BUtils.GenericCartWrapper gCartWrapper = B2BUtils.getCartId(usr.Id, effectiveAccountId);

        //Call getRecommendedProductsForWebCart to get Recommended Products
        if(gCartWrapper != null && gCartWrapper.cartId != null){
            skuList = getRecommendedProductsForWebCart(gCartWrapper.cartId, usr.Available_Countries__c);
        }
        
        return skuList;
    }

    /**
     * @description Method to get User Details
     * @param userId 
     * @return  `User`
     */
    public static User getUser(Id userId){
        List<User> usrList = [SELECT Id, Effective_Account_Id__c, Available_Countries__c FROM User WHERE Id =:userId WITH SECURITY_ENFORCED];

        return usrList.get(0);
    }
}