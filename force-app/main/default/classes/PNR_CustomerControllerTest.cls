/**********************************************************************
Name: PNR_CustomerControllerTest
=======================================================================
Req: This is the test class for the  PNR_CustomerController class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned Khan     13/06/2019      Initial Development
2.0   JUned Khan	 01/07/2019	      Modified for Sprint 3.
2.0   JUned Khan	 15/07/2019	      Modified for Sprint 4.

***********************************************************************/
@isTest
public class PNR_CustomerControllerTest {
    
    @isTest 
    static void validatedmethod(){
        
       User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('TL','PNR_Teamlead');
        testadminUser.IsActive = true;
        testadminUser.ManagerId = usr.Id;
        insert testadminUser;
        
        System.runAs (usr) { 
            // Customer creation
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            insert cust;
            acclist.add(cust);
            Account cust1= PNR_TestDataUtility.getDirectCustomerRec();
            cust1.Country__c=countryId;
            insert cust1;
            acclist.add(cust1);
            //Diageo Contact creation for CS Rep
            PNR_Diageo_Contact__c con = PNR_TestDataUtility.getPNRDiageoContactData();
            con.PNR_Contact_Type__c ='Customer Service Rep';
            con.PNR_Diageo_Rep__c =testadminUser.id; 
            con.PNR_Customer__c=acclist[0].Id;
            insert con;
            PNR_Diageo_Contact__c con1 = PNR_TestDataUtility.getPNRDiageoContactData();
            con1.PNR_Contact_Type__c ='Credit Controller';
            con1.PNR_Diageo_Rep__c =testadminUser.id; 
            con1.PNR_Customer__c=acclist[0].Id;
            insert con1;
            //Diageo Contact creation for Account Manager Rep
            PNR_Diageo_Contact__c conam = PNR_TestDataUtility.getPNRDiageoContactData();
            conam.PNR_Name__c='Test';
            conam.PNR_Contact_Type__c ='Account Manager';
            conam.PNR_Customer__c=acclist[0].Id;
            insert conam;
            PNR_Diageo_Contact__c conam1 = PNR_TestDataUtility.getPNRDiageoContactData();
            conam1.PNR_Name__c='Testing';
            conam1.PNR_Contact_Type__c ='Account Manager';
            conam1.PNR_Customer__c=acclist[0].Id;
            insert conam1;
           	List<Account> customer =  PNR_CustomerController.getCustomerList(usr.Id,true);
            //check the customer list
            Integer customersize = customer.size();           
        	//System.assertNotEquals(customersize,0); 
           	List<Account> kamcustomer =  PNR_CustomerController.getCustomerList(conam.PNR_Name__c,false);
            //check the KAM customer list
            Integer kamcustomersize = kamcustomer.size();           
        	System.assertNotEquals(kamcustomersize,0); 
            Map<String,String> ulist=PNR_CustomerController.getReporteeList();
            //check the reporteelist list
            Integer usersize = ulist.size();           
        	System.assertNotEquals(usersize,0);
            // check the diageoContact update for Customer Service Rep/Credit Controller Role
            String result=PNR_CustomerController.updateDiageoContact(con.PNR_Diageo_Rep__c,con.PNR_Contact_Type__c,testadminUser.id,acclist,true);
			system.assertEquals(result, 'Success');
            // check the diageoContact update for Account Manager Role
            String amrres=PNR_CustomerController.updateDiageoContact(conam.PNR_Name__c,conam.PNR_Contact_Type__c,'Testing',acclist,false);
			system.assertEquals(amrres, 'Success');
            // check for unassign the Diageo contact from Customer rep/credit controller to Team Lead
            String unassignres=PNR_CustomerController.updateDiageoContactTL(con1.PNR_Diageo_Rep__c,acclist);
			//system.assertEquals(unassignres, 'Success');
        }
    }
}