/**
 * @name D1_SAPOrderSimulator
 * @description  Simulation run for Orders in Checkout process 
 * @history
 * VERSION		AUTHOR			DATE		DETAIL
 * 1.0			Dipanjan Das	-			-
 * 2.0			Ajay			27/07/21	GA Tagging(NCP-3959)
 * 3.0			Kapil Baliyan	07/07/22	NCP-7085
 * 4.0			Kapil Baliyan	01/12/2022	NCP-7580(processItemResponse)
 * 5.0			Mukesh Kanth	20/12/2023	US-147857: Pass Payment Term Code to SAP on Simulation
 * 6/0			Prasanth T		23/04/2024	152068: Added condition to include tax in minimum threshold calculation.
 **/
public without sharing class D1_SAPOrderSimulator {
	/**
	 * @description processItemResponse method
	 * @param responseItems 
	 * @param cartItems 
	 * @param userCart 
	 * @return  `List<D1_CheckoutSimulation.CartItemWrapper>`
	 */    
	public static List<D1_CheckoutSimulation.CartItemWrapper> processItemResponse(List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1> responseItems, List<CartItem> cartItems, WebCart userCart){
		final String productFields = 'D1_Brand__c, Product_Card_Title__c, D1_Size__c, StockKeepingUnit, Packaging_Configuration__c';//Product fields separated by comma, Max 5 fields can be specified NCP-3959
        //string translatedValue = '';
		Map<String, CartItem> matnrCartItemMap = new Map<String, CartItem>();

		for (CartItem ci : cartItems) {
			matnrCartItemMap.put(ci.Product2.SAP_Material_Id__c, ci);  
		}

		Map<Id, ConnectApi.CartItemResult> cartApiDataMap = new Map<Id, ConnectApi.CartItemResult>();
		if(!Test.isRunningTest()){
			ConnectApi.CartItemCollection cartItemFromApi = ConnectApi.CommerceCart.getCartItems(userCart.webStoreId, userCart.accountId, userCart.Id, productFields, null, 100, null);// NCP-3959 Added PRODUCT_FIELDS
			
			for (ConnectApi.CartItemResult cartApiData: cartItemFromApi.cartItems) {
				cartApiDataMap.put(cartApiData.cartItem.productId, cartApiData);
			}
		}

		List<D1_CheckoutSimulation.CartItemWrapper> simulatedCartItems = new List<D1_CheckoutSimulation.CartItemWrapper>();
		if(responseItems != null){
			for(D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Response_D1 resItem : responseItems){
				D1_CheckoutSimulation.CartItemWrapper cartItemWrap = new D1_CheckoutSimulation.CartItemWrapper();
                cartItemWrap.productId = matnrCartItemMap!=NULL && matnrCartItemMap.containsKey(resItem.MATERIAL) ? matnrCartItemMap.get(resItem.MATERIAL).Product2Id : '';
				if(!Test.isRunningTest()){
					cartItemWrap.cartApiData = cartApiDataMap.get(cartItemWrap.productId).cartItem;
					cartItemWrap.imageURL = '/shop' + cartApiDataMap.get(cartItemWrap.productId)?.cartItem?.productDetails?.thumbnailImage?.url;
					cartItemWrap.imageURL = cartItemWrap.imageURL == '/shop/img/b2b/default-product-image.svg' ? '/shop/resource/D1_CommonIcons/D1_CommonIcons/icons/default-image.svg':cartItemWrap.imageURL;
				}
				cartItemWrap.brandName = translatedValue(cartItemWrap.cartApiData,'D1_Brand__c');////NCP-6391 //MATNR_CARTITEM_MAP.get(resItem.MATERIAL).Product2.D1_Brand__c; ////NCP-2309
				cartItemWrap.productCardTitle = translatedValue(cartItemWrap.cartApiData,'Product_Card_Title__c');//NCP-6391 //MATNR_CARTITEM_MAP.get(resItem.MATERIAL).Product2.Product_Card_Title__c; //NCP-2309
				cartItemWrap.prodSize = matnrCartItemMap!=NULL && matnrCartItemMap.containsKey(resItem.MATERIAL) ? matnrCartItemMap.get(resItem.MATERIAL).Product2.D1_Size__c : '';
				cartItemWrap.priceError = resItem.PRICE_ERROR;
				cartItemWrap.quantityError = (resItem.KBMENG == '0.0');
				cartItemWrap.belowMinimumError = resItem.BELOW_MIN;
				cartItemWrap.orderedQuantity = resItem.TARGET_QTY;
				cartItemWrap.confirmedQuantity = resItem.KBMENG != null ? resItem.KBMENG.substringBefore('.') : '0';
				cartItemWrap.currencyCode = resItem.CURRENCY_x;
               	cartItemWrap.skuData = translatedValue(cartItemWrap.cartApiData);//NCP-4413
				cartItemWrap.itemPrice = cartItemWrap.priceError ?  '0.00' : resItem.PRICE;
				cartItemWrap.itemTax = resItem.TAX;
				cartItemWrap.isOutofStock = (cartItemWrap.confirmedQuantity == '0' || cartItemWrap.confirmedQuantity == '0.0');
				cartItemWrap.isPartialOutofStock = cartItemWrap.isOutofStock ? false : (Decimal.valueOf(cartItemWrap.confirmedQuantity) < Decimal.valueOf(cartItemWrap.orderedQuantity)); //NCP-7085
				cartItemWrap.listPrice = resItem.LISTPRICE_UNIT; //NCP-7580
				cartItemWrap.unitaryRebate = resItem.UNITARY_REBATE;
				cartItemWrap.commercialDiscount = resItem.COMMERCIAL_DISCOUNT;
				cartItemWrap.logisticDiscount = resItem.LOGISTIC_DISCOUNT;
				cartItemWrap.otherDiscount = resItem.OTHER_DISCOUNT;
				cartItemWrap.discountCurrMark = resItem.DISCOUNT_CURRMARK;
				cartItemWrap.specialTaxDuty = resItem.SPECIAL_TAXDUTY;
				cartItemWrap.netValueUnit = resItem.NETVALUE_UNIT;
				cartItemWrap.vat = resItem.VAT;
				simulatedCartItems.add(cartItemWrap);                      
			}			
		}else{
			for(CartItem ci : cartItems){
				D1_CheckoutSimulation.CartItemWrapper cartItemWrap = new D1_CheckoutSimulation.CartItemWrapper();
				cartItemWrap.productId = ci.Product2Id;
				if(!Test.isRunningTest()){
					cartItemWrap.cartApiData = cartApiDataMap.get(cartItemWrap.productId).cartItem;
					cartItemWrap.imageURL = '/shop' + cartApiDataMap.get(cartItemWrap.productId)?.cartItem?.productDetails?.thumbnailImage?.url;
					cartItemWrap.imageURL = cartItemWrap.imageURL == '/shop/img/b2b/default-product-image.svg' ? '/shop/resource/D1_CommonIcons/D1_CommonIcons/icons/default-image.svg':cartItemWrap.imageURL;
				}			
                cartItemWrap.brandName = translatedValue(cartItemWrap.cartApiData,'D1_Brand__c');//NCP-6391  ci.Product2.D1_Brand__c; //NCP-2309
				cartItemWrap.productCardTitle = translatedValue(cartItemWrap.cartApiData,'Product_Card_Title__c');//NCP-6391  ci.Product2.Product_Card_Title__c; //NCP-2309
				cartItemWrap.prodSize = ci.Product2.D1_Size__c;
				cartItemWrap.priceError = false;
				cartItemWrap.quantityError = false;
				cartItemWrap.belowMinimumError = false;
				cartItemWrap.orderedQuantity = String.valueOf(ci.Quantity);
				cartItemWrap.confirmedQuantity = String.valueOf(0);
				cartItemWrap.currencyCode = ci.CurrencyIsoCode;
               	cartItemWrap.skuData = translatedValue(cartItemWrap.cartApiData);//NCP-4413
				cartItemWrap.itemPrice = String.valueOf(0.00);
				cartItemWrap.itemTax = String.valueOf(0.00);
				cartItemWrap.isOutofStock = false;
				cartItemWrap.isPartialOutofStock = false;
				cartItemWrap.listPrice = String.valueOf(0.00); //NCP-7580
				cartItemWrap.unitaryRebate = String.valueOf(0.00);
				cartItemWrap.commercialDiscount = '0%';
				cartItemWrap.logisticDiscount = String.valueOf(0.00);
				cartItemWrap.otherDiscount = '0%';
				cartItemWrap.discountCurrMark = String.valueOf(0.00);
				cartItemWrap.specialTaxDuty = String.valueOf(0.00);
				cartItemWrap.netValueUnit = String.valueOf(0.00);
				cartItemWrap.vat = String.valueOf(0.00);
				simulatedCartItems.add(cartItemWrap);                      
			}
		}
		 
		return simulatedCartItems;
	}
	/**
	 * @description generateRequest method
	 * @param splitId 
	 * @param userCart 
	 * @param cartItems 
	 * @return  `D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request`
	 */	
    public static D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request generateRequest(Id splitId, WebCart userCart, List<CartItem> cartItems){

        D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request headerRequest = new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request();
        List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Request> orderItems = new List<D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Request>();       

        for (CartItem ci : cartItems) {
            system.debug('SAPMATERIALCHECK - '+ci.Product2.SAP_Material_Id__c);
            if (!string.isBlank(ci.Product2.SAP_Material_Id__c)) {
                D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Request orderItem = new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Item_Request();
                orderItem.SFDC_ID = ci.Id;
                orderItem.SFDC_ITEM_NUM = ci.Name;
                orderItem.MATNR = ci.Product2.SAP_Material_Id__c;
                orderItem.KWMENG = ci.Quantity;
                //Modified for NCP-2612
                orderItem.VRKME = String.isNotBlank(ci.Portfolio_Item__r.Ordering_UoM_Override__c) ?ci.Portfolio_Item__r.Ordering_UoM_Override__c :ci.UOM__c;
                //Modified for NCP-2612
                orderItem.WERKS = '';  
                orderItems.add(orderItem);
			}
        }

        headerRequest.SFDC_ID = userCart.Id;
        headerRequest.SFDC_ORD_NUM = 'Simulate';
        headerRequest.KUNWE = userCart.Shipto_Party__c;
        headerRequest.KUNAG = userCart.Soldto_Party__c;
		if(userCart.Order_Split_1__c == splitId){
			headerRequest.VDATU = userCart.Split_1_Delivery_date__c;
			headerRequest.BSTNK = userCart.PoNumber;
		}else if(userCart.Order_Split_2__c == splitId){
			headerRequest.VDATU = userCart.Split_2_Delivery_date__c;
			headerRequest.BSTNK = userCart.Split_2_PO_Number__c;
		}     
		headerRequest.STATUS = userCart.Status;
        headerRequest.ERDAT = system.today();
        headerRequest.ERNAM = userCart.createdBy.Name;            
        headerRequest.VKORG = userCart.Sales_Area__r.Sales_Organisation_Code__c;
        headerRequest.VTWEG = userCart.Sales_Area__r.Distribution_Channel_Code__c;
        headerRequest.SPART = userCart.Sales_Area__r.Division_Code__c;
        headerRequest.KVGR1 = ''; //Booking In Indicator
        headerRequest.EMAIL = userCart.createdBy.Email;
        headerRequest.ORDER_GROUP = 'Simulate_Group';
        headerRequest.SHIPPING_INSTRUCTIONS = userCart.Delivery_Instructions__c;
        headerRequest.CS_INSTRUCTIONS = userCart.Customer_Service_Instruction__c;
        headerRequest.ORDER_ITEMS = orderItems;
        headerRequest.ZTERM = userCart.Payment_Term_Code__c != null ? userCart.Payment_Term_Code__c : ''; //Added Payment_Term_Code__c for US-147857 

		return headerRequest;	
    }
	/**
	 * @description processSimulationResponse
	 * @param response 
	 * @param userCart 
	 * @param cartItems 
	 * @param splitId 
	 * @param isSimulationException 
	 * @param isSimulationExceptionMsg 
	 * @return  `D1_CheckoutSimulation.cartWrapper`
	 */	
    public static D1_CheckoutSimulation.cartWrapper processSimulationResponse(D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 response, WebCart userCart, List<CartItem> cartItems, Id splitId, Boolean isSimulationException, String isSimulationExceptionMsg){
        D1_CheckoutSimulation.cartWrapper simulatedCartWrapper = new D1_CheckoutSimulation.cartWrapper();
		simulatedCartWrapper.cartId = userCart.Id;
        simulatedCartWrapper.userCart = userCart;
		isSimulationException = isSimulationException? isSimulationException : (response.MESSAGES == null);
        if(!isSimulationException){
            for(D1_OrderSimulationController.DT_SalesOrderSimulate_Message_Response splitMessage : response.MESSAGES){
                if(splitMessage.TYPE_x.equals('E')){
                    isSimulationException = true;
                    isSimulationExceptionMsg = splitMessage.MESSAGE;
                    break;
                }
            }
			isSimulationException = isSimulationException? isSimulationException : (response.HEADER == null);
        }

        simulatedCartWrapper.isSimulated = !isSimulationException;
        simulatedCartWrapper.isError = isSimulationException;
        simulatedCartWrapper.errorMessage = isSimulationExceptionMsg;
        simulatedCartWrapper.simulationMsg = isSimulationException ? Label.D1_Simulation_Error : Label.D1_Simulation_Success;
		simulatedCartWrapper.isCreditBlock = false;
		simulatedCartWrapper.creditBlockMsg = Label.D1_order_restricted;
		simulatedCartWrapper.isOutsideATP = isSimulationException ? false: response.HEADER.OUTSIDE_ATP;
		simulatedCartWrapper.ATPDays = simulatedCartWrapper.isOutsideATP ? response.HEADER.ATP_DAYS : 0;
		simulatedCartWrapper.cartTotals = new D1_CheckoutSimulation.CartTotalWrapper();
		// Defect NCP - 3401 
		if(userCart.Order_Split_1__c == splitId) {
			simulatedCartWrapper.cartTotals.splitName = userCart.Order_Split_1__r.Market_Description__c != null ? 
															userCart.Order_Split_1__r.Market_Description__c : userCart.Order_Split_1__r.Description__c;

		}else if(userCart.Order_Split_2__c == splitId) {
			simulatedCartWrapper.cartTotals.splitName = userCart.Order_Split_2__r.Market_Description__c != null ? userCart.Order_Split_2__r.Market_Description__c : userCart.Order_Split_2__r.Description__c;
		}
		simulatedCartWrapper.cartTotals.splitSubTotal = isSimulationException ? 0.00 : Decimal.valueOf(checkifNull(response.HEADER.VALUE));
		simulatedCartWrapper.cartTotals.splitTax = isSimulationException ? 0.00 : Decimal.valueOf(checkifNull(response.HEADER.TAX));
		simulatedCartWrapper.cartTotals.splitOrderTotal = simulatedCartWrapper.cartTotals.splitSubTotal + simulatedCartWrapper.cartTotals.splitTax;	
		simulatedCartWrapper.cartTotals.orderBelowMinimum = isSimulationException ? false : response.HEADER.BELOW_MIN;
		simulatedCartWrapper.cartTotals.minThreshold = simulatedCartWrapper.cartTotals.orderBelowMinimum ? Decimal.valueOf(response.HEADER.MESSAGE_VALUE) : 0.00 ;
		simulatedCartWrapper.cartTotals.orderAboveMaximum = isSimulationException ? false : response.HEADER.ABOVE_MAX;
		simulatedCartWrapper.cartTotals.maxThreshold = simulatedCartWrapper.cartTotals.orderAboveMaximum ? Decimal.valueOf(response.HEADER.MESSAGE_VALUE) : 0.00 ;
		simulatedCartWrapper.cartTotals.isHardWarning = (simulatedCartWrapper.cartTotals.orderBelowMinimum || simulatedCartWrapper.cartTotals.orderAboveMaximum);
        //152068
        Id userId = UserInfo.getUserId();
        try{
            D1_setting__c taxCalcSimulationCheck = D1_UtilityClass.getD1Setting(userId);            
            if(!taxCalcSimulationCheck.Calculate_Tax_On_Simulation__c){
                simulatedCartWrapper.cartTotals.belowThresholdByAmount = simulatedCartWrapper.cartTotals.orderBelowMinimum ? (simulatedCartWrapper.cartTotals.minThreshold - simulatedCartWrapper.cartTotals.splitSubTotal) : 0.00;
            }
            else{
                simulatedCartWrapper.cartTotals.belowThresholdByAmount = simulatedCartWrapper.cartTotals.orderBelowMinimum ? (simulatedCartWrapper.cartTotals.minThreshold - simulatedCartWrapper.cartTotals.splitSubTotal - simulatedCartWrapper.cartTotals.splitTax) : 0.00;
            }
        }catch(exception e){
            System.debug('ERRORCHECK - '+e.getMessage());
        }
		simulatedCartWrapper.cartTotals.aboveThresholdByAmount = simulatedCartWrapper.cartTotals.orderAboveMaximum ? (simulatedCartWrapper.cartTotals.splitSubTotal - simulatedCartWrapper.cartTotals.maxThreshold) : 0.00;		 
        simulatedCartWrapper.splitcartItems = isSimulationException ? processItemResponse(null, cartItems, userCart) : processItemResponse(response.ITEMS, cartItems, userCart);

		for(D1_CheckoutSimulation.CartItemWrapper cartItemWrap: simulatedCartWrapper.splitcartItems){
			if(cartItemWrap.isOutofStock){
				simulatedCartWrapper.isProductOutofStock = true;
			}
			if(cartItemWrap.priceError){
				simulatedCartWrapper.isProductPriceUnavailable = true; 
			}
			if(cartItemWrap.belowMinimumError){
				simulatedCartWrapper.isProductBelowMin = true;
			}
		}
		simulatedCartWrapper.cartTotals.isHardWarning = simulatedCartWrapper.cartTotals.isHardWarning ? true : simulatedCartWrapper.isProductBelowMin;
        return simulatedCartWrapper;  				
    }

	/**
	 * @description checkifNull method
	 * @param value 
	 * @return  `String`
	 */	
    private static String checkifNull(String value){
        return value != null ? value : '0';
    }

    /**
	 * @description checkifNull method
	 * @param cartApiData 
	 * @return  `String`
	 */	
    private static String translatedValue(ConnectApi.AbstractCartItem cartApiData){
        if(cartApiData != null){
			//string skuLabel = System.Label.D1_SKU;
			//string size = cartApiData.productDetails.fields.get('D1_Size__c');
			//string packagingConfiguration = cartApiData.productDetails.fields.get('Packaging_Configuration__c');
			//string sku = cartApiData.productDetails.fields.get('StockKeepingUnit');
			String translatedValue = translatedValue(cartApiData,'D1_Size__c')+' | '+translatedValue(cartApiData,'Packaging_Configuration__c')+' | '+System.Label.D1_SKU+' '+translatedValue(cartApiData,'StockKeepingUnit'); //size + ' | ' +packagingConfiguration+' | '+skuLabel+sku;

			return translatedvalue;
        }
        return '';
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
}