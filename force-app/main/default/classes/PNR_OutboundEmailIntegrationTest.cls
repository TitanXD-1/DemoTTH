/**********************************************************************
Name: PNR_OutboundEmailIntegrationTest
=======================================================================
Req: This is the test class for the  PNR_OutboundEmailIntegration class.
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sudipta Nandi        08/16/2019      Initial Development
***********************************************************************/
@isTest
public class PNR_OutboundEmailIntegrationTest {
    public static string signeture;
    @testSetup static void testDataMethod(){
        PNR_TestDataUtility.createOrgSettings();
        Id countryId = PNR_TestDataUtility.setupCountry('AUS');
        Account cust= PNR_TestDataUtility.getDirectCustomerRec();
        cust.Country__c=countryId;
        //insert accList;
        insert cust;
       
        Invoice__c inv =PNR_TestDataUtility.getPNRInvoiceData();
        inv.Account__c=cust.Id;
        inv.Sales_Org__c='SE01';
        //insert invList;
        insert inv;
       
       
        Case cse =PNR_TestDataUtility.getCaseData();
        //cse.AccountId=cust.Id;
        cse.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        cse.Reference_Invoice__c=inv.Id;
        cse.AccountId  = inv.account__c;
        cse.Sales_Org__c = inv.sales_org__c;
        cse.Correction_Document_SAP_Number__c = '';
        cse.Rejection_Reason__c = 'None';
       
        Test.startTest();
        insert cse;
        //added by sai
        EmailMessage emailMsgVar = new EmailMessage();
        emailMsgVar.ParentId = cse.id;
        emailMsgVar.Incoming = false;
        cse.Status = 'In Progress';
       
        update cse;
        Insert emailMsgVar;
       
        list<Correction_Document__c> cdList = new list<Correction_Document__c>();
        list<PNR_CorrectionDocumentMapping__c> invItemsCol = new list<PNR_CorrectionDocumentMapping__c> ();
       
       
        Correction_Document__c crd =PNR_TestDataUtility.getCorrectionDocData();
        crd.Type_of_Reference__c='Single';
        crd.Reference_invoice__c =inv.Id;
        crd.Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82';
        crd.Case__c = cse.Id;
        crd.Bill_To__c ='10114';
        crd.Approver_Email__c = 'a.a@gmail.com';
        //insert crd;
        cdList.add(crd);
       
        Correction_Document__c crdWithOutCorrectionOf =PNR_TestDataUtility.getCorrectionDocData();
        crdWithOutCorrectionOf.Type_of_Reference__c='Single';
        crdWithOutCorrectionOf.Reference_invoice__c =inv.Id;
        crdWithOutCorrectionOf.Correction_Of__c = '';
        crdWithOutCorrectionOf.Case__c = cse.Id;
        //insert crdWithOutCorrectionOf;
        cdList.add(crdWithOutCorrectionOf);
        Correction_Document__c crdmul =PNR_TestDataUtility.getCorrectionDocData();
        crdmul.Type_of_Reference__c='Multiple';
        crdmul.Document_Type__c='YDR';
        crdmul.Correction_Of__c = 'Base Price - YPRI';
        crdmul.Approver_Email__c = 'a.a@gmail.com';
        crdmul.Case__c = cse.Id;
        //insert crdmul;
        cdList.add(crdmul);
        test.stopTest();
        insert cdList;
       
        Approver_Matrix__c appMat = PNR_TestDataUtility.getApproverMatrix();
        Insert appMat;
        PNR_ApproverMatrix.updateEmailAdd(crdmul.Id, 'tanmoy.bardhan@diageo.com');
       
        PNR_CorrectionDocumentMapping__c inserInv = new PNR_CorrectionDocumentMapping__c();
        inserInv.Invoice__c = inv.Id;
        inserInv.Product_Number__c = 'Test01';
        inserInv.SAP_Line_Item_Number__c = 'Test01';
        inserInv.Correction_Document__c=cdList[2].Id;
        //insert inserInv;
        invItemsCol.add(inserInv);
       
        PNR_CorrectionDocumentMapping__c inserInv1 = new PNR_CorrectionDocumentMapping__c();
        inserInv1.Invoice__c = inv.Id;
        inserInv1.Product_Number__c = 'Test01';
        inserInv1.SAP_Line_Item_Number__c = 'Test01';
        inserInv1.Correction_Document__c=cdList[1].Id;
        //insert inserInv1;
        invItemsCol.add(inserInv1);
        insert invItemsCol;
    }
    @isTest static void validatedmethod(){
        //create System Admin User
        Test.startTest();
        User testadminUser = PNR_TestDataUtility.runAsUser('TL','PNR_Teamlead');    
        insert testadminUser;
        User usr = [SELECT Id,Name,LastName FROM User WHERE Id=:UserInfo.getUserID()];  
        System.runAs (usr) {
            ContentVersion contentVersionrec = new ContentVersion(Title = 'Penguins',Content_Type__c ='Direct Customer', PathOnClient = 'Penguins.jpg',VersionData = Blob.valueOf('Test Content'),IsMajorVersion = true);        
            contentVersionrec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
            contentVersionrec.Content_Type__c = 'Direct Customer';
            contentVersionrec.Title = 'Test.jpeg';
            insert contentVersionrec;
            Account acc = [select id,Name from account where name='Test Customer Account'];
            Invoice__c inv1 = [select id from invoice__c where account__c =: acc.Id];
            list<Case> cse1 = [select id, accountid, Reference_Invoice__c from case where accountid =: acc.Id limit 1];
           
            Correction_Document__c cd1 = [select id, Correction_Of__c from Correction_Document__c where Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82' limit 1];
            Correction_Document__c cd2 = [select id, Type_of_Reference__c from Correction_Document__c where Bill_To__c ='10114' limit 1];
            Correction_Document__c cd3 = [select id, Approver_Email__c from correction_document__c where Approver_Email__c = 'a.a@gmail.com' limit 1];
            // Test.startTest();
            list<Invoice_Line_Item__c> invItems =  PNR_OutboundEmailIntegration.fetchInvoiceLineItems(inv1.Id, cd1.id);
            //check the Invoice record
            System.assertNotEquals(invItems,null, 'assert not equals');
           
            list<Invoice_Line_Item__c> invItems3 =  PNR_OutboundEmailIntegration.fetchLineItemsforMultiple(cd2.Id);
            //check the Invoice record
            System.assertNotEquals(invItems3,null, 'assert not equals');
           
            list<PNR_CorrectionDocumentMapping__c> invItems4 =  PNR_OutboundEmailIntegration.fetchInvoiceLineItemsForAll(cd2.Id);
            //check the Invoice record
            System.assertNotEquals(invItems4,null, 'assert not equals');
           
            Correction_Document__c cordrec =  PNR_OutboundEmailIntegration.getCorrectionInfoDetails(cd2.Id);
            //check the Invoice record
            System.assertNotEquals(cordrec,null, 'assert not equals');
           
            signeture =  PNR_OutboundEmailIntegration.getUserSigneture();
           
            List<String> varDocId = new List<String>();
            List<ContentDocument> contentDocIds = [select id from ContentDocument limit 3];
            for(ContentDocument rcord:contentDocIds){
                varDocId.add(rcord.id);
            }
           
            boolean isSendSuccessful =  PNR_OutboundEmailIntegration.sendEmailtoApprover('test Email','nam1.qa@diageo.com','nam.qa@diageo.com',cse1[0].Id,varDocId,cd1.Id,'<p> Hi this Test Email</p>');
            //check the Invoice record
            System.assertNotEquals(isSendSuccessful,false, 'assert not equals');
           
           
            PNR_OutboundEmailIntegration.deleteContentDocument(varDocId[0]);
           
            List<PNR_SalesOrg_Mapping__mdt> saveInvoiceLineItem =  PNR_OutboundEmailIntegration.fetchSalesOrgMapping();
            //check the Invoice record
            System.assertNotEquals(saveInvoiceLineItem,null, 'assert not equals');
           
            PNR_OutboundEmailIntegration.getAttachmentList(cse1[0].Id);
           
            PNR_OutboundEmailIntegration.validateEmail(cd3.Id, 'tanmoy.bardhan@diageo.com');
           
           
            Test.stopTest();
        }
       
    }
   
}