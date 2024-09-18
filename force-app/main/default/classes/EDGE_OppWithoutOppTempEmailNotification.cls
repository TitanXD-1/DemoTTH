/*
* Class Name: EDGE_OppWithoutOppTempEmailNotification
* Test Class: EDGE_OpportunitiesWOTemplateBatchTest
* Brief Description: This class is used to send email notification to the MDMs if there is any Opportunities
                     without opportunity  template
* Created Date: 
* History: 
* VERSION           AUTHOR              DATE                DETAIL
*  1.0              Sudipta Nandy       23/08/2024          155541 - GB Opportunity Scoring: Salesforce Email Notification to MDMs on Opportunities without Templates
*/
public with sharing class EDGE_OppWithoutOppTempEmailNotification {    
    /**
    * @description : To Send Email Notification to MDM
    * @param : countryCode
    */
    public static void sendEmail(String countryCode){
        String emailBody;
        String listViewURL = URL.getOrgDomainURL().toExternalForm()+System.label.EDGE_Opp_w_o_Opp_Temp_List_View;
        String embeddedLink = '<a href="'+listViewURL+'">LINK</a>';
        String queueName = countryCode+'_MDM';
        List<String> emailList = new List<String>();
        String languageName;
        List<Market_Setting__c> marketSettingList = [SELECT Id,Language__c FROM Market_Setting__c WHERE Geography__r.Code__c =:countryCode with SECURITY_ENFORCED];
        if(marketSettingList.size() >0){
            languageName = marketSettingList[0].Language__c != null ? marketSettingList[0].Language__c: 'en_US';
        }
        Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_emailBodyLine1','EDGE_emailBodyLine2','EDGE_emailSubject'}, languageName);        
        for(GroupMember member : [SELECT UserOrGroup.Email FROM GroupMember WHERE Group.name =:queueName AND Group.type='Queue' with SECURITY_ENFORCED ]){   
            emailList.add(member.UserOrGroup.Email);
        }
        emailBody = labelToTranslatedStrMap.get('EDGE_emailBodyLine1') + '<br></br>';
        emailBody += labelToTranslatedStrMap.get('EDGE_emailBodyLine2') + '<br></br>';
        emailBody += embeddedLink;
        String emailSubject = labelToTranslatedStrMap.get('EDGE_emailSubject');
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();    
        message.setSubject(emailSubject);
        message.setHtmlBody(emailBody);
        message.setToAddresses(emailList);
        if(emailList.size() >0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { message });            
            if (results[0].success) 
            {
                System.debug(LoggingLevel.Debug,'The email was sent successfully.');
            } else {
                System.debug(LoggingLevel.Debug,'The email failed to send: ' +  results[0].errors[0].message);
            } 
        }
    }
}