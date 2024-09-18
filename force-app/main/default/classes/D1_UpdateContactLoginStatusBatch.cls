/**
 * @name D1_UpdateContactLoginStatusBatch
 * @purpose Batch Class for monitoring and updating contact login history
 * @history                                                                                                                       
 * VERSION   AUTHOR             DATE              DETAIL
 * 1.0       Rubeena Naaz       21/12/2021        NCP-3359
 * 2.0       Kapil Baliyan      19/08/2022        NCP-7209
 * 3.0		 Subhrojit Majumdar	07/11/2022		  NCP-7386
 * 4.0       Kapil Baliyan      07/06/2023        NCP-8332 (Adding Org Wide Email Address Id)
**/

public class D1_UpdateContactLoginStatusBatch implements Database.Batchable<sobject>, Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Map<String,EmailTemplate> emailTempMap = new Map<String,EmailTemplate>();
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode = '';
    Map<String, String> labelToTranslatedStrMap = new Map<String,String>();
    Set<string> statusValues = new Set<String>{'Compliant','First Reminder','Second Reminder'};
    List<User> toDeactivateUser = new List<User>();
    
    //Constructor
    public D1_UpdateContactLoginStatusBatch(){
        //Fetch Required EmailTemplates
        for(EmailTemplate empTemp :[SELECT Id,Name,DeveloperName, FolderId, FolderName, IsActive, Body, Subject, Description, HtmlValue 
                                    FROM EmailTemplate 
                                    WHERE Folder.Name ='D1_EmailTemplates' 
                                    AND DeveloperName LIKE 'D1_Mailer%'])
        {
            emailTempMap.put(empTemp.DeveloperName,empTemp);
        }
    } 
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        
        //Query contacts countrywise whose next action date is less than equal to today //NCP-6408
        String query = 'SELECT Id,Email,FirstName,D1_Login_Counter__c,D1_Generic_Login_Counter__c,D1_CSG_Email__c,AccountId,Next_Action_Date__c,D1_Contact_Last_Login_Date__c,D1_Login_Reminder_Status__c,'+
                        'Account.Country_Code__c, MD_SubscriptionDate__c,D1_Invite_sent__c,Registration_Source__c,MD_ContactSubscriptions__c,MD_SubscriptionSource__c,D1_Setting__r.Language__c, D1_User__c, D1_NPS_Average_Score__c, D1_NPS_Survey_Date__c, D1_NPS_Survey_Name__c '+
            			'FROM Contact WHERE Next_Action_Date__c <= TODAY AND Account.Country_Code__c =:countryCode AND D1_Login_Reminder_Status__c IN :statusValues' ; 
        
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Contact> contactList){
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        Map<Id,Contact> primaryContactMap = new Map<Id,Contact>();
        Set<Id> accountIds = new Set<Id>();
        List<Messaging.SingleEmailMessage> emailsToSend = new  List<Messaging.SingleEmailMessage>();
        List<Contact> updateContact = new List<Contact>();
        Map<Id,Id> accountPrimaryContactMap = new Map<Id,Id>();
        Map<Id,User> contactUserMap = new Map<Id,User>();
        Map<Id,String> contactTypeMap = new Map<Id,String>();
        Map<Id,Set<Id>> contactAccountMap = new Map<Id,Set<Id>>();
        Map<Id,List<AccountContactRelation>> contactACRMap = new Map<Id,List<AccountContactRelation>>();
        List<AccountContactRelation> acrRecordsToUpdate = new List<AccountContactRelation>();
               
        try{
            if(!contactList.isEmpty()){
                for(Contact con : contactList){
                    contactMap.put(con.Id,con);
                }
            }

            //Checking if the contact is Primary/Secondary[mark contact as primary if its primary to even one account, otherwise it stays member of staff]
            if(!contactMap.isEmpty()){
                for(AccountContactRelation acr : [SELECT Id,D1_User_Role__c,ContactId,AccountId,D1_Active__c,D1_Roles__c 
                                                    FROM AccountContactRelation 
                                                    WHERE ContactId IN:contactMap.keyset() AND D1_Active__c = true
                                                    ORDER BY ContactId, D1_User_Role__c ASC])
                {
                    if(!contactTypeMap.containsKey(acr.ContactId) && acr.D1_User_Role__c != null){
                        contactTypeMap.put(acr.ContactId,acr.D1_User_Role__c);
                    }
                    if(contactTypeMap.containsKey(acr.ContactId) && contactTypeMap.get(acr.ContactId) != 'Primary' && acr.D1_User_Role__c == 'Primary'){
                        contactTypeMap.put(acr.ContactId,acr.D1_User_Role__c);
                    }

                    //NCP-5840
                    if(contactAccountMap.containsKey(acr.ContactId)){
                        contactAccountMap.get(acr.ContactId).add(acr.AccountId);
                        contactACRMap.get(acr.ContactId).add(acr);
                    }
                    else{
                        contactAccountMap.put(acr.ContactId, new Set<Id>{acr.AccountId});
                        contactACRMap.put(acr.ContactId, new List<AccountContactRelation>{acr});
                    }
                    accountIds.add(acr.AccountId);
                }

                for(User user : [SELECT Id,IsActive,ContactId,LanguageLocaleKey FROM User WHERE ContactId IN :contactMap.keyset() AND IsActive = true]){
                    contactUserMap.put(user.ContactId,user);
                }
            }
                        
            //Checking if there is any associated Primary Contact to the availabe account
            if(!accountIds.isEmpty()){
                for(AccountContactRelation acr : [SELECT Id,D1_User_Role__c,ContactId,AccountID 
                                                    FROM AccountContactRelation 
                                                    WHERE AccountID IN:accountIds AND D1_Active__c = true AND D1_User_Role__c = 'Primary'
                                                    ORDER BY ContactId, D1_User_Role__c ASC])
                {
                    //Get respective ACR for the contact to check Primary/Secondary
                    //KB: Can we add D1_User_Role__c = 'Primary' Filter in query instead of iterating and then checking
                    accountPrimaryContactMap.put(acr.AccountId,acr.ContactId);
                }
            }

            if(!accountPrimaryContactMap.isEmpty()){
                for(Contact con : [SELECT Id,Email,FirstName,D1_CSG_Email__c,AccountId,D1_Login_Reminder_Status__c,Next_Action_Date__c
                                   FROM Contact WHERE ID IN: accountPrimaryContactMap.values()])
                {
                    primaryContactMap.put(con.Id,con);
                }
            }
            if(!contactList.isEmpty()){
                //Get Org wide email address (NCP-8332)
                OrgWideEmailAddress orgWideObj = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = 'DiageoOne' LIMIT 1];

                for(Contact con : contactList){
                    Set<Id> existingContacts = new Set<Id>();
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                    String preferredLanguage = con.D1_Setting__r.Language__c != null ? con.D1_Setting__r.Language__c : 'en_US';

                    labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'D1_Hi', 'D1_Dear','D1_Mailer_First_Login_Reminder_Notification1','D1_Second_Login_Reminder_To_Primary_User',
                	'D1_Second_Login_Reminder_To_Primary_User_Body1','D1_Second_Login_Reminder_To_Primary_User_Body2','D1_Any_Questions_text','D1_Transfer_Order_Email_Body_7','D1_Transfer_Order_Footer',
                	'D1_Transfer_Order_Footer_2','D1_Transfer_Order_Footer_1','D1_Copyright_2020_All_rights_reserved_Diageo_PLC','D1_Second_Login_Reminder_Sub','D1_Mailer_First_Body1','D1_Username','D1_Login',
                    'D1_Second_Login_Reminder_Body','D1_Unsubscribed_Sub','D1_User','D1_Deactivation_Notification_PrimaryUser_Body','D1_Unsubscribed_from_DiageoOne','D1_We_are_sorry_to_see_you_go','D1_Second_Login_Reminder_Sub_2','D1_Unsubscribed_Sub_2'},preferredLanguage);

                    //Case1: User has not logged since 1 year
                    if(con.D1_Login_Reminder_Status__c == 'Compliant' && contactTypeMap.get(con.Id) != null){
                        EmailTemplate et1 = emailTempMap.get('D1_Mailer_First_Login_Reminder');
                        String emailBody1 = et1.HtmlValue;
                        emailBody1 = createTemplate(emailBody1,labelToTranslatedStrMap);
                        emailBody1  = emailBody1.replace('{!Contact.Email}', returnDefaultIfBlank(con.Email));
                        emailBody1  = emailBody1.replace('{!Contact.FirstName}', returnDefaultIfBlank(con.FirstName));
                        emailBody1  = emailBody1.replace('{!Contact.D1_CSG_Email__c}', returnDefaultIfBlank(con.D1_CSG_Email__c));
                        
                        email.setToAddresses(new String[] {con.Email});
                        email.setTemplateId(et1.Id);
                        email.setHtmlBody(emailBody1);
                        email.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Second_Login_Reminder_Sub')));
                        email.setOrgWideEmailAddressId(orgWideObj.Id); //NCP-8332
                        emailsToSend.add(email);

                        //Contact is secondary, and primary contact must be notified also
                        if(contactTypeMap.get(con.Id) == 'Member of Staff'){
                            //If Primary Contacts exists for this user //NCP-5840
                            Set<Id> accList = contactAccountMap.get(con.Id);
                            if(!accList.isEmpty()){
                                for(Id accountId : accList){
                                    if(accountPrimaryContactMap.get(accountId) != null && !existingContacts.contains(accountPrimaryContactMap.get(accountId))){
                                        Contact priContact = primaryContactMap.get(accountPrimaryContactMap.get(accountId));
                                    
                                        EmailTemplate et = emailTempMap.get('D1_Mailer_First_Login_Reminder_Notification_to_Primary_User');
                                        String emailBody = et.HtmlValue;
                                        emailBody = createTemplate(emailBody,labelToTranslatedStrMap);
                                        emailBody  = emailBody.replace('{!$Label.D1_Primary_User_First_Name}', priContact.FirstName);
                                        emailBody  = emailBody.replace('{!Contact.FirstName}', returnDefaultIfBlank(con.FirstName));
                                        emailBody  = emailBody.replace('{!Contact.D1_CSG_Email__c}', returnDefaultIfBlank(con.D1_CSG_Email__c));
                                        
                                        Messaging.SingleEmailMessage priEmail = new Messaging.SingleEmailMessage();
                                        priEmail.setToAddresses(new String[] {priContact.Email});
                                        priEmail.setTemplateId(et.Id);
                                        priEmail.setHtmlBody(emailBody);
                                        priEmail.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Mailer_First_Login_Reminder_Notification1')));
                                        priEmail.setOrgWideEmailAddressId(orgWideObj.Id); //NCP-8332
                                        emailsToSend.add(priEmail);
                                        existingContacts.add(priContact.Id);
                                    }
                                }
                            }
                        }
                        //update the status
                        con.D1_Login_Reminder_Status__c = 'First Reminder'; 
                    }
                    //Case 2:User has not logged in for more than an year and first reminder already sent
                    else if(con.D1_Login_Reminder_Status__c == 'First Reminder' && contactTypeMap.get(con.Id) != null){
                        EmailTemplate et1 = emailTempMap.get('D1_Mailer_Second_Login_Reminder');
                        String emailBody1 = et1.HtmlValue;
                        emailBody1 = createTemplate(emailBody1,labelToTranslatedStrMap);
                        emailBody1  = emailBody1.replace('{!Contact.Email}', returnDefaultIfBlank(con.Email));
                        emailBody1  = emailBody1.replace('{!Contact.FirstName}', returnDefaultIfBlank(con.FirstName));
                        emailBody1  = emailBody1.replace('{!Contact.D1_CSG_Email__c}', returnDefaultIfBlank(con.D1_CSG_Email__c));
                        
                        email.setToAddresses(new String[] {con.Email});
                        email.setTemplateId(et1.Id);
                        email.setHtmlBody(emailBody1);
                        email.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Second_Login_Reminder_Sub_2')));
                        email.setOrgWideEmailAddressId(orgWideObj.Id); //NCP-8332
                        emailsToSend.add(email);
                        
                        //Contact is secondary and primary contact must be notified also
                        if(contactTypeMap.get(con.Id) == 'Member of Staff'){
                            //If Primary Contacts exists for this user //NCP-5840
                            Set<Id> accList = contactAccountMap.get(con.Id);
                            if(!accList.isEmpty()){
                                for(Id accountId : accList){
                                    if(accountPrimaryContactMap.get(accountId) != null && !existingContacts.contains(accountPrimaryContactMap.get(accountId))){
                                        Contact priContact = primaryContactMap.get(accountPrimaryContactMap.get(accountId));
                                        
                                        EmailTemplate et = emailTempMap.get('D1_Mailer_Second_Login_Reminder_Notification_to_Primary_User');                      
                                        String emailBody = et.HtmlValue;
                                        emailBody = createTemplate(emailBody,labelToTranslatedStrMap);
                                        emailBody  = emailBody.replace('{!$Label.D1_Primary_User_First_Name}', priContact.FirstName);
                                        emailBody  = emailBody.replace('{!Contact.FirstName}', returnDefaultIfBlank(con.FirstName));
                                        emailBody  = emailBody.replace('{!Contact.D1_CSG_Email__c}', returnDefaultIfBlank(con.D1_CSG_Email__c));
                                        
                                        Messaging.SingleEmailMessage priEmail = new Messaging.SingleEmailMessage();
                                        priEmail.setToAddresses(new String[] {priContact.Email});
                                        priEmail.setTemplateId(et.Id);
                                        priEmail.setHtmlBody(emailBody);
                                        priEmail.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Second_Login_Reminder_To_Primary_User')));
                                        priEmail.setOrgWideEmailAddressId(orgWideObj.Id); //NCP-8332
                                        emailsToSend.add(priEmail);
                                        existingContacts.add(priContact.Id);
                                    }
                                }
                            }
                        }
                        //update the status
						con.D1_Login_Reminder_Status__c = 'Second Reminder';
                    }
                    
                    //Case 3:User has not logged in for over an year and second reminder also sent
                    else if(con.D1_Login_Reminder_Status__c == 'Second Reminder' && contactTypeMap.get(con.Id) != null){
                        
                        //If the user is primary, update the status
                        if(contactTypeMap.get(con.Id) == 'Primary'){
                            con.D1_Login_Reminder_Status__c = 'User To be Deactivated';
                        }
                        
                        //If user is secondary, check if primary is compliant or not
                        else{
                            List<Messaging.SingleEmailMessage> tempEmailList = new  List<Messaging.SingleEmailMessage>();
                            //NCP-5840
                            Boolean isPrimaryCompliant = true;
                            Set<Id> accList = contactAccountMap.get(con.Id);
                            if(!accList.isEmpty()){
                                for(Id accountId : accList){
                                    if(accountPrimaryContactMap.get(accountId) != null){
                                        //Primary Contact is also not compliant
                                        if(primaryContactMap.get(accountPrimaryContactMap.get(accountId)).D1_Login_Reminder_Status__c != 'Compliant' ||
                                            primaryContactMap.get(accountPrimaryContactMap.get(accountId)).Next_Action_Date__c <= System.today()){
                                            isPrimaryCompliant = false;
                                            break;
                                        }
                                        else{ //Prepare template if primary is compliant
                                            if(!existingContacts.contains(accountPrimaryContactMap.get(accountId))){
                                                Contact priContact = primaryContactMap.get(accountPrimaryContactMap.get(accountId));
                                            
                                                EmailTemplate et = emailTempMap.get('D1_Mailer_Deactivation_Notification_to_Primary_User');                      
                                                String emailBody = et.HtmlValue;
                                                emailBody = createTemplate(emailBody,labelToTranslatedStrMap);
                                                emailBody  = emailBody.replace('{!$Label.D1_Primary_User_First_Name}', priContact.FirstName);
                                                emailBody  = emailBody.replace('{!Contact.FirstName}', returnDefaultIfBlank(con.FirstName));
                                                emailBody  = emailBody.replace('{!Contact.D1_CSG_Email__c}', returnDefaultIfBlank(con.D1_CSG_Email__c));
                                                
                                                Messaging.SingleEmailMessage priEmail = new Messaging.SingleEmailMessage();
                                                priEmail.setToAddresses(new String[] {priContact.Email});
                                                priEmail.setTemplateId(et.Id);
                                                priEmail.setHtmlBody(emailBody);
                                                priEmail.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Unsubscribed_Sub_2')));
                                                priEmail.setOrgWideEmailAddressId(orgWideObj.Id); //NCP-8332
                                                tempEmailList.add(priEmail);
                                                existingContacts.add(priContact.Id);
                                            }
                                        }
                                    }
                                }
                                if(!isPrimaryCompliant){
                                    con.D1_Login_Reminder_Status__c = 'User To be Deactivated';   
                                }
                                else{
                                    //create secondary email template
                                    EmailTemplate et1 = emailTempMap.get('D1_Mailer_User_Deactivation_Notification');
                                    String emailBody1 = et1.HtmlValue;
                                    emailBody1 = createTemplate(emailBody1,labelToTranslatedStrMap);
                                    emailBody1  = emailBody1.replace('{!Contact.FirstName}', returnDefaultIfBlank(con.FirstName));
                                    emailBody1  = emailBody1.replace('{!Contact.D1_CSG_Email__c}', returnDefaultIfBlank(con.D1_CSG_Email__c));
                                    
                                    email.setToAddresses(new String[] {con.Email});
                                    email.setTemplateId(et1.Id);
                                    email.setHtmlBody(emailBody1);
                                    email.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Unsubscribed_Sub')));
                                    email.setOrgWideEmailAddressId(orgWideObj.Id); //NCP-8332
                                    emailsToSend.add(email);

                                    //Get users list that needs to be deactivated
                                    if(contactUserMap.containsKey(con.Id)){
                                        User user = contactUserMap.get(con.Id);
                                        user.IsActive = false;
                                        toDeactivateUser.add(user);
                                    }
                                    con.D1_Login_Reminder_Status__c = 'Deactivated';
                                    con.D1_Login_Counter__c = 0;//NCP-6925
                                    con.D1_Generic_Login_Counter__c = 0; //NCP-7458
                                    con.MD_SubscriptionDate__c = null; //NCP-6408
                                    con.D1_Invite_sent__c = null;
                                    con.D1_Contact_Last_Login_Date__c = null;
                                    con.Next_Action_Date__c =null;
                                    con.Registration_Source__c = '';
                                    con.MD_ContactSubscriptions__c = '';
            						con.MD_SubscriptionSource__c = '';
                                    con.D1_Last_opt_in_reminder_date__c = null;//NCP-6760
                                    con.D1_opt_in_Success_date__c = null;
                                    con.D1_User__c = FALSE; //NCP-7209
                                    con.D1_NPS_Average_Score__c = null;//NCP-7386
									con.D1_NPS_Survey_Date__c = null;//NCP-7386
									con.D1_NPS_Survey_Name__c = '';//NCP-7386

                                    //Add tempEmailList to emailsToSend List
                                    emailsToSend.addAll(tempEmailList);

                                    //Get ACRs to be updated for the contact
                                    List<AccountContactRelation> acrToUpdate = contactACRMap.get(con.Id);
                                    if(!acrToUpdate.isEmpty()){
                                        for(AccountContactRelation acr : acrToUpdate){
                                            acr.D1_Active__c = false;
                                            acr.D1_Roles__c = '';
                                            acr.D1_User_Role__c='';
                                            acrRecordsToUpdate.add(acr);
                                        }
                                    } 
                                }
                            }  
                        }
                    }
                    updateContact.add(con);
                }

                //Update ACR Records
                if(acrRecordsToUpdate.size() > 0){
                    update acrRecordsToUpdate;
                }
                
                //Update Contact
                if(updateContact.size() > 0){
                    update updateContact;
                }
                
                //Send Email
                if(!emailsToSend.isEmpty()){
					Messaging.sendEmail(emailsToSend);
                }
            }
        }
        catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    public void finish(Database.BatchableContext bc){ 
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'D1_UpdateContactLoginStatusBatch', exceptionMsg);
        }    
        else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
            //Update users to be deactivated
            if(!toDeactivateUser.isEmpty()){ 
                System.enqueueJob(new D1_UserUpdateQueueable(toDeactivateUser));
            }
        }

        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
    //Get Translated Values of the template
    private String createTemplate(String emailBody, Map<String,String> labelToTranslatedStrMap){

        String redirectLink = System.Label.D1_Community_Link+'/login';
        
        emailBody  = emailBody.replace('{!$Label.D1_Hi}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Hi')));
        emailBody  = emailBody.replace('{!$Label.D1_Dear}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Dear')));
        emailBody  = emailBody.replace('{!$Label.D1_Mailer_First_Login_Reminder_Notification1}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Mailer_First_Login_Reminder_Notification1')));
        emailBody  = emailBody.replace('{!$Label.D1_Second_Login_Reminder_To_Primary_User}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Second_Login_Reminder_To_Primary_User')));
        emailBody  = emailBody.replace('{!$Label.D1_Second_Login_Reminder_To_Primary_User_Body1}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Second_Login_Reminder_To_Primary_User_Body1')));
        emailBody  = emailBody.replace('{!$Label.D1_Second_Login_Reminder_To_Primary_User_Body2}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Second_Login_Reminder_To_Primary_User_Body2')));
        emailBody  = emailBody.replace('{!$Label.D1_Any_Questions_text}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Any_Questions_text')));
        emailBody  = emailBody.replace('{!$Label.D1_Transfer_Order_Email_Body_7}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Email_Body_7')));
        emailBody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Footer')));
        emailBody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_1}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Footer_1')));
        emailBody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_2}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Footer_2')));
        emailBody  = emailBody.replace('{!$Label.D1_Copyright_2020_All_rights_reserved_Diageo_PLC}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Copyright_2020_All_rights_reserved_Diageo_PLC')));
        emailBody  = emailBody.replace('{!$Label.D1_Second_Login_Reminder_Sub}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Second_Login_Reminder_Sub')));
        emailBody  = emailBody.replace('{!$Label.D1_Mailer_First_Body1}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Mailer_First_Body1')));
        emailBody  = emailBody.replace('{!$Label.D1_Username}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Username')));
        emailBody  = emailBody.replace('{!$Label.D1_Login}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Login')));
        emailBody  = emailBody.replace('{!$Label.D1_Second_Login_Reminder_Body}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Second_Login_Reminder_Body')));
        emailBody  = emailBody.replace('{!$Label.D1_Community_Link}/login',  redirectLink);
        emailBody  = emailBody.replace('{!$Label.D1_Unsubscribed_Sub}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Unsubscribed_Sub')));
        emailBody  = emailBody.replace('{!$Label.D1_User}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_User')));
        emailBody  = emailBody.replace('{!$Label.D1_Deactivation_Notification_PrimaryUser_Body}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Deactivation_Notification_PrimaryUser_Body')));
        emailBody  = emailBody.replace('{!$Label.D1_Unsubscribed_from_DiageoOne}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Unsubscribed_from_DiageoOne')));
        emailBody  = emailBody.replace('{!$Label.D1_We_are_sorry_to_see_you_go}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_We_are_sorry_to_see_you_go')));
        emailBody  = emailBody.replace('{!$Label.D1_Second_Login_Reminder_Sub_2}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Second_Login_Reminder_Sub_2')));
        emailBody  = emailBody.replace('{!$Label.D1_Unsubscribed_Sub_2}',  returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Unsubscribed_Sub_2')));

        return emailBody;
    }
    
    //Check for Null values
    private static String returnDefaultIfBlank(String value){
        return String.isEmpty(value) ? ' ' : value;
    }
}