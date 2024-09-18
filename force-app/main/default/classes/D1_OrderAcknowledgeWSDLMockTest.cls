// Test Class for D1_OrderAcknowledgeWSDL class

@isTest
public class D1_OrderAcknowledgeWSDLMockTest implements WebServiceMock {
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
            D1_OrderAcknowledgeWSDL.DT_OrderAck_Response responseX =  new D1_OrderAcknowledgeWSDL.DT_OrderAck_Response();
            responseX.DOCID = '123456';
            responseX.PDF_DATA = EncodingUtil.base64Encode(Blob.valueOf('Testing base 64 encode'));    
            responseX.SUCCESS = True; 
            // end
            response.put('response_x', responseX); 
        }
}