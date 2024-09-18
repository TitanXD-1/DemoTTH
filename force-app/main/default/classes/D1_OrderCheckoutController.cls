/**
 * @name : D1_OrderCheckoutController
 * @description : Controller Class for doing Simulation Callout to SAP
 * Continuation Framework: Kapil Baliyan
 * @history :
 * VERSION          AUTHOR              DATE            DETAIL
 * 1.0              Dipanjan Das        01/10/2021      Initial Development
 * 2.0              Kapil Baliyan       24/05/2022      NCP-6780 (Changing Logic for storing Tax Information)
 * 3.0              Mukesh Kanth        20/12/2023      US-147857: Pass Payment Term Code to SAP on Simulation
 */
public without sharing class D1_OrderCheckoutController {

    //Wrapper Class
    public class OrderCheckoutResponse{
        @AuraEnabled public string key {get; set;}
        @AuraEnabled public string interfaceName {get; set;}
        @AuraEnabled public string interfaceResponse {get; set;}
    }

    //Wrapper Class
    public class OrderCheckoutRequest{
        public string cartId {get; set;}
		public WebCart userCart {get; set;}
		public List<CartItem> cartItems {get; set;}
        public string interfaceName {get; set;}
        public Object interfaceRequest {get; set;}
    }
    
    /**
     * @description : This method is used to do Async Callout to SAP for Order Simulation
     * @param cartId : Cart Id
     * @return  `Object`
     */
    @AuraEnabled(continuation=true cacheable=true)
    public static Object doAsyncCallout(string cartId){
        if(cartId != null){
			Map<String, List<CartItem>> orderSplitCartItemMap = new Map<String, List<CartItem>>();
            WebCart userCart = [SELECT Id, Status, PoNumber, Split_2_PO_Number__c, WebStoreId, accountId, 
                                    Sales_Area__r.Distribution_Channel_Code__c, Sales_Area__r.Division_Code__c, Sales_Area__r.Sales_Organisation_Code__c, 
                                    Soldto_Party__c, Shipto_Party__c, Delivery_Instructions__c, Customer_Service_Instruction__c, 
                                    Order_Split_1__c, Order_Split_2__c, 
                                    Order_Split_1__r.Description__c , Order_Split_1__r.Market_Description__c, Order_Split_2__r.Description__c, 
                                    Order_Split_2__r.Market_Description__c, Split_1_Delivery_date__c, Split_2_Delivery_date__c,
                                    createdDate, createdBy.Name, createdBy.Email, Payment_Term_Code__c //Added Payment_Term_Code__c for US-147857 
                                    FROM WebCart 
                                    WHERE Id =:cartId LIMIT 1];	
										
            for (CartItem ci : [SELECT Id, Name, Sku, Product2Id, Product2.Name, Product2.Base_Unit_of_Measure__c, UOM__c, Portfolio_Item__r.Ordering_UoM_Override__c,
                                    Product2.SAP_Material_Id__c, Product2.D1_Size__c, ListPrice, Quantity, OrderSplit_Type__c, 
                                    OrderSplit_Type__r.Name, OrderSplit_Type__r.Description__c, CurrencyIsoCode,
                                    Product2.Product_Card_Title__c, Product2.D1_Brand__c, Product2.Packaging_Details__c    
                                    FROM CartItem 
                                    WHERE CartId = :cartId])
            {
                String splitName = ci.OrderSplit_Type__r.Description__c;
                if(orderSplitCartItemMap.containsKey(splitName)){
                    orderSplitCartItemMap.get(splitName).add(ci);
                }else{
                    orderSplitCartItemMap.put(splitName, new List<CartItem> {ci});
                }   
            }										
			
			List<OrderCheckoutRequest> orderCheckoutRequestList = new List<orderCheckoutRequest>();
			
			Integer timeOutInSeconds = 120;
			Continuation cont = new Continuation(timeOutInSeconds);
			cont.continuationMethod = 'processAllResponses';
			
			/*************************************Callout 1****************************************************/
			orderCheckoutRequestList.add(doAsyncSimulation(cont, 'Split1', userCart, orderSplitCartItemMap.values()[0]));

			/*************************************Conditional Callout 2****************************************************/
			if(orderSplitCartItemMap.keySet().size() > 1){
				orderCheckoutRequestList.add(doAsyncSimulation(cont, 'Split2', userCart, orderSplitCartItemMap.values()[1]));
			}
			cont.state = orderCheckoutRequestList;
    		return cont;
		}else{
			return null;
		}
    }
        
    public static OrderCheckoutRequest doAsyncSimulation(System.Continuation continuation, String splitName, WebCart userCart, List<CartItem> cartItems){
        AsyncD1_OrderSimulationController.AsyncHTTPS_Port simulationReq;
        AsyncD1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1Future simulationRes; 
        try{
            //Creating Order Checkout Request Wrapper Instance
            OrderCheckoutRequest orderCheckoutRequest = new OrderCheckoutRequest();
            orderCheckoutRequest.cartId = userCart.Id;
            orderCheckoutRequest.userCart = userCart;
            orderCheckoutRequest.cartItems = cartItems;
            orderCheckoutRequest.interfaceName = 'Order_Simulation_' + splitName;
            
            //Creating Async Class Instance for Callout
            simulationReq = new AsyncD1_OrderSimulationController.AsyncHTTPS_Port();
            orderSimulationSAPLogin(simulationReq);
            
            //Step 1 : Create Request
            D1_OrderSimulationController.DT_SalesOrderSimulateSF_Header_Request requestHeader = D1_SAPOrderSimulator.generateRequest(cartItems[0].OrderSplit_Type__c, userCart, cartItems);
            //Step 2 : Get Configs
            List<SAP_Order_Simulation_Settings__mdt> simulationSettings = [SELECT Simulation_Enabled__c, Org_Initial__c FROM SAP_Order_Simulation_Settings__mdt WHERE DeveloperName = 'SAP_Simulate_Setting' LIMIT 1];
        
            //Step 2: Do Callout
            orderCheckoutRequest.interfaceRequest = simulationRes = simulationReq.beginSI_SalesOrderSimulate_Sync_Out_D1(continuation, simulationSettings[0].Org_Initial__c, simulationSettings[0].Simulation_Enabled__c, requestHeader);
            return orderCheckoutRequest;
        }catch( Exception ex ){
            //NCP-3577
            D1_CustomLoggingUtility.logMessageFuture('D1_OrderCheckoutController', 'doAsyncSimulation',  ex.getMessage(), ex.getStackTraceString(), ex.getTypeName(), JSON.serialize(simulationReq), JSON.serialize(simulationRes));
            throw ex;
        }
    }

    /**
     * @description : Method to process callout response
     * @param state 
     * @return  `Object`
     */
    @AuraEnabled(cacheable=true)
    public static Object processAllResponses(Object state){
        List<OrderCheckoutResponse> orderCheckoutResponseList = new List<OrderCheckoutResponse>();
        List<OrderCheckoutRequest> orderCheckoutRequestList = (List<OrderCheckoutRequest>)state;
        Integer key = 1;
        for(OrderCheckoutRequest orderCheckoutRequest : OrderCheckoutRequestList){
			Boolean isSimulationException = false;
            String isSimulationExceptionMsg = '';
            OrderCheckoutResponse orderCheckoutResponse = new OrderCheckoutResponse();
            orderCheckoutResponse.interfaceName = orderCheckoutRequest.interfaceName;
            orderCheckoutResponse.key = string.valueOf(key);
            if(orderCheckoutRequest.interfaceName == 'Order_Simulation_Split1'){
				AsyncD1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1Future simulationResponseFutureSplit1 = (AsyncD1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1Future)orderCheckoutRequest.interfaceRequest;
				D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 simulationResponseSplit1 = new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1();
				try{
        			simulationResponseSplit1 = simulationResponseFutureSplit1.getValue();
            	}catch(Exception ex){
					isSimulationException = true;
                    isSimulationExceptionMsg = ex.getMessage();
        		}
                //Parse Response
                D1_CheckoutSimulation.cartWrapper cartWrapperSplit1 = D1_SAPOrderSimulator.processSimulationResponse(simulationResponseSplit1, orderCheckoutRequest.userCart, orderCheckoutRequest.cartItems, orderCheckoutRequest.cartItems[0].OrderSplit_Type__c, isSimulationException, isSimulationExceptionMsg);				
                orderCheckoutResponse.interfaceResponse = JSON.serialize(cartWrapperSplit1);              
			}	
			else if(orderCheckoutRequest.interfaceName == 'Order_Simulation_Split2'){
				AsyncD1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1Future simulationResponseFutureSplit2 = (AsyncD1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1Future)orderCheckoutRequest.interfaceRequest;
				D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1 simulationResponseSplit2 = new D1_OrderSimulationController.DT_SalesOrderSimulateSF_Response_D1();
				try{
					simulationResponseSplit2 = simulationResponseFutureSplit2.getValue();
            	}catch(Exception ex){
					isSimulationException = true;
                    isSimulationExceptionMsg = ex.getMessage();
				}
                //Parse Response
                D1_CheckoutSimulation.cartWrapper cartWrapperSplit2  = D1_SAPOrderSimulator.processSimulationResponse(simulationResponseSplit2, orderCheckoutRequest.userCart, orderCheckoutRequest.cartItems, orderCheckoutRequest.cartItems[0].OrderSplit_Type__c, isSimulationException, isSimulationExceptionMsg);
                orderCheckoutResponse.interfaceResponse = JSON.serialize(cartWrapperSplit2);				
			}
            orderCheckoutResponseList.add(orderCheckoutResponse);
            key++;
        }
        return orderCheckoutResponseList;
    }  
    
    /**
     * @description : Helper Method for setting details required for SAP Callout
     * @param req 
     */
    public static void orderSimulationSAPLogin(AsyncD1_OrderSimulationController.AsyncHTTPS_Port req){
        Map<String, D1_Commerce_SAP_Setting__mdt> commerceSettingMap = new Map<String, D1_Commerce_SAP_Setting__mdt>();
        for(D1_Commerce_SAP_Setting__mdt commerceSetting : [SELECT DeveloperName, Value__c, SF_Instance__c FROM D1_Commerce_SAP_Setting__mdt]){
            commerceSettingMap.put(commerceSetting.DeveloperName, commerceSetting);
        }
        req.endpoint_x = commerceSettingMap.get('Order_Simulation_Endpoint').Value__c;
        req.inputHttpHeaders_x = new Map<String,String>();
        req.inputHttpHeaders_x.put('Authorization', sapLoginMaster(commerceSettingMap.get('SAP_Username').Value__c, commerceSettingMap.get('SAP_Password').Value__c));
        req.clientCertName_x = commerceSettingMap.get('SAP_Cert_Name').Value__c;
        req.timeout_x = Integer.valueOf(commerceSettingMap.get('SAP_Timeout').Value__c);
    } 
    
    /**
     * @description : Helper Method for SAP Login
     * @param usrName 
     * @param pwd 
     * @return  `string`
     */
    public static string sapLoginMaster(String usrName, String pwd){      
        Blob headerValue = Blob.valueOf(usrName + ':' + pwd); 
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);  
        return authorizationHeader;     
    }  
    
    /**
     * @description : Helper method for getting currency symbol
     * @param userId 
     * @return  `String`
     */
    @AuraEnabled(cacheable = true)
    public static String getCurrencySymbol(Id userId){
        String currencySymbol;
        List<User> userRec = [SELECT Available_Countries__c FROM User WHERE Id = :userId  LIMIT 1];
        if (userRec != null && userRec.size() > 0) {
            String localeSettingName = userRec[0].Available_Countries__c + '_Locale_Setting';
            for(D1_User_Locale_Settings__mdt d1LocalSetting : [SELECT Currency_Symbol__c 
                                                                FROM D1_User_Locale_Settings__mdt 
                                                                WHERE DeveloperName = :localeSettingName 
                                                                LIMIT 1]){
                currencySymbol = d1LocalSetting.Currency_Symbol__c;
            }            
        }
        return currencySymbol;
    }


    /**
     * @description : Method to update Tax and Actual Price into Cart Item which are returned as Simulation Response
     * @param productWrapperJson 
     * @param cartId 
     */
    @AuraEnabled
    public static void updateCartItems(String productWrapperJson, Id cartId){
        if (!String.isEmpty(productWrapperJson) && cartId != null) {
            Set<Id> cartItemIds = new Set<Id>();
            List<CartTax> cartTaxList = new List<CartTax>();
            List<D1_CheckoutSimulation.CartItemWrapper> simulatedCartItems = (List<D1_CheckoutSimulation.CartItemWrapper>)JSON.deserialize(productWrapperJson, List<D1_CheckoutSimulation.CartItemWrapper>.Class);
            Map<Id, D1_CheckoutSimulation.CartItemWrapper> productWithWrapperMap = new Map<Id, D1_CheckoutSimulation.CartItemWrapper>();

            for (D1_CheckoutSimulation.CartItemWrapper cartItemWrap : simulatedCartItems) {
                productWithWrapperMap.put(cartItemWrap.productId, cartItemWrap);
            }

            //Get Cart Item
            List<CartItem> cartItemsToUpdate = [SELECT Id, Name, Sku, Product2Id, TotalLineAmount, AdjustmentTaxAmount, TotalPrice FROM CartItem WHERE CartId =:cartId];
            
            //Update CartItem TotalPrice
            for (CartItem ci : cartItemsToUpdate){
                String totalLineAmount = productWithWrapperMap.containsKey(ci.Product2Id) && productWithWrapperMap.get(ci.Product2Id).itemPrice != null? productWithWrapperMap.get(ci.Product2Id).itemPrice : '0.00';
                String taxAmount = productWithWrapperMap.containsKey(ci.Product2Id) && productWithWrapperMap.get(ci.Product2Id).itemTax != null ? productWithWrapperMap.get(ci.Product2Id).itemTax : '0.00';
                ci.TotalLineAmount = Decimal.valueOf(totalLineAmount);
                ci.TotalPrice = Decimal.valueOf(totalLineAmount);
                //NCP-6780 : Commented below line as we start storing Tax into standard CartTax object
                //ci.AdjustmentTaxAmount = Decimal.valueOf(taxAmount);

                //Create CartTax to store Tax related to CartItems - NCP-6780
                cartTaxList.add(createCartTax(ci, Decimal.valueOf(taxAmount)));

                //Create cartItemIds Set
                cartItemIds.add(ci.Id);
            }

            //Delete Existing Cart Tax
            delete [SELECT Id FROM CartTax WHERE CartItemId IN :cartItemIds];

            //Insert CartTax
            if(!cartTaxList.isEmpty()){
                insert cartTaxList;
            }

            //Update CartItems
            if (!cartItemsToUpdate.isEmpty()) {
                update cartItemsToUpdate;
            }
        }
    }

    /**
     * @description : Helper Method to create CartTax instance (NCP-6780)
     * @param ci : CartItem
     * @param taxAmount : Decimal
     * @return  `CartTax`
     */
    public static CartTax createCartTax(CartItem ci, Decimal taxAmount){
        CartTax tax = new CartTax(
            CartItemId = ci.Id,
            Name = ci.Name,
            Amount = taxAmount,
            TaxCalculationDate = Date.today(),
            TaxType = 'Actual'
        );

        return tax;
    }
}