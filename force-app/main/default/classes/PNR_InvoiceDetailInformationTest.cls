/**********************************************************************
Name: PNR_InvoiceDetailInformationTest
=======================================================================
Req: This is the test class for the  PNR_InvoiceDetailInformation class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Juned Khan        16/07/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_InvoiceDetailInformationTest {
    
    @isTest 
    static void validatedmethod(){
        PNR_Case_Claimed_Amount_Validation_Bypas__c claimed = new PNR_Case_Claimed_Amount_Validation_Bypas__c();
        claimed.By_Pass__c = true;
        insert claimed;
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('TL','PNR_Teamlead');    
        insert testadminUser;
        User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        System.runAs (usr) {
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account genericAcc = PNR_TestDataUtility.getDirectCustomerRec();
            Account cust= genericAcc;
            cust.Country__c=countryId;
            cust.AccountNumber='10438';
            insert cust;
            acclist.add(cust);
            genericAcc.Id = null;
            Account cust1= genericAcc;
            cust1.Country__c=countryId;
            cust1.AccountNumber='70731';
            insert cust1;
            acclist.add(cust1);
            Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
            inv.Account__c=cust.Id;
            inv.Sales_Org__c='SE01';
            insert inv;
            Case genericCase = PNR_TestDataUtility.getCaseData();
            Case cse = genericCase;
            cse.AccountId=cust.Id;
            cse.Reference_Invoice__c=inv.Id;
            insert cse;
            genericCase.Id = null;
            Case cse1 = genericCase;
            cse1.AccountId=cust.Id;
            cse1.Reference_Invoice__c=inv.Id;
            insert cse1;
            Correction_Document__c genericCd = PNR_TestDataUtility.getCorrectionDocData();
            Correction_Document__c crd = genericCd;
            crd.Type_of_Reference__c='Single';
            crd.Reference_invoice__c =inv.Id;
            crd.Distribution_Channel__c='10';
            crd.Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82';
            crd.Sales_Org__c='GB01';
            crd.Bill_To__c='10438';
            crd.Ship_To__c='70731';
            crd.Division__c='10';
            crd.Sold_To__c=cust.Id;
            crd.Reason_Code__c='B02 - Customer Service (Shared Services) Error';
            crd.Payer__c=cust.Id;
            crd.Case__c = cse.Id;
            Test.startTest();
            insert crd;
            
            genericCd.Id = null;
            Correction_Document__c crdmul = genericCd;
            crdmul.Type_of_Reference__c='Multiple';
            crdmul.Invoices_Affected__c='123456;12466';
            crdmul.Document_Type__c='YDR';
            crdmul.Sales_Org__c='AT01';
            crdmul.Correction_Of__c = 'Base Price - YPRI';
            crdmul.Distribution_Channel__c='10';
            crdmul.Bill_To__c='10438';
            crdmul.Ship_To__c='70731';
            crdmul.Division__c='10';
            crdmul.Sold_To__c=cust.Id;
            crdmul.Reason_Code__c='B02 - Customer Service (Shared Services) Error';
            crdmul.Payer__c=cust.Id;
            crdmul.Case__c = cse1.Id;
            insert crdmul;
            
            
            List<PNR_Partner_Function__c> pfToInsert= new List<PNR_Partner_Function__c>();
            PNR_Partner_Function__c genericPf= PNR_TestDataUtility.getPNRPartnerFunctionData();
            PNR_Partner_Function__c pfsoldto= genericPf;
            pfsoldto.PNR_Type__c='Sold-To';
            pfsoldto.PNR_Customer_No__c=cust.Id;
            pfsoldto.PNR_Distribution_Channel__c='Channel';
            pfsoldto.PNR_Division__c='Division';
            pfsoldto.PNR_Deletion_Flag_for_Sales_Level__c = false;
            insert pfsoldto;
            
            genericPf.Id = null;
            PNR_Partner_Function__c pfsoldto1= genericPf;
            pfsoldto1.PNR_Type__c='Payer';
            pfsoldto1.PNR_Customer_No__c=cust1.Id;
            pfsoldto1.PNR_Distribution_Channel__c='Channel';
            pfsoldto1.PNR_Division__c='Division';
            pfsoldto1.PNR_Deletion_Flag_for_Sales_Level__c = false;
            insert pfsoldto1;

            
            Invoice__c invrec =  PNR_InvoiceDetailInformation.fetchInvoiceDetailInfo(inv.Id);
            //check the Invoice record
            System.assertNotEquals(invrec,null);
            
            Invoice__c invrec1 =  PNR_InvoiceDetailInformation.fetchInvoiceDetailInfo('a0n9E000003AMPYQA4');
            //check the Invoice record
            System.assertEquals(invrec1,null);
            
            List<Direct_Reason_Code_Mapping__mdt> allReasoncode=PNR_InvoiceDetailInformation.fetchAllReasonCodes();
            //check the reason code record
            Integer drsize=allReasoncode.size();
            System.assertNotEquals(drsize,0);
            
            List<PNR_Greek_Reason_Code__mdt> allGreekReasoncode= PNR_InvoiceDetailInformation.getAllGreekReasonCodes();
            //check the reason code record
            Integer grSize=allGreekReasoncode.size();
            System.assertNotEquals(grSize,0);
            
            List<PNR_CorrectionOfPricingCondition__mdt> allpricingcode=PNR_InvoiceDetailInformation.fetchAllPricingCondition();
            //check the reason code record
            Integer allpsize=allpricingcode.size();
            System.assertNotEquals(allpsize,0);
            
            //single reference
            String cordoc=PNR_InvoiceDetailInformation.createCorrectionDocument(inv,'', 'Select','test', 'billingNotes', 'poNumber', cse.Id, 'Single', 'correctionOf','test','test','test',system.today());
            //check the single ref record
            System.assertNotEquals(cordoc,null);
            
            //multiple reference
            String multiplecordoc=PNR_InvoiceDetailInformation.createCorrectionDocument(inv,'12345678;09876543', 'Select','test', 'billingNotes', 'poNumber', cse.Id, 'Multiple', 'correctionOf','test','test','test',system.today());
            //check the multiple record
            System.assertNotEquals(multiplecordoc,null);
            
            Correction_Document__c correcdoc=PNR_InvoiceDetailInformation.fetchCorrectionDoc(crd.Id);
            //check for correction document
            System.assertNotEquals(correcdoc,null);
            
            
            crdmul.Ship_To__c = cust.Id;
            crdmul.Bill_To__c = cust.Id;
            Boolean cordocexist=PNR_InvoiceDetailInformation.updateCorrectionDocument(crdmul,crd.Id);
            //check the record update
            System.assertEquals(cordocexist,true);
            
            // for Sold-To
            String str=PNR_InvoiceDetailInformation.validateSoldtoCombination(pfsoldto.PNR_Sales_Org__c,pfsoldto.PNR_Sold_To__c,pfsoldto.PNR_Customer_No__c,pfsoldto.PNR_Customer_No__c,pfsoldto.PNR_Customer_No__c,'Channel','Division');
            //check the record update
            System.assertNotEquals(str,null);
            // For Payer
            String str1=PNR_InvoiceDetailInformation.validateSoldtoCombination(pfsoldto1.PNR_Sales_Org__c,'Sold-To',pfsoldto1.PNR_Customer_No__c,pfsoldto1.PNR_Customer_No__c,pfsoldto1.PNR_Customer_No__c,'Channel','Division');
            //check the record update
            System.assertNotEquals(str1,null);
            
            Map<String,String> fetchrecord=PNR_InvoiceDetailInformation.fetchShiptoBilltoId(crd.Id);
            //check the reporteelist list
            Integer fetchrecordsize = fetchrecord.size();           
        	System.assertNotEquals(fetchrecordsize,0);
            Test.stopTest();
           
        }
    }
    
}