/*
@Name: CO_CustomerEmailController

@Purpose: This class is used to send the documents as an attachment along with the email template to the customers.

@History                                                                   

VERSION    AUTHOR                  DATE              DETAIL
1.0        Abhishek & Anamika      12-07-2023        Initial Development
1.1        Anamika                 24-08-2023        USER STORY 144398
1.2        Anamika 				   07-08-2023		 User Story 144822
1.3        Anamika                 18/09/2023        User Story 145718,145315
*/

public with sharing class CO_CustomerEmailController {
    /*
* Method Name: sendEmailtoCustomerswithAttachment
* Purpose: This method is used to send the Email to Customer with Documents as an Attachment.
*/ 
    @InvocableMethod(label='Send Email to Customers' description='sends an email to customers with an attachment post the record is successfully created in RDDC')    
    public static void sendEmailtoCustomerswithAttachment(List<Customer_Request__c> custRequests){
        try{
            sendDocumentstoCustomers(custRequests[0]);            
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
    }
    
    /*
* Method Name: sendDocumentstoCustomers
* Purpose: This method is used to send the Documents as an Attachment to the Customers.
*/    
    public static void sendDocumentstoCustomers(customer_request__c custReq){
        System.debug(LoggingLevel.DEBUG, 'custReq--->'+custReq);
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        CO_Customer_Email_template_Setting__mdt eTemp = new CO_Customer_Email_template_Setting__mdt();
        
        //DeveloperName not accepting EN-English in metadata
        eTemp = (custReq.CO_Language__c == 'EN-English' ? CO_Customer_Email_template_Setting__mdt.getInstance('eng'):CO_Customer_Email_template_Setting__mdt.getInstance(custReq.CO_Language__c));
        
        EmailTemplate et = [SELECT Id, Body,Name FROM EmailTemplate WHERE Name =: eTemp.CO_Email_Template_Name__c WITH SECURITY_ENFORCED];
        System.debug(LoggingLevel.DEBUG, 'et--->'+et);
        mail.setTemplateId(et.Id);
        mail.setHtmlBody(et.Body); 
        mail.setTargetObjectId(custReq.OwnerId); 
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setWhatId(custReq.Id);
        mail.setSaveAsActivity(false);
        
        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
        ContentVersion cv = getContentVersion(custReq);        
        System.debug(LoggingLevel.DEBUG, 'cv--->'+cv);
        efa.setFileName(cv.Title);
        efa.setBody(cv.VersionData);
        
        // Start- modified as a part of US - 145718,145315
        List<Customer_Request__c> cusList = new List<Customer_Request__c>();
        cusList = [SELECT Id,CO_Sales_Person_Email__c,CO_Customer_CoP_Email__c,CO_Sales_Organisation__r.CO_Requestor_DL_Email__c,Owner.Email 
                   FROM Customer_Request__c WHERE Id =:custReq.Id WITH SECURITY_ENFORCED LIMIT 1 ];
        List<String> ccToList = new List<String>();
        if(!cusList.isEmpty()){
            if(!cusList.isEmpty() && String.isNotBlank(cusList[0].CO_Sales_Person_Email__c )){
                ccToList.add(cusList[0].CO_Sales_Person_Email__c);
            }
            if(!cusList.isEmpty() && String.isNotBlank(cusList[0].CO_Sales_Organisation__r.CO_Requestor_DL_Email__c )){
                ccToList.add(cusList[0].CO_Sales_Organisation__r.CO_Requestor_DL_Email__c);
            }
            ccToList.add(cusList[0].Owner.Email);  
            ccToList.add(cusList[0].CO_Customer_CoP_Email__c);
        }
        mail.setFileAttachments(new Messaging.Emailfileattachment[] {efa});            
        mail.setToAddresses(new String[] {custReq.CO_Contact_Person_Email__c});
        mail.setCCAddresses(ccToList);
        mailList.add(mail);
        //END
        Messaging.sendEmail(mailList);
    }
 
        /*
* Method Name: getContentVersion
* Purpose: This method is used to get the Content Version to send as an Attachment to the Customers.
*/    
    public static ContentVersion getContentVersion(customer_request__c custReq){
        ContentVersion  cv = new ContentVersion();
        try{
            Id directCustRecordTypeId = Schema.SObjectType.Customer_Request__c.getRecordTypeInfosByDeveloperName().get('Direct_Customer').getRecordTypeId();
            Id indirectCustRecordTypeId = Schema.SObjectType.Customer_Request__c.getRecordTypeInfosByDeveloperName().get('Indirect_Customer').getRecordTypeId();
            
            List<String> transactionValueList = System.Label.CO_Projected_annual_total_transaction_value_for_indirect_1.split(',');
            List<String> totaltransactionValueList = System.Label.CO_Projected_annual_total_transaction_value_for_indirect_2.split(',');      
            
            ID workspaceId = [SELECT Id FROM ContentWorkspace WHERE Name = 'Customer Onboarding'][0].Id;
            System.debug(LoggingLevel.DEBUG, 'workspaceId--->'+workspaceId);
                    
            if(custReq.RecordTypeId == directCustRecordTypeId){ 
                cv = [SELECT Id, title, versiondata, CO_Document_type__c, RecordType.Name,CO_Sales_Organisation__c,CO_Language_for_KYC__c FROM contentversion 
                      WHERE ContentDocument.ParentId = :workspaceId AND Content_Type__c = 'Other' 
                      AND CO_Document_type__c = 'Direct' AND CO_Language_for_KYC__c =:custReq.CO_Language__c
                      AND CO_Sales_Organisation__c INCLUDES (:custReq.CO_Sales_Org_Code__c) WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
            }else if((custReq.RecordTypeId == indirectCustRecordTypeId) && (transactionValueList.Contains(custReq.Estimated_annual_total_transaction_value__c))){
                cv = [SELECT Id, title, versiondata, CO_Document_type__c, RecordType.Name FROM contentversion 
                      WHERE ContentDocument.ParentId = :workspaceId AND Content_Type__c = 'Other' 
                      AND CO_Document_type__c =: System.Label.CO_Document_type_1 
                      AND CO_Language_for_KYC__c =:custReq.CO_Language__c 
                      AND CO_Sales_Organisation__c INCLUDES (:custReq.CO_Sales_Org_Code__c) WITH SECURITY_ENFORCED 
                      ORDER BY CreatedDate DESC LIMIT 1];
            } else if((custReq.RecordTypeId == indirectCustRecordTypeId) && (totaltransactionValueList.Contains(custReq.Estimated_annual_total_transaction_value__c))){
                cv = [SELECT Id, title, versiondata, CO_Document_type__c, RecordType.Name FROM contentversion 
                      WHERE ContentDocument.ParentId = :workspaceId AND Content_Type__c = 'Other' 
                      AND CO_Document_type__c =: System.Label.CO_Document_type_2
                      AND CO_Language_for_KYC__c =:custReq.CO_Language__c
                      AND CO_Sales_Organisation__c INCLUDES (:custReq.CO_Sales_Org_Code__c) WITH SECURITY_ENFORCED 
                      ORDER BY CreatedDate DESC LIMIT 1];
            }            
        }      
        catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
        return cv;
    }
}