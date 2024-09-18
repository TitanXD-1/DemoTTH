/**********************************************************************
Name: PNR_ContactsControllerTest
=======================================================================
Req: This is the test class for the  PNR_ContactsController class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned Khan     13/06/2019      Initial Development

***********************************************************************/
@isTest
public class PNR_ContactsControllerTest {
    @isTest 
    static void validationmethod(){
       //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        
        System.runAs ( testadminUser ) { 
            // Customer creation
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            insert cust;
            //Diageo Contact creation
            PNR_Diageo_Contact__c dgcon = PNR_TestDataUtility.getPNRDiageoContactData();
            dgcon.PNR_Diageo_Rep__c =testadminUser.Id; 
            dgcon.PNR_Customer__c=cust.Id;
            insert dgcon;
            //Diageo Customer Contact creation
            Contact custcon= PNR_TestDataUtility.getCustomerContactData();
            custcon.AccountId=cust.Id;
            insert custcon;
            //Check customer contacts
            List<Contact> custlist=PNR_ContactsController.getCustomerContacts(cust.Id);
            Integer custsize = custlist.size();
            system.assertEquals(custsize,1);
             //Check Diageo contacts
            List<PNR_Diageo_Contact__c> dglist=PNR_ContactsController.getDiageoContacts(cust.Id);
            Integer dgcsize = dglist.size();
            system.assertEquals(dgcsize,1);
        }
    }
}