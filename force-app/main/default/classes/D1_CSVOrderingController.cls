/**
 * @name D1_CSVOrderingController
 * @purpose Controller for Download/Upload CSV file in Catalogue page
 * @history                                                                                                                       
 * VERSION      AUTHOR             DATE             DETAIL
 * 1.0          Subhrojit         20/04/2023        Initial Development(NCP-8181)
 * 2.0          Pratap            21/04/2023        NCP-8177
**/
public without sharing class D1_CSVOrderingController {

    private static String webStoreName = System.Label.D1_Commerse_StoreName;

    /**
    * @description : Fetches ConnectApi Product Search Result
    * @param       : searchQuery (String) - Search Query String, userId (String) - User Id
    * @return      : `ProductWrapper` 
    * @reference   : https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_connectapi_output_product_search_results.htm
    */
    @AuraEnabled(cacheable = false)
    public static CsvDownloadWrapper getProducts(String searchQuery, String userId) {
        List<ConnectApi.ProductSummary> finalProductList  = new List<ConnectApi.ProductSummary>();
        ConnectApi.ProductSearchInput searchInput;
        ConnectApi.ProductSearchResults searchResult;
        Decimal pageSize = 200.0;
        Integer numberOfCalls = 0;
        
        User userDetail = [SELECT Effective_Account_Id__c FROM User WHERE Id =:userId WITH SECURITY_ENFORCED  LIMIT 1];
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name =:webStoreName WITH SECURITY_ENFORCED LIMIT 1];
        String categoryId = D1_CustomCommunityThemeController.getProductCategoryId();
        searchQuery = searchQuery.replace('@', categoryId);
        	
        try{
            for(Integer pageNumber = 0; pageNumber <= numberOfCalls; pageNumber++){
                
                searchQuery = searchQuery.removeEnd('}');
                searchQuery = searchQuery + ',"page":' + pageNumber;
                searchQuery = searchQuery + ',"pageSize":' + pageSize.intValue();
                searchQuery = searchQuery + '}';

                searchInput = (ConnectApi.ProductSearchInput) JSON.deserialize(searchQuery, ConnectApi.ProductSearchInput.class);
                searchResult = ConnectApi.CommerceSearch.searchProducts(webStore.Id, userDetail.Effective_Account_Id__c, searchInput);
                
                finalProductList.addAll(searchResult.productsPage.products);
                if(pageNumber == 0){
                    numberOfCalls = Integer.valueOf(Math.ceil(searchResult.productsPage.total / pageSize) - 1);
                }
            }
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }
        
        CsvDownloadWrapper retVal = new CsvDownloadWrapper();
        retVal.productList = finalProductList;
        retVal.headerFieldSet = getFieldSet('Product2', 'CSV_Product_Field_Set');
        return retVal;
    }

    /*Wrapper to send required data for CSV download*/
    public class CsvDownloadWrapper{
        @AuraEnabled public List<ConnectApi.ProductSummary> productList;
        @AuraEnabled public String headerFieldSet;
    }

    /**
     * Get Field Set for any sObject against Name
     * @userStory NCP-8181 
     * @param {String} sObjectName
     * @param {String} fieldSetName
     * @return {String}
     */
    @AuraEnabled(cacheable=true)
    public static String getFieldSet(String sObjectName, String fieldSetName) {
        String result = '';
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(sObjectName);
            Schema.DescribeSObjectResult d = objToken.getDescribe();
            Map<String, Schema.FieldSet> fieldSetMap = d.fieldSets.getMap();
            if(fieldSetMap.containsKey(fieldSetName)){
                for(Schema.FieldSetMember f : fieldSetMap.get(fieldSetName).getFields()) {
                     
                    if(String.isNotBlank(result)){
                        result += ',';
                    }
                    String jsonPart = '{';
                    jsonPart += '"required":"' + (f.getDBRequired() || f.getRequired()) + '",';
                    jsonPart += '"type":"' + (f.getType()) + '",';
                    jsonPart += '"label":"' + (f.getLabel()) + '",';
                    jsonPart += '"name":"' + f.getFieldPath() + '"';
                    jsonPart += '}';
                    result += jsonPart;
                }
            }
        }
        catch(Exception ex){
            result += ex.getLineNumber() + ' : ' + ex.getMessage();
        }
        return '['+result+']';
       
    }

    /**
    * @description : Adds Products in Cart
    * @param       : orderItems (String) - JSON String of Map of SKUs & Quantity, userId (String) - User Id, maxCartLimit (String) - cart max size
    * @return      : `Map<String,String>` - Map of Product SKU which is not added in Cart and the Error Message
    * @reference   : https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_CommerceCart_static_methods.htm#apex_ConnectAPI_Commerce_addItemsToCart_1
    */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled
    public static AddToCartResultWrapper addToCart(String orderItems, String userId, String maxCartLimit) { 
        Map<String,String> errorMsgWithProduct = new Map<String,String>();              //Map of Failed Products to Return
        Map<String,String> productSKUId = new Map<String,String>();                     //Map Of Product SKU & Product Id
        List<ConnectApi.BatchInput> cartItems = new List<ConnectApi.BatchInput>();      //List of BatchInput to pass into ConnectApi.CommerceCart.addItemsToCart
        List<String> prodSKUList = new List<String>();                                  //List of Product SKUs
        
        Map<String,String> skuQtyMap = (Map<String,String>)JSON.deserialize(orderItems, Map<String,String>.class);

        //Fetch Product Ids
        for(Product2 prodRec : [SELECT Id,StockKeepingUnit FROM Product2 WHERE StockKeepingUnit IN: skuQtyMap.keySet()]){
            productSKUId.put(prodRec.StockKeepingUnit, prodRec.Id);
        }

        //Create List of ConnectApi.CartItemInput
        for(String prodSKU : skuQtyMap.keySet()){
            if(productSKUId.containsKey(prodSKU)){
                ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
                cartInput.productId = productSKUId.get(prodSKU);
                cartInput.quantity = skuQtyMap.get(prodSKU);     
                cartInput.type = ConnectApi.CartItemType.PRODUCT;

                cartItems.add(new connectApi.BatchInput(cartInput));
                prodSKUList.add(prodSKU);
            }
            else{
                errorMsgWithProduct.put(prodSKU, System.Label.D1_CSV_InvalidSKUMsg);
            }
        }  
        
        //Query Required Paramaters To Make ConnectAPI call to Add Items into Cart
        User userDetail = [SELECT Effective_Account_Id__c FROM User WHERE Id =: userId WITH SECURITY_ENFORCED LIMIT 1];
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name =: webStoreName WITH SECURITY_ENFORCED LIMIT 1];
        WebCart cartRec = getWebCart(userDetail.Effective_Account_Id__c, webStore.Id, userId);

        //If Cart Limit does not exceeds on addition of new items, then add the items else return 
        AddToCartResultWrapper resultWrp = new AddToCartResultWrapper();
        resultWrp.cartLimitReached = maxCartLimitReached(cartRec.Id, productSKUId, Integer.valueOf(maxCartLimit));
        
        if(!resultWrp.cartLimitReached){
        try{
            //Call ConnectApi.CommerceCart.addItemsToCart and collect the results
            ConnectApi.BatchResult[] addResult = ConnectApi.CommerceCart.addItemsToCart(webStore.Id, userDetail.Effective_Account_Id__c , cartRec.Id,  cartItems);
            
            //ConnectApi.CommerceCart.addItemsToCart returns Results in the same order in which Products were passed to It
            //Hence with a simple Iteration we can get corresponding Error Messages of failed Items
            for(Integer indX = 0; indX < addResult.size(); indX++){
                if(!addResult[indX].isSuccess){
                        errorMsgWithProduct.put(prodSKUList[indX], addResult[indX].errorMessage.contains(':') ? addResult[indX].errorMessage.split(':')[1] : addResult[indX].errorMessage);
                }
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }

        resultWrp.failedItems = errorMsgWithProduct;
            resultWrp.cartId = cartRec.Id;
        }
        return resultWrp;
    }

    /**
    * @description : Fetches WebCart
    * @param       : accId (String) , webStoreId (String) , userId (String)
    * @return      : `WebCart`
    */
    public static WebCart getWebCart(String accId, String webStoreId, String userId){
        List<WebCart> webCartList = new List<WebCart>();
        webCartList = [SELECT Id FROM WebCart WHERE Status = 'Active' AND WebStoreId =: webStoreId AND AccountId =: accId AND OwnerId =: userId WITH SECURITY_ENFORCED];

        if(!Test.isRunningTest() && webCartList.isEmpty()){
            ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
            cartInput.effectiveAccountId = accId;
            ConnectApi.CommerceCart.createCart(webStoreId, cartInput);
        }
        webCartList = [SELECT Id FROM WebCart WHERE Status ='Active' AND WebStoreId =: webStoreId AND AccountId =: accId AND OwnerId =: userId WITH SECURITY_ENFORCED];
        
        if(Test.isRunningTest()){
            webCartList = [SELECT Id FROM WebCart WHERE Name = 'TestCart' AND Split_2_PO_Number__c = '123654' AND PoNumber = '4569875' WITH SECURITY_ENFORCED];
        }
        return webCartList[0];
    }


    /**
    * @description : Checks if addition of new Items exceeds total Unique Product count in Cart
    * @param       : cartId (String) , prodToAddMap (Map<String,String>) , cartLimit (Integer)
    * @return      : `Boolean`
    */
    public static Boolean maxCartLimitReached(Id cartID,  Map<String,String> prodToAddMap, Integer cartLimit){

        if(CartItem.SObjectType.getDescribe().isAccessible()){
            for(CartItem cItem : [SELECT Sku, Product2Id FROM CartItem WHERE CartId =: cartID]){
                prodToAddMap.put(cItem.Sku, cItem.Product2Id);
            }
        }

        return prodToAddMap.size() > cartLimit ? true : false;
    }

    /*Wrapper to return add to Cart Result*/
    public class AddToCartResultWrapper{
        @AuraEnabled public Boolean cartLimitReached;
        @AuraEnabled public Map<String,String> failedItems; 
        @AuraEnabled public String cartId; 
    }

}