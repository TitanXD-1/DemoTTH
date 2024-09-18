// Test class for D1_OrderAcknowledgeWSDL
@isTest
public class D1_OrderAcknowledgeControllerTest {
    @isTest
    public static void testGetAcknowledge(){
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new D1_OrderAcknowledgeWSDLMockTest());
        // Call the method that invokes a callout        
        D1_OrderAcknowledgeController.OrderAckResponse ordwrapp = new D1_OrderAcknowledgeController.OrderAckResponse();
        ordwrapp = D1_OrderAcknowledgeController.getOrderAckPDF('45698755', '45878965','545879587') ;        
        
        // Verify that a fake result is returned
        System.assertEquals(true, ordwrapp.isSuccess, 'result not returned successfully'); 
    }
}