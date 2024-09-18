/**********************************************************************************
Name: PNR_ExternalApproverEmailHandlerTest
===================================================================================
Purpose: This is the test class for PNR_ExternalApproverEmailHandler class
===================================================================================
History                                                            
-----------------------------------------------------------------------------------                                                            
VERSION    AUTHOR            	DATE              DETAIL
1.0        Tanmoy Bardhan     08-08-2019        Initial Development
2.0        Tanmoy Bardhan     26-09-2019        Modified
***********************************************************************************/
@isTest
public class PNR_ExternalApproverEmailHandlerTest {
    
    static testMethod void testInboundEmailApproved() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        
        // Create Test record.
        Case cse = PNR_TestDataUtility.getCaseData();
        Insert cse;
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :cse.Id].CaseNumber;
        
        Correction_Document__c cd = PNR_TestDataUtility.getCorrectionDocData();
        cd.Case__c = cse.Id;
        Insert cd;
    
        ContentVersion contentVersionrec = new ContentVersion(Title = 'Penguins',Content_Type__c ='Direct Customer', PathOnClient = 'Penguins.jpg',VersionData = Blob.valueOf('Test Content'),IsMajorVersion = true);        
        
        contentVersionrec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        contentVersionrec.Content_Type__c = 'Direct Customer';
        contentVersionrec.Title = 'Test.jpeg';
        insert contentVersionrec;
        
        List<String> varDocId = new List<String>();
        List<ContentDocument> contentDocIds = [select id from ContentDocument limit 3];
        for(ContentDocument rcord:contentDocIds){
            varDocId.add(rcord.id);
        }
        
        PNR_OutboundEmailIntegration.sendEmailtoApprover('test Email','nam1.qa@diageo.com','nam.qa@diageo.com',cse.Id,varDocId,cd.Id,'<p> Hi this Test Email</p>');
        
        
        
        email.subject = 'Sandbox: \'['+caseNumber+']\'-RONALD MARTIN (BUTCHERS) LTD-Dispute – Pricing : Approval request approved';
        
        
        env.fromAddress = 'test@test.com';
        List<String> toStr= new List<String>{'gb.qa@diageo.com'};
        email.toAddresses = toStr;
        email.ccAddresses = toStr;
        PNR_ExternalApproverEmailHandler obj= new PNR_ExternalApproverEmailHandler();
        //obj.handleInboundEmail(email, env );
        Messaging.InboundEmailResult result = obj.handleInboundEmail(email, env);
        System.assertEquals( result.success  ,true);
    }
    
    static testMethod void testInboundEmailRejected(){
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        
        // Create Test record.
        Case cse = PNR_TestDataUtility.getCaseData();
        Insert cse;
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :cse.Id].CaseNumber;
        
        Correction_Document__c cd = PNR_TestDataUtility.getCorrectionDocData();
        cd.Case__c = cse.Id;
        Insert cd;
        
         ContentVersion contentVersionrec = new ContentVersion(Title = 'Penguins',Content_Type__c ='Direct Customer', PathOnClient = 'Penguins.jpg',VersionData = Blob.valueOf('Test Content'),IsMajorVersion = true);        
        
        contentVersionrec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        contentVersionrec.Content_Type__c = 'Direct Customer';
        contentVersionrec.Title = 'Test.jpeg';
        insert contentVersionrec;
        
        List<String> varDocId = new List<String>();
        List<ContentDocument> contentDocIds = [select id from ContentDocument limit 3];
        for(ContentDocument rcord:contentDocIds){
            varDocId.add(rcord.id);
        }
        
        PNR_OutboundEmailIntegration.sendEmailtoApprover('test Email','nam1.qa@diageo.com','nam.qa@diageo.com',cse.Id,varDocId,cd.Id,'<p> Hi this Test Email</p>');
        
        email.subject = 'Sandbox: \'['+caseNumber+']\'-RONALD MARTIN (BUTCHERS) LTD-Dispute – Pricing : Approval request rejected';
        
        
        env.fromAddress = 'test@test.com';
        List<String> toStr= new List<String>{'gb.qa@diageo.com'};
        email.toAddresses = toStr;
        email.ccAddresses = toStr;
        PNR_ExternalApproverEmailHandler obj= new PNR_ExternalApproverEmailHandler();
        obj.handleInboundEmail(email, env );
        Messaging.InboundEmailResult result = obj.handleInboundEmail(email, env);
        System.assertEquals( result.success  ,true);
    }
    
    static testMethod void testInboundEmailWithChange(){
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        
        // Create Test record.
        Case cse = PNR_TestDataUtility.getCaseData();
        Insert cse;
        String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :cse.Id].CaseNumber;
        
        Correction_Document__c cd = PNR_TestDataUtility.getCorrectionDocData();
        cd.Case__c = cse.Id;
        Insert cd;
        
         ContentVersion contentVersionrec = new ContentVersion(Title = 'Penguins',Content_Type__c ='Direct Customer', PathOnClient = 'Penguins.jpg',VersionData = Blob.valueOf('Test Content'),IsMajorVersion = true);        
        
        contentVersionrec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        contentVersionrec.Content_Type__c = 'Direct Customer';
        contentVersionrec.Title = 'Test.jpeg';
        insert contentVersionrec;
        
        List<String> varDocId = new List<String>();
        List<ContentDocument> contentDocIds = [select id from ContentDocument limit 3];
        for(ContentDocument rcord:contentDocIds){
            varDocId.add(rcord.id);
        }
        
        PNR_OutboundEmailIntegration.sendEmailtoApprover('test Email','nam1.qa@diageo.com','nam.qa@diageo.com',cse.Id,varDocId,cd.Id,'<p> Hi this Test Email</p>');
        
        email.subject = 'Sandbox: \'['+caseNumber+']\'-RONALD MARTIN (BUTCHERS) LTD-Dispute – Pricing : Approval request approved with change';
        
        
        env.fromAddress = 'test@test.com';
        List<String> toStr= new List<String>{'gb.qa@diageo.com','qa.gb@diageo.com'};
        email.toAddresses = toStr;
        email.ccAddresses = toStr;
        PNR_ExternalApproverEmailHandler obj= new PNR_ExternalApproverEmailHandler();
        obj.handleInboundEmail(email, env );
        Messaging.InboundEmailResult result = obj.handleInboundEmail(email, env);
        System.assertEquals( result.success  ,true);
    }
    
}