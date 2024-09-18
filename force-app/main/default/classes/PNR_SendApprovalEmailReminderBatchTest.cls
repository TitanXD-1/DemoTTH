@isTest
public class PNR_SendApprovalEmailReminderBatchTest {
    public static string signeture;
    @testSetup static void DataMethod(){
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
        
        insert cse;
        
        Correction_Document__c crd =PNR_TestDataUtility.getCorrectionDocData();
        crd.Type_of_Reference__c='Single';
        crd.Reference_invoice__c =inv.Id;
        crd.Correction_Of__c = 'List Price Adjustments Paid On Invoice - YZ81/82';
        crd.Case__c = cse.Id;
        crd.Bill_To__c ='10114';
        crd.Approver_Email__c = 'a.a@gmail.com';
        
        insert crd;     
        
        
        EmailMessage emailMsgVar = new EmailMessage();
        emailMsgVar.ParentId = cse.id;
        emailMsgVar.Incoming = false;
        emailMsgVar.Subject = 'Approval request';
        emailMsgVar.ToAddress = 'test@test.com';
        emailMsgVar.CcAddress = 'test1@test.com';
        Insert emailMsgVar;
        ContentVersion contentVersionrec = new ContentVersion(Title = 'Penguins',Content_Type__c ='Direct Customer', PathOnClient = 'Penguins.jpg',VersionData = Blob.valueOf('Test Content'),IsMajorVersion = true);        
        
        contentVersionrec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        contentVersionrec.Content_Type__c = 'Direct Customer';
        contentVersionrec.Title = 'Test.jpeg';
        insert contentVersionrec;
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersionrec.Id].ContentDocumentId;
        crd.Sent_For_Approval_Batch_Date__c= system.today();
        crd.Status__c = 'Sent For External Approval';
        crd.Content_Document_Ids__c = conDocument;
        update crd;
    }
    
    @isTest static void validatedmethod(){
        Test.startTest();
        PNR_RemainderEmailSchedular sh1 = new PNR_RemainderEmailSchedular();
        system.schedule('scheduled Email remainder','0 0 23 * * ?', sh1); 
        Test.stopTest();
    }
}