/**
 * @name D_1BulkContactRegistrationController
 * @description D1_BulkContactRegistrationController Class for validating user's registration request for direct customer
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0        Narayana     04/02/2022        NCP-5958        
 **/
global with sharing class D1_BulkResendInviteController {
    public static final String DIAGEOONE_EXTERNAL_PROFILE = 'DiageoOne External User';
    @InvocableMethod
    public Static List<Response> resendBulkInvite(List<Requests> requestList){
        Response res = new Response();
        res.success = true;
        System.enqueueJob(new ResendBulkInviteAsync(requestList[0].contactId));
        List<Response> responseWrapper= new List<Response>();
        responseWrapper.add(res);
        return responseWrapper;

    }
    global class Requests {
        @InvocableVariable(label='contactId')
        global List<String> contactId;
    }
    global class Response {
        @InvocableVariable(label='success')
        global Boolean success;
    }

    public class ResendBulkInviteAsync implements Queueable {
        public List<String> contactIdCol;
        public ResendBulkInviteAsync(List<String> values){
            this.contactIdCol = values;
        }
        public void execute(QueueableContext context) {
            processBulkResendInvite(contactIdCol);
        }
    }

    public static void processBulkResendInvite(List<string> contactIdList){
        Map<Id,ResendInviteWrapper> resendInviteMap = processContactsForResend(contactIdList);
        sendEmail(resendInviteMap.values());
    }
    public static Map<Id,D1_BulkResendInviteController.ResendInviteWrapper> processContactsForResend(List<String> contactIds){
        Set<String> successContactIds = new Set<String>();
        Map<Id, ResendInviteWrapper> resendInviteMap = new Map<Id,ResendInviteWrapper>();
        if(!contactIds.isEmpty()){
            Set<String> contactIdSet = new Set<String>(contactIds);
            for(User usr : [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Phone,Contact.MD_SubscriptionDate__c,
                            Contact.D1_Contact_Last_Login_Date__c,Contact.D1_Invite_sent__c,Contact.D1_Login_Reminder_Status__c,
                            AccountId, Account.Name, Account.AccountNumber, Account.Country__c,isActive  FROM User 
                            WHERE ContactId IN :contactIdSet AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE])
            {
                if(isValidUser(usr)){
                    successContactIds.add(usr.ContactId);
                    ResendInviteWrapper resendInviteWrapper = createResendInviteWrapper(usr,'Success');
                    resendInviteMap.put(usr.ContactId,resendInviteWrapper);
                    System.resetPasswordWithEmailTemplate(usr.Id, true, 'D1_ReInvite_Email_to_Customers_Registration');//This statement is treated as DML by APEX Limit 150 in async
                }
                else{
                    if(!Usr.isActive){
                        ResendInviteWrapper resendInviteWrapper = createResendInviteWrapper(usr,'User should be active');
                        resendInviteMap.put(usr.ContactId,resendInviteWrapper);
                    }
                    else{
                        ResendInviteWrapper resendInviteWrapper = createResendInviteWrapper(usr,'Already D1 subscribed');
                        resendInviteMap.put(usr.ContactId,resendInviteWrapper);
                    }
                }
                contactIdSet.remove(usr.ContactId);
            }
            if(contactIdSet.size()>0){
                for(Contact con : [SELECT Id, Name, Email, Phone,MD_SubscriptionDate__c,
                                    D1_Contact_Last_Login_Date__c,D1_Invite_sent__c,D1_Login_Reminder_Status__c,
                                    AccountId, Account.Name, Account.AccountNumber, Account.Country__c from Contact
                                    where Id IN:contactIdSet
                                    ])
                {
                    ResendInviteWrapper resendInviteWrapper = createResendInviteWrapperFromContact(con,'User should be active');
                    resendInviteMap.put(con.Id,resendInviteWrapper);
                }

            }

        }
        if(successContactIds.size()>0){
            updateContactFields(successContactIds);
        }
        return resendInviteMap;
    }
    public static ResendInviteWrapper createResendInviteWrapperFromContact(Contact con,String status){
        ResendInviteWrapper resendInviteWrapper = new ResendInviteWrapper();
        String emptyString ='';
        resendInviteWrapper.contactName = con.Name!=null? con.Name : emptyString;
        resendInviteWrapper.status = status!=null? status : emptyString;
        resendInviteWrapper.email =con.Email!=null ?con.Email : emptyString;
        resendInviteWrapper.accNo = con.Account.AccountNumber!=null?con.Account.AccountNumber : emptyString;
        resendInviteWrapper.accName = con.Account.Name!=null?con.Account.Name : emptyString;
        resendInviteWrapper.phoneVal = con.Phone!=null?con.Phone : emptyString;
        resendInviteWrapper.marketId = con.Account.Country__c;
        return resendInviteWrapper;
    }
    public static boolean isValidUser(User usr){//NCP-6795 //NCP-8078 - added new picklist value conditions
         if( usr.isActive && usr.Contact.D1_Contact_Last_Login_Date__c==null 
             && usr.Contact.D1_Invite_sent__c!=null && ( usr.Contact.D1_Login_Reminder_Status__c==null  || 
             usr.Contact.D1_Login_Reminder_Status__c.contains('Invite Resent') || 
             usr.Contact.D1_Login_Reminder_Status__c.contains('First Reminder Invite Resent') ||
             usr.Contact.D1_Login_Reminder_Status__c.contains('Second Reminder Invite Resent')) ) {
                return true;
        }
        return false;
    } 
    //Method to send Email
    public static void sendEmail(List<D1_BulkResendInviteController.ResendInviteWrapper> wrapList){
        String header = '<th style="background-color:#FFF2CC">No.</th>'+'<th style="background-color:#FFF2CC">Contact name </th>'+'<th style="background-color:#FFF2CC">Account No </th>';
        header=header+'<th style="background-color:#FFF2CC">Account Name </th>'+'<th style="background-color:#FFF2CC">Email</th>'+'<th style="background-color:#FFF2CC">Phone</th>';
        header=header+'<th style="background-color:#FFF2CC">Status</th>'+'<th style="background-color:#FFF2CC">Date and Time </th>';
       // String header = 'No. '+'\t'+ 'Contact name '+'\t' +'Account No '+'\t'+ 'Account Name '+'\t'+ 'Email '+'\t'+ 'Phone '+'\t'+'Status '+'\t'+ 'Date and Time '+'\n';
        String finalstr ='<table border="1">'+ header;
        Integer rowCount = 1;
        Date dateVal = Date.today();
        String str = String.valueof(DateTime.now());
        String sDate = String.valueof(dateVal.day())+ '/' + String.valueof(dateVal.month()) + '/'+String.valueof(dateVal.year()) +' '+ str.substringAfter(' ');
        Set<String> marketIdSet = new Set<String>();
        List<String> address = new List<String>();
        
        for(ResendInviteWrapper wrapObj : wrapList){
            marketIdSet.add(wrapObj.marketId);
            finalstr = finalstr + '<tr><td>' +rowCount ;
            finalstr = finalstr +'</td><td>'+wrapObj.contactName + '</td><td>' + wrapObj.accNo + '</td><td>' + wrapObj.accName + '</td><td>' + wrapObj.email + '</td><td>' + wrapObj.phoneVal + '</td><td>';
            finalstr = finalstr + wrapObj.status + '</td><td>' + sDate + '</td></tr>';
            rowCount++;    
        }
        finalstr=finalstr+'</table>';
        
        //Get Email Ids
        address = D1_RegistrationDirectCustomerController.getEmail(marketIdSet);
        address.add(UserInfo.getUserEmail());
        
        //Get Blob Value of data
        Blob b = blob.valueOf(finalstr);
        
        //Creating Message
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(address);
        Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
        a.setBody(b);
        a.setContentType('application/vnd.ms-excel');
        a.setFileName('Bulk Registration Invite Report.xls');
        a.setInline(false);
        m.setFileAttachments(new Messaging.EmailFileAttachment[] { a } );
        m.setSubject('Bulk Registration Invite Completed');
        m.setPlainTextBody('Please see attachment for detail result.');
        OrgWideEmailAddress orgWideObj = [select DisplayName,Id from OrgWideEmailAddress where DisplayName = 'DiageoOne'];
        m.setOrgWideEmailAddressId(orgWideObj.Id);
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { m } );
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { m } );
        if (results[0].success) {
            System.debug(LoggingLevel.INFO,'@@The email was sent successfully.');
        } else {
            System.debug(LoggingLevel.ERROR, results[0].errors[0].message);
        }
    }      
    public static void updateContactFields(Set<String> successContactIds){
        List<Contact> contactsToUpdate = new List<Contact>();
        
        if(successContactIds.size()>0)
        {   
            for(contact con : [SELECT id,D1_Login_Reminder_Status__c,D1_Invite_sent__c FROM Contact WHERE Id IN:successContactIds]){ //NCP-8078- Adding condition once manual bulk invite sent
				
                con.D1_Login_Reminder_Status__c = (con.D1_Login_Reminder_Status__c == null)? 'First Reminder Invite Resent' : 
                                                  (con.D1_Login_Reminder_Status__c == 'First Reminder Invite Resent' ? 'Second Reminder Invite Resent' : 'Invite Resent'); //NCP-8078
                con.D1_Invite_sent__c = Date.Today();
                contactsToUpdate.add(con);
            }   
            update contactsToUpdate; 
        }       
    }

    public static ResendInviteWrapper createResendInviteWrapper(User usr,String status){
        ResendInviteWrapper resendInviteWrapper = new ResendInviteWrapper();
        String emptyString ='';
        resendInviteWrapper.contactName = usr.Contact.Name!=null? usr.Contact.Name : emptyString;
        resendInviteWrapper.status = status!=null? status : emptyString;
        resendInviteWrapper.email =usr.Contact.Email!=null ?usr.Contact.Email : emptyString;
        resendInviteWrapper.accNo = usr.Account.AccountNumber!=null?usr.Account.AccountNumber : emptyString;
        resendInviteWrapper.accName = usr.Account.Name!=null?usr.Account.Name : emptyString;
        resendInviteWrapper.phoneVal = usr.Contact.Phone!=null?usr.Contact.Phone : emptyString;
        resendInviteWrapper.marketId =usr.Account.Country__c;
        return resendInviteWrapper;
    }

     //Wrapper Class
     public class ResendInviteWrapper {
        @AuraEnabled public String userId {get;set;}
        @AuraEnabled public String contactId {get; set;}
        @AuraEnabled public String contactName {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public Boolean isSuccess {get; set;}
        @AuraEnabled public String accNo {get; set;}
        @AuraEnabled public String accName {get; set;}
        @AuraEnabled public String phoneVal {get; set;}
        @AuraEnabled public String marketId {get; set;}
    }
}