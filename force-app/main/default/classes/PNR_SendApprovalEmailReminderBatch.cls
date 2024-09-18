public class PNR_SendApprovalEmailReminderBatch implements Database.Batchable<sObject>{
    
     public Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([select id, status__c, Case__c,Content_Document_Ids__c
                                         from Correction_Document__c
                                         where status__c = 'Sent For External Approval' and Sent_For_Approval_Batch_Date__c=Today]);
    }
    
     public void execute(Database.BatchableContext BC, List<Correction_Document__c> scope){
        
        List<Correction_Document__c> corrDocList = (List<Correction_Document__c>)scope;
        sendEmailsToApprover(corrDocList);
        
    }
    
    private static void sendEmailsToApprover(List<Correction_Document__c> corrDocList){
        
        Map<Id,EmailMessage> caseIdEmailMsgMap = new Map<Id,EmailMessage>();
        Set<Id> caseIDSet = new Set<Id>();
        List<Messaging.SingleEmailMessage> singleMsgList = new List<Messaging.SingleEmailMessage>();
        
        for(Correction_Document__c cd : corrDocList)
        {
            caseIDSet.add(cd.Case__c);
        }
        
        List<EmailMessage>  emailMsgList = [Select Id, CcAddress, ParentId, ToAddress, FromAddress, HtmlBody, Subject
                                            from EmailMessage where Subject like  '%Approval request' and  ParentId IN : caseIDSet];
        
        
        for(EmailMessage em : emailMsgList)
        {
            caseIdEmailMsgMap.put(em.ParentId, em);
        }
        
        for(Correction_Document__c corrDoc : corrDocList )
        {
            List<String> contentDocIds = new List<String>();
            if(!String.isBlank(corrDoc.Content_Document_Ids__c)){
                contentDocIds = corrDoc.Content_Document_Ids__c.split(';');
            }
            PageReference pdfAttachment =  Page.PNR_ExternalEmailVF;
            pdfAttachment.getParameters().put('Id',corrDoc.Id);
            pdfAttachment.setRedirect(true);
            Blob b ;
            //added for test class purpose
            if(Test.isRunningTest()) { 
                b = blob.valueOf('Unit.Test');
            } else {
                b = pdfAttachment.getContent();
            }
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setContentType('application/pdf');
            efa.setFileName(caseIdEmailMsgMap.get(corrDoc.Case__c).subject+'.pdf');
            efa.setInline(false);
            efa.setBody(b);
            
            Messaging.SingleEmailMessage message = sendEmail(caseIdEmailMsgMap.get(corrDoc.Case__c),efa,contentDocIds);            
        	singleMsgList.add(message);
        }
        
        if(!singleMsgList.isEmpty()){
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(singleMsgList);
            System.debug(results);
            
        }
        
    }
    
    private static Messaging.SingleEmailMessage  sendEmail(EmailMessage emailMsg,Messaging.EmailFileAttachment emailFileAttachment,List<String> contentDocIds){
        
        //System.debug('owea::' + owea);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        
        String orgWideEmailAddressId = [select Id from OrgWideEmailAddress where Address =:System.Label.PNR_FromEmailAddressForApproval Limit 1].Id;
        
        message.setOrgWideEmailAddressId(orgWideEmailAddressId);
        if(!String.isBlank(emailMsg.CcAddress)){
           message.ccaddresses = emailMsg.CcAddress.split(';');  
        }
        if(!String.isBlank(emailMsg.ToAddress)){
           message.toAddresses = emailMsg.ToAddress.split(';'); 
           // message.toAddresses.add('deepika.gulati@diageo.com') ;
        }
        
        message.subject = emailMsg.subject;
        message.htmlbody = 'Remainder Mail to approve the request. <br/> '+emailMsg.HtmlBody;
        message.setUseSignature(false);
        message.setCharset('UTF-8');
        message.setFileAttachments(new Messaging.EmailFileAttachment[] {emailFileAttachment});
        //system.debug('--- ContentDocId  --- '+ ContentDocId );
        if(!contentDocIds.isEmpty()){
            map<Id,ContentVersion> allDocuments;
            allDocuments = new map<Id,ContentVersion>([SELECT Id, Title, FileType, ContentDocumentId FROM ContentVersion where ContentDocumentId in:contentDocIds]);
            
            list<id> allDocumentsIds = new list<Id>(allDocuments.keySet());
            message.setEntityAttachments(allDocumentsIds); 
        }
        
        return message;
    }
    public void finish(Database.BatchableContext BC){
   }

}