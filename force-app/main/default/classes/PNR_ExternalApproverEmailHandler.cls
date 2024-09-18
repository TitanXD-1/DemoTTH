/**********************************************************************************
Name: PNR_ExternalApproverEmailHandler
===================================================================================
Purpose: This is the Controller class to handle inbound external email for approval
===================================================================================
History                                                            
-----------------------------------------------------------------------------------                                                            
VERSION    AUTHOR            	DATE              DETAIL
1.0        Tanmoy Bardhan     08-08-2019        Initial Development
2.0        Tanmoy Bardhan     10-08-2019        Modified
3.0		   Tanmoy Bardhan	  23-08-2019		Modified to validate approver email before updating status
***********************************************************************************/
global without sharing class PNR_ExternalApproverEmailHandler implements Messaging.InboundEmailHandler{
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        String[] replyEmailSubject;
        String desiredEmailSubject='';
        String[] subject;
        String caseNumber = '';
        String status = '';
        String emailSubjectLine = '';
        Id caseId;
        String beforeLast = '';
        String statusBeforeLast = '';
        Correction_Document__c cDoc;
        List<Case> caseList = new List<Case>();
        
        emailSubjectLine = email.subject;
        caseNumber = emailSubjectLine.substringBetween('[',']').trim();
        status = emailSubjectLine.substringAfterLast(' ').trim();
        beforeLast = emailSubjectLine.substringBeforeLast(' ').trim();
        statusBeforeLast = beforeLast.substringAfterLast(' ').trim();
        
        if(caseNumber != '' && caseNumber != Null){
            //caseId = [SELECT Id, CaseNumber FROM Case WHERE CaseNumber = :caseNumber].Id;
            caseList = [SELECT Id, CaseNumber,Status FROM Case WHERE CaseNumber = :caseNumber];
            if(!caseList.isEmpty())
            caseId = caseList[0].Id;
            //if(!caseList.isEmpty() && caseList[0].Status != 'Closed' && caseList[0].Status != 'Rejected' && caseList[0].Status != 'Externally Approved' && caseList[0].Status != 'Externally Rejected' && caseList[0].Status != 'Externally Approved With Change'){//change start
            if(!caseList.isEmpty() && caseList[0].Status == 'Sent for External Approval'){ //PION-2191 : checking if the status is 'sent for external approval' before changing it to 'Externally Approved'
                Case cse = new Case();
                cse.Id = caseId;
                if(status.equalsIgnoreCase('Approved') || status.equalsIgnoreCase('Approve')){
                    if(!statusBeforeLast.equalsIgnoreCase('not')){
                        cse.Status = 'Externally Approved';
                    }else{
                        cse.Status = 'Externally Rejected';
                    }
                }else if(status.equalsIgnoreCase('Rejected') || status.equalsIgnoreCase('Reject')){
                    if(!statusBeforeLast.equalsIgnoreCase('not')){
                        cse.Status = 'Externally Rejected';
                    }else{
                        cse.Status = 'In Progress'; 
                    }
                }else if(status.equalsIgnoreCase('Change')){
                    cse.Status = 'Externally Approved With Change';
                }
                if(Schema.sObjectType.Correction_Document__c.isAccessible()){
                 cDoc = [SELECT Id FROM Correction_Document__c WHERE Case__c = :caseId];
                }
                Correction_Document__c cDocument = new Correction_Document__c();
                cDocument.Id = cDoc.Id;
                if(status.equalsIgnoreCase('Approved') || status.equalsIgnoreCase('Approve')){
                    if(!statusBeforeLast.equalsIgnoreCase('not')){
                        cDoc.Status__c = 'Externally Approved';
                    }else{
                        cDoc.Status__c = 'Externally Rejected';
                    }
                }else if(status.equalsIgnoreCase('Rejected') || status.equalsIgnoreCase('Reject')){
                    if(!statusBeforeLast.equalsIgnoreCase('not')){
                        cDoc.Status__c = 'Externally Rejected';
                    }else{
                        cDoc.Status__c = 'In Progress'; 
                    }
                }else if(status.equalsIgnoreCase('Change')){
                    cDoc.Status__c = 'Externally Approved With Change';
                }
                
                //condition added to validate approver email
                Boolean isValid = PNR_ApproverMatrix.validateApproverEmail(cDoc.Id, email.fromAddress);
                if(isValid){
                    Database.SaveResult saveRslt = Database.update(cse, false);
                    Database.SaveResult saveRsltupd = Database.update(cDoc, false);
                }else{
                    cse.Status = 'Select External approver to resend';
                    cDoc.Status__c = 'Select External approver to resend';
                    Database.SaveResult saveRslt = Database.update(cse, false);
                    Database.SaveResult saveRsltupd = Database.update(cDoc, false);
                }
            }//change end
            EmailMessage emailMessages = new EmailMessage();
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
            emailMessages.Subject = email.subject;
            emailMessages.Incoming = True;
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
                        System.debug('inserted record Id:==>' +saveRsltIns.getId());
                        insert attachment;
                    }
                }
                if(email.binaryAttachments != null)
                {
                    for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
                        Attachment attachment = new Attachment();
                        attachment.Name = bAttachment.fileName;
                        attachment.Body = bAttachment.body;
                        attachment.ParentId = saveRsltIns.getId();
                        System.debug('inserted record Id:==>' +saveRsltIns.getId());
                        insert attachment;
                    }
                }
            }
        }
        
        result.success = true;
        return result;
    }
}