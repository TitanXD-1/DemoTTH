/**
@name D1_GTMController
@description GTM Helper
@history
VERSION     AUTHOR         DATE            DETAIL
1.0         Ajay           28/6/21         Initial Development (NCP-3674)
2.0         Ajay           09/8/21         GTM metadata parameter override (NCP-4261)
**/
public without sharing class D1_GTMController {

    /**
     * @description Get User information
     * @userStory NCP-4261
     * @return configuration
     **/
    @AuraEnabled(cacheable = true)
    public static Map<String, Object> getGTMConfiguration(){
        return new Map<String, Object>{
            'userDetail' => getCurrentUserDetails(),
            'mapOfTypeParameterOverrides' => getParameterOverrideMapping()
        };
        
    }
    
    /**
     * @description Get User information
     * @updated NCP-4261
     * @return user details
     */
    public static User getCurrentUserDetails(){
        
        if(UserInfo.getUserType() == 'Guest'){
            return null;
        }
        
        List<User> users = [SELECT Id, Effective_Account_Id__c, ContactId, D1_User_Type__c, Available_Countries__c, LanguageLocaleKey
                            FROM User
                            WHERE Id =: UserInfo.getUserId()];
        return users.size() > 0 ? users[0] : null;
    }

    /**
     * @description Get Parameter override mapping 
     * @userStory NCP-4261
     * @return mapping
     */
    public static Map<String, Map<String, Map<String, String>>> getParameterOverrideMapping(){
        final String namedPage = 'comm__namedPage';	
        Map<String, Map<String, Map<String, String>>> mapOfTypeParameterOverrides = new Map<String, Map<String, Map<String, String>>>();

        for (D1_GTM_Parameter_Override__mdt overrideConfig : [SELECT Page_Type__c, Page_Content_or_Record_Name__c, Override_Parameter__c, Overridden_Value__c FROM D1_GTM_Parameter_Override__mdt]) {
            /**
             * @example: overrideConfig
             *  Page Type   | Page, Content or Record Name  | 	Override Parameter  | Overridden Value
             *  Named Page  | Training_page__c              |   pageCategory        | 	Training
             *  Named Page  | Training_page__c              |   pageTitle           | 	Training
             * */

            /**
             * For Object & CMS Content convert into url format
             * @example Order_Items__c -> order-items
             */
            if(overrideConfig.Page_Type__c != namedPage){
                overrideConfig.Page_Content_or_Record_Name__c = toURLFormat(overrideConfig.Page_Content_or_Record_Name__c);
            }
            
            /**
             *  Named Page : {Training_page__c: {pageCategory: Training, pageTitle:Training}}
             * */ 
            Map<String, Map<String, String> > pageTypeMapValue = mapOfTypeParameterOverrides.get(overrideConfig.Page_Type__c);

            if(pageTypeMapValue == null){
                pageTypeMapValue = new Map<String, Map<String, String>>();
                mapOfTypeParameterOverrides.put(overrideConfig.Page_Type__c, pageTypeMapValue);
            }

            /**
             *  Training_page__c: {pageCategory: Training, pageTitle:Training}
             * */ 
            Map<String, String> pageMapValue = pageTypeMapValue.get(overrideConfig.Page_Content_or_Record_Name__c);
            if(pageMapValue == null){
                pageMapValue = new Map<String, String>();
                pageTypeMapValue.put(overrideConfig.Page_Content_or_Record_Name__c, pageMapValue);
            }

            pageMapValue.put(overrideConfig.Override_Parameter__c, overrideConfig.Overridden_Value__c);
        }

        return mapOfTypeParameterOverrides;
    }

    /**
     * @description convert to URL format
     * @param input String to convert
     * @example Order_Items__c -> order-items
     * @return mapping
     */
    @testVisible
    private static String toURLFormat(String input){
        input = input.removeEnd('__c');
        input = input.replace('_', '-');
        return input.toLowerCase();
    }
    
    /**
     * @description Get Product information
     * @userStroy NCP-3918
     * @param productId id of product
     * @return Product
     */
    @AuraEnabled
    public static object getProduct(String productId){
        String price = '0';
        List<String> fields = new List<String>();
        fields.add('Name');
        fields.add('CurrencyIsoCode');
        fields.add('StockKeepingUnit');
        fields.add('D1_Brand__c');
        fields.add('D1_Category__c');
        fields.add('D1_Type__c');
        fields.add('Product_Card_Title__c');
        fields.add('Id');
        String communityId = '';
        String webstoreId='';
        if(UserInfo.getUserType() == 'Guest'){return null;}
        communityId = Network.getNetworkId();
        webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);        
        ConnectApi.ProductDetail obj = ConnectApi.CommerceCatalog.getProduct(webstoreId,productId,null,fields,false,null,false,false,false);
        if(obj.entitlement.canViewPrice){
            ConnectApi.ProductPrice p = ConnectApi.CommerceStorePricing.getProductPrice(webstoreId,productId,null); price = p.unitPrice;
        }
        return new Map<String, Object>{ 'productFields' => obj.fields,'canViewPrice'=> obj.entitlement.canViewPrice,'price'=>price };
       
    }
}