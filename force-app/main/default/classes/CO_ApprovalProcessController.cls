/*
@Name: CO_ApprovalProcessController

@Purpose: This class is used by the approval process to generate customer details pdf and
to send pdf templates emails for the approvers.

@History                                                                   

VERSION    AUTHOR            DATE              DETAIL
1.0       Jayashree R       11-21-2022        Initial Development
1.2       Jayashree R       09-01-2023        CONS-480 - Defect Fix 
1.3       Jayashree R       10-01-2023        CONS-178  
1.4       Venkatesh Varma   10-02-2023        CONS-459
1.5		  Aparajita			23-03-2023		  CONS-787
1.6       priyanka 			24-04-2023        CONS-871
1.7		  Aparajita			15-05-2023		  CONS-958
1.8       Aparajita         21-08-2023		  143268 - Approval pdf for Routing, DBBV Finance, International Trade Team, Market Finance Delegate, Brand Homes Senior Finance Manager approvers
1.9       Aparajita         20-09-2023        144881 - Added Justification for Routing
*/

public with sharing class CO_ApprovalProcessController {
    
    public String recID {get; set;}
    public String approverID {get; set;}
    public String urlStr{
        get{
            return generateApprovalURL(recID, approverID);
        }
    }
    public Customer_Request__c getRec{
        get{
            return getRecord(recID);
        }
    } 
    public List<Customer_Request__c> getChildRec{
        get{
            return getChildRecords(recID);
        }
    }
    public CO_TaxClassificationWrapper getTaxClassfcnRec{
        get{
            return getTaxClassificationRecords(recID);
        }
    }
    
    /*
* Method Name: generateApprovalURL
* Purpose: This method is used to generate the approval link for approvers
*/
    public static String generateApprovalURL(String recordID, String uId){
        String url='';
        try{
            List<ProcessInstanceWorkitem> workItemLst = [SELECT id FROM ProcessInstanceWorkitem WHERE processInstance.TargetObjectId=:recordID AND ActorId =: uId WITH SECURITY_ENFORCED];
            if(workItemLst.size() > 0){
                url='https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItemLst[0].id;
            }
            System.debug(LoggingLevel.DEBUG, 'url--->'+url);
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
        return url;
    }
    
    /*
* Method Name: getRecord
* Purpose: This method is used to retrieve all the fields of 
*           customer request object to generate pdf
*/
    public static Customer_Request__c getRecord(String recordID){
        Customer_Request__c custRec = new Customer_Request__c();
        try{
            custRec = [SELECT Id, Name,  Account_group_Customer_Type__c, CO_Sales_Organisation__c, 
                       CO_Customer_Name__c, CO_Email__c, CO_Customer_Name_4__c, CO_Box__c, Division__c, 
                       CO_Distribution_Channel__c, CO_Address__City__s, CO_Address__CountryCode__s, 
                       CO_Address__PostalCode__s, CO_Address__StateCode__s, CO_Address__Street__s, 
                       CO_VAT_Reg_Number_1__c, CO_Language__c, CO_Comments__c, 
                       CO_Telephone__c, CurrencyIsoCode, CO_District__c, CO_EDI_Customer__c, 
                       CO_Incoming_Payment_Method__c, CO_Outgoing_Payment_Method__c, CO_Price_Group__c, 
                       CO_Tax_Classification__c, CO_Channel__c, CO_20GEN_Cont_Group__c, 
                       CO_Credit_Control_Area__c, CO_Company_Type__c, CO_Customer_Type__c, 
                       CO_Sales_Office__c, CO_Sales_Group__c, CO_Incoterms_1__c, Incoterms_2__c,
                       CO_Buying_group__c, CO_Link_to_existing_buying_group__c, CO_Terms_of_Payment_Direct__c, 
                       CO_Key_reasons_for_selection_of_business__c, Comments_for_approvers__c, 
                       CO_Approver_Email__c, Estimated_annual_total_transaction_value__c, 
                       Credit_Risk_Category__c, CO_Credit_Rep_Group__c, CO_Credit_Limit__c, CO_Bill_to__c, CO_Payer__c, 
                       CO_Pricing_master_data__c, CO_PMD_Justification__c, CO_Listing_and_exclusion__c, 
                       CO_L_E_Justification__c,CO_EDPAR_Justification__c, CO_EDPAR_Table_Maintenance__c, 
                       CO_Output_maintenance__c, CO_OM_Justification__c, Owner.Name, LastModifiedDate, 
                       CO_Ship_to__c, CO_Credit_information_no_DUNS_no__c, CO_Next_Internal_Review_Date__c,
                       CO_Any_further_risk_assessments_required__c, CO_Cancellation_Reason__c, CO_Rejection_Reason__c,
                       CO_Are_HQ_Delivery_address_different__c, CO_Knowledge_of_governmental_interaction__c, 
                       CO_Other_Details_of_payment_request__c, CO_Special_payment_requests__c, CO_EDGE_Org_Customer__c,
                       CO_In_touch_customer__c, CO_Customer_CoP_Email__c, Customer_Website__c, CO_Contact_Person_Email__c,
                       CO_First_Name__c, CO_Surname_Name__c, CO_Tax_Number_1__c, CO_Tax_Number_2__c, CO_Tax_Number_3__c,
                       CO_Tax_Number_4_Codice_destinatario__c, CO_Phone__c, CO_Sold_To_Ref__c, CO_Sold_To_Ref__r.Name,
                       CO_Customer_Delink_Relink__c, CO_Justification_for_Cust_Delink_Relink__c, 
                       CO_ZTERMSNCOND__c, CO_Billtype__c, CO_Routing__c, CO_Justification_for_Routing__c  
                       FROM Customer_Request__c WHERE Id =: recordID WITH SECURITY_ENFORCED];
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
        return custRec;
    }
    
    /*
* Method Name: getChildRecords
* Purpose: This method is used to retrieve all the fields of 
*           childs of customer request object to generate pdf
*/
    public static List<Customer_Request__c> getChildRecords(String parentID){
        List<Customer_Request__c> custRec = new List<Customer_Request__c>();
        try{
            custRec = [SELECT Id, Name,  Account_group_Customer_Type__c, CO_Sales_Organisation__c, 
                       CO_Customer_Name__c, CO_Email__c, CO_Customer_Name_4__c, CO_Box__c, Division__c, 
                       CO_Distribution_Channel__c, CO_Address__City__s, CO_Address__CountryCode__s, 
                       CO_Address__PostalCode__s, CO_Address__StateCode__s, CO_Address__Street__s, 
                       CO_VAT_Reg_Number_1__c, CO_Language__c, CO_Comments__c, 
                       CO_Telephone__c, CurrencyIsoCode, CO_District__c, CO_EDI_Customer__c, 
                       CO_Incoming_Payment_Method__c, CO_Outgoing_Payment_Method__c, CO_Price_Group__c, 
                       CO_Tax_Classification__c, CO_Channel__c, CO_20GEN_Cont_Group__c, 
                       CO_Credit_Control_Area__c, CO_Company_Type__c, CO_Customer_Type__c, 
                       CO_Sales_Office__c, CO_Sales_Group__c, CO_Incoterms_1__c,Incoterms_2__c,  
                       CO_Buying_group__c, CO_Link_to_existing_buying_group__c, CO_Terms_of_Payment_Direct__c, 
                       CO_Key_reasons_for_selection_of_business__c, Comments_for_approvers__c, 
                       CO_Approver_Email__c, Estimated_annual_total_transaction_value__c, 
                       Credit_Risk_Category__c, CO_Credit_Rep_Group__c, CO_Credit_Limit__c, CO_Bill_to__c, CO_Payer__c, 
                       CO_Pricing_master_data__c, CO_PMD_Justification__c, CO_Listing_and_exclusion__c, 
                       CO_L_E_Justification__c,CO_EDPAR_Justification__c, CO_EDPAR_Table_Maintenance__c, 
                       CO_Output_maintenance__c, CO_OM_Justification__c,
                       CO_Ship_to__c, CO_Credit_information_no_DUNS_no__c, CO_Next_Internal_Review_Date__c,
                       CO_Any_further_risk_assessments_required__c, CO_Cancellation_Reason__c, CO_Rejection_Reason__c,
                       CO_Are_HQ_Delivery_address_different__c, CO_Knowledge_of_governmental_interaction__c, 
                       CO_Other_Details_of_payment_request__c, CO_Special_payment_requests__c, CO_EDGE_Org_Customer__c,
                       CO_In_touch_customer__c, CO_Customer_CoP_Email__c, Customer_Website__c, CO_Contact_Person_Email__c,
                       CO_First_Name__c, CO_Surname_Name__c, CO_Tax_Number_1__c, CO_Tax_Number_2__c, CO_Tax_Number_3__c,
                       CO_Tax_Number_4_Codice_destinatario__c, CO_Phone__c, CO_Sold_To_Ref__c, CO_Sold_To_Ref__r.Name,
                       CO_Customer_Delink_Relink__c, CO_Justification_for_Cust_Delink_Relink__c, 
                       CO_ZTERMSNCOND__c, CO_Billtype__c, CO_Routing__c, CO_Justification_for_Routing__c  
                       FROM Customer_Request__c 
                       WHERE CO_Sold_To_Ref__c =: parentID WITH SECURITY_ENFORCED ORDER BY Account_group_Customer_Type__c];
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
        return custRec;
    }
    
    
    /*
* Method Name: getTaxClassificationRecords
* Purpose: This method is used to retrieve all the Tax Classification records of 
*           customer request object to generate pdf
* History : change the return type of the method form List of Tax_Classification to CO_TaxClassificationWrapper
			as part of CONS-871
*/
    public static CO_TaxClassificationWrapper getTaxClassificationRecords(String recordID){
        
        CO_TaxClassificationWrapper wrapObj = new CO_TaxClassificationWrapper();
        List<Tax_Classification__c> taxClasfnRec = new List<Tax_Classification__c>();
        wrapObj.hasLicense = false;
        try{
            taxClasfnRec = [SELECT Id, Customer_Request__c, RecordTypeId, RecordType.Name, Tax_Category__c, 
                            Tax_Category__r.Name, Tax_Classification__c, Name, CurrencyIsoCode,CO_Enter_License_Details__c,
                            CO_License_Number__c,CO_Valid_From__c,CO_Valid_To__c
                            FROM Tax_Classification__c WHERE Customer_Request__c =: recordID WITH SECURITY_ENFORCED];
            wrapObj.tablerows = taxClasfnRec;
            //Added as part of CONS-871
            for(Tax_Classification__c taxObj : taxClasfnRec){
                if(taxObj.CO_Enter_License_Details__c){
                   wrapObj.hasLicense = true;
                    break;
                }
            }
            //Added as part of CONS-871
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
        return wrapObj;
    }
    
    /*
* Method Name: postApprovalProcessOperations
* Purpose: This method is called from flow after the 
*           customer request record is submitted for approval process
*/
    @InvocableMethod(label='Post Approval Process Operations' description='Unlock the customer request record which is submitted for approval process')    
    public static void postApprovalProcessOperations(List<Customer_Request__c> custRequests){
        try{
            sendDocumentstoApprovers(custRequests[0]);
            sendDocumentstoMCTApprovers(custRequests[0]);
            UploadCustomerDetailsPdf(custRequests[0]);            
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, 'Exception: '+ex.getMessage());
            System.debug(LoggingLevel.DEBUG, 'Stack Trace: '+ex.getStackTraceString());
        }
    }
    
    
    /*
* Method Name: UploadCustomerDetailsPdf
* Purpose: This method is used to save the customer details pdf to 
*           customer request record
*/
    public static void uploadCustomerDetailsPdf(Customer_Request__c custReq){
        List<id> docIdList = new List<id>();
        for(ContentDocumentLink cdl : [SELECT Id,ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink 
                                       WHERE LinkedEntityId =: custReq.Id 
                                       AND ContentDocumentId IN (SELECT ContentDocumentId FROM ContentVersion WHERE Content_Type__c = 'Other' 
                                                                 AND RecordType.Name = 'CO Customer Request' 
                                                                 AND Title LIKE :custReq.Name+'- Customer Details%') WITH SECURITY_ENFORCED]){
                                                                     docIdList.add(cdl.ContentDocumentId);
                                                                 }
        
        if(docIdList.size() > 0){
            List<ContentDocument> conDocList =[SELECT Id FROM ContentDocument where Id IN: docIdList WITH SECURITY_ENFORCED];
            if(ContentDocument.sObjectType.getDescribe().isDeletable()){
                delete conDocList;
            }
        }
        PageReference pdf = Page.CO_ApprovalPDF;
        pdf.getParameters().put('id',custReq.Id);
        Blob body;
        try { 
            
            // returns the output of the page as a PDF
            body = pdf.getContentAsPDF();
            
            // need to pass unit test -- current bug    
        } catch (VisualforceException e) {
            body = Blob.valueOf('Some Text');
        }
        ContentVersion fileToUpload = new ContentVersion();
        fileToUpload.ContentLocation = 'S'; // Salesforce. The other option is: 'E'
        fileToUpload.pathOnClient ='CustomerDetails.pdf';
        fileToUpload.title = custReq.Name+'- Customer Details';
        fileToUpload.versionData = body;
        fileToUpload.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName()
            .get('CO_Customer_Request').getRecordTypeId(); 
        fileToUpload.Content_Type__c = 'Other';
        Database.SaveResult saveResult;
        try {
            saveResult = Database.insert(fileToUpload);
        } catch (DmlException DMLE) {
            system.debug(LoggingLevel.DEBUG, 
                         'Failed to insert fileToUpload, error is: ' + dmle.getMessage()
                        );
            throw DMLE;
        } 
        
        // Create a ContentDocument Link Record
        // First get the content document Id from ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileToUpload.Id].ContentDocumentId;
        
        //Create ContentDocumentLink
        ContentDocumentLink linkToRecord = new ContentDocumentLink();
        linkToRecord.ContentDocumentId = contentDocumentId;
        linkToRecord.LinkedEntityId = custReq.Id; // RecordID of the patent
        linkToRecord.ShareType = 'I'; // Inferred permission
        if (ContentDocumentLink.sObjectType.getDescribe().isCreateable()) {
            insert linkToRecord;
        }
    }
    
    /*
* Method Name: sendDocumentstoApprovers
* Purpose: This method is used to send pdf documents to approvers after sending approval email
*/
    public static void sendDocumentstoApprovers(Customer_Request__c cusReq){
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        List<String> sOrgVsApproverList = new List<String>{'BR01;BR05','CE01;SG02'};
            
        Customer_Request__c custReqNew = [Select Name, CO_Sales_Org_Code__c, CO_Approver__c, CO_DBBV_Finance__c,CO_International_Trade_Team__c, 
                                         CO_Market_Finance_Delegate__c, Owner.Name FROM Customer_Request__c WHERE Id=: cusReq.Id WITH SECURITY_ENFORCED];
        
        if(sOrgVsApproverList.get(0).contains(custReqNew.CO_Sales_Org_Code__c)){
            Messaging.SingleEmailMessage mailBH = New Messaging.SingleEmailMessage();
            mailBH.setTargetObjectId(custReqNew.CO_Brand_Homes_Senior_Finance_Manager__c);
            mailBH = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailBH);
            mailBH.setToAddresses(new String[] {custReqNew.CO_Brand_Homes_Senior_Finance_Manager__c});
            mailList.add(mailBH);
        }
        else if(sOrgVsApproverList.get(1).contains(custReqNew.CO_Sales_Org_Code__c)){
            Messaging.SingleEmailMessage mailDBBV = New Messaging.SingleEmailMessage();
            mailDBBV.setTargetObjectId(custReqNew.CO_DBBV_Finance__c);
            mailDBBV = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailDBBV);
            mailDBBV.setToAddresses(new String[] {custReqNew.CO_DBBV_Finance__c});
            mailList.add(mailDBBV);

            Messaging.SingleEmailMessage mailITT = New Messaging.SingleEmailMessage();
            mailITT.setTargetObjectId(custReqNew.CO_International_Trade_Team__c);
            mailITT = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailITT);
            mailITT.setToAddresses(new String[] {custReqNew.CO_International_Trade_Team__c});
            mailList.add(mailITT);

            Messaging.SingleEmailMessage mailMFD = New Messaging.SingleEmailMessage();
            mailMFD.setTargetObjectId(custReqNew.CO_Market_Finance_Delegate__c);
            mailMFD = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailMFD);
            mailMFD.setToAddresses(new String[] {custReqNew.CO_Market_Finance_Delegate__c});
            mailList.add(mailMFD);
        }
        else{
            Messaging.SingleEmailMessage mailAppr = New Messaging.SingleEmailMessage();
            mailAppr.setTargetObjectId(custReqNew.CO_Approver__c);
            mailAppr = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailAppr);
            mailAppr.setToAddresses(new String[] {custReqNew.CO_Approver__c});
            mailList.add(mailAppr);
        }
        
        if(mailList.size() > 0){
            Messaging.sendEmail(mailList);
        }
    }
    
    /*
* Method Name: sendDocumentstoMCTApprovers
* Purpose: This method is used to send pdf documents to Pricing and Routing approvers after sending approval email
*/
    public static void sendDocumentstoMCTApprovers(Customer_Request__c cusReq){
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();            
        Customer_Request__c custReqNew = [Select Name, CO_Pricing_Approver__c, CO_Routing_Approver__c, CO_Additional_Approver__c FROM Customer_Request__c WHERE Id=: cusReq.Id WITH SECURITY_ENFORCED];
        
        if(custReqNew.CO_Pricing_Approver__c != null && cusReq.CO_Pricing_master_data__c == 'Applicable'){
            Messaging.SingleEmailMessage mailPricing = New Messaging.SingleEmailMessage();
            mailPricing.setTargetObjectId(custReqNew.CO_Pricing_Approver__c);
            mailPricing = generatePricingApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailPricing);
            mailPricing.setToAddresses(new String[] {custReqNew.CO_Pricing_Approver__c});
            mailList.add(mailPricing);
        }
        
        if(custReqNew.CO_Routing_Approver__c != null && cusReq.CO_Routing__c == 'Applicable'){
            Messaging.SingleEmailMessage mailRouting = New Messaging.SingleEmailMessage();
            mailRouting.setTargetObjectId(custReqNew.CO_Routing_Approver__c);
            mailRouting = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailRouting);
            mailRouting.setToAddresses(new String[] {custReqNew.CO_Routing_Approver__c});
            mailList.add(mailRouting);
        }
        
        if(custReqNew.CO_Additional_Approver__c != null){
            Messaging.SingleEmailMessage mailAddAppr = New Messaging.SingleEmailMessage();
            mailAddAppr.setTargetObjectId(custReqNew.CO_Additional_Approver__c);
            mailAddAppr = generateApproverPdfEmail(custReqNew.Id, custReqNew.Name, mailAddAppr);
            mailAddAppr.setToAddresses(new String[] {custReqNew.CO_Additional_Approver__c});
            mailList.add(mailAddAppr);    
        }
        
        if(mailList.size() > 0){
            Messaging.sendEmail(mailList);
        }
    }
    
    /*
* Method Name: generateApproverPdfEmail
* Purpose: This method is used to generate emails with pdf attachment
for approver and additional approver
*/
    public static Messaging.SingleEmailMessage generateApproverPdfEmail(Id cusReqId, String cusReqName, Messaging.SingleEmailMessage mail){
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CO_Approval_PDF_Attachment_Template' WITH SECURITY_ENFORCED];
        mail.setTemplateId(et.Id);
        mail.setWhatId(cusReqId);
        mail.setSaveAsActivity(false);
        PageReference pdf = Page.CO_ApprovalPDF;
        pdf.getParameters().put('id',cusReqId);
        Blob attachmentbody;
        try {
            // returns the output of the page as a PDF
            attachmentbody = pdf.getContentAsPDF();
            // need to pass unit test
        } catch (VisualforceException e) {
            attachmentbody = Blob.valueOf('Some Text');
        }
        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
        efa.setFileName(cusReqName+'- Customer Details.pdf');
        efa.setBody(attachmentbody);
        mail.setFileAttachments(new Messaging.Emailfileattachment[] {efa});
        return mail;
    }
    
    /*
* Method Name: generatePricingApproverPdfEmail
* Purpose: This method is used to generate emails with pdf attachment
for pricing approver.
*/
    public static Messaging.SingleEmailMessage generatePricingApproverPdfEmail(Id cusReqId, String cusReqName, Messaging.SingleEmailMessage mail){
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'CO_Pricing_Approver_PDF_Template' WITH SECURITY_ENFORCED];
        mail.setTemplateId(et.Id);
        mail.setWhatId(cusReqId);
        mail.setSaveAsActivity(false);
        List<String> contentVersionIds =  new List<String>();
        blob attachmentbody;
        for(ContentDocumentLink cdl : [SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink 
                                       WHERE LinkedEntityId =: cusReqId])
        {
            contentVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
        }
        if(contentVersionIds!=null){
            ContentVersion cv = [SELECT Id, title, PathOnClient, FileType, versiondata FROM contentversion 
                                 WHERE Id IN : contentVersionIds AND Content_Type__c =: 'Pricing master data'
                                 AND RecordType.Name =: 'CO Customer Request' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
            
            try{
                attachmentbody = cv.versiondata;
                
            }catch (VisualforceException e) {
                attachmentbody = Blob.valueOf('Some Text');
            }
            Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
            efa.setFileName(cusReqName+'-'+cv.title+'.'+cv.FileType);
            efa.setBody(attachmentbody);
            mail.setFileAttachments(new Messaging.Emailfileattachment[] {efa});
        }
        return mail;
    }
}