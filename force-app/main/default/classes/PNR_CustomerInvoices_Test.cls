@isTest
/**********************************************************************
  Name: PNR_CustomerInvoices_Test
========================================================================
 Purpose: This is the test class for PNR_CustomerInvoices apex class
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
	1.0        Tanmoy Bardhan     16-07-2019        Initial Development
***********************************************************************/
public class PNR_CustomerInvoices_Test {

	static testMethod void testSoldTo() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        
        Invoice__c inv = PNR_TestDataUtility.getPNRInvoiceData();
        Insert inv;
        
        Test.startTest();
        List<Invoice__c> invList = PNR_CustomerInvoices.getCustomerInvoices(inv.Account__c, 'Sold-To', 'GB01');
        Invoice__c invo = [SELECT Id, SAP_Invoice_Number__c FROM Invoice__c WHERE Id = :invList[0].Id];
        system.assertEquals(invo.SAP_Invoice_Number__c, '98765432');
        Test.stopTest();
	}
	
	static testMethod void testPayer() {
        Account acct = PNR_TestDataUtility.getDirectCustomerRec();
        Insert acct;
        
        Invoice__c inv = PNR_TestDataUtility.getPNRInvoiceData();
        Insert inv;
        
        Test.startTest();
        List<Invoice__c> invList = PNR_CustomerInvoices.getCustomerInvoices(inv.Account__c, 'Payer', 'GB01');
        Invoice__c invo = [SELECT Id, SAP_Invoice_Number__c FROM Invoice__c WHERE Id = :invList[0].Id];
        system.assertEquals(invo.SAP_Invoice_Number__c, '98765432');
        Test.stopTest();
	}

}