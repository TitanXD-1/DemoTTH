/*
Name: EDGE_CoachingFormService

Purpose: 

History                                                            
-                                                          
VERSION   AUTHOR            	DATE              DETAIL
1.0       Preyanka Ghosh      18/09/2019        ES20-5910
2.0		  Sagar Barman		  10/12/2019		ES20-6347
3.0       Mayukh S Roy        27/06/2023        298236
*/
@RestResource(urlMapping='/CoachingFormService/*')
global with sharing class EDGE_CoachingFormService {
    
    @HttpGet
    global static ContentVersion doGet() { // http method can't return Blob
        Id coachingReportId = RestContext.request.params.get('coachingReportId');
        String language = UserInfo.getLanguage(); //298236 - To get User Language and set it as a Parameter.
        PageReference coachingPage = new PageReference('/apex/EDGE_CoachingReportPDF?id=' + coachingReportId + '&label_lang='+language); //298236 - Added LabelLang
        ContentVersion cont = new ContentVersion(); 
        if(Test.isRunningTest()){
            cont.VersionData = blob.valueOf('Hi');            
        } else {
            cont.VersionData = coachingPage.getContentAsPdf();              
        } 
        /**** Send Email with the pdf to Sales Rep and Manager */       
        sendEmail(coachingReportId,cont);
        return cont;        
    }
    //Send Email with the pdf to Sales Rep and Manager/
    public static void sendEmail(Id coachingReportId,ContentVersion cont){ 
        Coaching_Report__c coachingReport=new Coaching_Report__c();
        //Added Schema.SObjectType.Coaching_Report__c.isAccessible() && Schema.SObjectType.Survey__c.isAccessible() --by Divya
        if(Schema.SObjectType.Coaching_Report__c.isAccessible() && Schema.SObjectType.Survey__c.isAccessible() && Schema.SObjectType.User.isAccessible()){
            coachingReport = [SELECT Id, Name,Content_Document_Id__c, Survey__r.Name, Sales_Representative__r.Email, 
                              Original_Sales_Manager__r.Email, Current_Sales_Manager__r.Email From Coaching_Report__c Where Id =: coachingReportId WITH SECURITY_ENFORCED LIMIT 1];
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();        
        toAddresses.add(coachingReport.Sales_Representative__r.Email);
        toAddresses.add(coachingReport.Current_Sales_Manager__r.Email);   
        system.debug(LoggingLEVEL.DEBUG,'coachingReport.Sales_Representative__r.Email '+coachingReport.Sales_Representative__r.Email);
        mail.setToAddresses(toAddresses);        
        mail.setSubject(Label.EDGE_CoachingFormMailSubject);
        mail.plaintextbody = Label.EDGE_CoachingFormMailBody +coachingReport.Survey__r.Name+ '.';
        //Set Email File Attachments
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Messaging.Emailfileattachment emailFileAttac = new Messaging.Emailfileattachment();
        emailFileAttac.setFileName( coachingReport.Name+'.'+'pdf');
        emailFileAttac.setBody(cont.versiondata); 
        fileAttachments.add(emailFileAttac);
        mail.setFileAttachments(fileAttachments);
        // at the end send Email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});        
    }
}