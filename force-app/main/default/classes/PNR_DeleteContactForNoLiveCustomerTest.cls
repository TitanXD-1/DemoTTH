/**********************************************************************
Name: PNR_DeleteContactForNoLiveCustomerTest
=======================================================================
Req:  
User Story : PION-1408- Contact Deletion for No Live Customer
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Sudipta Nandi       2/3/2020      Initial Development
2.0 	Jayashree R			15/11/2021		Modified
***********************************************************************/
@isTest
public class PNR_DeleteContactForNoLiveCustomerTest {

	static testMethod void testBatch() {
          
        List<Account> accList = new List<Account>(); //PION-1611 : created list to insert accounts
        Account directAccount = PNR_TestDataUtility.getDirectCustomerRec();
        directAccount.Deletion_Flag_from_SAP__c=False;
        directAccount.AccountSource = 'SAP - Pioneer';
        directAccount.Products_Enabled__c = 'Pioneer';
        accList.add(directAccount);
        
        Account directAccount1 = PNR_TestDataUtility.getDirectCustomerRec();
        directAccount1.Deletion_Flag_from_SAP__c=True;
        directAccount1.AccountSource = 'SAP - Pioneer';
        directAccount1.Products_Enabled__c = 'DBA';
        accList.add(directAccount1);
        
        Insert accList;
        
        List<Contact> conList = new List<Contact>(); //PION-1611 : created list to insert contacts
        Contact con = PNR_TestDataUtility.getCustomerContactData();
        con.FirstName = 'to be deleted';
        con.AccountId = directAccount.Id;
        conList.add(con);
        
        Contact con2 = PNR_TestDataUtility.getCustomerContactData();
        con2.FirstName = 'to be deleted';
        con2.AccountId = directAccount1.Id;
        conList.add(con2);
        
        Insert conList;
        
        List<Case> caseList = new List<Case>(); //PION-1611 : created list to insert cases
        Case cse =PNR_TestDataUtility.getCaseData();
        cse.AccountId = directAccount.Id;
        cse.ContactId = con.Id;
        cse.Type ='Dispute – Delivery';
        //PION-1611 : assigning record type to case for test coverage
        cse.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        caseList.add(cse);
        
        //PION-1611 : creating dispute pricing case for test coverage
        Case cse1 =PNR_TestDataUtility.getCaseData();
        cse1.AccountId = directAccount.Id;
        cse.ContactId = con2.Id;
        cse1.Type ='Dispute – Pricing';
        cse1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        caseList.add(cse1);
        
        Insert caseList;
        
        directAccount.Deletion_Flag_from_SAP__c = True;
        Update directAccount;
        
        Test.startTest();
        String cronExpr = '0 0 6 * * ?';
        String jobId = System.schedule('Delete Contacts',cronExpr,new PNR_DeleteContactNoLiveCustSchedular());
        List<Contact> deletedContact = [SELECT Id,Name, IsDeleted FROM Contact WHERE Id = :con.Id];
        System.assertEquals(1, deletedContact.size());
        Test.stopTest();
	}

}