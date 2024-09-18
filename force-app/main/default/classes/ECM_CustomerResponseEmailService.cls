/*
 Class Name: ECM_CustomerResponseEmailService
 @description: This class is used to receive & process inbound email for system-sent mails to Diageo customers. 
 @history: 
 VERSION      AUTHOR             DATE              DETAIL
 1.0		   Pratap Sen		  18/07/2022		Initital Development for ECM-5904
 1.1          Suvendu Roy         20/07/2022        ECM-5820 : Notifying Contract Owner for Customer responses_SFDC_GLO
 1.2          Anamika Shukla      18/08/2022        ECM-5967 : Customer Reply for Invoice Requested Mail to save in System as new Content type _SFDC
 1.3		   Wribhu Bose	      19/08/2022		ECM-6001 : Added check for mail subject to add CIO to mailing list
 1.4          Suvendu Roy         10/12/2022        ECM-6041 : Notify the Contract Owner for Customer response_SFDC_Asset Contract
 1.5          Abhishek Shivam     02/12/2022        ECM-6434 : Bug - Mail Sent to Sales Rep after Customer replies

*/
global class ECM_CustomerResponseEmailService implements Messaging.InboundEmailHandler {
    /*
	* @description : Detects the inboundEmail replied on the system sent thread & finds the designated record number/name 
	* @return : Messaging.InboundEmailResult
	* @param : Messaging.InboundEmail email, Messaging.InboundEnvelope envelope
	*/
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) { 
        List<String> psInvoiceList = new List<String>();
        Matcher psMatcher;
        Matcher contractMatcher;
        Boolean isPS = false;
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        result.success = false;
        List<Messaging.EmailFileAttachment> attachmentsToSend = new List<Messaging.EmailFileAttachment>();
        List<String> emailToSend = new List<String>();
        List<Contract> conRecList = new List<Contract>();
        List<ECM_Payment_Summary__c> payList = new List<ECM_Payment_Summary__c>();
        //ECM-6041
        Id assetRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Asset Contract').getRecordTypeId();
        Boolean isAsset = false;
        String conNumber = '';
        String payNumber = '';
        String concat ='PS-';
        String conId,payId,conOwnerEmail,customerEmail,managerEmail;
        psInvoiceList = Label.ECM_PaymentSummary_Subject_Invoice.split(',');
        String geoCountry = '';
        List<Market_Setting__c> marketSettings = new List<Market_Setting__c>();
        String cioMailId = '';
        String language = '';   // ECM-6434
        String emailSubject = email.subject.toLowerCase().replaceAll('[^a-zA-Z0-9+]', '');//remove all special chars including whitespaces
        for(String sb : psInvoiceList ){
            if(emailSubject.contains(sb)){
                isPS = true;
                break;
            }
        }
        if(isPS){
            psMatcher = Pattern.compile('([a-zA-Z0-9]*)(ps)(\\d{6})([a-zA-Z0-9]*)').matcher(emailSubject);
            if(psMatcher.matches()){
                payNumber = psMatcher.group(3);
                concat = concat+payNumber;
                payList = [SELECT ID,Name,ECM_Contract__r.Owner.IsActive,ECM_Contract__r.Owner.Email,Owner__c,
                           ECM_Contract__r.Owner.ManagerId,ECM_Contract__r.Owner.Manager.IsActive,
                           ECM_Contract__r.Owner.Manager.Email,ECM_Type__c,ECM_Contract__r.Account.Email_for_contracts_payments__c,
                           ECM_Contract__r.Account.Country__c,ECM_Country_Code__c,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c	// Bug
                           FROM ECM_Payment_Summary__c 
                           Where Name =: concat 
                           LIMIT 1];
                if(!payList.isEmpty()){
                    payId = payList[0].Id;
                    customerEmail = payList[0].ECM_Contract__r.Account.Email_for_contracts_payments__c;
                    // ECM-6001 start + added ECM_Contract__r.Account.Country__c,ECM_Country_Code__c to PS query above
                    geoCountry = payList[0].ECM_Contract__r.Account.Country__c;
                    marketSettings = [SELECT Id, Geography__c, ECM_Payment_Management_Email__c FROM Market_Setting__c WHERE Geography__c =: geoCountry LIMIT 1];
                    cioMailId = marketSettings[0].ECM_Payment_Management_Email__c;
                    // ECM-6001 end
                    if(String.isNotBlank(customerEmail) && email.fromAddress == customerEmail){
                        attachmentsToSend = fetchAndSaveEmailwithAttachments(payId,email,isPS); 
                        result.success = (!attachmentsToSend.isEmpty());
                    }
                }
            }
        }else{
                contractMatcher = Pattern.compile('([a-zA-Z0-9]*)(\\d{8})([a-zA-Z0-9]*)').matcher(emailSubject);
                if(contractMatcher.matches()){
                    conNumber = contractMatcher.group(2); 
            conRecList = [SELECT Id,Account.Email_for_contracts_payments__c,
                              Owner.Email,Owner.IsActive,Owner.ManagerId,RecordTypeId,
                      	  Owner.Manager.Email,Owner.Manager.IsActive,ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c  // Bug
                          FROM Contract 
                          WHERE ContractNumber =: conNumber 
                          LIMIT 1];
            if(!conRecList.isEmpty()){
                conId = conRecList[0].Id;
                customerEmail = conRecList[0].Account.Email_for_contracts_payments__c;
                if(String.isNotBlank(customerEmail) && email.fromAddress == customerEmail){
                            attachmentsToSend = fetchAndSaveEmailwithAttachments(conId, email,isPS);
                    result.success = (!attachmentsToSend.isEmpty());
                }
            }
        }
            }
        if(!isPS && result.success){
            
             if(String.isNotBlank(conRecList[0].ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c)){
                 //ECM-6434
              language =  conRecList[0].ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c;
            }
            
            if(String.isNotBlank(conRecList[0].RecordTypeId) && conRecList[0].RecordTypeId==assetRecordTypeId){
                isAsset = true;
            }
            if(conRecList[0].Owner.IsActive && String.isNotBlank(conRecList[0].Owner.Email)){
                emailToSend.add(conRecList[0].Owner.Email);
            }
            if(String.isNotBlank(conRecList[0].Owner.ManagerId) && conRecList[0].Owner.Manager.IsActive){
                emailToSend.add(conRecList[0].Owner.Manager.Email);
            }
            if(!emailToSend.isEmpty()){
                result.success = sendMailtoConOwner(emailToSend,attachmentsToSend,conNumber,isPS,isAsset,language);
                }
        
            }
        else if(isPS && result.success){
            
            if(String.isNotBlank(payList[0].ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c)){
                //ECM-6434
                language =  payList[0].ECM_Contract__r.ECM_Agreement_Type__r.ECM_Language_for_Customer_Email__c;
            }
            if(payList[0].ECM_Contract__r.Owner.IsActive && String.isNotBlank(payList[0].ECM_Contract__r.Owner.Email)){
                emailToSend.add(payList[0].ECM_Contract__r.Owner.Email);
            }
            // ECM-6001 start
            if(payList[0].ECM_Country_Code__c == 'GB' && String.isNotBlank(payList[0].ECM_Contract__r.Owner.ManagerId) && payList[0].ECM_Contract__r.Owner.Manager.IsActive){
                emailToSend.add(payList[0].ECM_Contract__r.Owner.Manager.Email);
            }
            if(String.isNotBlank(cioMailId)) {   
                emailToSend.add(cioMailId);
            }
 
                // ECM-6001 end
                if(!emailToSend.isEmpty()){
                result.success = sendMailtoConOwner(emailToSend,attachmentsToSend,payNumber,isPS,false,language);
            }
        }
        return result;
    }
    /*
	* @description : Add the inboun email & it's attachment to Contract and prepares list of email attachments to forward to contract owner  
	* @return : List<Messaging.EmailFileAttachment>
	* @param : Id conId : Contract Id where attachments need to be added, Messaging.InboundEmail email : Inbound email
	*/
    public static List<Messaging.EmailFileAttachment> fetchAndSaveEmailwithAttachments(Id conId,Messaging.InboundEmail email,Boolean isPS) {
        Id recordtypeId;
        if(isPS){
            recordtypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('ECM_Payments').getRecordTypeId();
        }else{
            recordtypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
        }
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        Map<Id,ContentVersion> contentVersionIdMap = new Map<Id,ContentVersion>();
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        List<Messaging.EmailFileAttachment> attachmentsToSend = new List<Messaging.EmailFileAttachment>();
        String mailBody = 'from: '+email.fromName +'<'+email.fromAddress+'>'+ '\n'+ 
                          'to: '+email.toAddresses+'\n'+
                          'cc: '+email.ccAddresses+'\n'+
                          'inReplyTo: '+email.inReplyTo+'\n'+
                          'replyTo: '+email.replyTo+'\n'+
                          'date: '+System.now()+'\n'+
                          'subject: '+email.subject+'\n'+'\n'+
                           email.plainTextBody;
        Blob mailcontent = Blob.valueOf(mailBody);
        
        ContentVersion cVersion = createContentVersion(mailcontent, email.subject, recordtypeId);
        cVersion.PathOnClient = email.subject+'.eml';
        contentVersionList.add(cVersion);
        attachmentsToSend.add(createEmailFileAttachment(mailcontent, email.subject+'.eml'));
        if(email.textAttachments != null){
            for (Messaging.Inboundemail.TextAttachment txtAttachment : email.textAttachments) {
                contentVersionList.add( createContentVersion(Blob.valueOf(txtAttachment.body), email.subject+'_'+txtAttachment.fileName, recordtypeId));
                attachmentsToSend.add(createEmailFileAttachment(Blob.valueOf(txtAttachment.body), txtAttachment.fileName));
            }
        }
        if(email.binaryAttachments != null){
            for (Messaging.Inboundemail.BinaryAttachment binAttachment : email.binaryAttachments) {
                contentVersionList.add( createContentVersion(binAttachment.body, email.subject+'_'+binAttachment.fileName, recordtypeId));
                attachmentsToSend.add(createEmailFileAttachment(binAttachment.body, binAttachment.fileName));
            }
        }
        try{
            if(!contentVersionList.isEmpty()){
            	insert contentVersionList;   
            }
            contentVersionIdMap = new Map<Id,ContentVersion>(contentVersionList);
            for(contentVersion cVersionIt : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN: contentVersionIdMap.keySet()]){
                contentDocumentLinkList.add(createContentDocumentLink(cVersionIt.ContentDocumentId ,conId));
            }
            if(!contentDocumentLinkList.isEmpty()){
                insert contentDocumentLinkList;
            }
        }catch(Exception ex){
            System.debug('Exception Caught in fetchAndSaveEmailwithAttachments Method of ECM_CustomerResponseEmailService at Line:'+ ex.getLineNumber() +'\n'+ ex.getMessage());
        }
        return attachmentsToSend;
    }
    
    /*
	* @description : Sends mail with attachments
	* @return : Boolean
	* @param : String emailAddress : recipient address, List<Messaging.EmailFileAttachment> attachments : List of email attachments ,String RecordTypeId : RecordType of ContentVersion
	*/
    public static Boolean sendMailtoConOwner(List<String> emailAddress,List<Messaging.EmailFileAttachment> attachments, String recNumber,Boolean isPaySummary, Boolean isAsset,String langauge){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> emailContent = new List<String>();

        if(!isPaySummary){
            //ECM-6434
            if(langauge.equals(Label.ECM_GermanDe))
            {
                emailContent = isAsset? Label.ECM_notificationMailToConOwner_forAssetCon.split(',') : Label.ECM_notificationMailToConOwner_German.split(',');

            }else{ 
                emailContent = isAsset? Label.ECM_notificationMailToConOwner_forAssetCon.split(',') : Label.ECM_notificationMailToConOwner.split(',');
            }
            
        }else{
            //ECM-6434
            if(langauge.equals(Label.ECM_GermanDe))
            {    
				emailContent = Label.ECM_PSNotificationtoConOwner_German.split(',');
			}else{ 
                emailContent = Label.ECM_PSNotificationtoConOwner.split(',');
            }
            
            
        }
        email.setSubject(emailContent[0]+recNumber); //New Message for Contract - 
        email.setSenderDisplayName(emailContent[1]); //Contract Management System 
        email.setPlainTextBody(emailContent[2]); // Please find the response from customer for your contract in attached.
        email.setToAddresses(emailAddress);
        email.setFileAttachments(attachments);
        try{
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        }catch(Exception ex){
            System.debug('Exception Caught in sendMailtoConOwner Method of ECM_CustomerResponseEmailService at Line:'+ ex.getLineNumber() +'\n'+ ex.getMessage());
            return false;
        }
        return true;
    }
    
    /*
	* @description : Creates ContentVersion Record
	* @return : ContentVersion
	* @param : Blob versionData : Content/VersionData of ContentVersion, String fileName : Title of ContentVersion ,String RecordTypeId : RecordType of ContentVersion
	*/
    public static ContentVersion createContentVersion(Blob versionData, String fileName, String recordTypeId){
        ContentVersion cVersion = new ContentVersion();
        cVersion.RecordTypeId = recordTypeId;
        cVersion.Content_Type__c = 'Customer Emails';
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
        cVersion.PathOnClient = fileName;	//File name with extention
        cVersion.Title = fileName;	//Name of the file
        cVersion.VersionData = versionData;
        return cVersion;
    }
    
    /*
	* @description : Creates ContentDocumentLink Record to link ContentDocument & ContentVersion
	* @return : ContentDocumentLink
	* @param : String contentDocumentId : ContentDocumentId of ContentVersion, String contractId : ParentId for ContentDocumentLink
	*/
    public static ContentDocumentLink createContentDocumentLink(String contentDocumentId,String contractId){
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = contentDocumentId;	//Add ContentDocumentId
        cDocLink.LinkedEntityId = contractId;	//Add attachment parentId
        cDocLink.ShareType = 'I';	//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'InternalUsers';	//AllUsers, InternalUsers, SharedUsers
        return cDocLink;
    }
    
    /*
	* @description : Creates Messaging.EmailFileAttachment Record to add in Email
	* @return : Messaging.EmailFileAttachment
	* @param : Blob bodyAttchmnt : Body of the Email Attachment, String nameAttchmnt : Name of the Email Attachment
	*/
    public static Messaging.EmailFileAttachment createEmailFileAttachment(Blob bodyAttchmnt,String nameAttchmnt){
        Messaging.EmailFileAttachment attachMent = new Messaging.EmailFileAttachment();
        attachMent.setBody(bodyAttchmnt);
        attachMent.setFileName(nameAttchmnt);
        return attachMent;
    }
}