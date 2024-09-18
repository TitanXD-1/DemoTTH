/**
 * @name: D1_B2BCartController
 * @description : This class is needed to build Custom API for mobile to 
 * share contacts with sales reps
 * @history                                                               
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0        Ayush Kumar       28/12/2020        NCP-1195
 * 1.0		  Ajay				28/12/2020        NCP-1492,95,96
 * 2.0        Ajay              06/12/2021        NCP-2827
 * 3.0		  Narayana			27/07/2021		  NCP-3922,3923,3924,3925
 * 4.0 	      Sai Kumar,						  TechDev stories 
 * 5.0	      Dipanjan					  
 **/
public without sharing class D1_B2BCartController {

	/**
	 * @description : Get Cart Item (Product) Information
	 * @userStory 
	 * @param webStoreId : webStoreId 
	 * @param accountId  : Effective Account Id from User
	 * @param cartId  : webcart id of User with Active status 
	 * @param pageParam  : 
	 * @param sortParam  : 
	 * @return List of CartItemWrapper 
	**/
    @AuraEnabled
    public static List < CartItemWrapper > getCartItems(String webStoreId, String accountId, String cartId, String pageParam, String sortParam) {
        
        List < CartItemWrapper > cartFinalData = new List < CartItemWrapper > ();
        
        if (string.isNotBlank(webStoreId) && string.isNotBlank(accountId)) {
            
            if (string.isNotBlank(cartId)) {
               ConnectApi.CartItemSortOrder resolvedSortParam = B2BUtils.resolveSortParam(sortParam);
                
                ConnectApi.CartItemCollection cartItemFromApi = ConnectApi.CommerceCart.getCartItems(webStoreId, accountId, cartId, 'D1_Brand__c,Product_Card_Title__c,D1_Size__c,Packaging_Configuration__c,StockKeepingUnit', pageParam,100, resolvedSortParam);
                
                return setUpCartItemWrapper(cartItemFromApi,cartId);
            }
        }
        return cartFinalData;
    }
    
	/**
	 * @description : Get Cart Item (Product) Information along with Images
	 * @userStory 
	 * @param cartItemFromApi : ConnectApi.CartItemCollection 
	 * @param cartId  : webcart id of User with Active status 
	 * @return List of CartItemWrapper 
	**/
	@testVisible
	private static List < CartItemWrapper > setUpCartItemWrapper(ConnectApi.CartItemCollection cartItemFromApi,String cartId){
        Map < String, ConnectApi.CartItemResult > cartDataMap = new Map < String, ConnectApi.CartItemResult > ();
        List < CartItemWrapper > cartFinalData = new List < CartItemWrapper > ();
        
        String currencyCode = cartItemFromApi.cartSummary.currencyIsoCode;
        if (cartItemFromApi.cartItems.size() > 0) {
            for (ConnectApi.CartItemResult cart: cartItemFromApi.cartItems) {
                cartDataMap.put(cart.cartItem.productId, cart);
            }
            List < CartItem > productList = [SELECT Product2Id,Product2.D1_Category__c ,Product2.StockKeepingUnit ,toLabel(Product2.D1_Size__c) ,Product2.D1_Brand__c, Product2.Brand_Variant__r.Name,
                                             toLabel(Product2.Packaging_Configuration__c), Portfolio_Item__c,
                                             OrderSplit_Type__r.Market_Description__c,OrderSplit_Type__r.SAP_OrderSplit_ID__c,
                                             OrderSplit_Type__r.Description__c,Product2.Product_Card_Title__c,Product2.Packaging_Details__c,
											 OrderSplit_Type__r.Exempt_From_Weight_Validation__c, OrderSplit_Type__r.MOQ_Multiple__c, Portfolio_Item__r.weight__c, UOM__c,Quantity, Portfolio_Item__r.Pallet_Quantity__c,Cases_Per_Layer__c
                                             FROM CartItem WHERE CartId =: cartId AND Product2Id IN: cartDataMap.keySet()
                                             ORDER BY CreatedDate ASC
                                            ];
            
            if (productList.size() > 0) {
                for (CartItem prod: productList) {
                    if (cartDataMap.containsKey(prod.Product2Id)) {
						ConnectApi.AbstractCartItem cartApiData = cartDataMap.get(prod.Product2Id).cartItem;

                        CartItemWrapper cw = new CartItemWrapper();
                        cw.cartApiData = cartDataMap.get(prod.Product2Id).cartItem;
                        cw.productId = prod.Product2Id;
                        cw.brandName = translatedValue(cartApiData,'D1_Brand__c');//prod.Product2.D1_Brand__c;
						cw.productCardTitle = translatedValue(cartApiData,'Product_Card_Title__c');//prod.Product2.Product_Card_Title__c;
                        cw.brandVariantName = prod.Product2.Brand_Variant__r.Name;
                        cw.skuData = prod.Product2.Packaging_Configuration__c;
						cw.imageURL = cartDataMap.get(prod.Product2Id)?.cartItem?.productDetails?.thumbnailImage?.url;
                        cw.currencyCode = currencyCode;
						cw.weightValidation = prod.OrderSplit_Type__r.Exempt_From_Weight_Validation__c;
						cw.grossWeight = prod.Portfolio_Item__r.weight__c;
						cw.uom = prod.UOM__c; 
						cw.quantity = prod.Quantity;
                        cw.casesPerPallet = prod.Portfolio_Item__r.Pallet_Quantity__c;
                 		cw.splitId=prod.OrderSplit_Type__r.SAP_OrderSplit_ID__c;
						cw.moqValue = prod.OrderSplit_Type__r.MOQ_Multiple__c; 
                        cw.productCategory = prod.Product2.D1_Category__c;
						cw.StockKeepingUnit = prod.Product2.StockKeepingUnit;
						cw.size = prod.Product2.D1_Size__c;

                        cw.packagingDetail = translatedValue(cartApiData,'D1_Size__c')+' | '+translatedValue(cartApiData,'Packaging_Configuration__c')+' | '+System.Label.D1_SKU+' '+translatedValue(cartApiData,'StockKeepingUnit');//prod.Product2.D1_Size__c +' | '+prod.Product2.Packaging_Configuration__c+' | SKU:'+prod.Product2.StockKeepingUnit;//NCP-4413

                        cw.casesPerLayer = prod.Cases_Per_Layer__c; //NCP-6035

						if (prod.OrderSplit_Type__r.Market_Description__c != null) {
							cw.splitValue = prod.OrderSplit_Type__r.Market_Description__c;
						} else if (prod.OrderSplit_Type__r.Description__c != null) {
							cw.splitValue = prod.OrderSplit_Type__r.Description__c;
						} else {
							cw.splitValue = '';
						}
                        cartFinalData.add(cw);
                    }
                }
            }
        
        }
        return cartFinalData;
    }

	/**
	 * @description get translated field value from  ConnectApi.AbstractCartItem
	 * @param cartApiData 
	 * @return  `String`
	 */	
    private static String translatedValue(ConnectApi.AbstractCartItem cartApiData, String fieldApiName){
        string translatedValue = '';
        if(cartApiData != null && cartApiData?.productDetails?.fields?.get(fieldApiName) != null){
			translatedValue = cartApiData.productDetails.fields.get(fieldApiName);
        }
		return translatedValue;
    }

	/**
	  @description : Cart Item Wrapper
	*/

	public class CartItemWrapper {
		@AuraEnabled public ConnectApi.AbstractCartItem cartApiData {get;set;}
		@AuraEnabled public String productId {get;set;}
		@AuraEnabled public String brandName {get;set;}
		@AuraEnabled public String brandVariantName {get;set;}
		@AuraEnabled public String skuData {get;set;}
		@AuraEnabled public String imageURL {get;set;}
		@AuraEnabled public String currencyCode {get;set;}
		@AuraEnabled public String splitValue {get;set;}
		@AuraEnabled public String productCardTitle {get;set;}
		@AuraEnabled public String packagingDetail {get;set;}
		@AuraEnabled public boolean weightValidation {get;set;}
		@AuraEnabled public decimal grossWeight {get;set;}
		@AuraEnabled public String uom {get;set;}
		@AuraEnabled public decimal quantity {get;set;}
		@AuraEnabled public decimal casesPerPallet {get;set;}
        @AuraEnabled public String splitId {get;set;}
		@AuraEnabled public Decimal moqValue {get; set;}
        @AuraEnabled public String productCategory {get;set;}
		@AuraEnabled public String StockKeepingUnit {get;set;}
		@AuraEnabled public String size	{get;set;}
		@AuraEnabled public decimal casesPerLayer {get;set;} //NCP-6035
	}

	/**
	 * @author Ajay
	 * @date 23-12-2020
	 * @userStory NCP-1496,NCP-1495
	 * @description Update Single Cart Item
	 * @param  webStoreId store id
	 * @param accountId account id
	 * @param cartId cart Id
	 * @param cartItemId CartItem Id
	 * @param cartItem ConnectApi.CartItemInput cartItem
	 * @return CartItem ConnectApi.CartItemInput The updated cart item
	 */

	@AuraEnabled
	public static ConnectApi.CartItem updateCartItem(String webStoreId, String accountId, String cartId, String cartItemId, ConnectApi.CartItemInput cartItem) {
		return ConnectApi.CommerceCart.updateCartItem(webStoreId, accountId, cartId, cartItemId, cartItem);
	}

	/**
	 * @auther Ajay
	 * @date 23-12-2020
	 * @userStory NCP-1496,NCP-1495
	 * @description Delete Cart Single Item 
	 * @param  webStoreId webstore id
	 * @param accountId account Id
	 * @param cartId Cart Id
	 * @param cartItemId cart Item Id
	 */

	@AuraEnabled
	public static void deleteCartItem(String webStoreId, String accountId, String cartId, String cartItemId) {
		ConnectApi.CommerceCart.deleteCartItem(webStoreId, accountId, cartId, cartItemId);
	}
	/**
	 * @description Delete Cart 
	 * @param  webStoreId webstore id
	 * @param accountId account Id
	 * @param cartId Cart Id
	 */
	@AuraEnabled
	public static void deleteCart(String webStoreId,String accountId,String cartId){
		ConnectApi.CommerceCart.deleteCart(webstoreId,accountId,cartId);
	}
	/**
	 * @description Create New Cart 
	 * @param  webStoreId webstore id
	 * @param accountId account Id
	 * @return ConnectApi.CartSummary
	 */	
	@AuraEnabled
  	public static ConnectApi.CartSummary createCart(String webStoreId, String accountId) {

		ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
    	cartInput.effectiveAccountId = accountId;
		return ConnectApi.CommerceCart.createCart(webStoreId, cartInput);
	}

	/**
	 * @description Demonstrates how to call ConnectApi.CommerceCart.getCartSummary
	 * @param  communityId The Id of the community from which the call originated
	 * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
	 * @param activeCartOrId ID of the cart, active, or current.
	 */

	@AuraEnabled
	public static ConnectApi.CartSummary getCartSummary(String webStoreId, String accountId, String cartId) {
        if(cartId != NULL) {
			return ConnectApi.CommerceCart.getCartSummary(
				webStoreId,
				accountId,
				cartId
			);
		}
		return NULL;
	}
	/**
	 * @description get max order line item details
	 * @param cartId Cart Id
	 */
    
    @AuraEnabled
    public static  WebCart getMaxOrderLineItems(Id cartId){
        
        WebCart cart =[Select id,Sales_Area__r.Max_Order_Line_Items__c,
							  CanViewPrice__c,
							  Total_Weight__c,
							  Sales_Area__r.Max_Weight__c,
							  Sales_Area__r.Max_Pallets__c,
							  Total_Keg__c,Total_Pallets__c 
							  from WebCart where id =: cartId];
        return cart;
	}
	
}