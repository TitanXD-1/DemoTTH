/**
 * @name D1_BillingHistoryWSDLMockTest
 * @description D1_BillingHistoryWSDL Mock
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0         Ajay            08/02/21    Initial Development(NCP-1476)
 **/
@isTest
public class D1_BillingHistoryWSDLMockTest implements WebServiceMock {
    /**
     * @description 
     * @param stub 
     * @param request 
     * @param response 
     * @param endpoint 
     * @param soapAction 
     * @param requestName 
     * @param responseNS 
     * @param responseName 
     * @param responseType 
     **/
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
            D1_BillingHistoryWSDL.DT_BillingHistory_Response_D1 responseX =  new D1_BillingHistoryWSDL.DT_BillingHistory_Response_D1();
            
            List<D1_billingHistoryWSDL.DT_BillingHistory_Docs_D1> docList = new List<D1_billingHistoryWSDL.DT_BillingHistory_Docs_D1>();
            D1_billingHistoryWSDL.DT_BillingHistory_Docs_D1 doc = new D1_billingHistoryWSDL.DT_BillingHistory_Docs_D1();
            doc.DOCID = 'test-data';
			doc.DOCTY = 'test-data';
			doc.DESCR = 'test-data';
			doc.DDATE = null;
			doc.VALUE = 'test-data';
			doc.DOCCUR = 'test-data';
			doc.DOCDUEDATE = 'test-data';
            
            docList.add(doc);
            responseX.DOCS = docList;
            
            // end
            response.put('response_x', responseX); 
        }
}