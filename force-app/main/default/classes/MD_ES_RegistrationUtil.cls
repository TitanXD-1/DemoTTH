/**************************************************************************************
Apex Class Name  :  MD_ES_RegistrationUtil 
Version          :  1.0
Created Date     :  13/05/2019
Release          :  R1
Function         :
Modification Log :
---------------------------------------------------------------------------------------
* Developer                                  Date                   Description
* -------------------------------------------------------------------------------------
* Damian Marino / Cristian Canepa            13/05/2019              Original Version
* Hernan Arakaki                             25/09/2019             ECOM-3737 - EDGE - MD Registration - Adjustment to populate "Products Enabled" field
**************************************************************************************/
public without sharing class MD_ES_RegistrationUtil {
    
    static Account accountData;
    static Contact contactData;
    static Geography__c countryData;

    public static Map<String,DiageoCMS__Cluster__c> mapClusterByCountry {get;set;}

    public static Map<String,DiageoCMS__Cluster__c> getMapClusterByCountry(String countryCode){
        if(mapClusterByCountry == null || !mapClusterByCountry.containsKey(countryCode)){
            if(mapClusterByCountry == null){
                mapClusterByCountry = new Map<String,DiageoCMS__Cluster__c>();
            }
            DiageoCMS__Cluster__c cluster = [SELECT Id, MD_ClusterMasterDataManager__c, MD_MyDiageoPermissions__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c =: countryCode LIMIT 1];
            mapClusterByCountry.put(countryCode,cluster);
        }       
        return mapClusterByCountry;
    }
    
    public static MD_JSONResponse checkVATNumber(Map<String, SObject> formData) {
        MD_JSONResponse response = new MD_JSONResponse();
        accountData = (Account) formData.get('Account');
        List<Account> owners = getAccountsByVAT(accountData.VAT_Number__c, 'Owner', false);
        List<Account> outlets = new List<Account>();
        if(owners.isEmpty()){
            outlets = getAccountsByVAT(accountData.VAT_Number__c, 'Outlet', true);
            if (outlets.isEmpty()){
                response.message = 'NON EXISTING VAT';      
            }else{
                if (outlets.size()>1){response.message = vatAlreadyExists(formData);}
            }
        } else {
            if (owners.size()>1){
                response.message = vatAlreadyExists(formData);
            } else{
                if (!hasAssociatedOutlets(owners.get(0).Id)){
                    MD_ES_RegistrationUtil.generateCaseForExistingContact(formData, Label.MD_RegistrationNewCustomer);
                    response.message =  Label.MD_ErrorOutletUser;
                }
            }  
        }        
        if (String.IsBlank(response.message)){
            Id accountId = owners.size() == 1 ? owners.get(0).Id : outlets.get(0).Id;
            if (validateChannels(accountId, owners.size() == 1)){
                if(getVATStatus(formData)){
                    response.message = vatAlreadyUsed(formData);
                }else{
                    response.message = unusedVat(formData);
                }
            }
            else{
                System.debug('generateCaseForExistingContact - validateChannels');
                MD_ES_RegistrationUtil.generateCaseForExistingContact(formData, Label.MD_RegistrationChannelNotEligible);
                response.message =  Label.MD_ErrorOutletUser;
            }
        }
        return response;
    }
    

    public static Boolean hasAssociatedOutlets(Id accountId){
        return [SELECT Id FROM Account WHERE Operator__c =: accountId].size()>0;
    }
    
    public static List<Account> getAccountsByVAT(String vatNumber, String recordType, Boolean independent){
        String query = '';
        query += 'SELECT Id ';
        query += 'FROM Account ';
        query += 'WHERE VAT_Number__c =: vatNumber ';
        query += 'AND RecordType.DeveloperName =: recordType';
        /* ECOM-3738 - EDGE - MD Registration - Independent Outlet adjustment - Andrew's enhancement request - BEGIN */
        query += independent == true ? ' AND (IsIndependent__c = true OR Independent_of_Operator__c = true)' : '';
        /* ECOM-3738 - EDGE - MD Registration - Independent Outlet adjustment - Andrew's enhancement request - END */
        return Database.query(query);
    }
    
    private static Boolean validateChannels(Id accountId, Boolean owner){
        List<Account> accList;
        if (owner){
             accList = [SELECT Id FROM Account WHERE Operator__c =: accountId AND Global_Channel__c = 'On Trade'];
        }else{
              accList = [SELECT Id FROM Account WHERE Id =: accountId AND Global_Channel__c = 'On Trade'];
        }
      
        if (accList.size()>0){
            return true;
        }else{
            return false;
        }
    }
    
    @TestVisible
    private static String vatAlreadyUsed(Map<String, SObject> formData){
        try{
            System.debug('generateCaseForExistingContact - vatAlreadyUsed');
            MD_ES_RegistrationUtil.generateCaseForExistingContact(formData, Label.MD_RegistrationVATUsed);
            return 'CASE CREATED';
        }catch(Exception e)  { 
            try{
                System.debug('on vatAlreadyUsed Exception: ' + e);
                generateErrorCase(e, formData);
            }catch(Exception ex){
                System.debug('on vatAlreadyUsed - GenerateErrorCase Exception: ' + e);
            }
        }
        return Label.MD_ErrorOutletUser;        
    }
    
    
    public static String vatAlreadyExists(Map<String, SObject> formData){
        try{
            System.debug('generateCaseForExistingContact - vatAlreadyExists');
            MD_ES_RegistrationUtil.generateCaseForExistingContact(formData, Label.MD_RegistrationVatExists);
            return 'CASE CREATED';
        }catch(Exception e)  { 
            try{
                System.debug('on vatAlreadyExists Exception: ' + e);
                generateErrorCase(e, formData);
            }catch(Exception ex){
                System.debug('on vatAlreadyExists - GenerateErrorCase Exception: ' + e);
            }
        }
        return Label.MD_ErrorOutletUser;        
    }
    
    @TestVisible
    private static String unusedVat(Map<String, SObject> formData){
        Id contactId = getContactId(formData);
        System.debug('on unusedVat ContactId: ' + contactId);
        if (contactId != null){
            return contactExists(contactId, formData);
        }else{
            Savepoint sp = Database.setSavepoint();
            try{
                System.debug('unusedVat');
                Contact newContact = MD_ES_RegistrationUtil.generateContactForExistingAccount(formData);
                sendEmail(newContact.Id);
                return 'CONTACT CREATED';                
            } catch (Exception e){
                try{
                    System.debug('on unusedVat Exception: ' + e);
                    Database.rollback(sp);
                    generateErrorCase(e, formData); 
                }catch(Exception ex){
                    System.debug('on unusedVat - GenerateErrorCase Exception: ' + e);
                }
            }          
        }    
        return Label.MD_ErrorOutletUser;           
    }
    
    @TestVisible
    private static string contactExists(Id contactId, Map<String, SObject> formData){
        if (checkPermissionSet(contactId)){
            try{
                System.debug('generateCaseForExistingContact - contactExists');
                MD_ES_RegistrationUtil.generateCaseForExistingContact(formData, Label.MD_RegistrationUserEnabled);
                return 'CONTACT EXISTS';
            }catch(Exception e)  {
                try{
                    System.debug('on contactExists Exception: ' + e);
                    generateErrorCase(e, formData);
                }catch(Exception ex){
                    System.debug('on contactExists - GenerateErrorCase Exception: ' + e);
                }
            }
        }else{
            try{
                addAccountRelationship(formData, contactId);
                MD_RegistrationUtil.createUser(new Set<Id>{contactId});
                return 'RELATIONSHIP ADDED';
            }catch(Exception e)  {
                try{
                    System.debug('on contactExists Exception: ' + e);
                    generateErrorCase(e, formData);
                }catch(Exception ex){
                    System.debug('on contactExists - GenerateErrorCase Exception: ' + e);
                }
            }
        }
        return Label.MD_ErrorOutletUser; 
    }
    
    private static void addAccountRelationship(Map<String, SObject> formData, Id contactId){
        Account ac = (Account) formData.get('Account');
        
        List<Account> outlets = [SELECT Id, Country__r.Code__c ,
                                 (SELECT Id,ContactId, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c, MD_Status__c, MD_Role__c, MD_UserProfile__c 
                                  FROM AccountContactRelations) 
                                 FROM Account 
                                 WHERE VAT_Number__c =: ac.VAT_Number__c AND Global_Channel__c = 'On Trade' AND RecordType.DeveloperName = 'Outlet'];
        
        List<AccountContactRelation> toUpdate = new List<AccountContactRelation>();
        List<AccountContactRelation> toInsert = new List<AccountContactRelation>();
        Boolean relatedContact;
        for(Account out: outlets){
            String countryCode = out.Country__r.Code__c;
            relatedContact = false;
            for (AccountContactRelation acr: out.AccountContactRelations){
                if(acr.ContactId == contactId){
                    relatedContact = true;
                    acr.MD_AssignedPermissions__c = getMapClusterByCountry(countryCode).get(countryCode).MD_MyDiageoPermissions__c;
                    acr.MD_MyDiageoEnabled__c = true;
                    acr.MD_Status__c = 'Active';
                    acr.MD_Role__c = 'Owner';
                    acr.MD_UserProfile__c = 'Primary User';
                    toUpdate.add(acr);
                    break;
                }
            }
            if (relatedContact == false){
                AccountContactRelation newRelation = new AccountContactRelation(
                    AccountId = out.Id,
                    ContactId = contactId,            
                    MD_AssignedPermissions__c = getMapClusterByCountry(countryCode).get(countryCode).MD_MyDiageoPermissions__c,
                    MD_MyDiageoEnabled__c = true,
                    MD_Status__c = 'Active',
                    MD_Role__c = 'Owner',
                    MD_UserProfile__c = 'Primary User');
                toInsert.add(newRelation);
            }
        }
        
        System.debug('on addAccountRelationship TO UPDATE: ' + toUpdate);
        if (toUpdate.size()> 0)
            update toUpdate;
        
        System.debug('on addAccountRelationship TO INSERT: ' + toInsert);
        if (toInsert.size()>0)
            insert toInsert;
    }
    
    private static Id getContactId(Map<String, SObject> formData){
        Contact c = (Contact) formData.get('Contact');
        String mobile = c.MobilePrefix__c + c.Mobile__c;
        List<Contact> contacts = [SELECT Id FROM Contact WHERE MobilePhone =: mobile OR Email =: c.Email LIMIT 1];
        if (contacts.size()>0){
            return contacts.get(0).Id;
        }else{
            return null;
        }
    }
    
    private static boolean checkPermissionSet(Id contactId){
        return [SELECT Id
                FROM PermissionSetAssignment 
                WHERE assignee.contactId =: contactId
                AND PermissionSet.Name = 'MD_MyDiageoUser'].size() > 0;       
    }
    
    
    public static void generateErrorCase(Exception e, Map<String, SObject> formData){
        Id myDiageoCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MD_RegistrationIssues').getRecordTypeId();
        Case newCase = new Case(
            RecordTypeId = myDiageoCaseRecordType,
            Type = 'Registration Issues',
            MD_Subject__c = Label.MD_RegistrationNonIdentifiedError,
            Description = generateCaseDescription('Unexpected error', formData, e.getMessage() + '\n Line: ' + e.getLineNumber() + '\n Stacktrace: ' + e.getStackTraceString())
        );
        
        System.debug('CG - in MD_ES_RegistrationUtil.generateErrorCase() method. newCase: ' + newCase);
        
        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
        
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        dmlOpts.EmailHeader.TriggerUserEmail = true;
        
        //Setting the DMLOption on Case instance
        newCase.setOptions(dmlOpts);
        
        insert newCase;
        
    }
    
    private static String generateCaseDescription(String descriptionTitle, Map<String, SObject> formData, String errorMessage) {
        
        Map<String,Map<String,Object>> populatedFieldsByObject = new Map<String,Map<String,Object>>();
        
        List<String> objectNames = new List<String>();
        
        //gets all the objects and fields included in the formData to search for the field labels
        for(String objectName: formData.keySet()){
            if(objectName != null){
                Map<String,Object> objectMap = formData.get(objectName).getPopulatedFieldsAsMap();
                populatedFieldsByObject.put(objectName,objectMap);
                objectNames.add(objectName);
            }
        }
        
        //does a describe of the objects and gets the fieldmap for each
        Map<String,Map<String,Schema.SObjectField>> fieldsMapByObject = new Map<String,Map<String,Schema.SObjectField>>();
        Map<String,String> objectApiToLabel = new Map<String,String>();
        for(Schema.DescribeSobjectResult describe: Schema.describeSObjects(objectNames)){
            fieldsMapByObject.put(describe.getName().toLowerCase(),describe.fields.getMap());
            objectApiToLabel.put(describe.getName().toLowerCase(),describe.getLabel());
        }
        
        //Builds the description string with the object name
        String description = '';
        for(String key: populatedFieldsByObject.keySet()){
            String objectLabel = objectApiToLabel.get(key.toLowerCase());
            description += '\n\n' + objectLabel + ': ';
            for(String field: populatedFieldsByObject.get(key).keySet()){
                String fieldLabel = fieldsMapByObject.get(key.toLowerCase()).get(field.toLowerCase()).getDescribe().getLabel();
                String fieldValue = '';
                if((String) populatedFieldsByObject.get(key).get(field) != 'null'){
                    fieldValue = (String) populatedFieldsByObject.get(key).get(field);
                }
                description += '\n- ' + fieldLabel + ': ' + fieldValue;
            }
        }
        if (errorMessage != null) 
            description += '\n\n' + descriptionTitle + ' - ' + errorMessage;  
        System.debug('CG - MD_ES_RegistrationUtil.generateCaseDescription() method - description: ' + description);
        return description;
    }
    
    
    private static Boolean getVATStatus(Map<String, SObject> formData){
        Account acc = (Account)formData.get('Account');
        List<Account> outlets = [SELECT Id, (SELECT Id FROM AccountContactRelations WHERE MD_MyDiageoEnabled__c = true AND MD_Status__c = 'Active') 
                                 FROM Account WHERE VAT_Number__c =: acc.VAT_Number__c AND RecordType.DeveloperName = 'Outlet'];
        
        
        for(Account outlet : outlets){
            if (!outlet.AccountContactRelations.IsEmpty())
                return true;
        }
        return false;
    }
    
    private static void generateCaseForExistingContact(Map<String, SObject> formData, String subject) {
        accountData = (Account) formData.get('Account');
        contactData = (Contact) formData.get('Contact');     
        Id myDiageoCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MD_RegistrationIssues').getRecordTypeId();
        
        List<Account> existingAccount = [SELECT Id FROM Account WHERE VAT_Number__c =: accountData.VAT_Number__c LIMIT 1];
        
        Case newCase = new Case(
            AccountId = existingAccount.isEmpty() ? null : existingAccount[0].Id,
            RecordTypeId = myDiageoCaseRecordType,
            Type = 'Registration Issues',
            MD_Subject__c = subject,
            Description = generateCaseDescription(null, formData, null)
        );
        
        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
        
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        
        //Setting the DMLOption on Case instance
        newCase.setOptions(dmlOpts);
        
        insert newCase;
    }
    
    private static Contact generateContactForExistingAccount(Map<String, SObject> formData){
        accountData = (Account) formData.get('Account');
        contactData = (Contact) formData.get('Contact');
        countryData = (Geography__c) formData.get('Geography__c');
        List<Account> outlets = [SELECT Id, Country__r.Code__c, Products_Enabled__c
                                    FROM Account 
                                    WHERE VAT_Number__c =: accountData.VAT_Number__c 
                                        AND RecordType.DeveloperName = 'Outlet'];
        
        String primaryOutletId = outlets.get(0).Id;     
        
        Contact newContact = createContact(primaryOutletId, outlets.get(0).Country__r.Code__c);      
            
        insert newContact;          
        
        List<AccountContactRelation> relations = createRelations(outlets, newContact, primaryOutletId, outlets.get(0).Country__r.Code__c);        
        insert relations;
        
        /* ECOM-3737 - BEGIN */
        List<Account> accountsToUpdate = new List<Account>();
        for(Account a : outlets) {
            if(a.Products_Enabled__c == null) {
                a.Products_Enabled__c = 'MyDiageo';
                accountsToUpdate.add(a);
            }else if(!a.Products_Enabled__c.contains('MyDiageo')) {
                a.Products_Enabled__c = a.Products_Enabled__c + ';MyDiageo';
                accountsToUpdate.add(a);
            }
        }

        update accountsToUpdate;
        /* ECOM-3737 -   END */

        newContact.MD_Approvalstatus__c = 'Approved';
        update newContact;
        
        return newContact;
    }
    
    public static List<AccountContactRelation> createRelations(List<Account> outlets, Contact newContact, String primaryOutletId, String countryCode){
        List<AccountContactRelation> primaryRelation = [SELECT Id, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c, MD_Status__c, MD_Role__c, MD_UserProfile__c 
                                                        FROM AccountContactRelation WHERE ContactId =: newContact.Id LIMIT 1];
        if(! primaryRelation.isEmpty()){
            primaryRelation.get(0).MD_AssignedPermissions__c = getMapClusterByCountry(countryCode).get(countryCode).MD_MyDiageoPermissions__c;
            primaryRelation.get(0).MD_MyDiageoEnabled__c = true;
            primaryRelation.get(0).MD_Status__c = 'Active';
            primaryRelation.get(0).MD_Role__c = 'Owner';
            primaryRelation.get(0).MD_UserProfile__c = 'Secondary User';
            primaryRelation.get(0).Contact_type__c = 'Primary';
            update primaryRelation;
        }
        
        List<AccountContactRelation> relations = new List<AccountContactRelation>();
        for(Account outlet : outlets){
            if(outlet.Id != primaryOutletId){
                relations.add(new AccountContactRelation(
                    AccountId = outlet.Id,
                    ContactId = newContact.Id,            
                    MD_AssignedPermissions__c = getMapClusterByCountry(countryCode).get(countryCode).MD_MyDiageoPermissions__c,
                    MD_MyDiageoEnabled__c = true,
                    MD_Status__c = 'Active',
                    MD_Role__c = 'Owner',
                    MD_UserProfile__c = 'Secondary User',
                    Contact_type__c = 'Secondary'
                ));
            }
        }
        
        return relations;
    }
    
    public static MD_JSONResponse submitRequestForApproval(Map<String, SObject> formData) {
        MD_ES_RegistrationUtil.generateCaseForExistingContact(formData, Label.MD_RegistrationNewCustomer);
        return new MD_JSONResponse(true, Label.MD_SuccessfullySubmitted, MD_JSONResponse.MD_JSONResponseType.SUCCESS);  
        /*String message;
        Savepoint sp = Database.setSavepoint();
        try{
            System.debug('submitRequestForApproval');
            MD_JSONResponse succesfullResponse = MD_ES_RegistrationUtil.submitRequestForApproval(formData, true);
            return succesfullResponse;
        } catch (Exception e){
            try{
                System.debug('on submitRequestForApproval Exception: ' + e);
                Database.rollback(sp);
                generateErrorCase(e, formData);
            }catch(Exception ex){
                System.debug('on submitRequestForApproval GenerateErrorCase: ' + e);
            }
        }
        message = Label.MD_ErrorOutletUser;
        return new MD_JSONResponse(true, message, MD_JSONResponse.MD_JSONResponseType.ERROR);*/
    }
    
    
   /* public static MD_JSONResponse submitRequestForApproval(Map<String, SObject> formData, Boolean innerMethod) {
        /*accountData = (Account) formData.get('Account');
        contactData = (Contact) formData.get('Contact');
        countryData = (Geography__c) formData.get('Geography__c');
        Contact contact = generateContactForApproval();        
        String currentUserId = UserInfo.getUserId();        
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments(Label.MD_SubmittingForApproval);
        request.setObjectId(contact.id);
        request.setSubmitterId(currentUserId);
        request.setProcessDefinitionNameOrId('MD_ContactApproval');
        request.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(request);        
        if(result.isSuccess()){
        return new MD_JSONResponse(true, Label.MD_SuccessfullySubmitted, MD_JSONResponse.MD_JSONResponseType.SUCCESS);            
        } else {
        return new MD_JSONResponse(false, Label.MD_FailedSubmitting, MD_JSONResponse.MD_JSONResponseType.ERROR);
        }
                return new MD_JSONResponse(true, Label.MD_SuccessfullySubmitted, MD_JSONResponse.MD_JSONResponseType.SUCCESS);   
            }
            /* 
        private static Contact generateContactForApproval(){ 
        Geography__c geography = getGeographyTree();
        Map<String, Id> accountRecordTypes = new Map<String, Id>();
        for(RecordType accountRecordType : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account']) {
        accountRecordTypes.put(accountRecordType.DeveloperName, accountRecordType.Id);
        }

        String ownerRecordTypeId = accountRecordTypes.get('Owner');
        String prospectRecordTypeId = accountRecordTypes.get('Prospect');

        Account owner = createOwner(ownerRecordTypeId, geography); 
        insert owner;
        Account prospect = createProspect(prospectRecordTypeId, geography, owner.Id);
        insert prospect;
        Contact contact = createContact(prospect.Id, geography.Code__c);
        insert contact;



        return contact;
    }

    private static Account createOwner(String recordTypeId, Geography__c geography){
        return new Account(Name = accountData.AccountNumber
        , VAT_Number__c = accountData.VAT_Number__c
        , BillingStreet = accountData.BillingStreet
        , BillingCountry = geography.Parent_Geography__r.Parent_Geography__r.Name
        , Phone = contactData.mobilePhone
        , Global_Channel__c = 'On Trade'
        , Global_Sub_Channel__c = 'On trade'
        , Global_Segment__c = 'Bars'
        , Global_Sub_Segment__c = 'Modern Bars'
        , Region__c = geography.Id
        , Area__c = geography.Parent_Geography__c
        , Country__c = geography.Parent_Geography__r.Parent_Geography__c
        , Cluster__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
        , Hub__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
        , Market__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
        , RecordTypeId = recordTypeId
        , OwnerId = getCluster(geography.Parent_Geography__r.Parent_Geography__r.Code__c).MD_ClusterMasterDataManager__c
        );
    }

    @TestVisible
    private static Account createProspect(String recordTypeId, Geography__c geography, Id ownerId){
        System.debug([SELECT Id, Name, Geography__r.Code__c, Type__c FROM Pick_Up_Options__c]);
        Pick_Up_Options__c option = [SELECT Id FROM Pick_Up_Options__c 
        WHERE Name = 'N0[ES]' 
        AND Geography__r.Code__c =: countryData.Code__c 
        AND Type__c = 'Outlet Visit Prioritization' LIMIT 1];

        return new Account(Name = accountData.Name
        , Operator__c = ownerId
        , ParentId = ownerId
        , BillingStreet = accountData.BillingStreet
        , BillingCountry = geography.Parent_Geography__r.Parent_Geography__r.Name
        , Phone = contactData.mobilePhone
        , Outlet_Visit_Prioritisation_Grade__c = option.Id
        , BillingState = 'España'
        , Region__c = geography.Id
        , Area__c = geography.Parent_Geography__c
        , Country__c = geography.Parent_Geography__r.Parent_Geography__c
        , Cluster__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
        , Hub__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
        , Market__c = geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c
        , Global_Channel__c = 'On Trade'
        , Global_Sub_Channel__c = 'On trade'
        , Global_Segment__c = 'Bars'
        , Global_Sub_Segment__c = 'Modern Bars'
        , BillingPostalCode = accountData.BillingPostalCode
        , RecordTypeId = recordTypeId
        , OwnerId = getCluster(geography.Parent_Geography__r.Parent_Geography__r.Code__c).MD_ClusterMasterDataManager__c
        );
    }
    */
    private static Contact createContact(String prospectId, String countryCode){
        return new Contact(FirstName = contactData.FirstName,
                           LastName = contactData.LastName,
                           Mobile__c = contactData.Mobile__c,
                           MobilePrefix__c = contactData.MobilePrefix__c,
                           Email = contactData.Email,
                           Contact_Type__c = 'Primary',
                           MD_CurrentOutlet__c = prospectId,
                           Registration_Source__c = 'MyDiageo',
                           MD_SubscriptionSource__c = 'Frontend',
                           AccountId = prospectId,
                           OwnerId = getMapClusterByCountry(countryCode).get(countryCode).MD_ClusterMasterDataManager__c
                          );
    }
    
   /* private static Geography__c getGeographyTree(){
        return [SELECT Id, Name, Code__c, 
                Parent_Geography__c, 
                Parent_Geography__r.Parent_Geography__c,
                Parent_Geography__r.Parent_Geography__r.Name,
                Parent_Geography__r.Parent_Geography__r.Code__c,
                Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c 
                FROM Geography__c 
                WHERE Parent_Geography__r.Parent_Geography__r.Code__c =: countryData.Code__c LIMIT 1];
    }*/
    
    @TestVisible
    private static void sendEmail(Id contactId){
        List<String> mails = new List<String>();

        System.debug('MD - in MD_ES_RegistrationUtil.sendEmail() method. contactId: ' + contactId);

        Group g = [SELECT Id, Email FROM Group WHERE Type = 'Queue' AND DeveloperName = 'MD_ContactInformation' LIMIT 1];
        for(User u: [SELECT Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'MD_ContactInformation')]){
            mails.add(u.email); 
        }
        if(! mails.contains(g.email)){
            mails.add(g.email);
        }

        System.debug('MD - in MD_ES_RegistrationUtil.sendEmail() method. mails: ' + mails);

        List<EmailTemplate> emailTemplates = [SELECT Id, Name FROM EmailTemplate where name = 'MD_NewContactCreation' LIMIT 1];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(contactId);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setToAddresses(mails);
        mail.setTemplateId(emailTemplates.get(0).Id);
        
        System.debug('MD - in MD_ES_RegistrationUtil.sendEmail() method. mail: ' + mail);

        if(!Test.isRunningTest()) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }
    
    public static DiageoCMS.FormResponseWrapper resolveResponse(MD_JSONResponse jsonResponse) {
        DiageoCMS.FormResponseWrapper response = new  DiageoCMS.FormResponseWrapper();
        if (jsonResponse.message == 'NON EXISTING VAT'){ 
            response.status = 'NON EXISTING VAT';
            response.message = 'NO EXISTE VAT';
        }else if (jsonResponse.message == 'CASE CREATED'){
            response.status = 'CASE CREATED';
            response.message = 'CASO CREADO';
        }else if (jsonResponse.message == 'CONTACT CREATED'){
            response.status = 'CONTACT CREATED';
            response.message = 'CONTACTO CREADO';
        }else if (jsonResponse.message == 'RELATIONSHIP ADDED'){
            response.status = 'RELATIONSHIP ADDED';
            response.message = 'RELACION AÑADIDA';
        }else if (jsonResponse.message == Label.MD_SuccessfullySubmitted){
            response.status = 'SUCCESS';
            response.message = jsonResponse.message;
        }else if (jsonResponse.message == Label.MD_FailedSubmitting){
            response.status = 'FAILED';
            response.message = jsonResponse.message;
        }else{
            response.status = 'ERROR';
            response.message = jsonResponse.message;
        }
        return response;
    }
    
    
}