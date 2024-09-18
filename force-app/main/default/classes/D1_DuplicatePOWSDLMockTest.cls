/*
* @name: D1_DuplicatePOWSDLMockTest
* @discription : Mock Class D1_OrderDuplicatePOCheckWSDL
* @history                                                                                                                        
* VERSION     AUTHOR            DATE              DETAIL
* 1.0         Saurav Paul       18/02/2021         Initial Development*/

public class D1_DuplicatePOWSDLMockTest implements WebServiceMock{
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
            D1_OrderDuplicatePOCheckWSDL.DT_PurchaseOrderCheck_Response_D1 responseX = new D1_OrderDuplicatePOCheckWSDL.DT_PurchaseOrderCheck_Response_D1();
        	List<D1_OrderDuplicatePOCheckWSDL.CONFLICTS_element> conflictList = D1_TestDataUtility.getOrderDuplicatePOCheckWSDL('123456','985632','01236547896542');
            responseX.CONFLICTS = conflictList;
            response.put('response_x', responseX); 
        }
}