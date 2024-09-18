/**
 * @name : D1_OrderHistoryWSDLMockTest
 * @description : Test Class D1_OrderHistoryWSDLMock
 * @history                                                                                                                   
 * VERSION     AUTHOR            DATE              DETAIL
 * 3.0			Abhishek		06/07/2021			NCP-3782(refactor)
 * 4.0			Mukesh			14/06/2024			152922
 **/
@isTest
public class D1_OrderHistoryWSDLMockTest implements WebServiceMock{
    /**
     * @description doInvoke
     * @param stub 
     * @param request 
     * @param response 
     * @param endpoint 
     * @param soapAction 
     * @param requestName 
     * @param responseNS 
     * @param responseName 
     * @param responseType 
     */ 
    @SuppressWarnings('PMD.ExcessiveParameterList')   
    public void doInvoke(
        Object stub,
        Object request,
        Map<String, Object> response,          
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
            // start - specify the response you want to send
            D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Response_D1 responseX =  new D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Response_D1();

            D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1 item = D1_TestDataUtility.getSalesOrderHistoricalInboundItemResponse();
			item.VALUE ='100';
            item.TAX ='10';
            
            D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Delivery_Response_D1 deliveryResponce = new D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Delivery_Response_D1();
            deliveryResponce.GOODS_MOVEMENT_STATUS ='30';
            deliveryResponce.DELIVERY_NUMBER ='1041019512';
            deliveryResponce.PLANNED_GI_DATE = System.today();
            deliveryResponce.ACTUAL_GI_DATE = System.today();
            deliveryResponce.BILLING_DATE = System.today();
            deliveryResponce.PICK_DATE = System.today();
            deliveryResponce.DELIVERY_DATE = System.today();
            deliveryResponce.TRANSPORT_PLANNING_DATE = System.today();
            deliveryResponce.LOADING_DATE = System.today();
            
            D1_OrderHistoryWSDL.ITEM_element itemElementResponce = new D1_OrderHistoryWSDL.ITEM_element();
            itemElementResponce.DELIVERY_NUM = '1041019512';
            itemElementResponce.ITEM_NUMBER = '000010';
            itemElementResponce.ITEM_CATEGORY = 'YCSR';
            itemElementResponce.MATERIAL = '585836';
            itemElementResponce.DESCRIPTION = 'AGUARDENTE NEGA FULO 12X750ML';
            itemElementResponce.BATCH = 'TEST';
            itemElementResponce.DELIVERY_QUANTITY = '3.000';
            itemElementResponce.SALES_UNIT = 'CAS';
            itemElementResponce.NET_WEIGHT = 27.000;
            itemElementResponce.GROSS_WEIGHT = 48.900;
            itemElementResponce.WEIGHT_UNIT = 'KG';
            itemElementResponce.VOLUME = 0.123;
            itemElementResponce.VOLUME_UNIT = 'M3';
            itemElementResponce.REFERENCE_DOC = '0100089809';
            itemElementResponce.EAN_UPC = '17896113900029'; 
                
            deliveryResponce.ITEM = new List<D1_OrderHistoryWSDL.ITEM_element>{itemElementResponce};
                
            D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1 order = D1_TestDataUtility.getSalesOrderHistoricalInboundHeaderResponse();
            order.VALUE = '100';
            order.TAX = '10';
            order.TOTAL_VALUE = 110;
            order.ITEMS = new List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Item_Response_D1>{item};
            order.DELIVERY = new List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Delivery_Response_D1>{deliveryResponce};
                
            responseX.ORDER = new List<D1_OrderHistoryWSDL.DT_SalesOrderHistoricalInbound_Header_Response_D1>{order};
            
            // end
            response.put('response_x', responseX); 
        }
}