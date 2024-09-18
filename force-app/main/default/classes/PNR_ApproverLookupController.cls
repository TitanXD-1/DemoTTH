public without sharing class PNR_ApproverLookupController {
    /*Start:Wrapper class*/
    public class PNR_CorrectionWrapper {
        @AuraEnabled public String documentType {get;set;} 
        @AuraEnabled public String refInvoice {get;set;} 
        @AuraEnabled public String caseNumber {get;set;} 
        @AuraEnabled public String caseType {get;set;} 
        @AuraEnabled public String accountName {get;set;} 
        @AuraEnabled public String typeOfReference {get;set;} 
        @AuraEnabled public decimal totalClaimedAmount {get;set;}
        @AuraEnabled public String reasonCode {get;set;}
        @AuraEnabled public String currencySign {get;set;}
        @AuraEnabled public String toAddress {get;set;}
        @AuraEnabled public String correctionId {get;set;}
        @AuraEnabled public String caseId {get;set;}
        @AuraEnabled public String signeture {get;set;}
        @AuraEnabled public String contentDocumentIds {get;set;}
        @AuraEnabled public String emailBody {get;set;}
        @AuraEnabled public String responseBody {get;set;}
        @AuraEnabled public String emailSubject {get;set;}
        @AuraEnabled public String caseSubType {get;set;}
        @AuraEnabled public String caseBreakdown {get;set;}
        @AuraEnabled public InvoiceLineItem [] items; 
        public PNR_CorrectionWrapper (){
            
        }
        public PNR_CorrectionWrapper (String documentType,String refInvoice,
                                      String caseNumber,String caseType, String accountName, String typeOfReference,
                                      decimal totalClaimedAmount,String reasonCode,String currencySign,String toAddress,
                                      String correctionId, String caseId, String signeture, String contentDocumentIds, String caseSubType, String caseBreakdown){
                                          this.documentType = documentType;
                                          this.refInvoice = refInvoice;
                                          this.caseNumber = caseNumber;
                                          this.caseType = caseType;
                                          this.accountName = accountName;
                                          this.typeOfReference = typeOfReference;
                                          this.totalClaimedAmount = totalClaimedAmount;
                                          this.reasonCode = reasonCode;
                                          this.currencySign = currencySign;
                                          this.toAddress = toAddress;
                                          this.correctionId = correctionId;
                                          this.caseId = caseId;
                                          this.signeture = signeture;
                                          this.contentDocumentIds = contentDocumentIds;
                                          this.caseSubType = caseSubType;
                                          this.caseBreakdown = caseBreakdown;
                                          items = new InvoiceLineItem [0];
                                      }
        
    }
    //Wrapper Class for Line Items
    public class InvoiceLineItem {
        @AuraEnabled public String productNumber {get;set;} 
        @AuraEnabled public String ProductDes {get;set;} 
        @AuraEnabled public String invoiceQuantity {get;set;} 
        @AuraEnabled public decimal invoiceNetPrice {get;set;} 
        @AuraEnabled public decimal claimedAmount {get;set;} 
        @AuraEnabled public String claimedQty {get;set;} 
        @AuraEnabled public String claimedUOM {get;set;}
        @AuraEnabled public String currencyIsoCode {get;set;} 
        @AuraEnabled public String invoiceUom {get;set;}
        
        public InvoiceLineItem (String productNumber,String ProductDes,String invoiceQuantity,
                                decimal invoiceNetPrice, decimal claimedAmount,
                                String claimedQty, String claimedUOM, String currencyIsoCode, String invoiceUom){
                                    this.productNumber = productNumber;
                                    this.ProductDes = ProductDes;
                                    this.invoiceQuantity = invoiceQuantity;
                                    this.invoiceNetPrice = invoiceNetPrice;
                                    this.claimedAmount = claimedAmount;
                                    this.claimedQty = claimedQty;
                                    this.claimedUOM = claimedUOM;
                                    this.currencyIsoCode = currencyIsoCode;
                                    this.invoiceUom = invoiceUom;
                                }
    }
    //End Warpper class
    
    
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String objectName) {
        String searchKey = searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'select id,Name, Approver_Email__c from Approver_Matrix__c where Approver_Email__c LIKE: searchKey order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        System.debug('returnList==>' + returnList);
        return returnList;
    }
    @AuraEnabled
    public static List < Correction_Document__c > fetchcorrectionDocumentValues(String approverEmail) {
        List < Correction_Document__c > corDocs = new List < Correction_Document__c >();
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            corDocs = [SELECT Id, Name,Sales_Org__c, CurrencyIsoCode, Distribution_Channel__c,
                       Document_Type__c, Division__c, Payer__c, Payer__r.Name, Payer__r.AccountNumber, Sold_To__c,
                       Sold_To__r.Name, Sold_To__r.AccountNumber, Reason_Code__c, Ship_To__c, Type_of_Reference__c,
                       Bill_To__c, PO_Number__c, Case__c, Case__r.CaseNumber,Case__r.Type, Approver_Email__c, Invoices_Affected__c,
                       Previous_Approver_Email__c, Reference_invoice__r.SAP_Invoice_Number__c,
                       Billing_notes_for_printing__c, Correction_Of__c, Status__c,Claimed_Amount__c
                       FROM Correction_Document__c
                       WHERE Approver_Email__c =:approverEmail AND Status__c = 'Sent for External Approval'];
        }
        return corDocs;
    }
    @AuraEnabled
    public static List<String> fetchApproverList(String record,String currentApproverEmail){
        List<String> approverEmailList = new List<String>();
        List<String> approverEmails = new List<String>();
        approverEmails = PNR_ApproverMatrix.fetchApproverEmail(record);
        System.debug('approverEmails=====>' + approverEmails);
        if(!approverEmails.isEmpty()){
            for(string appEmail : approverEmails){
                if(currentApproverEmail != appEmail){
                    approverEmailList.add(appEmail); 
                }
            }
        }
        return approverEmailList;
    }
    
    @AuraEnabled
    public static Boolean updateEmailAdd(List <Correction_Document__c> corRecords, String emailAddress){
        boolean isSuccess = true;
        Database.SaveResult[] sRec = Database.update(corRecords, false);
        for (Database.SaveResult sr : sRec) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully updated Correction Document:====> ' + sr.getId());
            }
            
            else {
                for(Database.Error err : sr.getErrors()) {
                    isSuccess = false;
                    System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Correction fields that affected this error:===> ' + err.getFields());
                }
            }
        }
        return isSuccess;
    }
    @AuraEnabled
    public static List < PNR_ApproverLookupController.PNR_CorrectionWrapper> fetchcorrectionDocumentsInfo(String[] corIds) {
        User currUser;
        if(Schema.sObjectType.User.isAccessible()){
            currUser = [Select Id,Signature from User where Id=:userinfo.getuserId()];
        }
        System.debug('currUser=====>' +currUser);
        string userSignature = currUser.Signature;
        if (String.isNotBlank(userSignature)) {
            userSignature = userSignature.replace('\n','<br>');
        }
        
        List < Correction_Document__c > corDocSet = new List < Correction_Document__c >();
        List < PNR_ApproverLookupController.PNR_CorrectionWrapper> wrapperContexts = new List < PNR_ApproverLookupController.PNR_CorrectionWrapper>();
        Set<String> invItmNameSet = new Set<String>();
        Map<String,List<String>> corrDocMap = new Map<String,List<String>>();
        List<PNR_CorrectionDocumentMapping__c> lineItmList = new List<PNR_CorrectionDocumentMapping__c>();
        Map<String,PNR_CorrectionDocumentMapping__c> lineItmMap = new Map<String,PNR_CorrectionDocumentMapping__c>();
        
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            corDocSet = [SELECT Id, Name,Sales_Org__c, CurrencyIsoCode, Distribution_Channel__c,
                         Document_Type__c, Division__c, Payer__c, Payer__r.Name, Payer__r.AccountNumber, Sold_To__c,
                         Sold_To__r.Name, Sold_To__r.AccountNumber, Reason_Code__c, Ship_To__c, Type_of_Reference__c,
                         Bill_To__c, PO_Number__c, Case__c, Case__r.CaseNumber,Case__r.Type, Case__r.Dispute_Breakdown__c, Case__r.Dispute_Sub_type__c, Approver_Email__c, Invoices_Affected__c,
                         Previous_Approver_Email__c, Reference_invoice__r.SAP_Invoice_Number__c,
                         Billing_notes_for_printing__c, Correction_Of__c, Status__c,Claimed_Amount__c,Claimed_Invoice_Line_Items__c,Content_Document_Ids__c
                         FROM Correction_Document__c
                         WHERE Id in : corIds];
        }
        if(!corDocSet.isEmpty()){
            for(Correction_Document__c corrDocObj : corDocSet){
                if(String.isNotBlank(corrDocObj.Claimed_Invoice_Line_Items__c)){
                    String claimedItem = corrDocObj.Claimed_Invoice_Line_Items__c;
                    List<String> sapItem = claimedItem.split(';');
                    corrDocMap.put(corrDocObj.Id,new List<String>{});
                    corrDocMap.get(corrDocObj.Id).addAll(sapItem);
                    invItmNameSet.addAll(sapItem);
                    
                }
            }
            if(!invItmNameSet.isEmpty() && Schema.sObjectType.Invoice_Line_Item__c.isAccessible()){
                lineItmList = [SELECT Id,Name,Product_Number__c,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c,Invoice_Quantity__c,
                               Claimed_Net_Amount__c,CurrencyIsoCode,Invoice_Net_Price_Item__c,Invoice_Unit_of_Measure__c,Product_Description__c
                               FROM PNR_CorrectionDocumentMapping__c
                               WHERE Name IN : invItmNameSet];
                if(!lineItmList.isEmpty()){
                    for(PNR_CorrectionDocumentMapping__c itemObj : lineItmList){
                        lineItmMap.put(itemObj.Name,itemObj);
                    }
                }
            }
            for(Correction_Document__c corrDoc : corDocSet){
                PNR_CorrectionWrapper  parentWrap = new PNR_CorrectionWrapper(String.valueOf(corrDoc.Document_Type__c),
                                                                              String.valueOf(corrDoc.Reference_invoice__r.SAP_Invoice_Number__c),
                                                                              String.valueOf(corrDoc.Case__r.CaseNumber),
                                                                              String.valueOf(corrDoc.Case__r.Type),
                                                                              String.valueOf(corrDoc.Sold_To__r.Name),
                                                                              String.valueOf(corrDoc.Type_of_Reference__c),
                                                                              corrDoc.Claimed_Amount__c,
                                                                              String.valueOf(corrDoc.Reason_Code__c),
                                                                              String.valueOf(corrDoc.CurrencyIsoCode),
                                                                              String.valueOf(corrDoc.Approver_Email__c),
                                                                              String.valueOf(corrDoc.Id),
                                                                              String.valueOf(corrDoc.Case__c),
                                                                              String.valueOf(userSignature),
                                                                              String.valueOf(corrDoc.Content_Document_Ids__c),
                                                                              String.valueOf(corrDoc.Case__r.Dispute_Sub_type__c),
                                                                              String.valueOf(corrDoc.Case__r.Dispute_Breakdown__c));
                if(String.isNotBlank(corrDoc.Claimed_Invoice_Line_Items__c)){
                    for(String itemName : corrDoc.Claimed_Invoice_Line_Items__c.split(';')){
                        if(!lineItmMap.isEmpty() && lineItmMap.containsKey(itemName)){
                            PNR_CorrectionDocumentMapping__c lineItem  = lineItmMap.get(itemName);
                            parentWrap.items.add(new InvoiceLineItem(String.valueOf(lineItem.Product_Number__c), 
                                                                     String.valueOf(lineItem.Product_Description__c),
                                                                     String.valueOf(lineItem.Invoice_Quantity__c),
                                                                     lineItem.Invoice_Net_Price_Item__c,
                                                                     lineItem.Claimed_Net_Amount__c,
                                                                     String.valueOf(lineItem.Claimed_Volume__c),
                                                                     String.valueOf(lineItem.Unit_of_Measure_of_Claimed_QTY__c),
                                                                     String.valueOf(lineItem.CurrencyIsoCode),
                                                                     String.valueOf(lineItem.Invoice_Unit_of_Measure__c)));
                            
                        }
                    }
                }
                wrapperContexts.add(parentWrap);
            }
        }
        System.debug('wrapperContexts===>' + wrapperContexts);
        return wrapperContexts;
    }
    @AuraEnabled
    public static boolean sendEmailtoApprover(List <PNR_ApproverLookupController.PNR_CorrectionWrapper> records) {
        boolean isSucess = false;
        for(PNR_ApproverLookupController.PNR_CorrectionWrapper record : records){
            
            OrgWideEmailAddress[] owea;
            String fromAddress = System.Label.PNR_FromEmailAddressForApproval;
            System.debug('fromAddress=====>' +fromAddress);
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            // Set recipients to two contact IDs.
           // if(Schema.sObjectType.OrgWideEmailAddress.isAccessible()){
                owea = [select Id from OrgWideEmailAddress where Address =:fromAddress];
            //}
            if ( owea.size() > 0 ) {
                message.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            String[] toaddressCol = record.toAddress.split(',');
            
            message.toAddresses = toaddressCol;
            message.subject = record.emailSubject;
            message.htmlbody = record.emailBody;
            message.setUseSignature(false);
            message.setCharset('UTF8');
            if(String.isNotEmpty(record.contentDocumentIds) && String.isNotBlank(record.contentDocumentIds)) {
                String [] ContentDocId = record.contentDocumentIds.split(';');
                map<Id,ContentVersion> allDocuments;
                allDocuments = new map<Id,ContentVersion>([SELECT Id, Title, FileType, ContentDocumentId FROM ContentVersion where ContentDocumentId in:ContentDocId]);
                
                list<id> allDocumentsIds = new list<Id>(allDocuments.keySet());
                system.debug('--- allDocumentsIds  --- '+ allDocumentsIds );
                message.setEntityAttachments(allDocumentsIds); 
            }
            
            System.debug('message value =============>' + message);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
            if (results[0].success) {
                
                EmailMessage emailMessages = new EmailMessage();
                emailMessages.ParentId = record.caseId;
                for(String str : toaddressCol){
                    emailMessages.ToAddress = str;
                }
                system.debug('To address==>'+emailMessages.ToAddress);
                emailMessages.FromAddress = fromAddress;
                emailMessages.HtmlBody = record.emailBody;
                emailMessages.Subject = record.emailSubject;
                if(Schema.SObjectType.EmailMessage.isCreateable()
                   && Schema.SObjectType.EmailMessage.isAccessible()){
                       Insert emailMessages;                            
                   }
                
                
                Case caseRecord = new Case();
                caseRecord.Id = record.caseId;
                caseRecord.Status = 'Sent for External Approval';
                if(Schema.SObjectType.Case.isUpdateable()){
                    update caseRecord;
                }
                
                Correction_Document__c corRecord = new Correction_Document__c();
                corRecord.Id = record.correctionId;
                corRecord.Status__c = 'Sent for External Approval';
                if(Schema.SObjectType.Correction_Document__c.isUpdateable()){
                    update corRecord;
                }
                
                isSucess = true;
                
                System.debug('The email was sent successfully.');
            } else {
                System.debug('The email failed to send: ==>' + results[0].errors[0].message);
            }
        }
        
        return isSucess;
    }
    
}