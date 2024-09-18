/**********************************************************************
Name: PNR_fetchInvoiceFromSAPTest
=======================================================================
Req:  
User Story : This test class is used to test PNR_fetchInvoiceFromSAP
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Tanmoy Bardhan       22/10/2019      testFetchandUpdateInvoice
1.1		Saurav Paul			22/10/2019		getSAPDataTest
***********************************************************************/
@isTest
public class PNR_fetchInvoiceFromSAPTest {

	static testMethod void testFetchandUpdateInvoice() {
        Account acc = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acc;
        
        Invoice__c inv = PNR_TestDataUtility.getPNRInvoiceData();
        inv.Account__c = acc.Id;
        Insert inv;
        
        Invoice_Line_Item__c invItemObj = PNR_TestDataUtility.getInvLineItm(inv.Id);
        Insert invItemObj;
        
        Case cse = PNR_TestDataUtility.getCaseData();
        Insert cse;
        
        Test.startTest();
        PNR_fetchInvoiceFromSAP.updateCaseRecord(cse.Id,'98765432','GB01');
        PNR_fetchInvoiceFromSAP.getInvoiceList('98765432','GB01');
        PNR_fetchInvoiceFromSAP.getInvoiceDetl(cse.Id);
        List<Invoice_Line_Item__c> invoiceLineItemList = [SELECT Id, Name
                                      FROM Invoice_Line_Item__c
                                      WHERE Invoice__r.SAP_Invoice_Number__c = '98765432'
                                      AND Invoice__r.Sales_Org__c = 'GB01'];
        system.assertEquals(1, invoiceLineItemList.size());
        Test.stopTest();
	}
    /*******************************************************************
    Method  : getSAPDataTest
    Purpose : This method is used to test getSAPData
    ***********************************************************************/
    @isTest
    public static void getSAPDataTest(){
        Account accRec = PNR_TestDataUtility.getDirectCustomerRec();
        accRec.AccountNumber = '0000010121';
        accRec.KUNNR__c = '0000010121';
        insert accRec;
        System.assert(accRec.Id != null);
        
        Order__c orderObj = PNR_TestDataUtility.getNewOrderData();
        orderObj.SAP_Order_Number__c= '9012026665';
        orderObj.Account__c = accRec.Id;
        insert orderObj;
        System.assert(orderObj.Id != null);
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('invoiceFetchSuccess');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_fetchInvoiceFromSAP.getSAPData('salesOrg','invNumber');
        Test.stopTest();
    }

}