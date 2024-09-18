/**********************************************************************
Name: PNR_ApproverLookupControllerTest
=======================================================================
Req: This is the test class for the  PNR_ApproverLookupController class. 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sudipta Nandi        10/22/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_ApproverLookupControllerTest {
    
    @isTest 
    static void validatedmethod(){
        
        
        //create System Admin User
        User testadminUser = PNR_TestDataUtility.runAsUser('TL','PNR_Teamlead');    
        insert testadminUser;
        User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];
        System.runAs (usr) {
            PNR_TestDataUtility.createOrgSettings();
            Id countryId = PNR_TestDataUtility.setupCountry('AUS');
            List<Account> acclist=new List<Account>();
            Account cust= PNR_TestDataUtility.getDirectCustomerRec();
            cust.Country__c=countryId;
            insert cust;
            
            Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
            inv.Account__c=cust.Id;
            inv.Sales_Org__c='SE01';
            insert inv;
            
            Case cse =PNR_TestDataUtility.getCaseData();
            cse.RecordTypeId = Schema.SObjectType.case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
            cse.CurrencyIsoCode = 'GBP';
            cse.Claimed_Amount__c = 102.00;
            cse.AccountId=cust.Id;
            cse.Reference_Invoice__c=inv.Id;
            insert cse;
            
            Case cse1 =PNR_TestDataUtility.getCaseData();
            cse.RecordTypeId = Schema.SObjectType.case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
            cse1.CurrencyIsoCode = 'AUD';
            cse1.Claimed_Amount__c = 300.00;
            cse1.AccountId=cust.Id;
            cse1.Reference_Invoice__c=inv.Id;
            insert cse1;
            
            list<PNR_CorrectionDocumentMapping__c> invItemsCol = new list<PNR_CorrectionDocumentMapping__c> ();
            
            
            Correction_Document__c crd =PNR_TestDataUtility.getCorrectionDocData();
            crd.Type_of_Reference__c='Single';
            crd.Reference_invoice__c =inv.Id;
            crd.Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82';
            insert crd;
            
            Correction_Document__c crdWithOutCorrectionOf =PNR_TestDataUtility.getCorrectionDocData();
            crdWithOutCorrectionOf.Type_of_Reference__c='Single';
            crdWithOutCorrectionOf.Reference_invoice__c =inv.Id;
            crdWithOutCorrectionOf.Correction_Of__c = '';
            insert crdWithOutCorrectionOf;
            
            Correction_Document__c crdmul =PNR_TestDataUtility.getCorrectionDocData();
            crdmul.Type_of_Reference__c='Multiple';
            crdmul.Document_Type__c='YDR';
            crdmul.Correction_Of__c = 'Base Price - YPRI';
            crdmul.Approver_Email__c = 'a.a@gmail.com';
            crdmul.Case__c = cse.Id;
            crdmul.Sales_Org__c = 'GB01';
            crdmul.Reason_Code__c = 'B04 - Pricing - wrong base price / disc (IMC)';
            insert crdmul;
            
           PNR_CorrectionDocumentMapping__c inserInv = new PNR_CorrectionDocumentMapping__c();
            inserInv.Invoice__c = inv.Id;
            inserInv.Product_Number__c = 'Test01';
            inserInv.SAP_Line_Item_Number__c = 'Test01';
            inserInv.Correction_Document__c=crdmul.Id;
            insert inserInv;
            invItemsCol.add(inserInv);
            
            PNR_CorrectionDocumentMapping__c inserInv1 = new PNR_CorrectionDocumentMapping__c();
            inserInv1.Invoice__c = inv.Id;
            inserInv1.Product_Number__c = 'Test01';
            inserInv1.SAP_Line_Item_Number__c = 'Test01';
            inserInv1.Correction_Document__c=crdWithOutCorrectionOf.Id;
            insert inserInv1;
            invItemsCol.add(inserInv1);
            
            PNR_CorrectionDocumentMapping__c invreocrd = [select Id, Name from PNR_CorrectionDocumentMapping__c where ID = : inserInv1.Id];
            
            Correction_Document__c crdmuldiffPrice =PNR_TestDataUtility.getCorrectionDocData();
            crdmuldiffPrice.Type_of_Reference__c='Multiple';
            crdmuldiffPrice.Document_Type__c='YDR';
            crdmuldiffPrice.Correction_Of__c = 'Base Price - YPRI';
            crdmuldiffPrice.Approver_Email__c = 'a.a@gmail.com';
            crdmuldiffPrice.Case__c = cse1.Id;
            crdmuldiffPrice.Sales_Org__c = 'GB01';
            crdmuldiffPrice.Reason_Code__c = 'B04 - Pricing - wrong base price / disc (IMC)';
            crdmuldiffPrice.Claimed_Invoice_Line_Items__c = invreocrd.Name;
            insert crdmuldiffPrice;
            
            Approver_Matrix__c appMat = PNR_TestDataUtility.getApproverMatrix();
            Insert appMat;
            
            List < Correction_Document__c > corDocs = new List < Correction_Document__c >();
            
            
            PNR_ApproverLookupController.fetchLookUpValues('tanmoy.bardhan@diageo.com', 'Approver_Matrix__c');
            
            corDocs = PNR_ApproverLookupController.fetchcorrectionDocumentValues('a.a@gmail.com');
            System.assertNotEquals(corDocs, null);
            System.debug('corDocs===>' + corDocs);
            PNR_ApproverLookupController.updateEmailAdd(corDocs, 'tanmoy.bardhan@diageo.com');
            PNR_ApproverLookupController.fetchApproverList(crdmul.Id,'a.a@gmail.com');
            PNR_ApproverLookupController.fetchApproverList(crdmuldiffPrice.Id,'a.a@gmail.com');
            
            String[] ids = new List<String>();
            ids.add(crdmuldiffPrice.Id);
            ids.add(crdmul.Id);
            Test.startTest();
            List < PNR_ApproverLookupController.PNR_CorrectionWrapper> correctionData = PNR_ApproverLookupController.fetchcorrectionDocumentsInfo(ids);
            if(correctionData!=null){
                for( PNR_ApproverLookupController.PNR_CorrectionWrapper record: correctionData){
                    record.emailBody = 'test';
            		record.emailSubject = 'test';
            		record.responseBody = 'test';
                }  
            }
            
            PNR_ApproverLookupController.sendEmailtoApprover(correctionData);
            Test.stopTest();
        }
    }
    
}