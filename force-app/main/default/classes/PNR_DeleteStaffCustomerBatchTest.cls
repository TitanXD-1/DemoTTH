/**********************************************************************
Name: PNR_DeleteStaffCustomerBatchTest
=======================================================================
Req:  
User Story : PION-964- Old Contact Deletion
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Sudipta Nandi       1/11/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_DeleteStaffCustomerBatchTest {
    
    static testMethod void testBatch() {
        Account directAccount = PNR_TestDataUtility.getDirectCustomerRec();
        directAccount.Sort__c = 'staff';
        Insert directAccount;
        
        Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
        inv.Account__c=directAccount.Id;
        inv.Sales_Org__c='SE01';
        insert inv;
        
        Id dynamicRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Direct_Order'].Id;
        // Diageo Order creation.
        Order__c ord = PNR_TestDataUtility.getNewOrderData();
        ord.Account__c=directAccount.Id;
        ord.RecordTypeId = dynamicRecordTypeId;
        ord.Payer_Number__c = directAccount.Id;
        ord.Billing_Document__c = null;
        ord.Is_Deletion_Indicator_Flag__c = false;
        insert ord;
        
        Contact con = PNR_TestDataUtility.getCustomerContactData();
        con.FirstName = 'to be deleted';
        con.AccountId = directAccount.Id;
        Insert con;
        
        Case cse = PNR_TestDataUtility.getCaseData();
        cse.ContactId = con.Id; 
        Insert cse;
        
        PNR_Partner_Function__c pfsoldto=PNR_TestDataUtility.getPNRPartnerFunctionData();
        pfsoldto.PNR_Type__c='Sold-To';
        pfsoldto.PNR_Customer_No__c=directAccount.Id;
        pfsoldto.PNR_Distribution_Channel__c='Channel';
        pfsoldto.PNR_Division__c='Division';
        pfsoldto.PNR_Deletion_Flag_for_Sales_Level__c = false;
        insert pfsoldto;
        
        Test.startTest();
        Database.executeBatch(new PNR_DeleteStaffCustomerBatch());
        List<Account> deletedAcc = [SELECT Id,Name,IsDeleted FROM Account WHERE Id = :directAccount.Id];
        System.assertEquals(1, deletedAcc.size());
        Test.stopTest();
    }
    
}