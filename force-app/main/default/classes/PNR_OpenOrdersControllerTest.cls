/**********************************************************************
Name: PNR_OpenOrdersControlleTest
=======================================================================
Req: This is the test class for the  PNR_OpenOrdersControlle class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sudipta Nandi     14/06/2019      Initial Development

***********************************************************************/
@isTest
public class PNR_OpenOrdersControllerTest {
    @isTest 
    static void validatemethod(){
        
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        System.runAs ( testadminUser ) {
            // Customer creation
               // Customer creation
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            insert cust;
            //Daigeo contract creation
            /*Contract contrc =PNR_TestDataUtility.getContractData();
            contrc.AccountId=cust.Id;
            contrc.Status='Draft';
            contrc.ContractTerm=2;
            contrc.StartDate=system.today();
            insert contrc; */
            
           
            Id dynamicRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Direct_Order'].Id;
            // Diageo Order creation.
            Order__c ord = PNR_TestDataUtility.getNewOrderData();
            ord.Account__c=cust.Id;
            ord.RecordTypeId = dynamicRecordTypeId;
            ord.Payer_Number__c = cust.Id;
            ord.Billing_Document__c = null;
            ord.Is_Deletion_Indicator_Flag__c = false;
            insert ord;
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
            
            List<Order__c> soldOrderDetails =  PNR_OpenOrdersController.fetchOpenOrders(pfsold.PNR_Customer_No__c,pfsold.PNR_Type__c,'SE01');
            List<Order__c> payerOrderDetails = PNR_OpenOrdersController.fetchOpenOrders(pfpay.PNR_Customer_No__c, pfpay.PNR_Type__c,'SE01');
            //check the Sold Order list
            Order__c ordrec1=[Select id,SAP_Order_Number__c,PO_Number__c from Order__c where id=:soldOrderDetails[0].Id ];
            system.assertnotEquals(ordrec1.PO_Number__c,null);
            
            //check the Payer Order list
            Order__c ordrec2=[Select id,SAP_Order_Number__c,PO_Number__c from Order__c where id=:payerOrderDetails[0].Id ];
            system.assertnotEquals(ordrec2.PO_Number__c,null);
            
        }
    }
}