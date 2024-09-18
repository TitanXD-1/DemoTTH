/**********************************************************************
Name: PNR_LookUpControllerTest
=======================================================================
Req: This is the test class for the  PNR_LookUpController class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned Khan        18/06/2019      Initial Development

***********************************************************************/
@isTest
public class PNR_LookUpControllerTest {
    
     @isTest 
    static void lookupmethod(){
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
            //Diageo Contact creation for rep user
            PNR_Diageo_Contact__c dgcon = PNR_TestDataUtility.getPNRDiageoContactData();
            dgcon.PNR_Diageo_Rep__c =testadminUser.Id; 
            dgcon.PNR_Contact_Type__c='Customer Service Rep';
            insert dgcon;
             //Diageo Contact creation for kam user
            PNR_Diageo_Contact__c dgkam = PNR_TestDataUtility.getPNRDiageoContactData();
            dgkam.PNR_Name__c ='TestUser'; 
            dgkam.PNR_Contact_Type__c='Account Manager';
            insert dgkam;
            //Diageo Customer Contact creation
            Contact custcon= PNR_TestDataUtility.getCustomerContactData();
            custcon.AccountId=cust.Id;
            insert custcon;
            //Check for LookupValue method
            List<sObject> lookuprec=PNR_LookUpController.fetchLookUpValues(cust.Name,acclist.getSObjectType().getDescribe().getName());
			Integer lokupsize = lookuprec.size();
            system.assertEquals(lokupsize,1);
            //Check for negative PNR_Diageo_Contact__c LookupValue method
            List<sObject> pnrlookup=PNR_LookUpController.fetchLookUpValues(dgkam.PNR_Name__c,dgcon.getSObjectType().getDescribe().getName());
			Integer recordsize = pnrlookup.size();
            system.assertEquals(recordsize,1);
        }
        
    }

}