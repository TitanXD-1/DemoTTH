/**********************************************************************
Name: PNR_deleteContactBatchTest
=======================================================================
Req:  
User Story : PION-806- Old Contact Deletion
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Tanmoy Bardhan       21/10/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_deleteContactBatchTest {

	static testMethod void testBatch() {
        Account directAccount = PNR_TestDataUtility.getDirectCustomerRec();
        Insert directAccount;
        
        Contact con = PNR_TestDataUtility.getCustomerContactData();
        con.FirstName = 'to be deleted';
        con.AccountId = directAccount.Id;
        Insert con;
        
        Test.startTest();
        String cronExpr = '0 0 6 * * ?';
        String jobId = System.schedule('Delete Old Contacts',cronExpr,new PNR_deleteContactBatchSchedular());
        List<Contact> deletedContact = [SELECT Id,Name, IsDeleted FROM Contact WHERE Id = :con.Id];
		System.assertEquals(1, deletedContact.size());
        Test.stopTest();
	}

}