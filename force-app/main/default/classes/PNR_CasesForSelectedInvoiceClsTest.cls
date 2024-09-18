/*
 * @class: PNR_CasesForSelectedInvoiceClsTest
 * @description: This is test class for PNR_CasesForSelectedInvoiceCls.
 * @author: Sai Kiran Sagaram
 * This class is written for PION-1594 change.
 * */
@isTest
public class PNR_CasesForSelectedInvoiceClsTest {
	@isTest
    public static void getDuplicateCase(){
        Test.startTest();
            Account acc = PNR_TestDataUtility.getDirectCustomerRec();
            insert acc;
            
            Invoice__c inv = PNR_TestDataUtility.getPNRInvoiceData();
        	inv.Account__c = acc.id;
            Insert inv;
            
            Case cs = new Case();
            cs.AccountId = acc.Id;
            cs.Reference_Invoice__c = inv.id;
            insert cs;
        	PNR_CasesForSelectedInvoiceCls.getDuplicateCases(cs.Id);
        Test.stopTest();
    }
     @isTest
        public static void getDuplicateCaseNegativeScenario(){
            Test.startTest();
            Account acc = PNR_TestDataUtility.getDirectCustomerRec();
            insert acc;
            
            Case cs = new Case();
            cs.AccountId = acc.Id;
            insert cs;
            PNR_CasesForSelectedInvoiceCls.getDuplicateCases(cs.Id);
            Test.stopTest();
        }
    
    
}