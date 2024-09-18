/*
Name: PNR_EmailCommunicationHandler
Purpose: This is the Controller class to handle inbound external email for approval

History                                                                                                                       
VERSION    AUTHOR            	DATE              DETAIL
1.0        Sudipta Nandi     09-17-2019        Initial Development
2.0        Suvendu Roy       08-05-2023        145010 
*/
global without sharing class PNR_EmailCommunicationHandler implements Messaging.InboundEmailHandler{
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        String[] replyEmailSubject;
        String desiredEmailSubject='';
        String[] subject;
        String caseNumber = '';
        
        map<String,Attachment> attachmentMap = new map<string,Attachment>();
        
        String emailSubjectLine = '';
        Id caseId;
        emailSubjectLine = email.subject;
        caseNumber = emailSubjectLine.substringBetween('[',']').trim();
        EmailMessage emailMessages = new EmailMessage();
        if(caseNumber != '' && caseNumber != Null){
            caseId = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber = :caseNumber].Id;
            emailMessages.ParentId = caseId;
            for(String str : email.toAddresses){
                if(emailMessages.ToAddress != null){
                    emailMessages.ToAddress = emailMessages.ToAddress+' , '+str;
                }
                else {
                    emailMessages.ToAddress = str;
                }
            }
            
            if(email.ccAddresses != null){
                for(String str : email.ccAddresses){
                    if(emailMessages.CcAddress != null){
                        emailMessages.CcAddress = emailMessages.CcAddress+' , '+str;
                    }
                    else {
                        emailMessages.CcAddress = str;
                    }
                }
            }
            emailMessages.FromAddress = email.fromAddress;
            emailMessages.FromName = email.fromName;
            emailMessages.TextBody = email.plainTextBody;
            emailMessages.HtmlBody = email.htmlBody;
            emailMessages.Subject = email.subject;
            emailMessages.Incoming =true;
            Database.SaveResult saveRsltIns = Database.insert(emailMessages, false);
            if(saveRsltIns.isSuccess()){
                if(email.textAttachments != null)
                {
                    // Save attachments, if any
                    for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
                        Attachment attachment = new Attachment();
                        
                        attachment.Name = tAttachment.fileName;
                        attachment.Body = Blob.valueOf(tAttachment.body);
                        attachment.ParentId = saveRsltIns.getId();
                        insert attachment;
                    }
                }
                if(email.binaryAttachments != null)
                {
                    for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                        String headerValue;
                        Attachment attachment = new Attachment();
                        attachment.Name = bAttachment.fileName;
                        attachment.Body = bAttachment.body;
                        attachment.ParentId = saveRsltIns.getId();
                        insert attachment;
                        for(Messaging.InboundEmail.Header header: bAttachment.headers){
                            if(header.name.startsWith('Content-ID') || header.name.startsWith('X-Attachment-Id') || (header.value.startsWith('ii') || header.value.startsWith('< image'))){
                                headerValue = header.value.replaceAll('<', '').replaceAll('>', '');
                            }
                        }
                        attachmentMap.put(headerValue, attachment);
                    }
                    Organization org = [ SELECT instanceName FROM Organization WHERE id = :UserInfo.getOrganizationId() LIMIT 1 ];
                    
                    String attachmentDownloadURL = Url.getOrgDomainUrl().toExternalForm().substringbefore('.')+'--'+'c.' + org.instanceName.toLowerCase() + '.content.force.com/servlet/servlet.FileDownload?file=';
                    
                    for ( String contentId : attachmentMap.keySet() ) {
                        if(string.IsNotEmpty(contentId))
                        {
                            String cid = contentId.replace( '<', '' ).replace( '>', '' );
                            String url = attachmentDownloadURL + String.valueOf( attachmentMap.get( contentId ).id ).left( 15 );
                            emailMessages.htmlBody = emailMessages.htmlBody.replaceAll( 'cid:' + cid, url );
                        }
                    }
                    update emailMessages;
                }
            }
            
        }
        result.success = true;
        return result;
    }
}