/**
Name: PNR_InvoiceLineItemsTest
==
Req: This is the test class for the  PNR_InvoiceLineItems class. 
==
History                                                            
---                                                        
VERSION   AUTHOR            DATE              DETAIL
1.0   Sudipta Nandi        30/07/2019      Initial Development
**/
@isTest
public class PNR_InvoiceLineItemsTest {
    
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
            List<Invoice__c> invList = new List<Invoice__c>();
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            insert cust;
            
            Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
            inv.Account__c=cust.Id;
            inv.Sales_Org__c='SE01';
            invList.add(inv);
            //insert inv;
            
            Invoice__c inv2 =PNR_TestDataUtility.getPNRInvoiceData();
            inv2.Account__c=cust.Id;
            inv2.Name = '00000000';
            inv2.Sales_Org__c='SE01';
            invList.add(inv2);
            //insert inv2;
            
            insert invList;
            
            Case cse =PNR_TestDataUtility.getCaseData();
            cse.AccountId=cust.Id;
            cse.Reference_Invoice__c=inv.Id;
            insert cse;
            
            list<Invoice_Line_Item__c> invItemsCol = new list<Invoice_Line_Item__c> ();
            
            List<Correction_Document__c> cdList = new List<Correction_Document__c>();
            Correction_Document__c crd =PNR_TestDataUtility.getCorrectionDocData();
            crd.Type_of_Reference__c='Single';
            crd.Reference_invoice__c =inv.Id;
            crd.Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82';
            Test.startTest();
            crd.Case__c = cse.Id;
            cdList.add(crd);
            //insert crd;
            
            Correction_Document__c crdWithOutCorrectionOf =PNR_TestDataUtility.getCorrectionDocData();
            crdWithOutCorrectionOf.Type_of_Reference__c='Single';
            crdWithOutCorrectionOf.Reference_invoice__c =inv.Id;
            crdWithOutCorrectionOf.Correction_Of__c = '';
            crdWithOutCorrectionOf.Case__c = cse.Id;
            cdList.add(crdWithOutCorrectionOf);
            //insert crdWithOutCorrectionOf;
            
            Correction_Document__c crdmul =PNR_TestDataUtility.getCorrectionDocData();
            crdmul.Type_of_Reference__c='Multiple';
            crdmul.Document_Type__c='YDR';
            crdmul.Correction_Of__c = 'Base Price - YPRI';
            crdmul.Case__c=cse.Id;
            cdList.add(crdmul);
            //insert crdmul;
            
            insert cdList;
            
            Invoice_Line_Item__c inserInv = new Invoice_Line_Item__c();
            inserInv.Invoice__c = inv.Id;
            inserInv.Product_Number__c = 'Test01';
            //inserInv.SAP_Line_Item_Number__c = 'Test01';
            inserInv.Correction_Document__c=crd.Id;
            inserInv.SAP_Line_Item_Number__c = '10';
            insert inserInv;
            invItemsCol.add(inserInv);
            
            Invoice_Line_Item__c inserInv1 = new Invoice_Line_Item__c();
            inserInv1.Invoice__c = inv.Id;
            inserInv1.Product_Number__c = 'Test01';
            //inserInv1.SAP_Line_Item_Number__c = 'Test01';
            inserInv1.Correction_Document__c=crd.Id;
            inserInv.SAP_Line_Item_Number__c = '20';
            insert inserInv1;
            invItemsCol.add(inserInv1);
            
            Invoice_Line_Item__c saveInv = new Invoice_Line_Item__c();
            saveInv.Invoice__c = inv.Id;
            saveInv.Product_Number__c = 'Test01';
            saveInv.SAP_Line_Item_Number__c = 'Test01';
            saveInv.Correction_Document__c=crdmul.Id;
            
            PNR_CorrectionDocumentMapping__c saveInvwithMapping = new PNR_CorrectionDocumentMapping__c();
            saveInvwithMapping.Invoice__c = inv.Id;
            saveInvwithMapping.Product_Number__c = 'Test01';
            saveInvwithMapping.SAP_Line_Item_Number__c = 'Test01';
            saveInvwithMapping.Correction_Document__c=crdmul.Id;
            
            //Product__c prod = PNR_TestDataUtility.getProduct();
            //prod.Name = 'Test04';
            //Insert prod;
            
            List<Product_Sales_Area__c> prodList = PNR_InvoiceLineItems.fetchSKUList('NA01','10');
            
            
            list<PNR_CorrectionDocumentMapping__c> invItemsColMappingCor =  PNR_InvoiceLineItems.fetchInvoiceLineItems(inv.Id,crd.Id,null);
            //check the Invoice record
            System.assertNotEquals(invItemsColMappingCor,null);
            
            list<PNR_CorrectionDocumentMapping__c> invItemsColMappingCor2 =  PNR_InvoiceLineItems.fetchInvoiceLineItems(inv.Id,crdWithOutCorrectionOf.Id,null);
            //check the Invoice record
            System.assertNotEquals(invItemsColMappingCor2,null);
            
            list<PNR_CorrectionDocumentMapping__c> invItemsColMappingCor3 =  PNR_InvoiceLineItems.fetchLineItemForMapping(crdmul.Id);
            //check the Invoice record
            System.assertNotEquals(invItemsColMappingCor3,null);
            
            list<PNR_CorrectionDocumentMapping__c> invItemsColMappingCor4 =  PNR_InvoiceLineItems.fetchLineItemForMapping(crdWithOutCorrectionOf.Id);
            //check the Invoice record
            System.assertNotEquals(invItemsColMappingCor4,null);
            
            Correction_Document__c cordrec =  PNR_InvoiceLineItems.fetchInvoiceNumber(crd.Id);
            //check the Invoice record
            System.assertNotEquals(cordrec,null);
            
            PNR_CorrectionDocumentMapping__c crdMapping = [SELECT Id  from PNR_CorrectionDocumentMapping__c where Correction_Document__c = :crd.Id][0];
            
            boolean isSavedSuccessful =  PNR_InvoiceLineItems.saveClaimedLineItem(String.valueOf(crdMapping.Id),crd.Id);
            //check the Invoice record
            System.assertNotEquals(isSavedSuccessful,false);
            
            boolean isUpdateSuccessful =  PNR_InvoiceLineItems.updateClaimedLineItemAmountForMapping(invItemsColMappingCor,crd.Id);
            //check the Invoice record
            //System.assertNotEquals(isUpdateSuccessful,false);
            
            boolean isSavedTotal =  PNR_InvoiceLineItems.saveItemsAndTotalAmountForMapping(invItemsColMappingCor,'100',cse.Id,'GBP');
            //check the Invoice record
            //System.assertNotEquals(isSavedTotal,false);
            
            PNR_InvoiceLineItems.getPlants();
            PNR_InvoiceLineItems.getDeletedLineItems(crd.Id, inv.Id);
            
            boolean saveInvoiceLineItem =  PNR_InvoiceLineItems.saveInvoiceLineItemsForMapping(saveInvwithMapping,crd.Id);
            //check the Invoice record
            System.assertNotEquals(saveInvoiceLineItem,false);
            List<PNR_SalesOrg_Mapping__mdt> recordvals = PNR_InvoiceLineItems.fetchSalesOrgMapping();
            System.assertNotEquals(recordvals,null);
            
             boolean isRemovedSuccessful =  PNR_InvoiceLineItems.removeMultipleRefLineItemForMapping(invItemsColMappingCor,crd.Id);
            //check the Invoice record
            //System.assertNotEquals(isRemovedSuccessful,false);
            //
             List<PNR_Recharge_Material__mdt> rechargeMaterials = PNR_InvoiceLineItems.getRechargeMaterials();
			  System.assertNotEquals(rechargeMaterials,null);       
            List<SObject> so = PNR_AutocompleteController.getRecords(null, null, null, null, null, null);
            
        }
        User testRepUser = PNR_TestDataUtility.runAsUser('CSRep','PNR_CustomerServiceRep');    
        insert testRepUser;
        //User repUsr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        System.runAs (testRepUser){
            PNR_InvoiceLineItems.checkServiceRep();
        }
        Test.stopTest();
    }
    
}