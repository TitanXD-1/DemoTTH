/**********************************************************************
Name: PNR_EmailMessageTriggerTest
=======================================================================
Purpose: Test class for PNR_EmailMessageTrigger and PNR_CreateContactFromEmailMessage
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE                      DETAIL
1.0      	Pratik Kumar   	  16th Nov, 2021        PION: 1650 - Test class for PNR_EmailMessageTrigger and PNR_CreateContactFromEmailMessage
***********************************************************************/
@isTest
public class PNR_EmailMessageTriggerTest {
    
    public static testMethod void testContactSave() {
        
        User u = PNR_TestDataUtility.runAsUser('EmailCheck', 'PNR_CustomerServiceRep');
        UserRole rl = [SELECT Id FROM UserRole WHERE Name = 'Direct Customer'];
        u.UserRoleId = rl.Id;
        insert u;

        User u1 = PNR_TestDataUtility.runAsUser('EmailCheck1', 'PNR_CustomerServiceRep');
        u1.UserRoleId = rl.Id;
        insert u1;

        Test.startTest();
        
        System.runAs(u){
            Account ac = PNR_TestDataUtility.getDirectCustomerRec();
            ac.name = 'Pioneer Email History';
            insert ac;

            Case cse =PNR_TestDataUtility.getCaseData();
            cse.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
            insert cse;
        
            Contact con = new Contact();
            con.LastName = 'LastName';
            con.FirstName = 'FirstName';
            con.Email = 'emailcheck@example.com';
            insert con;

            EmailMessage emailMessage = new EmailMessage();
            emailMessage.status = '3';
            emailMessage.relatedToId = cse.Id; 
            emailMessage.fromAddress = 'billing@abc.com';
            emailMessage.fromName = 'Billing Department';
            emailMessage.toAddress = 'emailcheck@example.com; emailcheck1@edgeorg.com; emailcheck@edgeorg.com';
            emailMessage.ccAddress = 'trialemail@edgeorg.com';
            emailMessage.bccAddress = 'trial2@edgeorg.com';
            emailMessage.Subject = 'Contact Save';

            emailMessage.HtmlBody = 'This is to save email Ids';
            insert emailMessage;
        }
        Test.stopTest();
    }
}