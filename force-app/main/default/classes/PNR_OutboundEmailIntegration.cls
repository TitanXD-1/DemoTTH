/**********************************************************************
@name PNR_OutboundEmailIntegration

@description This is the Controller class for PNR_OutboundEmailIntegration

History                                                            
                                                           
VERSION    AUTHOR            DATE              DETAIL
1.0        Sudipta Nandi     08-06-2019        Initial Development
***********************************************************************/

public with sharing class PNR_OutboundEmailIntegration {
    /***************************************
* Name : PNR_OutboundEmailIntegration
* @description  This method is used to fetch caseInfo based on CaseId 
****************************************/
    public static String htmlBody;
    @AuraEnabled
    public static list<Invoice_Line_Item__c> fetchInvoiceLineItems(String invoiceId, String claimedInvoiceLineItems) {
        set<String> ids = new  set<String>();
        //System.debug('claimedInvoiceLineItems=============>' + claimedInvoiceLineItems);
        list<Invoice_Line_Item__c> invoiceLineItemInfo = new list<Invoice_Line_Item__c>();
        for(String str:claimedInvoiceLineItems.split(';')){
            ids.add(str);
        }
        try{
            if(Schema.sObjectType.Invoice_Line_Item__c.isAccessible()){
                invoiceLineItemInfo = [SELECT Product_Number__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c FROM Invoice_Line_Item__c WHERE Invoice__c = :invoiceId AND Name in : ids ORDER BY SAP_Line_Item_Number__c ASC];
            } 
        }
        catch(Exception ex){
            system.debug(LoggingLevel.WARN, 'Exception Message =====>: ' + ex.getMessage());
            invoiceLineItemInfo = null;
        }
        //System.debug(LoggingLevel.WARN, 'invoiceLineItemInfo=============>' + invoiceLineItemInfo);
        return invoiceLineItemInfo;
        
    }
    /*@description to fetch invoice line items for multiple reference correctin document
     * @return list of invoice line item
     * */
    @AuraEnabled
    public static list<Invoice_Line_Item__c> fetchLineItemsforMultiple(String corId) {
        
        //System.debug(LoggingLevel.WARN, 'correction document Id=============>' + corId);
        list<Invoice_Line_Item__c> invoiceLineItemInfo = new list<Invoice_Line_Item__c>();
        
        try{
            if(Schema.sObjectType.Invoice_Line_Item__c.isAccessible()){
                invoiceLineItemInfo = [SELECT Product_Number__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c FROM Invoice_Line_Item__c WHERE Correction_Document__c = :corId];
            } 
        }
        catch(Exception ex){
            system.debug(LoggingLevel.WARN, 'Exception Message =====>: ' + ex.getMessage());
            invoiceLineItemInfo = null;
        }
        //System.debug(LoggingLevel.WARN, 'invoiceLineItemInfo=============>' + invoiceLineItemInfo);
        return invoiceLineItemInfo;
        
    }
    /*
     * @description fetches invoice lineitems from correction document mapping
     * @return List of invoice lineitems from correction document mapping
     * */
    @AuraEnabled
    public static list<PNR_CorrectionDocumentMapping__c> fetchInvoiceLineItemsForAll(String corId) {
       
        list<PNR_CorrectionDocumentMapping__c> invoiceLineItemInfo = new list<PNR_CorrectionDocumentMapping__c>();
        try{
            if(Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
                invoiceLineItemInfo = [SELECT Product_Number__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c,PNR_Recharge_Material__c FROM PNR_CorrectionDocumentMapping__c WHERE Correction_Document__c = :corId ORDER BY SAP_Line_Item_Number__c ASC];
            } 
        }
        catch(Exception ex){
            system.debug(LoggingLevel.WARN, 'Exception Message =====>: ' + ex.getMessage());
            invoiceLineItemInfo = null;
        }
        //System.debug(LoggingLevel.WARN, 'invoiceLineItemInfo=============>' + invoiceLineItemInfo);
        return invoiceLineItemInfo;
        
    }
    /*
     * @description returns correction document details
     * @return correction document
     * */
    @AuraEnabled
    public static Correction_Document__c getCorrectionInfoDetails(String recordId) {
        //This methd is for getting Correction_Document__c info from Correction_Document__c Object based on Correction_Document__c Id
        Correction_Document__c corDoc;
        //System.debug(LoggingLevel.WARN, 'corDoc Id=============>' + recordId);
        try{
            if(Schema.sObjectType.Correction_Document__c.isAccessible()){
                //PION-1670 : querying Invoices_Affected__c to display invoices of multiple reference CD in the email
                corDoc = [SELECT Name,Sales_Org__c, CurrencyIsoCode, Distribution_Channel__c,
                          Document_Type__c, Division__c, Payer__c, Payer__r.Name, Sold_To__c,
                          Sold_To__r.Name, Reason_Code__c, Ship_To__c, Type_of_Reference__c,
                          Bill_To__c, PO_Number__c, Case__c, Case__r.CaseNumber,Case__r.Type,Case__r.Claimed_Amount__c,Case__r.CurrencyIsoCode,Case__r.Dispute_Breakdown__c,Case__r.Dispute_Sub_type__c, Approver_Email__c,
                          Previous_Approver_Email__c, Reference_invoice__c, Reference_invoice__r.SAP_Invoice_Number__c,Claimed_Invoice_Line_Items__c,Status__c, Invoices_Affected__c
                          FROM Correction_Document__c
                          WHERE Id = :recordId];
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.WARN, 'Exception Message =====>: ' + ex.getMessage());
            corDoc = null;
        }
        return corDoc;
        
    }
    /*
     * @description
     * @return returns a string
     * */
    @AuraEnabled
    public static String getUserSigneture() {
        User currUser;
        if(Schema.sObjectType.User.isAccessible()){
            currUser = [Select Id,Signature from User where Id=:userinfo.getuserId()];
        }
        //System.debug('currUser=====>' +currUser);
        string userSignature = currUser.Signature;
        if (String.isNotBlank(userSignature)) {
            userSignature = userSignature.replace('\n','<br>');
        }
        return userSignature;
    }
    
  
    @AuraEnabled
    
    public static boolean sendEmailtoApprover(String subject, String ccAddress, String toAddress,String caseId,List<String> ContentDocId,String corRecordId, String originalEmailBody) {
        boolean isSucess = false;
        //Calling VF page; PION-1631 change; Attaching PDF to the mail. Converting VF page into PDF.
        PageReference pdfAttachment =  Page.PNR_ExternalEmailVF;
        pdfAttachment.getParameters().put('Id',corRecordId);
        pdfAttachment.setRedirect(true);
        Blob b ;
        //added for test class purpose
        if(Test.isRunningTest()) { 
            b = blob.valueOf('Unit.Test');
        } else {
            b = pdfAttachment.getContent();
        }
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setContentType('application/pdf');
        efa.setFileName(subject+'.pdf');
        efa.setInline(false);
        efa.setBody(b);
        OrgWideEmailAddress[] owea;
        String fromAddress = System.Label.PNR_FromEmailAddressForApproval;
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        // Set recipients to two contact IDs.
        //if(Schema.sObjectType.OrgWideEmailAddress.isAccessible()){
           owea = [select Id from OrgWideEmailAddress where Address =:fromAddress];
       // }
        //System.debug('owea==>' + owea);
        if ( owea.size() > 0 ) {
            message.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        String[] toaddressCol = toAddress.split(',');
        if(string.isNotBlank(ccAddress) && string.isNotEmpty(ccAddress)){
            String[] ccaddressCol = ccAddress.split(',');
            message.ccaddresses = ccaddressCol;
        }
        message.toAddresses = toaddressCol;
        message.subject = subject;
        message.htmlbody = originalEmailBody;
        message.setUseSignature(false);
        message.setCharset('UTF-8');
        message.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        //system.debug('--- ContentDocId  --- '+ ContentDocId );
        if(!ContentDocId.isEmpty()){
            map<Id,ContentVersion> allDocuments;
            allDocuments = new map<Id,ContentVersion>([SELECT Id, Title, FileType, ContentDocumentId FROM ContentVersion where ContentDocumentId in:ContentDocId]);
            
            list<id> allDocumentsIds = new list<Id>(allDocuments.keySet());
            //system.debug(LoggingLevel.WARN, '--- allDocumentsIds  --- '+ allDocumentsIds );
            message.setEntityAttachments(allDocumentsIds); 
        }
        
        //System.debug(LoggingLevel.WARN, 'message value =============>' + message);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
        if (results[0].success) {
            
            EmailMessage emailMessages = new EmailMessage();
            emailMessages.ParentId = caseId;
            for(String str : toaddressCol){
                emailMessages.ToAddress = str;
            }
            //system.debug('To address==>'+emailMessages.ToAddress);
            emailMessages.CcAddress = ccAddress;
            emailMessages.FromAddress = fromAddress;
            emailMessages.HtmlBody = originalEmailBody;
            emailMessages.Subject = subject;
            if(Schema.SObjectType.EmailMessage.isCreateable()
               && Schema.SObjectType.EmailMessage.isAccessible()){
                   Insert emailMessages;                            
               }
            
            
            Case caseRecord = new Case();
            caseRecord.Id = caseId;
            caseRecord.Status = 'Sent for External Approval';
            if(Schema.SObjectType.Case.isUpdateable()){
                update caseRecord;
            }
            // Get the Pioneer business hours
			BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsActive = true and Name='Pioneer: Business Hours'];
            Correction_Document__c corRecord = new Correction_Document__c();
            corRecord.Id = corRecordId;
            
            if(corRecord.Sent_For_Approval_Batch_Date__c ==null && bh!=null){
                corRecord.Sent_For_Approval_Batch_Date__c = Date.valueOf(BusinessHours.addGMT(bh.Id,Date.today(),2*86400000L));
            } 
            corRecord.Status__c = 'Sent for External Approval';
            if(Schema.SObjectType.Correction_Document__c.isUpdateable()){
                update corRecord;
            }
            
            Attachment att=new Attachment();
            att.Body=b;
            att.Name= subject+'.pdf';
            att.parentId=caseRecord.Id;
            if(Schema.SObjectType.Attachment.isCreateable()){
               insert att;
            }
            //Save Content Document Id
            if(ContentDocId != null){
                string docId = '';
                for(string str : ContentDocId){
                    if(string.isNotEmpty(docId) || string.isNotBlank(docId)){
                        docId = docId + ';'+ str;
                    }
                    else{
                        docId = str;
                    }
                }
                Correction_Document__c corRecordEmailBody = new Correction_Document__c();
                corRecordEmailBody.Id = corRecordId;
                corRecordEmailBody.Content_Document_Ids__c = docId;
                if(Schema.SObjectType.Correction_Document__c.isUpdateable()){
                    update corRecordEmailBody;
                }
            }
            
            isSucess = true;
            
           // System.debug('The email was sent successfully.');
        } else {
           // System.debug('The email failed to send: ==>' + results[0].errors[0].message);
        }
        return isSucess;
    }
    /* @AuraEnabled
    //Method to retrieve attachments associated to customer Id
    public static List<ContentVersion> getAttachmentList(String contentDocumentId) {
    List<ContentVersion> contentVersionList = new List<ContentVersion>();
    
    if(Schema.sObjectType.ContentVersion.isAccessible()){
    contentVersionList =  [SELECT Id, ContentDocumentId, Title, FileType 
    FROM ContentVersion 
    WHERE ContentDocumentId IN: contentDocumentIdSet];
    }
    return contentVersionList;
    }*/
    /*
     * @descriptiondeletes content document
     * 
     * */
    @AuraEnabled
    public static void deleteContentDocument(Id verid) {
        ContentDocument ver =new ContentDocument ();
        try{
            if(verid != null && Schema.sObjectType.ContentDocument.isAccessible() && Schema.SObjectType.ContentDocument.isDeletable()){
                ver = [select id from ContentDocument where Id = :verid]; 
                delete ver;
            }
        }catch(Exception ex){            
            //system.debug('Error in NAC_MaintenanceController in method deleteContentDocument-->'+ex.getMessage() + ' and Line Number is ->' +ex.getLineNUmber());
        }
        
    }
    /*
     * @description fetches sales org from custom metadata
     * @return sales org from custom metadata
     * */
    @AuraEnabled
    public static List<PNR_SalesOrg_Mapping__mdt> fetchSalesOrgMapping()
    {
        List<PNR_SalesOrg_Mapping__mdt> allsalesOrg = new List<PNR_SalesOrg_Mapping__mdt>();
        if(Schema.sObjectType.PNR_SalesOrg_Mapping__mdt.isAccessible()){
            allsalesOrg= [SELECT DeveloperName,Sales_Org_Name__c FROM PNR_SalesOrg_Mapping__mdt order by DeveloperName];
        }
        return allsalesOrg;
    }
    
    /*
     * @description calls validataApproverEmail from PNR_ApproverMatrix
     * @return true or false
     * */
    @AuraEnabled
    public static Boolean validateEmail(String recordId, String emailAddress)
    {
        Boolean isValid = PNR_ApproverMatrix.validateApproverEmail(recordId,emailAddress);
        return isValid;
    }
    /*
     * @description fetches attachmentlist
     * @return list of content version
     * */
     @AuraEnabled
    //Method to retrieve attachments associated to Case Id
    public static List<ContentVersion> getAttachmentList(String caseId) {
        //system.debug('caseId:' + caseId);
        Set<Id> contentDocumentIdSet = new Set<Id>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        if(Schema.sObjectType.ContentDocumentLink.isAccessible()){
            List<ContentDocumentLink> contentDocList = [SELECT ContentDocumentId, LinkedEntityId  
                                                        FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId = : caseId];
            for(ContentDocumentLink docLink : contentDocList) {
                contentDocumentIdSet.add(docLink.ContentDocumentId);
            }
        }
        
        if(Schema.sObjectType.ContentVersion.isAccessible()){
            contentVersionList =  [SELECT Id, ContentDocumentId, Title
                                   FROM ContentVersion 
                                   WHERE ContentDocumentId IN: contentDocumentIdSet];
        }
        return contentVersionList;
    }
}