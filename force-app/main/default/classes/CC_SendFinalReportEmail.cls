public class CC_SendFinalReportEmail {
    public class FlowInputs {
        @InvocableVariable public String toAddress;
        @InvocableVariable public String ccAddress;
        @InvocableVariable public String recordId;
    }
    
    @invocablemethod
    public static void sendFinalReportEmail(List<FlowInputs> request){
        String toAddress = request[0].toAddress;
        String ccAddress = request[0].ccAddress!=null?request[0].ccAddress:null;
        String recordId = request[0].recordId; 
        Contact c = new Contact(firstName=toAddress,lastName=toAddress,Email=toAddress);
        insert c;
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(c.Id); 
        //message.setSenderDisplayName(‘Company Support’); 
        //message.setReplyTo(‘no-reply@company.com’);
        message.setUseSignature(false); 
        message.setBccSender(false); 
        message.setSaveAsActivity(true); 
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Final Report'];
        message.setTemplateID(emailTemplate.Id); 
        
        message.setWhatId(recordId); //This is important for the merge fields in template to work
        message.toAddresses = new String[] {toAddress};
        if(ccAddress != null && ccAddress != '')
            message.ccaddresses = new String[]{ccAddress};
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>();
        results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: ' +  results[0].errors[0].message);
        }
        delete c;
        
        EmailMessage em = [Select id,parentId from emailMessage where parentId=:recordId ORDER BY CreatedDate DESC LIMIT 1];
        //Get Attachment
        Attachment attach = [Select id,Name,OwnerId,Body from Attachment where ParentId =:em.Id];
        
        //Insert ContentVersion
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = attach.Name;//File name with extention
        cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
        cVersion.OwnerId = attach.OwnerId;//Owner of the file
        cVersion.Title = attach.Name;//Name of the file
        cVersion.VersionData = attach.Body;//File content
        Insert cVersion;
        
        //After saved the Content Verison, get the ContentDocumentId
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        
       List<CC_Customer_Concern__c> cc = [Select id from CC_Customer_Concern__c where cc_Case__c =:recordId];
        
        CC_ContentDocumentLinkTriggerHelper.calledFromSendFinalReport = true;
        
        //Insert ContentDocumentLink
        if(cc.size()>0){
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
        cDocLink.LinkedEntityId = cc[0].Id;//Add attachment parentId
        cDocLink.ShareType = 'V';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
        Insert cDocLink;
        }
    }
}