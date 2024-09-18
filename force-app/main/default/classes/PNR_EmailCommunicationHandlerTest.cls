@isTest
public class PNR_EmailCommunicationHandlerTest {
    
    static testMethod void testInboundEmailApproved() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        
        // Create Test record.
        Case cse = PNR_TestDataUtility.getCaseData();
        Insert cse;
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :cse.Id].CaseNumber;
        
        
        email.subject = 'Sandbox: \'['+caseNumber+']\'-RONALD MARTIN (BUTCHERS) LTD-Dispute – Pricing : Approval request approved';
        
        
        env.fromAddress = 'test@test.com';
        List<String> toStr= new List<String>{'GAS.qa@diageo.com'};
            email.toAddresses = toStr;
        email.ccAddresses = toStr;
        List<Messaging.InboundEmail.Header> headerList =  new List<Messaging.InboundEmail.Header>();
        
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header(); 
        hditem.name='Date'; 
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700'; 
        headerList.add(hditem);
        
        
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        attachment.headers = headerList;
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
            
            Messaging.InboundEmail.textAttachment attachment1 = new Messaging.InboundEmail.textAttachment();
        attachment1.body = 'my attachment text';
        attachment1.fileName = 'textfile.txt';
        attachment1.headers = headerList;
        attachment1.mimeTypeSubType = 'text/plain';
        email.textAttachments = new Messaging.inboundEmail.textAttachment[] { attachment1 };
            
            PNR_EmailCommunicationHandler obj= new PNR_EmailCommunicationHandler();
        //obj.handleInboundEmail(email, env );
        Messaging.InboundEmailResult result = obj.handleInboundEmail(email, env);
        System.assertEquals( result.success  ,true);
    }
    
}