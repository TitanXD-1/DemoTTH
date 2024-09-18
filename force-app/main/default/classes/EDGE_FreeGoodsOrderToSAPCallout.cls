/*
*@Name: EDGE_FreeGoodsOrderToSAPCallout
*@Description: This Class is build the JSON and send callout to SAP
*@History                                                            
*
*VERSION			AUTHOR					DATE				DETAIL
*1.0			Saurav Prasad			30/10/2023			Initial Development: 147473 - Salesforce Attribute mapping with corresponding Mulesoft Attribute in JSON file for sending Free Goods Order to SAP
*1.1			Saurav Prasad			15/11/2023			147474 - Capture SAP Response and Populate the SAP fields in Free Goods Order Object
*1.2			Doman/Shivam			27/11/2023			147971/148542
*1.3			Doman Murmu				11/12/2023			149245 - QA_SAP error message value text is not visible in email
*/
public with sharing class EDGE_FreeGoodsOrderToSAPCallout {
    public static Integer salesDocNumber = 1;
    public static final String EDGE_SAP = 'sap';
    public static final String EDGE_FILENAME = 'PaymentFileData';
    public static final String EDGE_CALLOUT = 'callout:';
    public static final String EDGE_POST = 'POST';
    public static final String EDGE_CONTENTTYPE = 'Content-Type';
    public static final String EDGE_APPJSON = 'application/json';
    public static final String SUCCESS = 'Success';
    public static final String FAIL = 'Failed';
    public static final Map<String,EDGE_Free_Goods_Order_to_SAP__mdt> FREEGOODSMDT = new Map<String,EDGE_Free_Goods_Order_to_SAP__mdt>();
    public static String request = '';
    public static String response = '';
    private static Map<Id,Market_Setting__c> marketSettingMap = new Map<Id,Market_Setting__c>();	//147971 - changed to global

    @future(callout = true)
    public static void getOrder(set<Id> orderIds){
        
        Set<Id> countryIds = new Set<Id>();
        Map<String,List<Order_Item__c>> mapOfOrdWithOrdItems = new Map<String,List<Order_Item__c>>();
        List<Order__c> updateOrderList =new List<Order__c>();
        
        try{
            getMetaData();
            getOrderItems(orderIds,countryIds,mapOfOrdWithOrdItems);
            getMarketSetting(countryIds, marketSettingMap);
            processOrders(mapOfOrdWithOrdItems, updateOrderList);
        }
        catch(Exception ex){
            handleException(ex);
        }
    }
    
    private static void getMetaData(){
        
        for(EDGE_Free_Goods_Order_to_SAP__mdt freeGood : EDGE_Free_Goods_Order_to_SAP__mdt.getAll().values()){
            if(freeGood.EDGE_IsActive__c){
                FREEGOODSMDT.put(freeGood.DeveloperName,freeGood);
            }
        }
        
    }
    
    private static void getOrderItems(set<Id> orderIds, Set<Id> countryIds, Map<String,List<Order_Item__c>> mapOfOrdWithOrdItems){
        for(Order_Item__c orderItem:
            [SELECT Id,Quantity__c,Selected_UoM__c,Name,
             Reason_Code__r.Internal_Order__r.Name,
             Order__c,Order__r.Delivery_instructions__c,Order__r.Preferred_Delivery_Date__c,
             Order__r.Account__r.SAP_Ship_to__c,Order__r.Account__r.SAP_Sold_to__c,
             Order__r.Account__r.Sales_Org__c,Order__r.Sales_Representative__r.Name,
             Order__r.Account__r.Country__c,
             Product__c,Product__r.SAP_SKU_Code__c
             FROM Order_Item__c 
             WHERE Order__c IN: orderIds
             WITH SECURITY_ENFORCED
             ORDER BY Order__r.Delivery_Partner__c,Order__c]){
                 countryIds.add(orderItem.Order__r.Account__r.Country__c);
                 
                 if(!mapOfOrdWithOrdItems.containsKey(orderItem.Order__c)){	
                     mapOfOrdWithOrdItems.put(orderItem.Order__c,new List<Order_Item__c>{orderItem});
                 }else{
                     mapOfOrdWithOrdItems.get(orderItem.Order__c).add(orderItem);
                 }
             }
    }
    
    private static void getMarketSetting( Set<Id> countryIds, Map<Id,Market_Setting__c> marketSettingMap){
        if(!countryIds.isEmpty()){
            for(Market_Setting__c marketSetting : 
                [SELECT Id,Geography__c,SAP_Free_Goods_Order_Type__c, SAP_Free_Goods_Purchase_Order_Type__c,Send_SAP_Order_Failure_Email__c ,Language__c
                 FROM Market_Setting__c 
                 WHERE Geography__c IN: countryIds
                 WITH SECURITY_ENFORCED]){
                     marketSettingMap.put(marketSetting.Geography__c,marketSetting);
                 }
        }
    }

    private static void processOrders(Map<String, List<Order_Item__c>> mapOfOrdWithOrdItems, List<Order__c> updateOrderList) {
        
        for(String orderId: mapOfOrdWithOrdItems.keySet()){
            
            JSONGenerator gen = JSON.createGenerator(true);

            buildOrderJSON(gen, mapOfOrdWithOrdItems.get(orderId));
            request = gen.getAsString();
            
            HttpResponse httpRes = sendCallout(request);
            response = httpRes.getBody();
            Order__c order = new Order__c(Id = orderId);
            updateOrderStatus(order,httpRes,gen);
            updateOrderList.add(order);
            
        }
        updateOrderList(updateOrderList);
        EDGE_FreeGoodsOrderSAPErrorMail.sendSAPErrorEmail(updateOrderList, marketSettingMap);	// 147971, 149245 - @param updateOrderList
    }
    
    private static void updateOrderList(List<Order__c> updateOrderList) {
        if (!updateOrderList.isEmpty() && Schema.sObjectType.Order__c.isUpdateable()) {
            Update updateOrderList;
        }
    }
    
    /*
     * Method	:	sendCallout
     * Purpose	:	This method is used to send callout to mulesoft using named credential/ external credential
     * Params	:	String
     * Return	:	HttpResponse
     * Author	:	Saurav Prasad
     * Story	:	147474 - Capture SAP Response and Populate the SAP fields in Free Goods Order Objectd
     */
    
    private static HttpResponse sendCallout(String request){
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(EDGE_CALLOUT + 'EDGEMulesoft'); 
        httpReq.setMethod(EDGE_POST);
        httpReq.setBody(request);
        httpReq.setHeader(EDGE_CONTENTTYPE, EDGE_APPJSON);
        httpReq.setTimeout(120000);
        
        Http newHttp = new Http();
        HttpResponse httpRes = newHttp.send(httpReq);
        return httpRes;
    }
    
    /*
     * Method	:	updateOrderStatus
     * Purpose	:	This method is used to update transmission status in order
     * Params	:	set<Id>, Map<String,object>
     * Return	:	void
     * Author	:	Saurav Prasad
     * Story	:	147474 - Capture SAP Response and Populate the SAP fields in Free Goods Order Object
     */
    
    private static void updateOrderStatus(Order__c order, HttpResponse httpRes,JSONGenerator gen){
        Map<String,object> requestMap = (Map<String,object>) JSON.deserializeUntyped(httpRes.getBody());
        List<String> responseHeaders = System.Label.EDGE_FreeGoodsSAP_ResponseHeaders.split(';'); //CreditNote Number;CreditNote CreationDate;Response Message
        Boolean isSuccess = getStatusCode(httpRes.getBody());
        
        order.SAP_Error_Message__c = isSuccess ? null :nullCheck(getDataFromMap(responseHeaders[2],requestMap));
        order.SAP_Order_Creation_Date__c = isSuccess ? (Date.valueOf(nullCheck(getDataFromMap(responseHeaders[1],requestMap)))):null;
        order.SAP_Order_Number__c = isSuccess ? nullCheck(getDataFromMap(responseHeaders[0],requestMap)): null;
        order.SAP_Order_Transmission_Status__c =  isSuccess?SUCCESS:FAIL;
        
        updateLogMessage(httpRes, gen.getAsString());
    }
    
    private static void buildOrderJSON(JSONGenerator gen, List<Order_Item__c> orderItems) {
        gen.writeStartObject();
        gen.writeFieldName(EDGE_FILENAME);
        gen.writeStartArray();
        
        for (Order_Item__c orderItem : orderItems) {
            //Wrapper Build
            EDGE_SAPWrapper sapWrap = buildSAPWrapper(orderItem);
            writeFreeGoodsJSON(gen, sapWrap, orderItem);
        }
        
        gen.writeEndArray();
        gen.writeEndObject();
    }
    
    private static EDGE_SAPWrapper buildSAPWrapper(Order_Item__c orderItem){
        
        EDGE_SAPWrapper sapWrap = new EDGE_SAPWrapper();
        sapWrap.sapBillTo = '';
        if(!Test.isrunningTest()){
        	sapWrap.sapShippingInstructions = nullCheck((orderItem.Order__r.Delivery_instructions__c)).replaceAll('\r\n|\n|\r',' ');
        }else{
             sapWrap.sapShippingInstructions = nullCheck(orderItem.Order__r.Delivery_instructions__c);
        }
        sapWrap.sapFixedValueDate = '';
        sapWrap.sapSalesUnit = nullCheck(String.valueOf(orderItem.Selected_UoM__c));
        sapWrap.sapSfdcIn = nullCheck(String.valueOf(orderItem.Order__c));
        sapWrap.sapDistrChan = System.Label.EDGE_FreeGoodsSAP_Channel;
        sapWrap.sapTargetQty = nullCheck(String.valueOf(orderItem.Quantity__c));
        sapWrap.sapBatch = '';
        sapWrap.sapCostCenter = '';
        sapWrap.sapMaterialTaxClassification = '';
        sapWrap.sapPurchNoC = orderItem.Order__r.Sales_Representative__r.Name+'_Free_'+nullCheck(String.valueOf(orderItem.Order__r.Preferred_Delivery_Date__c));
        sapWrap.sapOrdReason = System.Label.EDGE_FreeGoodsSAP_OrderReason;
        sapWrap.sapPlant = ''; 
        sapWrap.sapCurrencyValue = '';
        sapWrap.sapSalesOrg = nullCheck(orderItem.Order__r.Account__r.Sales_Org__c);
        sapWrap.sapPoDateS = String.valueOf(Date.Today());
        sapWrap.sapPriceDate = '';
        sapWrap.sapDivision = System.Label.EDGE_FreeGoodsSAP_Division;
        sapWrap.sapCondType = '';
        sapWrap.sapPoMethS =  marketSettingMap.containsKey(orderItem.Order__r.Account__r.Country__c)?nullCheck(marketSettingMap.get(orderItem.Order__r.Account__r.Country__c).SAP_Free_Goods_Purchase_Order_Type__c):'';
        sapWrap.sapUnit = '';
        sapWrap.sapItemCategory = '';
        sapWrap.sapItmNumber = String.valueOf(salesDocNumber * 10);
        sapWrap.sapAmount = '';
        sapWrap.sapBillNote = '';
        sapWrap.sapMaterial = nullCheck(orderItem.Product__r.SAP_SKU_Code__c);
        sapWrap.sapOrderId = nullCheck(orderItem.Reason_Code__r.Internal_Order__r.Name);
        sapWrap.sapPer = '';
        sapWrap.sapShipto = nullCheck(orderItem.Order__r.Account__r.SAP_Ship_to__c);
        sapWrap.sapDocType = marketSettingMap.containsKey(orderItem.Order__r.Account__r.Country__c)?nullCheck(marketSettingMap.get(orderItem.Order__r.Account__r.Country__c).SAP_Free_Goods_Order_Type__c):'';
        sapWrap.sapPayer = '';
        sapWrap.sapReqDateH = nullCheck(String.valueOf(orderItem.Order__r.Preferred_Delivery_Date__c));
        sapWrap.sapCondValue = '';
        sapWrap.sapKunnrSo = nullCheck(orderItem.Order__r.Account__r.SAP_Sold_to__c);
        sapWrap.sapTaxClass1 = '';
        
        salesDocNumber++;
        
        return sapWrap;
    }
    
    private static void writeFreeGoodsJSON(JSONGenerator gen, EDGE_SAPWrapper sapWrap,Order_Item__c orderItem){
        
        //Serialize & de-serialize
        String str = JSON.serialize(sapWrap);
        Map<String,Object> obj =  (Map<String,Object>) JSON.deserializeUntyped(str);
        
        gen.writeStartObject(); 
        gen.writeFieldName(orderItem.Name);
        gen.writeStartObject();
        
        for(EDGE_Free_Goods_Order_to_SAP__mdt freeGood : FREEGOODSMDT.values()){  
            if(obj.containskey(EDGE_SAP+freeGood.DeveloperName)){
                gen.writeStringField(freeGood.MasterLabel, String.valueOf(obj.get(EDGE_SAP+freeGood.DeveloperName))==Null?'':String.valueOf(obj.get(EDGE_SAP+freeGood.DeveloperName)));               
            }
        }
        
        gen.writeEndObject();
        gen.writeEndObject();
        
    }
    
    private static void updateLogMessage(HttpResponse  httpRes,String request){
        String response = httpRes.getBody();
        
        switch on httpRes.getStatusCode() {
            when 200 {		
                D1_CustomLoggingUtility.logMessage('EDGE_FreeGoodsOrderToSAPCallout', 'getOrder', 'SUCCESS','','', request != null ? request : '', response!=null?response:'');
            }	
            when else {		  
                D1_CustomLoggingUtility.logMessage('EDGE_FreeGoodsOrderToSAPCallout', 'getOrder', httpRes.getStatus()+';'+httpRes.getStatusCode(),'','',  request != null ? request : '', httpRes.getBody());
            }
        }
    }

    private static String nullCheck(String str){
        return String.isBlank(str)?'':str;
    }
    
    private static Boolean getStatusCode(String response){
        return (String.isNotBlank(response) && (response.contains('ERROR') || response.contains('ErrorResponse' ) || response.contains('Duplicate'))?
                false:(String.isNotBlank(response) && (response.contains('SUCCESS') || response.contains('successfully')))?true:false);
    }
    
    private static String getDataFromMap(String key, Map<String,Object> objectMap){
        return (objectMap.containsKey(key)? String.valueOf(objectMap.get(key)):'');
    }
    
    private static void handleException(Exception ex) {
        D1_CustomLoggingUtility.logMessage('EDGE_FreeGoodsOrderToSAPCallout', 'getOrder', ex.getCause()+';'+ex.getLineNumber()+';'+ex.getMessage() ,ex.getStackTraceString(),ex.getTypeName(), request != NULL ?request:'', response != NULL ? response:'');
    }
}