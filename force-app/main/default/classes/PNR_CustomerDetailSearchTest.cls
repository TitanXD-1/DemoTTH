/**********************************************************************
Name: PNR_CustomerDetailSearchTest
=======================================================================
Req: This is the test class for the  PNR_CustomerDetailSearch class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned Khan        13/06/2019      Initial Development
1.1   Tanmoy Bardhan    03/07/2019      Modified after Order object changed to Order__c 
***********************************************************************/
@isTest
public class PNR_CustomerDetailSearchTest {
    @isTest 
    static void validateMethod(){
        
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
            PNR_Diageo_Contact__c con = PNR_TestDataUtility.getPNRDiageoContactData();
            con.PNR_Diageo_Rep__c =testadminUser.Id;   
            insert con;
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
            pfl.add(pfbill);

            //Diageo contract creation
           /* Contract contrc =PNR_TestDataUtility.getContractData();
            contrc.AccountId=cust.Id;
            contrc.Status='Draft';
            contrc.ContractTerm=2;
            contrc.StartDate=system.today();
            insert contrc; */
            // Diageo Order creation.
            Order__c ord = PNR_TestDataUtility.getNewOrderData();
            ord.Account__c = cust.Id;
            insert ord;
            //Diageo Invoice creation
           Invoice__c inv= PNR_TestDataUtility.getPNRInvoiceData();
            inv.Account__c = cust.Id;
            insert inv;  
            test.startTest();
             //Check getPartnerFunctionList
            List<PNR_Partner_Function__c> pflist=PNR_CustomerDetailSearch.getPartnerFunctionList();
            PNR_Partner_Function__c pf= [SELECT Id,PNR_Type__c FROM PNR_Partner_Function__c where Id=:pflist[0].Id];
            system.debug('pf.PNR_Type__c'+pf.PNR_Type__c);
            system.assertNotEquals(pf.PNR_Type__c, 'Ship-To');
            
            //check filterPartnerFunctionList for customer number
            List<PNR_Partner_Function__c> pfcustnum =PNR_CustomerDetailSearch.filterPartnerFunctionList('Customer Number',cust.AccountNumber);
            system.debug('pfcustnum---> '+pfcustnum);
            PNR_Partner_Function__c filterpf= [SELECT Id,PNR_Customer_No__c,PNR_Customer_No__r.Name FROM PNR_Partner_Function__c where Id=:pfcustnum[0].Id];
            system.debug('filterpf --> '+filterpf);
            system.debug('CUST Number'+filterpf.PNR_Customer_No__r.Name);
            //system.assertEquals(filterpf.PNR_Customer_No__r.Name, '10483');
            
            //check filterPartnerFunctionList for customer name
            List<PNR_Partner_Function__c> pfcustname =PNR_CustomerDetailSearch.filterPartnerFunctionList('Customer Name',cust.Name);
            PNR_Partner_Function__c filtercname= [SELECT Id,PNR_Customer_No__c,PNR_Customer_No__r.Name FROM PNR_Partner_Function__c where Id=:pfcustname[0].Id];
            system.debug('CUST Name'+filtercname.PNR_Customer_No__r.Name);
            system.assertEquals(filtercname.PNR_Customer_No__r.Name, 'Test Customer Account');
            
            //Check for Customer id
            String customerId=PNR_CustomerDetailSearch.getcustomerId(cust.AccountNumber);
            system.assertnotEquals(customerId,null);
            
            //Check for Salesorder Number
            List<Order__c> ordlist=PNR_CustomerDetailSearch.getOrderList(ord.Sales_Org__c, ord.SAP_Order_Number__c,'','');
            Order__c ordrec=[Select id,SAP_Order_Number__c,PO_Number__c from Order__c where id=:ordlist[0].Id ];
            system.assertnotEquals(ordrec.SAP_Order_Number__c,null);
            
            //Check for Purchase Number
            PNR_CustomerDetailSearch.getOrderList(ord.Sales_Org__c,'', ord.PO_Number__c,'');
            List<Order__c> ordlist1=PNR_CustomerDetailSearch.getOrderList(ord.Sales_Org__c, ord.SAP_Order_Number__c,'','');
            Order__c ordrec1=[Select id,SAP_Order_Number__c,PO_Number__c from Order__c where id=:ordlist1[0].Id ];
            system.assertnotEquals(ordrec1.PO_Number__c,null);
            
            //Check for Delivery Document Number
            PNR_CustomerDetailSearch.getOrderList(ord.Sales_Org__c,'', '', ord.Delivery_Document__c);
            List<Order__c> ordlist2=PNR_CustomerDetailSearch.getOrderList(ord.Sales_Org__c, ord.SAP_Order_Number__c,'','');
            Order__c ordrec2=[Select id,SAP_Order_Number__c,PO_Number__c,Delivery_Document__c from Order__c where id=:ordlist1[0].Id ];
            system.assertnotEquals(ordrec2.Delivery_Document__c,null);
            
            List<Invoice__c> invlist= PNR_CustomerDetailSearch.getInvoiceList(inv.SAP_Invoice_Number__c,inv.Sales_Org__c);
            system.debug('invlist==>'+invlist);
            Invoice__c invrec=[Select Id,Sales_Org__c from Invoice__c where id=:invlist[0].Id ];
            system.assertnotEquals(invrec.Id,null);
            test.stopTest();
        }
    }
	/*******************************************************************
    Method  : validateOrderFetch
    Purpose : This method is used to validate proper Order Data 
    ***********************************************************************/
	@isTest
	public static void validateOrderFetch(){
        //Inserting Account Record
        Account accRec = PNR_TestDataUtility.getDirectCustomerRec();
        accRec.AccountNumber = '0007000415';
        accRec.KUNNR__c = '0007000415';
        insert accRec;
        System.assert(accRec.Id != null);
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchSuccess');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
    /*******************************************************************
    Method  : validateOrdFetNoData
    Purpose : This method is used to validate no Order Data present in Response
    ***********************************************************************/
    @isTest
	public static void validateOrdFetNoData(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchNoData');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        System.assert(mock != null);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
    /*******************************************************************
    Method  : validateOrdFetNoAcc
    Purpose : This method is used to validate No Account Data Present
    ***********************************************************************/
   	@isTest
	public static void validateOrdFetNoAcc(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchSuccess');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        System.assert(mock != null);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
    /*******************************************************************
    Method  : validateOrdFetStatus
    Purpose : This method is used to validate Wrong JSON Status Code
    ***********************************************************************/
    @isTest
	public static void validateOrdFetStatus(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchSuccess');
        mock.setStatusCode(500);
        mock.setHeader('Content-Type', 'application/json');
        System.assert(mock != null);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
    /*******************************************************************
    Method  : ordFetWrngJSON
    Purpose : This method is used to validate Wrong JSON 
    ***********************************************************************/
  	@isTest
	public static void ordFetWrngJSON(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchWrongJSON');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        System.assert(mock != null);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
    /*******************************************************************
    Method  : ordFetWrngStatus
    Purpose : This method is used to validate different JSON Status
    ***********************************************************************/
 	@isTest
	public static void ordFetWrngStatus(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchWrongStatus');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        System.assert(mock != null);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
    /*******************************************************************
    Method  : orderFetchDiffDate
    Purpose : This method is used to validate different order date format
    ***********************************************************************/
   	@isTest
	public static void orderFetchDiffDate(){
        //Inserting Account Record
        Account accRec = PNR_TestDataUtility.getDirectCustomerRec();
        accRec.AccountNumber = '0007000415';
        accRec.KUNNR__c = '0007000415';
        insert accRec;
        System.assert(accRec.Id != null);
        
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
		mock.setStaticResource('OrderFetchDiffDate');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', 'salesOrder', 'purOrderNum', 'deliveryNum', null);
		Test.stopTest();
	}
   	/*******************************************************************
    Method  : invFetchSucc
    Purpose : This method is used to validate Proper Invoice fetch
    ***********************************************************************/
    @isTest
    public static void invFetchSucc(){
        Account accRec = PNR_TestDataUtility.getDirectCustomerRec();
        accRec.AccountNumber = '0000010121';
        accRec.KUNNR__c = '0000010121';
        insert accRec;
        System.assert(accRec.Id != null);
        
        InvandInvLineItembyPassValidation__c invandinvlineitem=new InvandInvLineItembyPassValidation__c();
        invandinvlineitem.Name='Testing';
        insert invandinvlineitem;
        
        Order__c orderObj = PNR_TestDataUtility.getNewOrderData();
        orderObj.SAP_Order_Number__c= '9012026665';
        orderObj.Account__c = accRec.Id;
        insert orderObj;
        System.assert(orderObj.Id != null);
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('invoiceFetchSuccess');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', null,null, null,'invNumber');
        Test.stopTest();
    }
    /*******************************************************************
    Method  : invFetchNoData
    Purpose : This method is used to validate no data found for Invoice
    ***********************************************************************/
    @isTest
    public static void invFetchNoData(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('invoiceFetchNoData');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        System.assert(mock != null);
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        PNR_CustomerDetailSearch.sendReq('salesOrg', null,null, null,'invNumber');
        Test.stopTest();
    }
}