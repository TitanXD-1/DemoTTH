global class CC_ProductionManagerEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        string approvercomments, status, InvestigationId;
        if(email.subject !=null){
            InvestigationId = email.subject.substringBetween('[',']').trim();
            status = email.subject.substringAfterLast(' ').trim();
            system.debug('rec name'+InvestigationId);
            system.debug('status'+status);
        }
        If(InvestigationId !=null){
            CC_Investigation__c invrec=[Select Id,Name,CC_Case__r.owner.email,CC_Case__r.CC_Team_Leader__c,CC_Production_Manager_Approval_Comments__c,CC_Investigation_Status__c from CC_Investigation__c where Name=:InvestigationId];
            if(status.equalsIgnoreCase('Approved') || status.equalsIgnoreCase('Approve')){
                invrec.CC_Investigation_Status__c ='Approved';            }
            else if(status.equalsIgnoreCase('Rejected') || status.equalsIgnoreCase('Reject')){
                invrec.CC_Investigation_Status__c ='Rejected';                
            }
            for(integer i=0;i<email.plainTextBody.split('\n').size();i++ ){
                    if(i>0){
                        approvercomments =approvercomments==Null?email.plainTextBody.split('\n')[i]+' ':approvercomments+email.plainTextBody.split('\n')[i]+' ';                
                    }
            }
            invrec.CC_Production_Manager_Approval_Comments__c =approvercomments;
            try{
                update invrec;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                string toaddress= invrec.CC_Case__r.owner.email;
                if(status.equalsIgnoreCase('Rejected') || status.equalsIgnoreCase('Reject')){
                    toaddress=toaddress+','+invrec.CC_Case__r.CC_Team_Leader__c;
                }
                String[] toaddressCol = toaddress.split(',');
                message.toAddresses = toaddressCol;
                message.subject = email.subject;
                message.htmlbody = 'Dear User,<br/><br/> Investingation-'+invrec.Name+' is &nbsp;'+invrec.CC_Investigation_Status__c+'&nbsp; with following comments.<br/>'+
                    				+invrec.CC_Production_Manager_Approval_Comments__c+'<br/><br/>Thanks';
                message.setUseSignature(false); 
                message.setCharset('UTF8');
                System.debug('message value =============>' + message);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
                result.success =true;
            }catch(exception e){
               result.success =false; 
            }
        }
        return result;
    }
}