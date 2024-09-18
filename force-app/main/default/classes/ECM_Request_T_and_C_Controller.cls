/**********************************************************************
Name: ECM_Request_T_and_C_Controller
=======================================================================
Purpose: This Class is used in Request Addendum button on Contract detail page
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Chandrakanth Suram      19/01/2021        Notification sent based on contract country for ECM-3686


***********************************************************************/ 

public class ECM_Request_T_and_C_Controller {
    @AuraEnabled
    public static contract getcontractdetails(string contractId){
        system.debug('contractId'+contractId);
        Contract conObj=[Select Id,Name,Status from contract where id=:contractId];
        return conObj;
    }
    
    @AuraEnabled
    public static void submitAddendumRequest(string contractId,string notestolegalstr){
        Contract conrec=[Select Id,Status,account.country__r.Code__c from Contract where Id=:contractId];
        conrec.Status='Legal Review';
        update conrec;
        
        ECM_Addendum__c addendum=New ECM_Addendum__c();
        addendum.ECM_Status__c ='In Approval';
        addendum.ECM_Addendum_Type__c='T&C (Terms & Conditions)';
        addendum.ECM_Contract__c=contractId;
        addendum.ECM_Notes_to_Legal__c =notestolegalstr;
        insert addendum;
       	String countrycode = conrec.account.country__r.Code__c;
       
        /* String countryName;
       
       User usrobj=[Select Id,Name,Available_Countries__c from User where id=:Userinfo.getUserId()];
        if(usrobj.Available_Countries__c=='AU'){
            countryName='Australia';
        }
        if(usrobj.Available_Countries__c=='ES'){
            countryName='Spain';
        }
        */
        Market_Setting__c AUMarket=[Select Id,Name,ECM_Legal_Notifications__c from Market_Setting__c where Geography__r.Code__c=:countrycode];
        system.debug('AUMarket'+AUMarket);
        if(AUMarket.ECM_Legal_Notifications__c !=null){
            system.debug('enter email');
            string emailstr=AUMarket.ECM_Legal_Notifications__c;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {emailstr}; 
            //    String[] ccAddresses = new String[] {'testcc1@mail.com','testcc1@mail.com'};
            mail.setToAddresses(toAddresses);
           // mail.setCcAddresses(ccAddresses);
           // mail.setReplyTo('myemail@mail.com');
           // mail.setSenderDisplayName('My Name');
            mail.setSubject('Addendum Request');
           // mail.setBccSender(false);
           // mail.setUseSignature(false);
            mail.setPlainTextBody('There is a new Terms & Conditions request in your queue to be processed');
            //mail.setHtmlBody('<b> This is HTML body </b>' );
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}