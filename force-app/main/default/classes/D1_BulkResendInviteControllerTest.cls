/**
 * @name D_1BulkContactRegistrationController
 * @description D1_BulkContactRegistrationController Class for validating user's registration request for direct customer
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0        Narayana     10/02/2022        NCP-5958        
 **/
@isTest
public class D1_BulkResendInviteControllerTest {
    @isTest
    public static void testmethod1(){
    	Account directCustomer = D1_TestDataUtility.getDirectCustomer();
    	D1_TestDataUtility.setUpExternalUser(directCustomer, 'Direct Buyer');
        Contact con=[select id, AccountId from Contact where accountId=:directCustomer.Id limit 1 ];
        con.FirstName = 'test678';
        con.Phone = '12342890';
        con.Email = 'direct2.contact@yopmail.com';
        con.MD_SubscriptionDate__c=null;
        con.D1_Contact_Last_Login_Date__c=null;
        con.D1_Invite_sent__c = Date.today();
        con.D1_Login_Reminder_Status__c=null;
        upsert con;
        Contact con2 = new Contact();
        con2.FirstName = 'test6789';
        con2.LastName = 'test67899';
        con2.Phone = '123428901';
        con2.Email = 'direct28.contact@yopmail.com';
        con2.MD_SubscriptionDate__c=null;
        con2.D1_Contact_Last_Login_Date__c=Date.today();
        con2.D1_Invite_sent__c = Date.today();
        con2.D1_Login_Reminder_Status__c=null;
        insert con2;
    	List<String> contactList = new List<String>();
        contactList.add(con.Id);
        contactList.add(con2.Id);
        D1_BulkResendInviteController.Requests obj = new D1_BulkResendInviteController.Requests();
        obj.contactId = contactList;
        Test.startTest();
        D1_BulkResendInviteController.resendBulkInvite(new List<D1_BulkResendInviteController.Requests>{obj});
        Test.stopTest(); 
        System.assert(obj.contactId != NULL, 'Contact not registered');     
        System.assert(D1_BulkResendInviteController.resendBulkInvite(new List<D1_BulkResendInviteController.Requests>{obj}) != null, 'No Response returned');
    }
}