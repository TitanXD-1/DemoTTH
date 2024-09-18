@isTest
public class PNR_MyCustomersControllerTest {
    @isTest 
    static void validatemethod(){
        
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
            cust.Sort__c='SORT123';
        	cust.Deletion_Flag_from_SAP__c= FALSE;
            insert cust;
            System.assert(cust.Id != null);
            //Diageo Contact creation
            PNR_Diageo_Contact__c con = PNR_TestDataUtility.getPNRDiageoContactData();
            con.PNR_Diageo_Rep__c =testadminUser.Id;
            con.PNR_Customer__c =cust.Id;
            insert con;
            System.assert(con.Id != null);
            // Diageo PF payer creation
            List<PNR_Partner_Function__c> pfl=new  List<PNR_Partner_Function__c>();
            PNR_Partner_Function__c pfpay=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfpay.PNR_Customer_No__c=cust.Id;
            pfpay.PNR_Type__c='Payer';
            insert pfpay;
            pfl.add(pfpay);
            // Diageo PF Sold-To creation
            PNR_Partner_Function__c pfsold=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfsold.PNR_Customer_No__c=cust.Id;
            pfsold.PNR_Type__c='Sold-To';
            insert pfsold;
            pfl.add(pfsold);
            // Diageo PF Ship-To creation
            PNR_Partner_Function__c pfship=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfship.PNR_Customer_No__c=cust.Id;
            pfship.PNR_Type__c='Ship-To';
            insert pfship;
            pfl.add(pfship);
            // Diageo PF Bill-To creation
            PNR_Partner_Function__c pfbill=PNR_TestDataUtility.getPNRPartnerFunctionData();
            pfbill.PNR_Customer_No__c=cust.Id;
            pfbill.PNR_Type__c='Bill-To';
            insert pfbill;
            System.assert(pfbill.Id != null);
            pfl.add(pfbill);
            
            System.debug('===='+pfl);
            
            //Check getPartnerFunctionList
            List<PNR_Partner_Function__c> pflist=PNR_MyCustomersController.getPartnerFunctionList();
            System.debug('====Id==='+pflist[0].Id);
            PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].Id];
            system.debug('pf.PNR_Type__c'+pf.PNR_Type__c);
            system.assertNotEquals(pf.PNR_Type__c, 'Ship-To');
            
            //check filterPartnerFunctionList for customer number
            List<PNR_Partner_Function__c> pfcustnum =PNR_MyCustomersController.filterPartnerFunctionList('Customer Number',cust.AccountNumber);
            PNR_Partner_Function__c filterpf= [SELECT Id,PNR_Customer_No__c,PNR_Customer_No__r.Name,PNR_Customer_No__r.AccountNumber FROM PNR_Partner_Function__c where Id=:pfcustnum[0].Id];
            system.debug('CUST Number'+filterpf.PNR_Customer_No__r.AccountNumber);
            system.assertEquals(filterpf.PNR_Customer_No__r.AccountNumber , '10483');
            
            //check filterPartnerFunctionList for customer name
            List<PNR_Partner_Function__c> pfcustname =PNR_MyCustomersController.filterPartnerFunctionList('Customer Name',cust.Name);
            PNR_Partner_Function__c filtercname= [SELECT Id,PNR_Customer_No__c,PNR_Customer_No__r.Name,PNR_Customer_No__r.AccountNumber FROM PNR_Partner_Function__c where Id=:pfcustname[0].Id];
            system.debug('CUST Number'+filtercname.PNR_Customer_No__r.Name);
            system.assertEquals(filtercname.PNR_Customer_No__r.Name, 'Test Customer Account');
            PNR_MyCustomersController.getCustomerId(cust.AccountNumber);
            PNR_MyCustomersController.getAttachmentList(cust.Id);
            PNR_MyCustomersController.checkTL();
            
        }
        
    }    
    
}