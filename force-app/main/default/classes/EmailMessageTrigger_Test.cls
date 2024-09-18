@isTest
public class EmailMessageTrigger_Test {
    @testSetup 
    public static void setup() {
        
        PNR_TestDataUtility.createOrgSettings();
        Id countryId = PNR_TestDataUtility.setupCountry('AUS');
        Account cust= PNR_TestDataUtility.getDirectCustomerRec();
        cust.Country__c=countryId;
        insert cust;
        
         Id ddRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Direct_Disputes').getRecordTypeId();
        Case cse =PNR_TestDataUtility.getCaseData();
        cse.CurrencyIsoCode = 'GBP';
        cse.Claimed_Amount__c = 102.00;
        cse.AccountId=cust.Id;
        cse.Status = 'New';
        cse.RecordTypeId = ddRecordTypeId;
        insert cse;
        
        EmailMessage emailMessage = new EmailMessage(); 
        emailMessage.status = '3'; 
        emailMessage.fromName = 'test'; 
        emailMessage.subject = 'This is the Subject! Approved';  
        emailMessage.htmlBody = '<html><body><b>Hello</b></body></html>';
        String[] toIds = new String[]{ cse.Id };  
            emailMessage.toIds = toIds; 
        emailMessage.ParentId = cse.Id;
        insert emailMessage;
    }
    
    static testmethod void deleteEmailTest(){
        case cse = [select id from case limit 1];
        cse.Status = 'Approval request Externally Approved';
        update cse;
        EmailMessage em = [select id from EmailMessage limit 1];
        try{ 
            update em;
            delete em;
        }catch(exception e){}
    }
    
    static testmethod void deletePositiveTest(){
        EmailMessage em = [select id from EmailMessage limit 1];
        delete em;
    }
}