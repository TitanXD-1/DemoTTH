/**
 * @name : D1_OrderInvoiceController
 * @description : Controller Class D1_OrderInvoiceWSDL
 * @Interface : I00254
 * @history                                                                                                      
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Manikant          11/01/2021         Initial Development(NCP-1369)
 * 2.0         Mukesh Kanth      20/06/2024         Schema Invoice processing - Brazil Order Detail page (152950)
 **/

public with sharing class D1_OrderInvoiceController {
    /**
     * @description getInvoice
     * @param orderNum 
     * @param shipToNumber 
     * @return  `OrderInvoicWrapper`
     */    
    @AuraEnabled
    public static OrderInvoicWrapper getInvoice(String orderNum , String shipToNumber, String docId, String salesOrg, String deliveryNo){
        D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Request_D1 request;//152950
        D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 response;

        try{   
            request = new D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Request_D1();//152950
            request.ORDER_NUM = orderNum;
            request.SHIP_TO = shipToNumber;
            request.SALES_ORG = salesOrg; //152950
            request.DEL_NUM = deliveryNo;//152950

            //Step 1: Do Callout
            response = doCallout(orderNum, shipToNumber, docId, salesOrg, deliveryNo);//152950
            
            //Step 2: Parse Response
            OrderInvoicWrapper orderInvoicWrapper = parseResponse(response);
            return orderInvoicWrapper;
        }
        catch(Exception ex){ 
            //NCP-3577
            D1_CustomLoggingUtility.logMessage('D1_OrderInvoiceController', 'getInvoice', ex, (request != NULL? JSON.serialize(request):''), (response != NULL? JSON.serialize(response):''));
            
            OrderInvoicWrapper orderInvoicWrapper = parseResponse(null);
            return orderInvoicWrapper;
        }
    }
    
    /**
     * @description Do Callout
     * @param orderNum 
     * @param shipToNumber 
     * @return  `D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1`
     */    
    public static D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 doCallout(String orderNum , String shipToNumber, String docId, String salesOrg, String deliveryNo){
        D1_OrderInvoiceWSDL.HTTPS_Port req = new D1_OrderInvoiceWSDL.HTTPS_Port();
        D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 response = new D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1();
        response = req.SI_Invoice_OrdNo_Sync_Out_D1(orderNum, shipToNumber, docId, deliveryNo, salesOrg);//152950
        return response;
    }
    
    /**
     * @description Parse Response  
     * @param response 
     * @return  `OrderInvoicWrapper`
     */    
    public static OrderInvoicWrapper parseResponse(D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 response){
        OrderInvoicWrapper orderPdfResponse = new OrderInvoicWrapper();
        if(response != null){
            orderPdfResponse.invoiceId = response.INVOICE_ID;
            orderPdfResponse.pdfData = response.PDF_DATA;
            orderPdfResponse.isSuccess = response.SUCCESS;
        }else{
            orderPdfResponse.invoiceId = '';
            orderPdfResponse.pdfData = '';
            orderPdfResponse.isSuccess = false;
        }
        return orderPdfResponse;
    }
    
    //Wrapper Class
    public class OrderInvoicWrapper{
        @AuraEnabled public String invoiceId {get;set;}
        @AuraEnabled public String pdfData {get;set;}
        @AuraEnabled public Boolean isSuccess {get;set;}
        
    }
}