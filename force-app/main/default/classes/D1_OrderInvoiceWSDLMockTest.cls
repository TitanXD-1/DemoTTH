/**
 * @name : D1_OrderInvoiceWSDLMock
 * @description : Mock Class D1_OrderInvoiceWSDL
 * @interface : I00254
 * @history                                                                       
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Manikant          11/01/2021         Initial Development(NCP-1369)
 **/

@isTest
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class D1_OrderInvoiceWSDLMockTest implements WebServiceMock {
    /**
     * @description do Invoke
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
    global void doInvoke(
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
            D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1 responseX =  new D1_OrderInvoiceWSDL.DT_Invoice_OrdNo_Response_D1();
            responseX.INVOICE_ID = '123456';
            responseX.PDF_DATA = EncodingUtil.base64Encode(Blob.valueOf('Testing base 64 encode'));    
            responseX.SUCCESS = True;
            responseX.STATUS = 'Confirmed';
            // end
            response.put('response_x', responseX); 
        }
}