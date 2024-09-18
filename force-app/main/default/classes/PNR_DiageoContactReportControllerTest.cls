/**********************************************************************
Name: PNR_DiageoContactReportControllerTest
=======================================================================
Req: This is the test class for the  PNR_DiageoContactReportController class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Juned Khan      03/09/2019      Initial Development
2.0     Tanmoy Bardhan  03/09/2019      Final Development
***********************************************************************/
@isTest
public class PNR_DiageoContactReportControllerTest {
  static testmethod void validationmethod1(){
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
          	cust.Deletion_Flag_from_SAP__c= FALSE;
            insert cust;
            //Diageo Contact creation
            PNR_Diageo_Contact__c dgcon = PNR_TestDataUtility.getPNRDiageoContactData();
            dgcon.PNR_Contact_Type__c = 'Customer Service Rep';
            dgcon.PNR_Diageo_Rep__c =testadminUser.Id; 
            dgcon.PNR_Customer__c=cust.Id;
            insert dgcon;
          // Diageo PF payer creation
            List<PNR_Partner_Function__c> pfl=new  List<PNR_Partner_Function__c>();
            PNR_Partner_Function__c pfpay=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfpay.PNR_Customer_No__c=cust.Id;
            pfpay.PNR_Type__c='Payer';
            pfpay.PNR_Deletion_Flag_for_Sales_Level__c = FALSE;
            insert pfpay;
          // wrapper data creation
            List<PNR_DiageoContactReportController.wrapperClass> dglist =new List<PNR_DiageoContactReportController.wrapperClass>();
          
            //Check Partner function
            PNR_DiageoContactReportController.wrapperClass ref=new PNR_DiageoContactReportController.wrapperClass();
            dglist=PNR_DiageoContactReportController.fetchDiageoContact(pfpay.PNR_Sales_Org__c);
            Integer dgcsize = dglist.size();
            system.assertNotEquals(dgcsize,0);
           // check for salesorg
           List<String> fetchsales=PNR_DiageoContactReportController.fetchSalesOrgs();
           Integer salessize = fetchsales.size();
           system.assertNotEquals(salessize,0);
      
      }
  }
  
  static testmethod void validationmethod2(){
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
          	cust.Deletion_Flag_from_SAP__c= FALSE;
            insert cust;
            //Diageo Contact creation
            PNR_Diageo_Contact__c dgcon = PNR_TestDataUtility.getPNRDiageoContactData();
            dgcon.PNR_Contact_Type__c = 'Credit Controller';
            dgcon.PNR_Diageo_Rep__c =testadminUser.Id; 
            dgcon.PNR_Customer__c=cust.Id;
            insert dgcon;
          // Diageo PF payer creation
            List<PNR_Partner_Function__c> pfl=new  List<PNR_Partner_Function__c>();
            PNR_Partner_Function__c pfpay=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfpay.PNR_Customer_No__c=cust.Id;
            pfpay.PNR_Type__c='Payer';
            pfpay.PNR_Deletion_Flag_for_Sales_Level__c = FALSE;
            insert pfpay;
          // wrapper data creation
            List<PNR_DiageoContactReportController.wrapperClass> dglist =new List<PNR_DiageoContactReportController.wrapperClass>();
          
            //Check Partner function
            PNR_DiageoContactReportController.wrapperClass ref=new PNR_DiageoContactReportController.wrapperClass();
            dglist=PNR_DiageoContactReportController.fetchDiageoContact(pfpay.PNR_Sales_Org__c);
            Integer dgcsize = dglist.size();
            system.assertNotEquals(dgcsize,0);
           // check for salesorg
           List<String> fetchsales=PNR_DiageoContactReportController.fetchSalesOrgs();
           Integer salessize = fetchsales.size();
           system.assertNotEquals(salessize,0);
      
      }
  }
  
  static testmethod void validationmethod3(){
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
          	cust.Deletion_Flag_from_SAP__c= FALSE;
            insert cust;
            //Diageo Contact creation
            PNR_Diageo_Contact__c dgcon = PNR_TestDataUtility.getPNRDiageoContactData();
            dgcon.PNR_Contact_Type__c = 'Account Manager';
            //dgcon.PNR_Diageo_Rep__c =testadminUser.Id; 
            dgcon.PNR_Name__c = 'test';
            dgcon.PNR_Customer__c=cust.Id;
            insert dgcon;
          // Diageo PF payer creation
            List<PNR_Partner_Function__c> pfl=new  List<PNR_Partner_Function__c>();
            PNR_Partner_Function__c pfpay=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfpay.PNR_Customer_No__c=cust.Id;
            pfpay.PNR_Type__c='Payer';
            pfpay.PNR_Deletion_Flag_for_Sales_Level__c = FALSE;
            insert pfpay;
          // wrapper data creation
            List<PNR_DiageoContactReportController.wrapperClass> dglist =new List<PNR_DiageoContactReportController.wrapperClass>();
          
            //Check Partner function
            PNR_DiageoContactReportController.wrapperClass ref=new PNR_DiageoContactReportController.wrapperClass();
            dglist=PNR_DiageoContactReportController.fetchDiageoContact(pfpay.PNR_Sales_Org__c);
            Integer dgcsize = dglist.size();
            system.assertNotEquals(dgcsize,0);
           // check for salesorg
           List<String> fetchsales=PNR_DiageoContactReportController.fetchSalesOrgs();
           Integer salessize = fetchsales.size();
           system.assertNotEquals(salessize,0);
      
      }
  }

}