/**
 * @name : D1_OrderHistoryController
 * @description : Request Order history from SAP
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Ajay            12/01/20    Initial Development(NCP-1422)
 * 2.0         Vikas           12/01/20    getOrderItemSummary(NCP-1423)
 * 3.0         Sai Kumar       10/03/21    getnonSfdcOrderInfoMap(NCP-2281)
 * 4.0         Narayana        14/09/21    (NCP-3159)
 * 5.0         Kapil Baliyan   24/02/2022  NCP-6302 - Added statusCode variable to store Status Code
 * 6.0         Kapil Baliyan   06/04/2022  NCP-6558
 * 7.0         Kapil Baliyan   18/05/2022  NCP-6586
 * 8.0         Kapil Baliyan   27/05/2022  NCP-6636
 * 9.0         Sayan Samaddar  10/06/2022  NCP-6841
 * 10.0        Kapil Baliyan   28/11/2022  NCP-7661
 * 11.0        Mukesh Kanth    7/6/2024    152922 : MIDDLE SECTION_Changes to be made for Order Detail page
 **/
public without sharing class D1_OrderHistoryController{
    private static Map < String, String > mapOfOrderStatusMapping;
    private static Map < String, Boolean > mapOfOrderHyperlinkTracking;
    private static Boolean isShowAccountName2Value;
    private static Map < String, String > OrderStatusMappingMap;//152922
    private static List <D1_User_Type__c> userType;//152922
    //private static Map < String, string > mapOfOrderProductToQuantity;//NCP-7661
    
    /**
     * @description : Order Wrapper Class
     */
    public class OrderWrapper{
        @AuraEnabled public List <OrderDetailWrapper> orders {get;set;}
        @AuraEnabled public String orderSummaryId {get;set;}
        @AuraEnabled public String accountId {get;set;}
        @AuraEnabled public Decimal maxOrderLineItem {get;set;}
        @AuraEnabled public Decimal orderProductCount {get;set;}
        @AuraEnabled public Id deliveryAddressId {get;set;}
        @AuraEnabled public String deliverToName {get;set;}
        @AuraEnabled public String deliverToName2 {get;set;}
        @AuraEnabled public String shipToNumber {get;set;}
        @AuraEnabled public String deliveryAddress {get;set;}
        @AuraEnabled public Boolean isRepeatOrderEnabled {get;set;}
        @AuraEnabled public DateTime orderDatetime {get;set;}
        @AuraEnabled public Integer slNo {get;set;}
    }

    /**
     * @description : Order Detail Wrapper Class
     */
    public class OrderDetailWrapper{
        @AuraEnabled public List <ProductDetailWrapper> products {get;set;}
        @AuraEnabled public String currencyType {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String customerRef {get;set;}
        @AuraEnabled public DateTime orderDatetime {get;set;}
        @AuraEnabled public Date requestedDeliveryDate {get;set;}
        @AuraEnabled public String sapOrderNumber {get;set;}
        @AuraEnabled public String statusValue {get;set;}
        @AuraEnabled public String statusCode {get; set;} //NCP-6302
        @AuraEnabled public Boolean displayMenu {get; set;}//NCP-6841
        @AuraEnabled public Boolean displayCancelOrderRequest {get; set;}
        @AuraEnabled public Boolean displayViewCancelOrder {get; set;}
        @AuraEnabled public String queryOnCancelOrderRequest {get; set;}
        @AuraEnabled public Integer slNo {get;set;}
        @AuraEnabled public Boolean isDisplayTrackOrder {get;set;}
        @AuraEnabled public Decimal totalValue {get;set;} //152923
        @AuraEnabled public List <DeliveryDetailWrapper> deliveries {get;set;}//152922
    }

    /** 
     * @description : Delivery detail Wrapper Class : 152922
     */
    public class DeliveryDetailWrapper{
        @AuraEnabled public List <ItemDetailWrapper> items {get;set;}
        @AuraEnabled public String goodsMovementStatus {get;set;}
        @AuraEnabled public String goodsMovementStatusCode {get;set;}
        @AuraEnabled public String deliveryNumber {get;set;}
        @AuraEnabled public Date plannedGIDate {get;set;}
        @AuraEnabled public Date actualGIdate {get;set;}
        @AuraEnabled public Date billingDate {get;set;}
        @AuraEnabled public Date pickDate {get;set;}
        @AuraEnabled public Date deliveryDate {get;set;}
        @AuraEnabled public Date transportPlanningDate {get;set;}
        @AuraEnabled public Date loadingDate {get;set;}
        @AuraEnabled public String statusColor {get;set;}
        @AuraEnabled public Boolean isDisplayTrackOrder {get;set;}
    }

    /** 
     * @description : Item detail Wrapper Class : 152922
     */
    public class ItemDetailWrapper{
        @AuraEnabled public String deliveryNumber {get;set;}
        @AuraEnabled public String itemNumber {get;set;}
        @AuraEnabled public String itemCategory {get;set;}
        @AuraEnabled public String material {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String batch {get;set;}
        @AuraEnabled public String deliveryQuantity {get;set;}
        @AuraEnabled public String salesUnit {get;set;}
        @AuraEnabled public Decimal netWeight {get;set;}
        @AuraEnabled public Decimal grossWeight {get;set;}
        @AuraEnabled public String weightUnit {get;set;}
        @AuraEnabled public Decimal volume {get;set;}
        @AuraEnabled public String volumeUnit {get;set;}
        @AuraEnabled public String referenceDoc {get;set;}
        @AuraEnabled public String eanUpc {get;set;}
        @AuraEnabled public Decimal totalValue {get;set;}
    }

    /**
     * @description : Product Detail Wrapper Class
     */
    public class ProductDetailWrapper{
        @AuraEnabled public String currencyType {get;set;}
        @AuraEnabled public String deliveredQuantity {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String item_number {get;set;}
        @AuraEnabled public String plant {get;set;}
        @AuraEnabled public String product {get;set;}
        @AuraEnabled public String quantity {get;set;}
        @AuraEnabled public String orderedQuantity {get;set;} //NCP-7184
        @AuraEnabled public Boolean orderedQuantityStatus {get;set;}
        @AuraEnabled public Boolean rejected {get;set;}
        @AuraEnabled public String salesUom {get;set;}
        @AuraEnabled public String tax {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String totalValue {get;set;}
    }

    /**
     * @description : SFDC Order Info Wrapper Class
     */
    @testVisible
    class SfdcOrderInfo{
        public Id orderSummaryId;
        public String deliveryAddress;
        public Id deliveryAddressId;
        public String deliverToName;
        public String deliverToName2;
        public String shipToNumber;
        public String accountId;
        public Decimal maxOrderLineItem;
        public Decimal orderProductCount;
    }

    /**
     * @description : Order History Request Wrapper Class
     */
    class OrderHistoryRequestWrapper{
        public String customer {get;set;}
        public String salesOrg {get;set;}
        public Date startDate {get;set;}
        public Date endDate {get;set;}
        public Integer topN {get;set;}
        public String orderGroup {get;set;}
        public String skuNumber {get;set;}
        public String description {get;set;}
        public String sapOrderNum {get;set;}
        public String customerReference {get;set;}
        public Boolean includeItems {get;set;}
        public String[] salesOrderNum {get;set;}
        public Boolean includeDel {get;set;}//154171
    }

    /**
    * @description Get Order History Records
    * @author Ajay
    * @story NCP-1422
    * @param  {String} StringjsonOrderHistoryRequest json string of Order Request
    * @return {List<OrderWrapper>} sfdc order grouped order-list
    */
    @AuraEnabled(cacheable = true)
    public static List < OrderWrapper > getOrderHistory(String jsonOrderHistoryRequest, Boolean isShowAccountName2Value)
    {
        OrderHistoryRequestWrapper request;
        List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1> response;

        try{
            D1_OrderHistoryController.isShowAccountName2Value = isShowAccountName2Value;
            request = (OrderHistoryRequestWrapper) JSON.deserialize(jsonOrderHistoryRequest, OrderHistoryRequestWrapper.class);

            //NCP-6636 : Added id condition to not do any callout if request/startDate/endDate is NULL
            if(request != null && request.startDate != null && request.endDate != null){
                //Step 1: Do Callout
                response = doCallout(request);
                
                //Step 2: Parse Response
                List < OrderWrapper > groupedOrderList = parseResponse(response);
                return groupedOrderList;
            }else{
                return null;
            }
        }
        catch (Exception ex){
            //NCP-3577
            D1_CustomLoggingUtility.logMessageFuture('D1_OrderHistoryController', 'getOrderHistory', ex.getMessage(), ex.getStackTraceString(), ex.getTypeName(), (request != NULL? JSON.serialize(request):''), (response != NULL? JSON.serialize(response):''));
            
            List < OrderWrapper > groupedOrderList = parseResponse(null);
            return groupedOrderList;
        }
    }

    /**
    * @description Request to SAP
    * @author Ajay
    * @story NCP-1422
    * @param  {OrderHistoryRequestWrapper} request
    * @return {List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1>} SAP responce
    */
    public static List < D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 > doCallout(OrderHistoryRequestWrapper request)
    {
        request = request == null ? new OrderHistoryRequestWrapper() : request;
        request.customer = request.customer == null ? '' : String.escapeSingleQuotes(request.customer);
        request.salesOrg = request.salesOrg == null ? '' : String.escapeSingleQuotes(request.salesOrg);
        request.topN = request.topN == null ? 0 : request.topN;
        request.orderGroup = request.orderGroup == null ? '' : String.escapeSingleQuotes(request.orderGroup);
        request.skuNumber = request.skuNumber == null ? '' : String.escapeSingleQuotes(request.skuNumber);
        request.description = request.description == null ? '' : String.escapeSingleQuotes(request.description);
        request.sapOrderNum = request.sapOrderNum == null ? '' : String.escapeSingleQuotes(request.sapOrderNum);
        request.customerReference = request.customerReference == null ? '' : String.escapeSingleQuotes(request.customerReference);
        request.includeItems = request.includeItems == null ? false : request.includeItems;
        request.salesOrderNum = request.salesOrderNum == null ? new List < String > () : request.salesOrderNum;
        request.includeDel = request.includeDel == null ? false : request.includeDel;//154171
        D1_OrderHistoryWSDL.HTTPS_Port orderController = new D1_OrderHistoryWSDL.HTTPS_Port();
        orderController.timeout_x = 120000;
        return orderController.SI_SalesOrderHistoricalInbound_Sync_Out_D1(request.customer, request.salesOrg, request.startDate, request.endDate, request.topN, request.orderGroup, request.skuNumber, request.description, request.sapOrderNum, request.customerReference, request.includeItems, request.salesOrderNum,request.includeDel);//154171
    }

    /**
    * @description Proceess SAP Responce & Returns sfdc order grouped order-list
    * @author Ajay
    * @story NCP-1422
    * @param  {List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1>} SAP Responce
    * @return {List<OrderWrapper>} sfdc order grouped order-list
    */
    @testVisible
    private static List < OrderWrapper > parseResponse(List < D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 > ordersResponce)
    {
        if (ordersResponce == null)
        {
            return new List < OrderWrapper > ();
        }
        //Method to Get Order Status Mapping
        setupOrderStatusMapping();
        //Getting Order Details from Salesforce
        Map < String, SfdcOrderInfo > mapOfSapOrderNoOrderInfo = getSfdcOrderInfoMap(ordersResponce);
        //Getting Order Details from Non-Salesforce
        Map < String, SfdcOrderInfo > mapnonSfdcOrderInfoMap = getnonSfdcOrderInfoMap(ordersResponce, mapOfSapOrderNoOrderInfo);
        List < OrderWrapper > listOfOrders = new List < OrderWrapper > ();
        Map < Id, Integer > mapOfGroupIndex = new Map < Id, Integer > ();
        //NCP-6841
        set<string> sapOrderNumberSet = new set<string>(); 
        for (D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponce: ordersResponce) {
            sapOrderNumberSet.add(orderResponce.SAP_ORDER_NUM);
        }

        Map < String, Case > cancelOrderCaseMap = new Map <String, Case>();  
        for(Case cs : [Select id,D1_Subject__c,Type,Status,D1_Order_Number__c from Case 
                                        where D1_Subject__c = 'Cancel My Order' 
                                        and D1_Order_Number__c IN :sapOrderNumberSet
                                        and Type = 'My Orders'
                                        and IsClosed != true]){
            cancelOrderCaseMap.put(cs.D1_Order_Number__c, cs);
        }
        //NCP-6841
        for (D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponce: ordersResponce)
        {
            String sapOrderNumber = orderResponce.SAP_ORDER_NUM;
            SfdcOrderInfo sfdcOrderInfoObj = mapOfSapOrderNoOrderInfo.get(sapOrderNumber);
            if (sfdcOrderInfoObj == null && mapnonSfdcOrderInfoMap.size() > 0 && mapnonSfdcOrderInfoMap.containsKey(sapOrderNumber))
            {
                sfdcOrderInfoObj = mapnonSfdcOrderInfoMap.get(sapOrderNumber);
            }
            sfdcOrderInfoObj = sfdcOrderInfoObj == null ? new SfdcOrderInfo() : sfdcOrderInfoObj;
            Id orderSummaryId = sfdcOrderInfoObj.orderSummaryId;
            Integer index;
            if (mapOfGroupIndex.containsKey(orderSummaryId)){
                index = mapOfGroupIndex.get(orderSummaryId);
            }
            //If we have multiple orders belong to same Order Summary, creating a list of orders which belong to same Order Summary
            if (orderSummaryId != null && index != null){
                List < OrderDetailWrapper > orders = listOfOrders[index].orders;
                Integer listSize = orders.size();
                OrderDetailWrapper detailObj = setupOrderDetails(orderResponce, listSize + 1, cancelOrderCaseMap);
                orders.add(detailObj);
            }
            else{
                Integer listSize = listOfOrders.size();
                OrderWrapper orderWrapperObj = setupOrderWrapper(orderResponce, sfdcOrderInfoObj, listSize + 1);
                OrderDetailWrapper detailObj = setupOrderDetails(orderResponce, 1, cancelOrderCaseMap);
                orderWrapperObj.orders.add(detailObj);
                orderWrapperObj.orderDatetime = detailObj.orderDatetime;
                listOfOrders.add(orderWrapperObj);
                mapOfGroupIndex.put(orderSummaryId, listSize);
            }
        }
        return listOfOrders;
    }
    
    /**
    * @description Fetch Order Information from SFDC
    * @author Ajay
    * 
    * @story NCP-1422
    * @param  {List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1>} SAP Responce
    * @return {Map<String, SfdcOrderInfo>} map of sap-order-number -> SFDC Order-Info
    */
    private static Map < String, SfdcOrderInfo > getSfdcOrderInfoMap(List < D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 > ordersResponce)
    {
        Set < String > setOfSapOrderNumbers = new Set < String > ();
        for (D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 order: ordersResponce){
            setOfSapOrderNumbers.add(order.SAP_ORDER_NUM);
        }
        Map < String, Id > mapOfOrderAccountId = new Map < String, Id > ();
        Map < Id, Decimal > maxOrderLineItemByOrderSummaryId = new Map < Id, Decimal > ();
        Map < Id, Decimal > orderProductCountByOrderSummaryId = new Map < Id, Decimal > ();
        Map < String, Id > mapOfSapOrderNoOrderSummaryId = new Map < String, Id > ();
        Map < Id, ContactPointAddress > mapOfOrderDelivery = new Map < Id, ContactPointAddress > ();
        for (Sales_Order__c salesOrder: [SELECT Id, Order_Summary__c, SAP_Order_Number__c, Order_Summary__r.AccountId, Order_Summary__r.Sales_Area__r.Max_Order_Line_Items__c,Order_Summary__r.Order_Product_Count__c,
                                         Order_Summary__r.Delivery_Address__r.Name, Order_Summary__r.Delivery_Address__r.Name2__c, Order_Summary__r.Delivery_Address__r.Address, Order_Summary__r.Delivery_Address__r.Account_Number__c
                                         FROM Sales_Order__c
                                         WHERE SAP_Order_Number__c IN: setOfSapOrderNumbers
                                        ]){
            mapOfSapOrderNoOrderSummaryId.put(salesOrder.SAP_Order_Number__c, salesOrder.Order_Summary__c);
            mapOfOrderDelivery.put(salesOrder.Order_Summary__c, salesOrder.Order_Summary__r.Delivery_Address__r);
            mapOfOrderAccountId.put(salesOrder.Order_Summary__c, salesOrder.Order_Summary__r.AccountId);
            maxOrderLineItemByOrderSummaryId.put(salesOrder.Order_Summary__c, salesOrder.Order_Summary__r.Sales_Area__r.Max_Order_Line_Items__c);
            orderProductCountByOrderSummaryId.put(salesOrder.Order_Summary__c, salesOrder.Order_Summary__r.Order_Product_Count__c);
        }//NCP-7184
        //Commented due to NCP-7661
        /*mapOfOrderProductToQuantity = new map<string,string>();
        for(OrderItemSummary orderItemObj : [select id,Product2.StockKeepingUnit,Quantity,Sales_Order__r.SAP_Order_Number__c from OrderItemSummary 
                                                where OrderSummaryId IN :mapOfSapOrderNoOrderSummaryId.values()]) {
            string strKey = orderItemObj.Sales_Order__r.SAP_Order_Number__c + '' + orderItemObj.Product2.StockKeepingUnit;
            mapOfOrderProductToQuantity.put(strKey,string.valueOf(orderItemObj.Quantity));
        }*/
        Map < String, SfdcOrderInfo > mapOfSapOrderNoOrderInfo = new Map < String, SfdcOrderInfo > ();
        for (String sapOrderNumber: mapOfSapOrderNoOrderSummaryId.keySet()){
            SfdcOrderInfo orderInfo = new SfdcOrderInfo();
            orderInfo.orderSummaryId = mapOfSapOrderNoOrderSummaryId.get(sapOrderNumber);
            orderInfo.accountId = mapOfOrderAccountId.get(orderInfo.orderSummaryId);
            orderInfo.maxOrderLineItem = maxOrderLineItemByOrderSummaryId.get(orderInfo.orderSummaryId);
            orderInfo.orderProductCount = orderProductCountByOrderSummaryId.get(orderInfo.orderSummaryId);
            setupDeliveryAddress(orderInfo, mapOfOrderDelivery.get(orderInfo.orderSummaryId));
            mapOfSapOrderNoOrderInfo.put(sapOrderNumber, orderInfo);
        }
        return mapOfSapOrderNoOrderInfo;
    }
    
    /**
    * @description Fetch Order Information from SFDC
    * @author Ajay
    * @story NCP-1422
    * @param  {List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1>} SAP Responce
    * @returns {Map<String, SfdcOrderInfo>} map of sap-order-number -> SFDC Order-Info
    */
    @testVisible
    private static void setupDeliveryAddress(SfdcOrderInfo orderInfo, ContactPointAddress deliveryObj){
        if (deliveryObj == null){
            return;
        }
        string deliveryObjName2 = '';
        if(D1_OrderHistoryController.isShowAccountName2Value == true){
            deliveryObjName2 = deliveryObj.Name2__c != null ?  deliveryObj.Name2__c : '';
        }
        
        Address deliveryAddressObj = deliveryObj.Address == null ? new Address() : deliveryObj.Address;
        orderInfo.deliveryAddressId = deliveryObj.Id;
        orderInfo.shipToNumber = deliveryObj.Account_Number__c;
        orderInfo.deliverToName = deliveryObj.Name + ',';
        orderInfo.deliverToName2 = deliveryObjName2;
        String street = deliveryAddressObj.getStreet();
        String city = deliveryAddressObj.getCity();
        String country = deliveryAddressObj.getCountry();
        List < String > addressList = new List < String > ();
        if (!String.isEmpty(street)){
            addressList.add(street);
        }
        if (!String.isEmpty(city)){
            addressList.add(city);
        }
        if (!String.isEmpty(country)){
            addressList.add(country);
        }
        orderInfo.deliveryAddress = String.join(addressList, ', ');
    }
    
    /**
    * @description Set up Order Wrapper Object
    * @author Ajay
    * @story NCP-1422
    * @param  {D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponceObj} SAP Responce(each object)
    * @param  {SfdcOrderInfo} SFDC Order-info
    * @param  {Integer} Unique Identifier
    * @return  {OrderWrapper} OrderWrapper Object
    */
    private static OrderWrapper setupOrderWrapper(D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponceObj, SfdcOrderInfo sfdcOrderInfoObj, Integer slNo){
        OrderWrapper orderWrapperObj = new OrderWrapper();
        orderWrapperObj.orders = new List < OrderDetailWrapper > ();
        orderWrapperObj.orderSummaryId = sfdcOrderInfoObj.orderSummaryId;
        orderWrapperObj.accountId = sfdcOrderInfoObj.accountId;
        orderWrapperObj.maxOrderLineItem = sfdcOrderInfoObj.maxOrderLineItem;
        orderWrapperObj.orderProductCount = sfdcOrderInfoObj.orderProductCount;
        orderWrapperObj.deliveryAddressId = sfdcOrderInfoObj.deliveryAddressId;
        orderWrapperObj.deliverToName = sfdcOrderInfoObj.deliverToName;
        orderWrapperObj.deliverToName2 = sfdcOrderInfoObj.deliverToName2;
        orderWrapperObj.shipToNumber = sfdcOrderInfoObj.shipToNumber;
        orderWrapperObj.deliveryAddress = sfdcOrderInfoObj.deliveryAddress;
        if (sfdcOrderInfoObj.orderSummaryId != null){
            orderWrapperObj.isRepeatOrderEnabled = true;
        }
        else{
            orderWrapperObj.isRepeatOrderEnabled = false;
        }
        orderWrapperObj.slNo = slNo;
        return orderWrapperObj;
    }
    
    /**
    * @description Set up Order Detail Wrapper Object
    * @author Ajay
    * @story NCP-1422
    * @param  {D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponceObj} SAP Responce(each object)
    * @param  {Integer} Unique Identifier
    * @return  {OrderDetailWrapper} OrderDetailWrapper Object
    */
    private static OrderDetailWrapper setupOrderDetails(D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponceObj, Integer slNo, Map < String, Case > cancelOrderCaseMap)
    {
        OrderDetailWrapper detailObj = new OrderDetailWrapper();
        detailObj.products = setupProductDetails(orderResponceObj.ITEMS,orderResponceObj.SAP_ORDER_NUM);
        //152922
        if(userType[0].D1_Setting__r.Show_Delivery__c){
            detailObj.deliveries = setupDeliveryDetails(orderResponceObj.DELIVERY);
        }
        
        detailObj.currencyType = orderResponceObj.CURRENCY_x;
        detailObj.value = orderResponceObj.VALUE;
        detailObj.customerRef = orderResponceObj.CUSTOMER_REF;
        detailObj.orderDatetime = orderResponceObj.ORDER_DATETIME;
        detailObj.requestedDeliveryDate = orderResponceObj.REQ_DEL_DATE;
        detailObj.sapOrderNumber = orderResponceObj.SAP_ORDER_NUM;
        detailObj.statusValue = mapOfOrderStatusMapping.get(orderResponceObj.STATUS);
        detailObj.statusCode = orderResponceObj.STATUS; //NCP-6302
        detailObj.totalValue = orderResponceObj.TOTAL_VALUE; //152923
        //NCP-6841
        if(detailObj.statusCode=='01' || detailObj.statusCode=='02' || detailObj.statusCode=='07' || detailObj.statusCode=='08'){
            detailObj.displayMenu = false;
        }
        else{
            detailObj.displayMenu = true;
        }        
        if(cancelOrderCaseMap.get(detailObj.sapOrderNumber)== Null){
            detailObj.displayCancelOrderRequest = false;
            detailObj.displayViewCancelOrder = true;
        } 
        else{
            detailObj.displayCancelOrderRequest = true;
            detailObj.displayViewCancelOrder = false;
            detailObj.queryOnCancelOrderRequest = cancelOrderCaseMap.get(detailObj.sapOrderNumber).id;
        }
        //NCP-6841
        detailObj.isDisplayTrackOrder = mapOfOrderHyperlinkTracking.get(orderResponceObj.STATUS);
        detailObj.slNo = slNo;
        return detailObj;
    }
    
    /**
    * @description Set up Product Detail Wrapper Object
    * @author Ajay
    * @story NCP-1422
    * @param  {D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 orderResponceObj} SAP Responce(each object)
    * @return  {ProductDetailWrapper} ProductDetailWrapper Object
    */
    private static List < ProductDetailWrapper > setupProductDetails(D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1[] productsResponce,string sapOrderNumber)
    {
        List < ProductDetailWrapper > products = new List < ProductDetailWrapper > ();
        ProductDetailWrapper product;
        if (productsResponce != null)
        {
            for (D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1 productResponce: productsResponce)
            {
                product = new ProductDetailWrapper();
                product.currencyType = productResponce.CURRENCY_x;
                product.deliveredQuantity = productResponce.DELIVERED_QUANTITY;
                product.description = productResponce.DESCRIPTION;
                product.item_number = productResponce.ITEM_NUMBER;
                product.plant = productResponce.PLANT;
                product.product = productResponce.PRODUCT;
                product.quantity = productResponce.QUANTITY;
                product.rejected = productResponce.REJECTED;
                product.salesUom = productResponce.SALES_UOM;
                product.tax = productResponce.TAX;
                product.value = productResponce.VALUE;
                product.totalValue = String.valueOf(Decimal.valueOf(productResponce.VALUE) + Decimal.valueOf(productResponce.TAX));
                
                //Commented due to NCP-7661
                /*string strKey =  sapOrderNumber + '' + productResponce.PRODUCT;     //NCP-7184
                if(mapOfOrderProductToQuantity.get(strKey) == NULL){
                    product.orderedQuantity = System.label.D1_None_D1_Order;
                    product.orderedQuantityStatus = true;
                }
                else {
                    product.orderedQuantity = mapOfOrderProductToQuantity.get(strKey);
                    product.orderedQuantityStatus = false;      
                }*/
                products.add(product);
            }
        }
        return products;
    }

    /**
    * @description Set up Delivery Detail Wrapper Object
    * @author Mukesh Kanth
    * @story 152922
    * @param  {D1_OrderHistoryWSDL.D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Delivery_Response_D1} SAP Responce(each object)
    * @return  {DeliveryDetailWrapper} DeliveryDetailWrapper Object
    */
    private static List < DeliveryDetailWrapper > setupDeliveryDetails(D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Delivery_Response_D1[] deliveriesResponce)
    {
        List < DeliveryDetailWrapper > deliveries = new List < DeliveryDetailWrapper > ();
        DeliveryDetailWrapper delivery;
        if (deliveriesResponce != null)
        {
            for (D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Delivery_Response_D1 deliveryResponce: deliveriesResponce)
            {
                delivery = new DeliveryDetailWrapper();
                
                if(deliveryResponce.BILLING_STATUS != null){
                    delivery.goodsMovementStatusCode = deliveryResponce.BILLING_STATUS;
                }
                else{
                    delivery.goodsMovementStatusCode = deliveryResponce.GOODS_MOVEMENT_STATUS;
                }
                
                delivery.goodsMovementStatus = mapOfOrderStatusMapping.get(delivery.goodsMovementStatusCode);
                delivery.statusColor = OrderStatusMappingMap.get(delivery.goodsMovementStatusCode);
                delivery.deliveryNumber = deliveryResponce.DELIVERY_NUMBER;
                delivery.plannedGIDate = deliveryResponce.PLANNED_GI_DATE;
                delivery.actualGIdate = deliveryResponce.ACTUAL_GI_DATE;
                delivery.billingDate = deliveryResponce.BILLING_DATE;
                delivery.pickDate = deliveryResponce.PICK_DATE;
                delivery.deliveryDate = deliveryResponce.DELIVERY_DATE;
                delivery.transportPlanningDate = deliveryResponce.TRANSPORT_PLANNING_DATE;
                delivery.loadingDate = deliveryResponce.LOADING_DATE;
                delivery.isDisplayTrackOrder = mapOfOrderHyperlinkTracking.get(delivery.goodsMovementStatusCode);
                delivery.items = setupItemDetails(deliveryResponce.ITEM);
                deliveries.add(delivery);        
            }
        }
        return deliveries;
    }

    /**
    * @description Set up Item Detail Wrapper Object
    * @author Mukesh Kanth
    * @story 152922
    * @param  {D1_OrderHistoryWSDL.ITEM_element[] itemElementsResponce} SAP Responce(each object)
    * @return  {ItemDetailWrapper} ItemDetailWrapper Object
    */
    private static List < ItemDetailWrapper > setupItemDetails(D1_OrderHistoryWSDL.ITEM_element[] itemElementsResponce)
    {
        List < ItemDetailWrapper > itemElements = new List < ItemDetailWrapper > ();
        ItemDetailWrapper itemElement;
        if (itemElementsResponce != null)
        {
            for (D1_OrderHistoryWSDL.ITEM_element itemElementResponce: itemElementsResponce)
            {
                itemElement = new ItemDetailWrapper();
                itemElement.deliveryNumber = itemElementResponce.DELIVERY_NUM;
                itemElement.itemNumber = itemElementResponce.ITEM_NUMBER;
                itemElement.itemCategory = itemElementResponce.ITEM_CATEGORY;
                itemElement.material = itemElementResponce.MATERIAL !=null ? itemElementResponce.MATERIAL.trim() : '';
                itemElement.description = itemElementResponce.DESCRIPTION;
                itemElement.batch = itemElementResponce.BATCH;
                itemElement.deliveryQuantity = itemElementResponce.DELIVERY_QUANTITY;
                itemElement.salesUnit = itemElementResponce.SALES_UNIT;
                itemElement.netWeight = itemElementResponce.NET_WEIGHT;
                itemElement.grossWeight = itemElementResponce.GROSS_WEIGHT;
                itemElement.weightUnit = itemElementResponce.WEIGHT_UNIT;
                itemElement.volume = itemElementResponce.VOLUME;
                itemElement.volumeUnit = itemElementResponce.VOLUME_UNIT;
                itemElement.referenceDoc = itemElementResponce.REFERENCE_DOC;
                itemElement.eanUpc = itemElementResponce.EAN_UPC;  
                itemElement.totalValue = null;    
                itemElements.add(itemElement);        
            }
        }
        return itemElements;
    }
    
    /**
    * @description Set up mapping of SAP status code to status value
    * @author Ajay
    * @story NCP-1422
    */
    private static void setupOrderStatusMapping(){
        Boolean hasLCTAccess = FeatureManagement.checkPermission('D1_LCT_Access');
        mapOfOrderStatusMapping = new Map < String, String > ();
        mapOfOrderHyperlinkTracking = new Map < String, Boolean > ();
        OrderStatusMappingMap = new Map < String, String > ();
        //Start : Changes Added for NCP-3426
        List<User> loggedInUser = [Select id, D1_User_Type_Id__c from user where Id =: Userinfo.getUserId() limit 1];
        userType = [select Id, D1_Setting__r.Language__c,D1_Setting__r.Show_Delivery__c from D1_User_Type__c where Id =: loggedInUser[0].D1_User_Type_Id__c limit 1]; //152922      
        
        for (D1_Order_Status_Mapping__mdt orderStatusConfig: [SELECT MasterLabel,ES_Value__c,DE_Value__c,IT_Value__c,BR_Value__c, Value__c,Is_LCT_Trackable__c,Shipment_Status_Color__c FROM D1_Order_Status_Mapping__mdt])
        {
            if(!userType.isEmpty() && userType[0]?.D1_Setting__r.Language__c == 'es' && orderStatusConfig.ES_Value__c != null ){
                mapOfOrderStatusMapping.put(orderStatusConfig.MasterLabel, orderStatusConfig.ES_Value__c);

            } else if(!userType.isEmpty() && userType[0]?.D1_Setting__r.Language__c == 'de' && orderStatusConfig.DE_Value__c != null) {
                mapOfOrderStatusMapping.put(orderStatusConfig.MasterLabel, orderStatusConfig.DE_Value__c);

            } else if(!userType.isEmpty() && userType[0]?.D1_Setting__r.Language__c == 'it' && orderStatusConfig.IT_Value__c != null) {
                mapOfOrderStatusMapping.put(orderStatusConfig.MasterLabel, orderStatusConfig.IT_Value__c);
                
            }else if(!userType.isEmpty() && userType[0]?.D1_Setting__r.Language__c == 'pt_BR' && orderStatusConfig.BR_Value__c != null) {
                mapOfOrderStatusMapping.put(orderStatusConfig.MasterLabel, orderStatusConfig.BR_Value__c);
            }
            else{
               mapOfOrderStatusMapping.put(orderStatusConfig.MasterLabel, orderStatusConfig.Value__c); 
            } 
            
            if(hasLCTAccess == true){
                mapOfOrderHyperlinkTracking.put(orderStatusConfig.MasterLabel,orderStatusConfig.Is_LCT_Trackable__c);
            }
            //152922
            OrderStatusMappingMap.put(orderStatusConfig.MasterLabel,orderStatusConfig.Shipment_Status_Color__c);
        }
        //End : Changes Added for NCP-3426
    }
    
    /**
     * @description  Method to get Order Item Summary
     * @author Vikas
     * @story NCP-1423
     * @param webStoreId 
     * @param accountId 
     * @param orderSummaryId 
     * @return  `List < ConnectApi.OrderItemSummaryProduct >`
     */    
    @AuraEnabled
    public static List < ConnectApi.OrderItemSummaryProduct > getOrderItemSummary(String webStoreId, String accountId, String orderSummaryId)
    {
        List < ConnectApi.OrderItemSummaryProduct > summaryProducts = new List < ConnectApi.OrderItemSummaryProduct > ();
        ConnectApi.OrderItemSummaryCollection orderItems = ConnectApi.CommerceBuyerExperience.getOrderItemSummaries(webStoreId, accountId, orderSummaryId);
        if (orderItems.items.size() > 0){
            for (ConnectApi.OrderItemSummary summary: orderItems.items){
                summaryProducts.add(summary.product);
            }
        }
        return summaryProducts;
    }
    
    /**
     * @author Vikas
     * @story NCP-1534
     * @description Method to get cart Item for repeat Order
     * @param webStoreId 
     * @param accountId 
     * @param cartId 
     * @param pageParam 
     * @param sortParam 
     * @param maxOrderLineItem 
     * @param summaryId 
     * @return  `boolean`
     */    
    @AuraEnabled
    public static boolean getCartItems(String webStoreId, String accountId, String cartId, String pageParam, String sortParam, Integer maxOrderLineItem, String summaryId)
    {
        Boolean ismaxProductCount = false;
        List < String > totalRepeatOrderProducts = new List<String>();
        if (string.isNotBlank(cartId))
        {
            ConnectApi.CartItemSortOrder resolvedSortParam = B2BUtils.resolveSortParam(sortParam);
            ConnectApi.CartItemCollection cartItemFromApi = ConnectApi.CommerceCart.getCartItems(webStoreId, accountId, cartId, pageParam, resolvedSortParam);
            List<OrderItemSummary> orderProducts = [Select id,StockKeepingUnit from OrderItemSummary where OrderSummaryId =: summaryId];
            for(OrderItemSummary item: orderProducts){
                totalRepeatOrderProducts.add(item.StockKeepingUnit);
            }
            List < String > sKUs = new List < String > ();
            if (cartItemFromApi.cartItems.size() > 0){
                for (ConnectApi.CartItemResult cart: cartItemFromApi.cartItems){
                    sKUs.add(cart.cartItem.productDetails.sku);
                }
            }
            List < String > nonMatchedSKUs = new List < String > ();
            for (String sku: totalRepeatOrderProducts){
                if (!sKUs.contains(sku)){
                    nonMatchedSKUs.add(sku);
                }
            }
            Integer cartItemCount = cartItemFromApi.cartItems.size();
            if ((nonMatchedSKUs.size() + cartItemCount) > maxOrderLineItem){ //NCP-6302 : Use > instead of >=
                ismaxProductCount = true;
            }
        }
        return ismaxProductCount;
    }
    
    /**
     * @author Vikas
     * @story NCP-1534, NCP-6586 (added cartId, deliveryAddressId)
     * @description Method to callout for adding Order to Cart Items
     * @param searchQuery 
     * @return  `Object`
     * @exception 
     */    
    @AuraEnabled(cacheable = false)
    public static List<Object> orderToCart(String searchQuery, String cartId, String deliveryAddressId)
    {
        Decimal apiVersionApexClass = [
            SELECT ApiVersion
            FROM ApexClass
            WHERE Name = 'D1_OrderHistoryController'
            //WITH SECURITY_ENFORCED
            LIMIT 1
        ].ApiVersion;
        HttpRequest httpRequest = new HttpRequest();
        List<Object> response;
        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type', 'application/json;  charset=utf-8');
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String apiUrl = '/services/data/v' + apiVersionApexClass + '/actions/standard/orderToCartAction';
        httpRequest.setEndpoint(baseUrl + apiUrl);
        httpRequest.setBody(searchQuery);
        string sessionId;
        if (!Test.isRunningTest())
        {
            sessionId = D1_B2BSearchController.getSessionId();
        }
        httpRequest.setHeader('Authorization', 'Bearer ' + sessionId);
        try
        {
            Http http = new Http();
            HttpResponse httpResponse = http.send(httpRequest);
            Integer statusCode = httpResponse.getStatusCode();
            if (statusCode >= 200 && statusCode <= 204)
            {
                //response = JSON.deserializeUntyped(httpResponse.getBody());
                response = (List<Object>)JSON.deserializeUntyped(httpResponse.getBody());
                
                //NCP-6586 : Check if isSuccess is true, update Delivery Address of Selected Order to Cart
                Boolean isSuccess = false;
                for(Object obj : response){
                    Map<String,Object> objItem = (Map<String,Object>)obj;
                    if((Boolean)objItem.get('isSuccess')){
                        isSuccess = true;
                        break;
                    }
                }

                if(isSuccess && String.isNotBlank(deliveryAddressId)){
                    ContactPointAddress cpAddress = [SELECT Id, Status__c FROM ContactPointAddress WHERE Id =:deliveryAddressId LIMIT 1];
                    if(cpAddress.Status__c == 'Active'){
                        WebCart cart = new WebCart();
                        cart.Id = cartId;
                        cart.Delivery_Address__c = deliveryAddressId;

                        update cart;
                    }
                }
            }
            else
            {
                throw new CalloutException(httpResponse.getBody());
            }
        }
        catch (System.Exception e)
        {
            throw e;
        }
        return response;
    }
    
    
    /**
    * @description Fetch Order Information from SFDC
    * @author Sai
    * @story NCP-2281
    * @param  {List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1>} SAP Responce,mapOfSapOrderNoOrderInfo Salesforce records
    * @return {Map<String, SfdcOrderInfo>} map of sap-order-number -> Non-SFDC Order-Info
    */
    private static Map < String, SfdcOrderInfo > getnonSfdcOrderInfoMap(List < D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 > ordersResponce, Map < String, SfdcOrderInfo > mapOfSapOrderNoOrderInfo)
    {
        Map < String, String > setOfSapOrderNumbers = new Map < String, String > ();
        Set < String > setOfShipToNumber = new Set < String > ();
        Map < String, ContactPointAddress > mapOfCustomernoDeliveryAddress = new Map < String, ContactPointAddress > ();
        for (D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 order: ordersResponce)
        {
            if (!mapOfSapOrderNoOrderInfo.containsKey(order.SAP_ORDER_NUM))
            {
                setOfSapOrderNumbers.put(order.SAP_ORDER_NUM, order.CUSTOMER_NO);
                setOfShipToNumber.add(order.CUSTOMER_NO);
            }
        }
        if (setOfShipToNumber.size() > 0)
        {
            for (ContactPointAddress addressRecord: [SELECT Id, Account_Number__c, AddressType, ParentId, Address, Name, Name2__c from ContactPointAddress
                                                     WHERE Account_Number__c in : setOfShipToNumber AND AddressType = 'Shipping'
                                                    ])
            {
                mapOfCustomernoDeliveryAddress.put(addressRecord.Account_Number__c, addressRecord);
            }
        }
        Map < String, SfdcOrderInfo > mapOfOlnySapOrderNoOrderInfo = new Map < String, SfdcOrderInfo > ();
        if (mapOfCustomernoDeliveryAddress.size() > 0)
        {
            for (String sapOrderNumber: setOfSapOrderNumbers.keySet())
            {
                if (setOfSapOrderNumbers.containsKey(sapOrderNumber))
                {
                    if (mapOfCustomernoDeliveryAddress.containsKey(setOfSapOrderNumbers.get(sapOrderNumber)))
                    {
                        SfdcOrderInfo orderInfo = new SfdcOrderInfo();
                        orderInfo.orderSummaryId = null;
                        orderInfo.accountId = mapOfCustomernoDeliveryAddress.get(setOfSapOrderNumbers.get(sapOrderNumber)).ParentId;
                        orderInfo.maxOrderLineItem = 0;
                        orderInfo.orderProductCount = 0;
                        setupDeliveryAddress(orderInfo, mapOfCustomernoDeliveryAddress.get(setOfSapOrderNumbers.get(sapOrderNumber)));
                        mapOfOlnySapOrderNoOrderInfo.put(sapOrderNumber, orderInfo);
                    }
                }
            }
        }
        return mapOfOlnySapOrderNoOrderInfo;
    }

}