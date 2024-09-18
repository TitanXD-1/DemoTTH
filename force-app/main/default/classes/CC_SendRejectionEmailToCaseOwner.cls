public class CC_SendRejectionEmailToCaseOwner {
    
    @AuraEnabled
    public static Boolean checkStatus(Id recordId){
        CC_Customer_Concern__c cc = [SELECT Id, CC_Status__c FROM CC_Customer_Concern__c WHERE Id =: recordId];
        if(cc.CC_Status__c == 'Under Investigation')
            return true;
        else
            return false;
    }
    
    @AuraEnabled
    public static void sendMail(Id recordId){
        CC_Customer_Concern__c cc = [SELECT Id, CC_Case__c, CC_Case__r.CaseNumber,
                                     CC_Rejected_Comments__c, CC_Case__r.CC_CSE__r.Name, CC_Case__r.Owner.Email
                                     FROM CC_Customer_Concern__c WHERE Id =: recordId];
        String currentUser = UserInfo.getName();
        Messaging.reserveSingleEmailCapacity(1);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String> {cc.CC_Case__r.Owner.Email});
        mail.setSenderDisplayName(currentUser);
        mail.setSubject('Concern '+cc.CC_Case__r.CaseNumber+' Rejection Notification');
        String body = 'Hi';
        body += '<br><br>';
        body += 'The Final report for the concern '+cc.CC_Case__r.CaseNumber+' has been rejected with the below comments.';
        body += '<br><br>';
        body += 'Comments: '+cc.CC_Rejected_Comments__c;
        body += '<br><br><br>';
        body += 'Thanks,';
        body += '<br>'+cc.CC_Case__r.CC_CSE__r.Name;
        mail.setHtmlBody(body);
        if(!Test.isRunningTest())
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}