/**
* @name : D1_OrderAcknowledgeController
* @description : Controller Class D1_OrderAcknowledgeWSDL
* @Interface : I00424
* @history                                                                                                                      
* VERSION     AUTHOR            DATE              DETAIL
* 1.0         Kapil Baliyan    08/01/2021         Initial Development(NCP-1370)
**/
public with sharing class D1_OrderAcknowledgeController {
    
    /**
     * @description getOrderAckPDF
     * @param SoldTo 
     * @param salesArea 
     * @param sapOrderNumber 
     * @return  `OrderAckResponse`
     */     
    @AuraEnabled
    public static OrderAckResponse getOrderAckPDF(string SoldTo, string salesArea, string sapOrderNumber){
        D1_OrderAcknowledgeWSDL.DT_OrderAck_Request request;
        D1_OrderAcknowledgeWSDL.DT_OrderAck_Response response;

        try{
            request = new D1_OrderAcknowledgeWSDL.DT_OrderAck_Request();
            request.CUSTOMER = SoldTo;
            request.SAP_SALES_AREA = salesArea;
            request.DOCID = sapOrderNumber;

            //Step 1: Do Callout
            response = doCallout(SoldTo, salesArea, sapOrderNumber);
            
            //Step 2: Parse Response
            OrderAckResponse orderAckResponse = parseResponse(response);
            return orderAckResponse;
        }catch(Exception ex){
            //NCP-3577
            D1_CustomLoggingUtility.logMessage('D1_OrderAcknowledgeController', 'getOrderAckPDF', ex, (request != NULL? JSON.serialize(request):''), (response != NULL? JSON.serialize(response):''));
            
            OrderAckResponse orderAckResponse = parseResponse(null);
            return orderAckResponse;
        }
    }
    
    /**
     * @description doCallout
     * @param SoldTo 
     * @param salesArea 
     * @param sapOrderNumber 
     * @return  `D1_OrderAcknowledgeWSDL.DT_OrderAck_Response`
     */    
    public static D1_OrderAcknowledgeWSDL.DT_OrderAck_Response doCallout(string SoldTo, string salesArea, string sapOrderNumber){
        D1_OrderAcknowledgeWSDL.HTTPS_Port req = new D1_OrderAcknowledgeWSDL.HTTPS_Port();
            
        D1_OrderAcknowledgeWSDL.DT_OrderAck_Response response = new D1_OrderAcknowledgeWSDL.DT_OrderAck_Response();
        response = req.SI_OrderAck_Sync_Out_D1(SoldTo, salesArea, sapOrderNumber);
        
        return response;
    }
    
    /**
     * @description parseResponse
     * @param response 
     * @return  `OrderAckResponse`
     */    
    public static OrderAckResponse parseResponse(D1_OrderAcknowledgeWSDL.DT_OrderAck_Response response){
        OrderAckResponse orderAckResponse = new OrderAckResponse();
        if(response != null){
            orderAckResponse.orderId = response.DOCID;
            orderAckResponse.pdfData = response.PDF_DATA;
            orderAckResponse.isSuccess = response.SUCCESS;
        }else{
            orderAckResponse.orderId = '';
            orderAckResponse.pdfData = '';
            orderAckResponse.isSuccess = false;
        }
        
        return orderAckResponse;
    }
    
    public class OrderAckResponse {
        @AuraEnabled public string orderId {get;set;}
        @AuraEnabled public string pdfData {get;set;}
        @AuraEnabled public boolean isSuccess {get;set;}
    }

}