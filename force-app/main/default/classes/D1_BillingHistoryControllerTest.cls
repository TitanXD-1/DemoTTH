/**
* @Name: D1_BillingHistoryWSDLMockTest
* 
* Purpose: Test class for D1_BillingHistoryController
* 
* History                                                            
* -                                                           
* VERSION		AUTHOR          DATE            DETAIL
* 1.0         	Ajay            08/02/2021    	Initial Development(NCP-1476)
* 2.0         	Gaurav          15/02/2021    	Test PDF Download (NCP-1477)
* 3.0           Subhrojit		02/01/2023		Refactor
**/

@isTest
public class D1_BillingHistoryControllerTest {
    
    /**
     * @Name : testBillingHistory
	 * @description : This method is used to test the getBillingHistory() method of the D1_BillingHistoryController class
	 */
    @isTest
    public static void testBillingHistory(){
        //Generate Mock Response for Test
        Test.setMock(WebServiceMock.class, new D1_BillingHistoryWSDLMockTest());
        
        Object billHistory;
        
        Test.startTest();
        //Callout Invocation
        billHistory = D1_BillingHistoryController.getBillingHistory('{}','en_GB'); 
        Test.stopTest();
        
        //Assertions
        System.assert(billHistory != NULL, 'Assertion failed');
        Assert.isNotNull(billHistory, 'Assertion failed');
    }
    
    /**
     * @Name : testDownloadFinancialDoc
	 * @description : This method is used to test the downloadFinancialDoc() method of the D1_BillingHistoryController class
	 */
    @isTest
    public static void testDownloadFinancialDoc(){
        //Generate Mock Response for Test
        Test.setMock(WebServiceMock.class, new D1_FinancialDocumentWSDLMockTest());
        
        Test.startTest();
        //Callout Invocation
        String docData = D1_BillingHistoryController.downloadFinancialDoc('1234', 'docType', '123123', '2021-02-03','');
        Test.stopTest();
        
        //Assertions
		System.assert(docData != NULL, ' Document not found');
		Assert.isNotNull(docData, ' Document not found');        
    }
    
    /**
     * @Name : testDocumentTypes
	 * @description : This method is used to test the getDocumentTypes() method of the D1_BillingHistoryController class
	 */
    @isTest
    public static void testDocumentTypes(){
        
        Test.startTest();
        //Callout Invocation        
        Map<String,D1_Financial_Document_Type__mdt> documents = D1_BillingHistoryController.getDocumentTypes('GB01','en_GB');
        Test.stopTest();
        
        //Assertions
		System.assert(documents != null,'No document type available');
		Assert.isNotNull(documents, 'No document type available');        
    }
}