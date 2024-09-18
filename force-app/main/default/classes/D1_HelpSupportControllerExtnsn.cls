/*
* @name: D1_HelpSupportControllerExtnsn
* @discription: D1_HelpSupportControllerExtnsn Class for Help and Support page 
* @history
* VERSION     AUTHOR           DATE        DETAIL
* 1.0         Saurav Paul      20/10/20    CreateCase
* 2.0         Gaurav Singh     11/10/20    Add Doc Number/Doc Type to returned wrapper
* 3.0         Amar Deep        25/05/2021  NCP-1542
* 4.0         Gaurav Singh     15/08/2021  NCP-2780
* 5.0         Amar Deep        12/10/2021  NCP-4797
* 6.0         Kapil Baliyan    05/04/2022  NCP-6387
* 7.0         Sayan Samaddar   14/06/2022  NCP-6842
* 8.0         Pratap Sen       29/12/2022  NCP-7727
* 9.0         Pratap Sen       06/01/2023  NCP-7804
* 10.0                         28/02/2023  CUS-97
* 11.0        Kapil Baliyan    03/06/2024  152938
* */
public without sharing class D1_HelpSupportControllerExtnsn {

    @AuraEnabled(cacheable=true)
    public static Map<String,String> getSubjectBlockMap(){
        Map<String,String> subjectBlockmap = new Map<String,String>();
        List<Support_Topic_Configs__mdt> supportTopicList = [ SELECT Id,Block__c,Subject__c FROM Support_Topic_Configs__mdt];
        for(Support_Topic_Configs__mdt supportTopicRecd : supportTopicList){
            subjectBlockmap.put(supportTopicRecd.Subject__c,String.valueof(supportTopicRecd.Block__c.setscale(0)));
        }
        return subjectBlockmap;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Pick_Up_Options__c> getReasonForCancellation(string countryCode){
        List<Pick_Up_Options__c> reasonForCancellations = new List<Pick_Up_Options__c>();
        //Check if country code is blank, refetch it from user again
        if(String.isBlank(countryCode)){
            User usr = [SELECT Id, Available_Countries__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
            countryCode = String.isNotBlank(usr.Available_Countries__c) ? usr.Available_Countries__c : '';
        }

        //If user country code is blank again, dont proceed further
        if(String.isNotBlank(countryCode)){
            List<Pick_Up_Options__c> options = [SELECT Id, Name FROM Pick_Up_Options__c WHERE RecordType.Name= 'Reason For Cancellation' 
                                                    AND Status__c = 'Active' AND Geography__r.Code__c =:countryCode ORDER BY Name ASC];

            //Get the translated values, if any exist
            reasonForCancellations = D1_TranslationsUtility.updateTranslationsInRecords(options);
        }

        return reasonForCancellations;
    }

    @AuraEnabled
    public static Boolean checkFileSize(String contentDocumentId){
        try {
            Boolean fileSizeExceed = false;
            if(String.isNotBlank(contentDocumentId)){
                List<ContentDocument> contentDocuments = [SELECT Id, ContentSize FROM ContentDocument WHERE Id =:contentDocumentId]; //WITH SECURITY
                if(contentDocuments != null && contentDocuments.size()>0){
                    Decimal tempFileSize = contentDocuments.get(0).ContentSize;
                    Decimal fileSize = tempFileSize.divide(1048576, 2);
                    if(fileSize > 7.0){
                        fileSizeExceed = true;

                        //Delete the File
                        Database.Delete(contentDocuments);
                    }
                }
            }
            return fileSizeExceed;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean removeFile(string contentDocumentId){
        Boolean isSuccess = false;
        try {
            if(String.isNotBlank(contentDocumentId)){
                delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
                isSuccess = true;
            }
            return isSuccess;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Database.DMLOptions getOption(){
        AssignmentRule ar = new AssignmentRule();
        ar = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = ar.id;
        dmlOpts.EmailHeader.TriggerUserEmail = true;  // NCP-2915
        return dmlOpts;
    }

    @AuraEnabled
    public static Id createCasee(CaseWrapperr caseWrapper, Boolean isPioneerMarket, Id contentVersionId){
        try {
            string recordTypeName = (isPioneerMarket && (caseWrapper.caseSubType == 'Price or Quantity is Wrong on My Invoice' || caseWrapper.caseSubType == 'Delivery Issue - Shortage, Quality, etc' || caseWrapper.caseSubType == 'Request to Return Goods')) ? 'Direct_Disputes' : 'Diageo_One_Cases';
            //Get Record Type Id
            Id caseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();

            //Create Case Instance
            Case cs = caseInstance(caseWrapper, caseRecTypeId);

            //Update Case Type
            cs.Type = (isPioneerMarket && (caseWrapper.caseSubType == 'Price or Quantity is Wrong on My Invoice' || caseWrapper.caseSubType == 'Delivery Issue - Shortage, Quality, etc' || caseWrapper.caseSubType == 'Request to Return Goods')) ? 'Dispute – Unknown' : cs.Type;

            //Get Ship To Account Id and associate it with AccountId
            Id shipToId = getShipToId(caseWrapper.deliverToAddress);
            cs.AccountId = shipToId != null ? shipToId : cs.AccountId;

            //Get DML Options
            Database.DMLOptions dmlOpts = getOption();

            //Set DML Options
            cs.setOptions(dmlOpts);

            //Insert Case
            insert cs;

            //Insert Case Attachment
            if(String.isNotBlank(contentVersionId)){
                createAttachment(cs.Id, contentVersionId);
            }

            return cs.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Create Case Instance
    public static Case caseInstance(CaseWrapperr caseWrapper, Id recordTypeId){
        //Case Instance
        Case cs = new Case();
        cs.RecordTypeId = recordTypeId;
        cs.Type = caseWrapper.caseType;
        cs.D1_Subject__c = caseWrapper.caseSubType;
        cs.Subject = caseWrapper.caseSubType;
        cs.Description = caseWrapper.caseDescription;
        cs.D1_Document_no__c = caseWrapper.documentNumber;
        cs.D1_Document_Type__c = caseWrapper.documentType;
        cs.D1_Order_Number__c = caseWrapper.orderNumber;
        cs.Reason_For_Cancellation__c = caseWrapper.reasonForCancellation;
        cs.D1_Delivery_Number__c = caseWrapper.deliveryNumber;
        cs.D1_Invoice_Number__c = caseWrapper.invoiceNumber;
        cs.D1_Batch_Number__c = caseWrapper.batchNumber;
        cs.D1_Number_Of_Items_To_Return__c = caseWrapper.numberOfItemsToReturned;
        cs.AccountId = caseWrapper.accountId;
        cs.ContactId = caseWrapper.contactId;
        cs.SuppliedEmail = caseWrapper.email;
        cs.Priority = caseWrapper.caseType == 'My Orders' && caseWrapper.caseSubType == 'Cancel My Order' ? '4-Critical' : '2-Medium';
        cs.Origin = 'Diageo One';
        cs.Status = 'Open';
        cs.D1_Master_Bundle__c = caseWrapper.masterEquipment;
        cs.D1_Equipment__c = caseWrapper.equipment;
        cs.D1_Equipment_Issue__c = caseWrapper.equipmentIssue;

        return cs;
    }

    public static Id getShipToId(string shipToNumber){
        Id shipToId;
        if(String.isNotBlank(shipToNumber)){
            List<Account> accs = [SELECT Id FROM Account WHERE KUNNR__c =:shipToNumber];
            if(accs != null && accs.size()>0){
                shipToId = accs.get(0).Id;
            }
        }
        
        return shipToId;
    }

    @AuraEnabled
    public static void createAttachment(Id caseId,Id contentVersionId){
        Id contentDocId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:contentVersionId].ContentDocumentId;

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = caseId;
        cdl.ContentDocumentId = contentDocId;
        cdl.shareType = 'V';
        Insert cdl; 
    }

    //Case Wrapper
    public class CaseWrapperr {
        @AuraEnabled public string caseType {get;set;}
        @AuraEnabled public string caseSubType {get;set;}
        @AuraEnabled public string caseDescription {get;set;}
        @AuraEnabled public string deliverToAddress {get;set;}
        @AuraEnabled public string documentNumber {get;set;}
        @AuraEnabled public string documentType {get;set;}
        @AuraEnabled public string orderNumber {get;set;}
        @AuraEnabled public string reasonForCancellation {get;set;}
        @AuraEnabled public string numberOfItemsToReturned {get;set;}
        @AuraEnabled public string deliveryNumber {get;set;}
        @AuraEnabled public string invoiceNumber {get;set;}
        @AuraEnabled public string batchNumber {get;set;}
        @AuraEnabled public string accountId {get;set;}
        @AuraEnabled public string contactId {get;set;}
        @AuraEnabled public string email {get;set;}
        @AuraEnabled public string masterEquipment {get;set;}
        @AuraEnabled public string equipment {get;set;}
        @AuraEnabled public string equipmentIssue {get;set;}
        @AuraEnabled public string preReqforInstallation {get;set;}
    }
    
    //NCP-2780
    @AuraEnabled(cacheable=true)
    public static Case getCreatedCase(Id caseId){
        Case caseRec = [SELECT id, CaseNumber, toLabel(D1_Subject__c), Description, D1_Document_no__c, D1_Document_Type__c, Type, 
                        D1_Batch_Number__c, D1_Order_Number__c, D1_Invoice_Number__c, D1_Delivery_Number__c,
                        D1_Number_Of_Items_To_Return__c, D1_Equipment__r.Name, D1_Equipment_Issue__c,
                        D1_Equipment_Issue__r.Name, D1_Master_Bundle__r.Name
                        FROM Case WHERE Id = :caseId];//, D1_Contract_Number__c
        if(caseRec.D1_Equipment_Issue__c != null){//NCP-7804
            caseRec.D1_Equipment_Issue__r.Name = caseRec.D1_Equipment_Issue__r.Name.substringBefore('[').trim();
        }
        return caseRec;
    }

    @AuraEnabled
    public static Id createCase(CaseWrapper caseWrap, Boolean isPioneerMarket){
        Id logInUser = UserInfo.getUserId();
        boolean isPioneerMarketCheck = false;
        List<User> userObj = new List<User>();
        

        if(UserInfo.getUserType() == 'Guest'){
            userObj = [SELECT Id,ContactId,Contact.AccountId,Contact.Email,Effective_Account_Id__c,UserType,D1_User_Type__c FROM User
                        WHERE Email =: caseWrap.contactEmail];
        }else{
            userObj = [SELECT Id,ContactId,Contact.AccountId,Contact.Email,Effective_Account_Id__c,UserType,D1_User_Type_Id__c,D1_User_Type__c FROM User 
                        WHERE Id =:logInUser];
        }
       
        
        
        
        //NCP-6842
        if(caseWrap.topic=='My Orders' && caseWrap.subject=='Cancel My Order' && caseWrap.selectedOrderNumber!=null){
            List<Case> duplicateCasesForCancelOrder = [Select id,status from case 
                                                        where IsClosed = false 
                                                        AND D1_Subject__c = 'Cancel My Order'
                                                        AND D1_Order_Number__c = :caseWrap.selectedOrderNumber];
            if(duplicateCasesForCancelOrder.size()>0) { //US 150154:PMD Fix 
                return null;
            }
        }
        
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts = D1_HelpSupportControllerExtnsn.getOption();

        //NCP-2610
        if(isPioneerMarket == True && (caseWrap.subject == 'Price or Quantity is Wrong on My Invoice' || caseWrap.subject == 'Delivery Issue - Shortage, Quality, etc' || caseWrap.subject == 'Request to Return Goods')){
            isPioneerMarketCheck = true;
        }
        
        //Get Record Type Id
        Id caseRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(isPioneerMarketCheck == True ? 'Direct Disputes' : 'Diageo One Cases').getRecordTypeId();//NCP-2780
        
        //Create Case Instance
        case caseObj = new case();
        caseObj.RecordTypeId = caseRecTypeId;
        caseObj.Type = (isPioneerMarketCheck == True  ? 'Dispute – Unknown' : caseWrap.topic); //NCP-2610   
        caseObj.D1_Subject__c = caseWrap.subject;
        caseObj.subject = caseObj.D1_Subject__c;
        caseObj.Origin = 'Diageo One';
        caseObj.Description = caseWrap.description;
        caseObj.D1_Document_no__c = caseWrap.selectedDocumentNo;
        caseObj.D1_Document_Type__c = caseWrap.documentType;
        //caseObj.D1_Contract_Number__c = caseWrap.selectedContractNumber;
        caseObj.D1_Order_Number__c = caseWrap.selectedOrderNumber;
        caseObj.D1_Delivery_Number__c = caseWrap.deliveryNumber;
        caseObj.D1_Invoice_Number__c = caseWrap.invoiceNumber;
        caseObj.D1_Batch_Number__c = caseWrap.batchNumber;
        caseObj.D1_Number_Of_Items_To_Return__c = caseWrap.noOfitemsToReturn;
        caseObj.SuppliedEmail = caseWrap.contactEmail;
        caseObj.D1_Equipment__c = (caseWrap.equipment != '')? caseWrap.equipment : NULL; //NCP-7727
        caseObj.D1_Equipment_Issue__c = (caseWrap.equipmentIssue != '')?  caseWrap.equipmentIssue : NULL;
        caseObj.D1_Master_Bundle__c = (caseWrap.masterBundleId != '')?  caseWrap.masterBundleId : NULL;
        caseObj.Status = 'Open';
        if(caseWrap.topic=='My Orders' && caseWrap.subject=='Cancel My Order'){ //US 150154:PMD Fix 
            caseObj.Reason_For_Cancellation__c = caseWrap.reasonForCancellationValue;
        }
        if(userObj!= null && !userObj.isEmpty()){
            caseObj.AccountId = userObj[0].Effective_Account_Id__c;
            //caseObj.AssociatedAccount__c = userObj[0].Effective_Account_Id__c;//CUS-97
            caseObj.ContactId = userObj[0].ContactId;
            caseObj.SuppliedEmail = userObj[0].Contact.Email;
        }
        
        if(caseWrap.topic=='My Orders' && caseWrap.subject=='Cancel My Order'){//NCP-6841
            caseObj.Priority = '4 - Critical';
        }
        
        //Set Shipping Account
        if(!String.isEmpty(caseWrap.selectedDeliverToAddressId)){
           caseObj.SAP_Ship_To_Customer_No__c = caseWrap.selectedDeliverToAddressId;
            List<Account> shippingAccList = [SELECT Id FROM Account WHERE KUNNR__c=:caseWrap.selectedDeliverToAddressId];   
            if (shippingAccList!=null && shippingAccList.size()>0 &&  userObj[0].D1_User_Type__c == 'Direct Buyer') {        //CUS-97
                caseObj.D1_Shipping_Account__c = shippingAccList.get(0).Id;
                caseObj.AccountId = shippingAccList.get(0).Id;//CUS-97

            }            
        }
        
        //Commented by Kapil
        /*if((caseRecTypeId != technicalIssueRecordTypeId)){ //NCP-3791 //(caseWrap.subject != 'Contract terms' || caseWrap.selectedContractNumber == null)  &&
           caseObj.setOptions(dmlOpts); 
        }*/

        //Set DML Options
        caseObj.setOptions(dmlOpts);

        try{
            insert caseObj;

            return caseObj.Id;
        }catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<FeedItemWrapper> getCaseFeeds(Id caseRecId){
        List<FeedItemWrapper> feedItemWrapList = new List<FeedItemWrapper>();
        //Added RelatedRecordId in query for NCP-2297
        Map<DateTime,EmailMessage> mapofCreateddateEmailmessage = new  Map<DateTime,EmailMessage>();
        for(EmailMessage emailbody : [SELECT Id, Parent.Id, FromAddress, ActivityId, CreatedDate, HtmlBody, Subject FROM EmailMessage WHERE (not(Subject like '%[Internal]%')) AND ParentId =:caseRecId]){
            integer diffsecs = 60-emailbody.createdDate.second();
            Datetime datecheck=emailbody.createdDate.addSeconds(diffsecs);
            mapofCreateddateEmailmessage.put(datecheck,emailbody);
        }
        for (FeedItem feed : [SELECT Id,RelatedRecordId, createdDate, createdBy.FirstName, createdby.LastName, body,Type FROM FeedItem WHERE ParentId = :caseRecId AND (Type = 'TextPost' OR Type = 'ContentPost' OR Type = 'LinkPost') AND Visibility = 'AllUsers']) {
            feedItemWrapList.add(new FeedItemWrapper(feed));
        }
        
        //Added for NCP-2297
        if (feedItemWrapList!=null && !feedItemWrapList.isEmpty()) {
            Map<String,FeedItemWrapper> feedItemsMap = new Map<String,FeedItemWrapper>();
            List<String> relatedRecordIds = new List<String>();
            for (FeedItemWrapper feedItemWrapper : feedItemWrapList) {
                if (feedItemWrapper.relatedRecordId!=null) {
                    relatedRecordIds.add(feedItemWrapper.relatedRecordId);      
                    feedItemsMap.put(feedItemWrapper.relatedRecordId,feedItemWrapper);       
                }    
            }
            if (relatedRecordIds!=null && !relatedRecordIds.isEmpty()) {
                // Get record file IDs        
                List<ContentVersion> files = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id IN :relatedRecordIds];
                for (ContentVersion docLink : files) {
                    feedItemsMap.get(docLink.Id).contentDocumentId = docLink.ContentDocumentId;
                    feedItemsMap.get(docLink.Id).contentDocumentURL = '/'+ Label.D1_Diageo_One + docLink.ContentDocumentId;  
                }    
            }
        }
        return feedItemWrapList;
    }
    
    @AuraEnabled
    public static String getContentDocumentURL(Id caseRecId, List<String> feedContentIds){
        String contentDocumentURL= '';
        List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :caseRecId];
        
        if (files!=null && !files.isEmpty()) {
            for (ContentDocumentLink docLink : files) {
                if (feedContentIds!=null && !feedContentIds.isEmpty() && feedContentIds.contains(docLink.ContentDocumentId)) {
                    continue;
                }
                else {
                    contentDocumentURL = '/'+Label.D1_Diageo_One + docLink.ContentDocumentId;
                }    
            }
        }
        return contentDocumentURL;
    }
    
    @AuraEnabled
    public static ContactPointAddressWrapper getOutletDetail(String caseRecordId){
        
        ContactPointAddressWrapper contactPointAddrWrapper = new ContactPointAddressWrapper();
        List<Case> caseObjList = [SELECT Id, /*D1_Shipping_Account__c,*/ ContactId, AccountId, Account.Name, Account.BillingStreet, Account.BillingCity, 
                                    Account.BillingCountry, Account.KUNNR__c FROM Case WHERE Id =:caseRecordId];
        
        contactPointAddrWrapper.name = caseObjList.get(0).Account.Name;
        contactPointAddrWrapper.accountNumber = caseObjList.get(0).Account.KUNNR__c ;
        contactPointAddrWrapper.street = caseObjList.get(0).Account.BillingStreet;
        contactPointAddrWrapper.city = caseObjList.get(0).Account.BillingCity;
        contactPointAddrWrapper.country = caseObjList.get(0).Account.BillingCountry;
        //Commented Below code due to refactor - 152938
        //Now all D1 cases are link to Ship-To we dont need to filter out based on Direct/InDirect
        /*List<User> userList = [SELECT Id, D1_User_Type__c FROM User WHERE ContactId = :caseObjList.get(0).ContactId LIMIT 1];
        if(userList.get(0).D1_User_Type__c == 'Outlet/Retailers'){
            contactPointAddrWrapper.name = caseObjList.get(0).Account.Name;
            contactPointAddrWrapper.accountNumber = caseObjList.get(0).Account.KUNNR__c ;
            contactPointAddrWrapper.street = caseObjList.get(0).Account.BillingStreet;
            contactPointAddrWrapper.city = caseObjList.get(0).Account.BillingCity;
            contactPointAddrWrapper.country = caseObjList.get(0).Account.BillingCountry;
        }
        else{
            if (caseObjList!=null && caseObjList.size()>0) {
                List<Account> shippingAccList = [SELECT id,KUNNR__c from account where Id=:caseObjList.get(0).D1_Shipping_Account__c];
                
                if (shippingAccList!=null && shippingAccList.size()>0) {
                    List<contactpointAddress> contactpointAddressObjList = [SELECT id,name,Account_Number__c,street,city,country from contactPointAddress where Account_Number__c=:shippingAccList.get(0).KUNNR__c];
                
                    if (contactpointAddressObjList!=null && contactpointAddressObjList.size()>0) {
                        contactPointAddrWrapper.name = contactpointAddressObjList.get(0).name;
                        contactPointAddrWrapper.accountNumber = contactpointAddressObjList.get(0).Account_Number__c;
                        contactPointAddrWrapper.street = contactpointAddressObjList.get(0).street;
                        contactPointAddrWrapper.city = contactpointAddressObjList.get(0).city;
                        contactPointAddrWrapper.country = contactpointAddressObjList.get(0).country;    
                    }
                }
            }
        }*/

        return contactPointAddrWrapper;
    }
    
    public class CaseWrapper{
        @AuraEnabled
        public String topic{get;set;}
        @AuraEnabled
        public String subject{get;set;}
        @AuraEnabled
        public String description{get;set;}
        @AuraEnabled
        public String selectedDocumentNo{get;set;}
        @AuraEnabled
        public String documentType{get;set;}
        @AuraEnabled
        public String selectedDeliverToAddressId{get;set;}
        //NCP-2610
        @AuraEnabled
        public String selectedOrderNumber{get;set;}
        @AuraEnabled
        public String deliveryNumber{get;set;}
        @AuraEnabled
        public String invoiceNumber{get;set;}
        @AuraEnabled
        public String batchNumber{get;set;}
        @AuraEnabled
        public String noOfitemsToReturn{get;set;}
        /*@AuraEnabled
        public String selectedContractNumber{get;set;}*/
        @AuraEnabled
        public String contactEmail{get;set;}
        @AuraEnabled
        public String reasonForCancellationValue{get;set;}
        //NCP-7727
        @AuraEnabled
        public String equipment{get;set;}
        @AuraEnabled
        public String equipmentIssue{get;set;}
        @AuraEnabled
        public String masterBundleId{get;set;}
    }

    public class ContactPointAddressWrapper{
        @AuraEnabled
        public String name{get;set;}
        @AuraEnabled
        public String accountNumber{get;set;}
        @AuraEnabled
        public String street{get;set;}
        @AuraEnabled
        public String city{get;set;}
        @AuraEnabled
        public String country {get;set;}
    }
    
    public class FeedItemWrapper{
        @AuraEnabled public String feedId;
        @AuraEnabled public String createdbyName;
        @AuraEnabled public String feedBody;
        @AuraEnabled public String feedTime;
        //Added for NCP-2297
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String relatedRecordId;
        @AuraEnabled public String contentDocumentURL;
        
        FeedItemWrapper(FeedItem feed){
            this.feedId = feed.Id;
            this.createdbyName = feed.CreatedBy.FirstName + ' ' + feed.CreatedBy.LastName;
            this.feedBody = feed.Body;
            this.feedTime = getElapsedTime(feed.CreatedDate);
            //Added for NCP-2297
            this.relatedRecordId = feed.RelatedRecordId;
        }
    }
    
    public static String getElapsedTime(DateTime startDateTime){
        Long startTime = startDateTime.getTime();
        Long timeNow = DateTime.now().getTime();
        Long milliseconds = timeNow - startTime;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Long hours = minutes / 60;
        Long days = hours / 24;
        
        
        
        return days > 0 ?  System.Label.D1_days.replace('{0}',string.valueOf(days)) : (hours > 0) ? 
                            System.Label.D1_Hours.replace('{0}',string.valueOf(hours)) : (minutes > 0) ? 
                            System.Label.D1_Minutes_Ago.replace('{0}',string.valueOf(minutes)) : System.Label.D1_Justnow;
        
    }
    
    /*  
    * @userstory :  NCP-1542
    * @discription:  get Map subject and Block from metadata
    * @Param: none
    * @Return: to get map of subject and block from metadata
    * Throws: Nil   
    */
    
     
    
     @AuraEnabled(cacheable = true)
    public static Map<String,Boolean> getSubjectVisibilityMap(){
        Map<String,Boolean> subjectVisibilitymap = new Map<String,Boolean>();
        List<Support_Topic_Configs__mdt> supportTopicList = [ SELECT Id,Available_On_Details__c,Subject__c FROM Support_Topic_Configs__mdt];
        for(Support_Topic_Configs__mdt supportTopicRecd : supportTopicList){
            subjectVisibilitymap.put(supportTopicRecd.Subject__c,supportTopicRecd.Available_On_Details__c);
        }
        return subjectVisibilitymap;
    } 

    @AuraEnabled
    public static Decimal  checkContentDocumentSize(Id contentVersionId){
        List<ContentDocument> contentDocumentList = new List<ContentDocument>();
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        Decimal  fileSize = 0.0;
        if(contentVersionId != null){
            contentVersionList = [SELECT ContentDocumentId from ContentVersion where Id = : contentVersionId];
        }
        if(contentVersionList.size()>0){
          contentDocumentList = [SELECT Id,ContentSize,Title,FileType FROM ContentDocument WHERE Id = :contentVersionList[0].ContentDocumentId];  
        }
        if(contentDocumentList.size()>0){
            Decimal temp = contentDocumentList[0].ContentSize;
            fileSize = temp.divide(1048576, 2);
            if(fileSize > 7.0){
               database.delete(contentDocumentList); 
            }   
        }
        return fileSize;
    }

    //Case Wrapper

}