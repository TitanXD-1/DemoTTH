/**
 * @name : D1_OrderInvoiceControllerTest
 * @description : Test Class D1_OrderInvoiceController
 * @interface : I00254
 * @history                                                                                                              
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Manikant          15/01/2021         Initial Development(NCP-1369)
 **/
@isTest
public class D1_OrderInvoiceControllerTest {
    /**
     * @description test Get Invoice
     */    
    @isTest
    public static void testGetInvoice(){ 
        Test.startTest();
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new D1_OrderInvoiceWSDLMockTest());
        // Call the method that invokes a callout        
        D1_OrderInvoiceController.OrderInvoicWrapper ordwrapp = new D1_OrderInvoiceController.OrderInvoicWrapper();
        ordwrapp = D1_OrderInvoiceController.getInvoice('45698755','45878965','YINV','IS011010','1053092734') ;        
       	
        D1_OrderInvoiceController.OrderInvoicWrapper orderInvoicWrapper = D1_OrderInvoiceController.parseResponse(null);
        orderInvoicWrapper = D1_OrderInvoiceController.parseResponse(null); 
        
        // Verify that a fake result is returned
        System.assertEquals(true, ordwrapp.isSuccess, 'result not returned successfully'); 
        test.stopTest();
    }
}