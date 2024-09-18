global class EmailPublisherLoader implements QuickAction.QuickActionDefaultsHandler {
    // Empty constructor
    global EmailPublisherLoader() {
    }
     // The main interface method
     global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults =
        (QuickAction.SendEmailQuickActionDefaults) defaults.get(0);
        List<id> toid= new  List<id>();
      if (sendEmailDefaults != null) {
            Case caserecord = [SELECT Status, Sales_Org__c, Reason,Origin,Owner.Email FROM Case 
                      WHERE Id=:sendEmailDefaults.getContextId()];
            if(caserecord != null && caserecord.Origin =='Diageo One'){
            EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();    
            // Set bcc address to make sure each email goes for audit
            emailMessage.BccAddress = caserecord.Owner.Email;
            emailMessage.ToAddress  = '';
            emailMessage.ValidatedFromAddress=System.Label.D1_Existing_Queries;
            emailMessage.CcAddress='';
            emailMessage.ToIds=toid;
            /* 
            Set Template related fields 
            When the In Reply To Id field is null we know the interface 
            is called on page load. Here we check if 
            there are any previous emails attached to the case and load 
            the 'New_Case_Created' or 'Automatic_Response' template.
            When the In Reply To Id field is not null we know that 
            the interface is called on click of reply/reply all 
            of an email and we load the 'Default_reply_template' template
            */
               Integer emailCount = [SELECT count() FROM EmailMessage 
                                      WHERE ParentId=:sendEmailDefaults.getContextId()];
                                      system.debug('emailCount==>'+emailCount);
                system.debug(sendEmailDefaults.getInReplyToId());
               // if(sendEmailDefaults.getInReplyToId() != null){
                if(caserecord.Sales_Org__c != null && caserecord.Sales_Org__c != '' && System.Label.C360_Sales_Ogs_for_Email_Template.contains(caserecord.Sales_Org__c))
                {
                    sendEmailDefaults.setTemplateId(
                            getTemplateIdHelper('C360_EXTERNAL_Template'));
                }else if (emailCount!= null && emailCount > 0) {
                            sendEmailDefaults.setTemplateId(
                                getTemplateIdHelper('D1_EXTERNAL_Template'));
                        } else {
                            sendEmailDefaults.setTemplateId(
                                getTemplateIdHelper('D1_EXTERNAL_Template'));
                        }
                        sendEmailDefaults.setInsertTemplateBody(true);
                        sendEmailDefaults.setIgnoreTemplateSubject(false);
                    }else {
                        
                        sendEmailDefaults.setInsertTemplateBody(false);
                        sendEmailDefaults.setIgnoreTemplateSubject(true);
                    }
                //}
                
           
        }
    }
    
    private Id getTemplateIdHelper(String templateApiName) {
        Id templateId = null;
        try {
            templateId = [select id, name from EmailTemplate 
                          where developername = : templateApiName].id;   
        } catch (Exception e) {
            system.debug('Unble to locate EmailTemplate using name: ' + 
                templateApiName + ' refer to Setup | Communications Templates ' 
                    + templateApiName);
        }
        return templateId;
    }

}