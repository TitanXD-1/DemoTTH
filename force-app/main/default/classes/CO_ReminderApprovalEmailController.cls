/*
@Name: CO_ReminderApprovalEmailController

@Purpose: This class is used to send reminder emails when the approvers do not approve the request.

@History                                                            

VERSION    AUTHOR            DATE              DETAIL
1.0       Jayashree R       11-25-2022        Initial Development
2.0		  Jayashree R		09-01-2023		  CONS-480 - Defect Fix 
3.0		  Aparajita         21-08-2023		  143268 - Reminder email for Routing, DBBV Finance, International Trade Team, Market Finance Delegate, Brand Homes Senior Finance Manager approvers
*/

public with sharing class CO_ReminderApprovalEmailController implements Messaging.InboundEmailHandler {
    
    /*
* Method Name: sendReminderEmail
* Purpose: this method is used to send reminder emails for the pending approvers
*/
    @InvocableMethod(label='Send Reminder Email' description='Send reminder email for pending approvals')    
    public static void sendReminderEmail(List<Customer_Request__c> cusRequests)   
    {       
        try {
            Customer_Request__c cusReq = [SELECT Id, Name, CO_Approver__c, CO_Pricing_Approver__c, CO_Additional_Approver__c, 
                                          CO_Routing_Approver__c, CO_DBBV_Finance__c, CO_International_Trade_Team__c, 
                                          CO_Market_Finance_Delegate__c, CO_Brand_Homes_Senior_Finance_Manager__c, 
                                          CO_Approver__r.Id, CO_Additional_Approver__r.Id, CO_Pricing_Approver__r.Id, 
                                          CO_Routing_Approver__r.Id, CO_DBBV_Finance__r.Id, CO_International_Trade_Team__r.Id, 
                                          CO_Market_Finance_Delegate__r.Id, CO_Brand_Homes_Senior_Finance_Manager__r.Id 
                                          FROM Customer_Request__c WHERE Id =: cusRequests[0].Id WITH SECURITY_ENFORCED];
            List<Id> pendingUsersIds = new List<Id>(); 
            for(ProcessInstanceWorkitem piw : [SELECT Id,ActorId  FROM ProcessInstanceWorkitem WHERE  ProcessInstance.TargetObjectId =:cusReq.Id
                                               AND ProcessInstance.Status = 'Pending' WITH SECURITY_ENFORCED]){
                                                   pendingUsersIds.add(piw.ActorId);
                                               } 
            
            EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CO_Reminder_Approval_Email_Template' WITH SECURITY_ENFORCED] ;
            EmailServicesAddress oEmailServiceAddress = [
                SELECT e.SystemModstamp, e.RunAsUserId, e.LocalPart, e.LastModifiedDate, e.LastModifiedById, e.IsActive, e.Id, e.FunctionId, e.EmailDomainName, e.CreatedDate, e.CreatedById, e.AuthorizedSenders 
                FROM EmailServicesAddress e
                WHERE e.IsActive = true and developerName= 'ReminderApprovalResponse'
            ].get(0); 
            String replyToAddress = oEmailServiceAddress.LocalPart + '@' + oEmailServiceAddress.EmailDomainName;
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            For(User u: [SELECT Id,Email FROM User WHERE Id IN : pendingUsersIds WITH SECURITY_ENFORCED]){
                List<string> toAddress = new List<string>();
                toAddress.add(u.email);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTemplateId(et.Id);
                mail.setToAddresses(toAddress);
                mail.setTargetObjectId(u.Id);
                mail.setWhatId(cusReq.Id);
                mail.setSaveAsActivity(false);
                mail.setUseSignature(false);
                mail.setReplyTo(replyToAddress);
                mail.setSenderDisplayName('Salesforce Approvals');
                allmsg.add(mail);
                if(u.Id == cusReq.CO_Pricing_Approver__r.Id){
                    Messaging.SingleEmailMessage mailPricing = New Messaging.SingleEmailMessage();
                    mailPricing.setTargetObjectId(u.Id);
                    mailPricing = CO_ApprovalProcessController.generatePricingApproverPdfEmail(cusReq.Id, cusReq.Name, mailPricing);
                    mailPricing.setToAddresses(toAddress); 
                    allmsg.add(mailPricing);
                }else{
                    Messaging.SingleEmailMessage mailNonPricing = New Messaging.SingleEmailMessage();
                    mailNonPricing.setTargetObjectId(u.Id);
                    mailNonPricing = CO_ApprovalProcessController.generateApproverPdfEmail(cusReq.Id, cusReq.Name, mailNonPricing);
                    mailNonPricing.setToAddresses(toAddress); 
                    allmsg.add(mailNonPricing);
                }
            }    
            Messaging.sendEmail(allmsg);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.DEBUG,'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG,'Stack Trace: '+ex.getStackTraceString());
        }
    }
    
    /*
* Method Name: handleInboundEmail
* Purpose: this method is used to receive the email sent to email service
* 			and resend the approver email for pending approvals  
*/
    public static Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail oInboundEmail, Messaging.InboundEnvelope oInboundEnvelope){
        Messaging.InboundEmailResult oInboundEmailResult = new Messaging.InboundEmailResult();
        try {
            String subject= oInboundEmail.subject;
            Pattern pat = Pattern.compile('([0-9]+)');
            Matcher matcher = pat.matcher(subject);
            Boolean matches = matcher.find();
            String cusReqNumber;
            if(matches){
                cusReqNumber = 'CUS-'+matcher.group(1);
            }
            String firstLine = oInboundEmail.plainTextBody.split('\n')[0];  
            String action;
            if(firstLine.containsIgnoreCase('Approved') || firstLine.containsIgnoreCase('approve') || firstLine.containsIgnoreCase('yes')){
                action = 'Approve';
            }
            else if(firstLine.containsIgnoreCase('Rejected') || firstLine.containsIgnoreCase('reject') || firstLine.containsIgnoreCase('no')){
                action = 'Reject';
            }
            String comments = oInboundEmail.plainTextBody.split('\n')[1]; 
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(comments);
            req.setAction(action);                
            Customer_Request__c cusReq = [SELECT Id FROM Customer_Request__c WHERE Name =: cusReqNumber WITH SECURITY_ENFORCED][0];
            
            Id piwId = getApprovalStepId(oInboundEmail.fromAddress, cusReq.Id ) ;
            req.setWorkitemId(piwId);
            Approval.ProcessResult result =  Approval.process(req);
            System.debug(LoggingLevel.DEBUG,result.isSuccess());
        } 
        catch (Exception e) {
            System.debug(LoggingLevel.DEBUG,'=== ID_Item.handleInboundEmail(...): ERROR: `e=' + e + '`');
            return oInboundEmailResult;
        }
        oInboundEmailResult.success = true;
        return oInboundEmailResult;
        
    }
    
    /*
* Method Name: getApprovalStepId
* Purpose: this method is used to retrive the approval step to update based 
on the approval email response
*/
    public static Id getApprovalStepId(String fromAddress, Id cusReqId){
        Set<Id> approverIds = new Set<Id>();
        for(User approver : [SELECT Id FROM User WHERE Email =: fromAddress AND 
                             isActive = True WITH SECURITY_ENFORCED]){
                                 approverIds.add(approver.Id);
                             }
        Id piwId;
        for(ProcessInstanceWorkitem piw : [SELECT Id,ActorId  FROM ProcessInstanceWorkitem WHERE  ProcessInstance.TargetObjectId =:cusReqId
                                           AND ProcessInstance.Status = 'Pending' WITH SECURITY_ENFORCED]){
                                               if(approverIds.contains(piw.ActorId)){
                                                   piwId = piw.Id;
                                                   break;
                                               }
                                           }
        return piwId  ;
    }
}