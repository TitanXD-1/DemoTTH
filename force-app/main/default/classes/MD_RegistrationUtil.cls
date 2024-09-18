/**************************************************************************************
Apex Class Name  :  MD_RegistrationUtil 
Version          :  1.0
Created Date     :  28/04/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         28/04/2019              Original Version
******************************************************************************/
public without sharing class MD_RegistrationUtil {
    
    public static PermissionSet myDiageoPermissionSet {get;set;}
    
    public static void getMyDiageoPermissionSet(){
        if(myDiageoPermissionSet == null){
            myDiageoPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'MD_MyDiageoUser'];    
        }
    }

    @future
    public static void assignPermissions(Set<Id> userIds, Id psetId){
        System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. BEGIN ');
        List<PermissionSetAssignment> inserts = new List<PermissionSetAssignment>();
        List<Contact> contactsToUpdate = new List<Contact>();
        Set<Id> contactIds = new Set<Id>();

        for(Id userId : userIds) {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. userId: ' + userId + ' - psetId: ' + psetId);
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId,PermissionSetId = psetId);
            inserts.add(psa);
        }

        try {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. inserts: ' + inserts);
            update contactsToUpdate;
            upsert inserts;

        }catch(DmlException e) {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getMessage: ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getStackTraceString: ' + e.getStackTraceString());
        }catch(Exception e) {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getMessage: ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getStackTraceString: ' + e.getStackTraceString());
        }
    }

    private static void setMyDiageoInvited(Set<Id> contactIds){
        List<Account> accounts = new List<Account>();
        
        for (AccountContactRelation acr: [SELECT Id, AccountId FROM AccountContactRelation WHERE ContactId in: contactIds AND MD_MyDiageoEnabled__c = true AND Account.MD_MyDiageoInvited__c = false]){
            accounts.add(new Account(Id = acr.AccountId, MD_MyDiageoInvited__c = true));
        }
        
        if (accounts.size()>0){
            update accounts;
        }
        
    } 
   
    @future
    public static void removePermissions(Set<Id> contactIds, String permissionName){
        System.debug('CG - in MD_RegistrationUtil.removePermissions() method. BEGIN ');
        List<PermissionSetAssignment> permissionsToRemove = [SELECT id FROM PermissionSetAssignment WHERE Assignee.ContactId IN :contactIds AND PermissionSet.Name = :permissionName];

        try {
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. inserts: ' + permissionsToRemove);
            delete permissionsToRemove;

        }catch(DmlException e) {
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. e.getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. e.getMessage: ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. e.getStackTraceString: ' + e.getStackTraceString());
        }catch(Exception e) {
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. e.getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. e.getMessage: ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.removePermissions() method. e.getStackTraceString: ' + e.getStackTraceString());
        }
    }

    public static Set<Id> createUser(Set<Id> contactIds){

        Map<Id,Contact> mapContacts = new Map<Id,Contact>([SELECT AccountId, Account.Country__c, Account.Country__r.Code__c, FirstName, LastName, Department, Title, MailingStreet, MailingCity, MailingState, MailingPostalCode, Email, Phone, Fax, MobilePhone FROM Contact WHERE Id IN: contactIds]);
        
        Set<String> countryCodes = new Set<String>();
        for(Contact con: mapContacts.values()){
            countryCodes.add(con.Account.Country__r.Code__c);
        }
        Map<Id,Id> mapContactExistingUser = new Map<Id,Id>();
        for(User existingUser: [SELECT Id,ContactId FROM User WHERE ContactId IN: mapContacts.keySet() AND IsPortalEnabled = true]){
            mapContactExistingUser.put(existingUser.ContactId, existingUser.Id);
        }

        Profile p = [SELECT Id FROM PROFILE WHERE Name = 'Customer Community Plus Login Custom'];

        Map<String,MD_CountryUserInformation__mdt> mapCountriesInfo = new Map<String,MD_CountryUserInformation__mdt>();
        List<MD_CountryUserInformation__mdt> countriesInfo = [SELECT Country__c, EmailEncodingKey__c, LanguageLocaleKey__c, LocaleSidKey__c, TimeZoneSidKey__c, DeveloperName, Grouping__c, AvailableCountry__c FROM MD_CountryUserInformation__mdt WHERE DeveloperName IN: countryCodes];
        if(countriesInfo.isEmpty() || countriesInfo.size() < countryCodes.size()){
            throw new createUserException(label.MD_CountryUserInformationMissing);
        }else{
            for(MD_CountryUserInformation__mdt countryInfo: countriesInfo){
                mapCountriesInfo.put(countryInfo.DeveloperName, countryInfo);
            }
        }
                
        List<User> usersInsert = new List<User>();
        
        for(Contact con: mapContacts.values()){
            if(!mapContactExistingUser.containsKey(con.Id)){
                String countryCode = con.Account.Country__r.Code__c;
                String communityNickNameRandomNumber = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3);
                con.FirstName = con.FirstName != null ? con.FirstName : '';
                String communityNickName = (con.FirstName + con.LastName).length() > 37 ? (con.FirstName + con.LastName).substring(0,36) + communityNickNameRandomNumber : (con.FirstName + con.LastName + communityNickNameRandomNumber);               

                Integer firstNameLength = con.FirstName.length();
                Integer lastNameLength = con.LastName.length();
                String alias = con.FirstName.substring(0, firstNameLength < 3 ? firstNameLength : 3) + con.LastName.substring(0, lastNameLength < 3 ? lastNameLength : 3);

                User newUser = new User(
                    LastName                = con.LastName, 
                    FirstName               = con.FirstName, 
                    Department              = con.Department, 
                    Title                   = con.Title,
                    Street                  = con.MailingStreet, 
                    City                    = con.MailingCity, 
                    State                   = con.MailingState, 
                    PostalCode              = con.MailingPostalCode, 
                    Email                   = con.Email, 
                    Phone                   = con.Phone, 
                    Fax                     = con.Fax, MobilePhone = con.MobilePhone,
                    Alias                   = alias,
                    UserName                = con.Email, 
                    CommunityNickname       = communityNickName, 
                    ProfileId               = p.Id, 
                    ContactId               = con.Id,
                    Country                 = mapCountriesInfo.get(countryCode).Country__c,            
                    LocaleSidKey            = mapCountriesInfo.get(countryCode).LocaleSidKey__c,
                    TimeZoneSidKey          = mapCountriesInfo.get(countryCode).TimeZoneSidKey__c,
                    EmailEncodingKey        = mapCountriesInfo.get(countryCode).EmailEncodingKey__c,
                    LanguageLocaleKey       = mapCountriesInfo.get(countryCode).LanguageLocaleKey__c,
                    Available_Countries__c  = (Test.isRunningTest()? 'GB':mapCountriesInfo.get(countryCode).AvailableCountry__c),
                    Grouping__c             = mapCountriesInfo.get(countryCode).Grouping__c
                    
                ); 
                usersInsert.add(newUser);
            }
            
        }

        try {
            insert usersInsert;
            
            Set<Id> newUserIds = new Set<Id>();
            newUserIds.addAll(new Map<Id,User>(usersInsert).keySet());
            getMyDiageoPermissionSet();

            List<PermissionSetAssignment> ps = [SELECT Id, Assignee.Id FROM PermissionSetAssignment  WHERE Assignee.Id in: mapContactExistingUser.values() AND PermissionSetId =: myDiageoPermissionSet.Id];

            Set<Id> newsIds = new Set<Id>();

            for(PermissionSetAssignment ps1: ps){
                newsIds.add(ps1.Assignee.Id);
            }

            for (Id i : mapContactExistingUser.values()){
                if (!newsIds.contains(i)){
                    newUserIds.add(i);
                }
            }     
            System.debug('MD_RegistrationUtils.createUser() method - Success - usersInsert: ' + usersInsert);

            List<Contact> contactsToUpdate = new List<Contact>();

            for(Id conId: contactIds){
                contactsToUpdate.add(new Contact(Id = conId, MD_MyDiageoInitialInviteDate__c = DateTime.now()));
            }
            update contactsToUpdate;

            setMyDiageoInvited(contactIds);

            assignPermissions(newUserIds,myDiageoPermissionSet.Id);
            return newUserIds;
        }catch(DMLException e){
            System.debug('MD_RegistrationUtils.createUser() method - Exception: ' + e);
            throw new createUserException(e.getDMLMessage(0));
        }catch(Exception e){
            System.debug('MD_RegistrationUtils.createUser() method - Exception: ' + e);
            throw new createUserException(e.getMessage());
        }
    }
   
    public static void upsertAccountContactRelations(List<AccountContactRelation> accContacts, List<AccountContactRelation> existingAccountContactRelations) {
        
        System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. accContacts: ' + accContacts);
        System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. existingAccountContactRelations: ' + existingAccountContactRelations);

        List<AccountContactRelation> relationsToUpdate = new List<AccountContactRelation>();
        List<AccountContactRelation> relationsToInsert = new List<AccountContactRelation>();
        
        for(AccountContactRelation ac : accContacts) {
            Boolean found = false;

            for(AccountContactRelation eacr : existingAccountContactRelations) {
                System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. in loop - ac.AccountId: ' + ac.AccountId + ' - ac.ContactId: ' + ac.ContactId);
                System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. in loop - eacr.AccountId: ' + eacr.AccountId + ' - eacr.AccountId: ' + eacr.ContactId);

                if((eacr.AccountId == ac.AccountId) && (eacr.ContactId == ac.ContactId)) {
                    eacr.MD_AssignedPermissions__c = ac.MD_AssignedPermissions__c;
                    eacr.MD_MyDiageoEnabled__c = true;
                    eacr.MD_Role__c = ac.MD_Role__c;
                    eacr.MD_Status__c = ac.MD_Status__c;
                    eacr.MD_UserProfile__c = ac.MD_UserProfile__c;
                    eacr.Contact_Type__c = 'Secondary';

                    relationsToUpdate.add(eacr);
                    found = true;
                }
            }

            System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. found: ' + found);

            if(!found) {
                AccountContactRelation newAc = new AccountContactRelation();
                newAc.ContactId = ac.ContactId;
                newAc.AccountId = ac.AccountId;
                newAc.Contact_Type__c = ac.Contact_Type__c;
                
                newAc.MD_AssignedPermissions__c = ac.MD_AssignedPermissions__c;
                newAc.MD_MyDiageoEnabled__c = true;
                newAc.MD_Role__c = ac.MD_Role__c;
                newAc.MD_Status__c = ac.MD_Status__c;
                newAc.MD_UserProfile__c = ac.MD_UserProfile__c;
                newAc.Contact_Type__c = 'Secondary';

                relationsToInsert.add(newAc);
            }
        }

        System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. relationsToInsert: ' + relationsToInsert);
        System.debug('CG - in MD_RegistrationUtil.upsertAccountContactRelations() method. relationsToUpdate: ' + relationsToUpdate);

        if(relationsToInsert.size() > 0) {
            insert relationsToInsert;
        }

        if(relationsToUpdate.size() > 0) {
            update relationsToUpdate;
        }
    }
    
    public static String insertContactAndAccContacts(Contact con, List<AccountContactRelation> accContacts, Id ownerId){
        ContactCreationResponse conCreationResp = new ContactCreationResponse();

        System.debug('CG - in MD_RegistrationUtil.insertContactAndAccContacts() method. con: ' + con);
        System.debug('CG - in MD_RegistrationUtil.insertContactAndAccContacts() method. accContacts: ' + accContacts);

        SavePoint sp = Database.setSavepoint();
        try{
            insert con;

            List<AccountContactRelation> existingAccountContactRelations = [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE ContactId = :con.Id];

            for(AccountContactRelation ac : accContacts) {
                ac.ContactId = con.Id;
            }
            
            upsertAccountContactRelations(accContacts, existingAccountContactRelations);

            conCreationResp.recordsCreated = new List<SObject>();
            conCreationResp.recordsCreated.addAll(accContacts);
            conCreationResp.recordsCreated.add(con);
            conCreationResp.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            conCreationResp.contact = con;

        }catch(Exception e){
            System.debug('CG - in MD_RegistrationUtil.insertContactAndAccContacts() method. EXCEPTION getTypeName: ' + e.getTypeName());
            System.debug('CG - in MD_RegistrationUtil.insertContactAndAccContacts() method. EXCEPTION getCause: ' + e.getCause());
            System.debug('CG - in MD_RegistrationUtil.insertContactAndAccContacts() method. EXCEPTION getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.insertContactAndAccContacts() method. EXCEPTION getMessage: ' + e.getMessage());
            Database.rollback(sp);
            conCreationResp.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            conCreationResp.message = e.getMessage();
        }
        return JSON.serialize(conCreationResp);
    }

    public class ContactCreationResponse extends MD_JSONResponse {
        public Contact contact;
        public List<SObject> recordsCreated;
    }

    public class createUserException extends Exception {}

    public static void createCase(Map<Id,Map<Id,String>> responseMap, String source){
        Id myDiageoCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('MD_RegistrationIssues').getRecordTypeId();
        
        String description = '';
        
        for (Id contactId : responseMap.keySet()){
                    
            String message = '';
            
            for (Id accountId : responseMap.get(contactId).keySet()){
                
                if (String.IsNotBlank(responseMap.get(contactId).get(accountId)) && responseMap.get(contactId).get(accountId) != 'Success'){
                    
                    message += '\n- Account Id: ' + accountId + ' -> ' + responseMap.get(contactId).get(accountId);
                    
                }
                
            }

            if (message.length()>0){
                description += '\n\nContact Id: ' + contactId;
                description += message;
            }
        }
        
        if (description.length()>0){

            description = 'Errors encountered during registration process:' + description;

            Case newCase = new Case(
                RecordTypeId = myDiageoCaseRecordType,
                Type = 'Registration Issues',
                Origin = source,
                MD_Subject__c = Label.MD_RegistrationProcessError,
                Subject = Label.MD_RegistrationProcessError,
                Description = description
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
               
    }

    // START REGISTRATION API
    
    final static Integer limitrecords = 100;

    public class registerContactsException extends Exception {}
    
    public static Map<Id,Map<Id,String>> registerContacts(Map<Id,Set<Id>> contactsMap, String countryCode, Boolean caseHandling, Boolean allOrNone, String source, String subscriptionSource, String userProfile){
                
        Savepoint sp = Database.setSavepoint();

        System.debug('CG - in MD_RegistrationUtil.registerContacts() method. BEGIN ');
        
        System.debug('CG - in MD_RegistrationUtil.registerContacts() method. contactsMap: ' + contactsMap);
        System.debug('CG - in MD_RegistrationUtil.registerContacts() method. caseHandling: ' + caseHandling);
        System.debug('CG - in MD_RegistrationUtil.registerContacts() method. allOrNone: ' + allOrNone);        
        
        Map<Id,Map<Id,String>> responseMap = new Map<Id,Map<Id,String>>();
        
        try{
                    
            if(contactsMap.size() > limitrecords){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_LimitContactsExceeded);
                throw new registerContactsException(label.MD_RegistrationAPI_LimitContactsExceeded);
            }
                                               
            Set<Id> accountIds = new Set<Id>();       
            for(Id contactId: contactsMap.keySet()){
                accountIds.addAll(contactsMap.get(contactId));
            }
            
            if(accountIds.size() > limitrecords){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_LimitAccountsExceeded);
                throw new registerContactsException(label.MD_RegistrationAPI_LimitAccountsExceeded);
            }
            
            //get information on all contacts and accounts
            Map<Id,Contact> mapAllContacts = new Map<Id,Contact>([SELECT Id, MD_SubscriptionSource__c, Registration_Source__c, MD_MyDiageoInitialInviteDate__c, AccountId, Account.Country__c, Account.Country__r.Code__c, FirstName, LastName, Department, Title, MailingStreet, MailingCity, MailingState, MailingPostalCode, Email, Phone, Fax, MobilePhone,Preferred_Language__c FROM Contact WHERE Id IN: contactsMap.keySet()]);
            Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, MD_MyDiageoInvited__c, Country__r.Code__c, Operator__r.Country_Code__c, RecordTypeId, Operator__r.RecordTypeId, Country_Code__c, Global_Channel__c, IsIndependent__c, Independent_of_Operator__c, VAT_Number__c, Operator__r.VAT_Number__c, Operator__r.Global_Channel__c, Products_Enabled__c
                                                                FROM Account 
                                                                WHERE Id IN: accountIds]);

            if(contactsMap.size() != mapAllContacts.size()){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_InvalidContactsInput);
                throw new registerContactsException(label.MD_RegistrationAPI_InvalidContactsInput);                
            }
            if(accountIds.size() != mapAccounts.size()){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_InvalidAccountsInput);
                throw new registerContactsException(label.MD_RegistrationAPI_InvalidAccountsInput);                
            }
            
            for(Id accountId: mapAccounts.keySet()){
                if(countryCode != mapAccounts.get(accountId).Country__r.Code__c){
                    System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_InvalidCountryCode);
                    throw new registerContactsException(label.MD_RegistrationAPI_InvalidCountryCode);                
                }
            }
            
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. countryCode: ' + countryCode);
            
            List<DiageoCMS__Cluster__c> clusters = [SELECT Id, DiageoCMS__ExternalId__c, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c =: countryCode LIMIT 1];        
            
            if(clusters.isEmpty()){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_ClusterNotFound);
                throw new registerContactsException(label.MD_RegistrationAPI_ClusterNotFound);             
            }else if(clusters[0].MD_MyDiageoPermissions__c == null || clusters[0].MD_CommunityPermissionSet__c == null){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_ClusterNotValid);
                throw new registerContactsException(label.MD_RegistrationAPI_ClusterNotValid);              
            }
            
            DiageoCMS__Cluster__c cluster = clusters[0];
            
            Map<Id,String> invalidAccounts;
            
            if(cluster.MD_RegistrationValidationsClass__c != null){
                
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS account validations.');
                        
                Type t  = Type.forName(cluster.MD_RegistrationValidationsClass__c);
                           
                if(t != null){
                    CP_RegistrationValidationsInterface validations = (CP_RegistrationValidationsInterface)t.newInstance();
                    invalidAccounts = validations.execute(mapAccounts);
                }        
                
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ERRORS: ' + invalidAccounts);
                
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXITS account validations.');
            }else{
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. No Account validation class specify on cluster.');
            }
    
            Map<String,AccountContactRelation> mapAccConRelationsByKey = new Map<String,AccountContactRelation>();
            
            List<AccountContactRelation> records = [SELECT Id, ContactId, AccountId, MD_UserProfile__c, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c, MD_Status__c FROM AccountContactRelation WHERE ContactId IN: contactsMap.keySet() AND AccountId IN: accountIds];
            for(AccountContactRelation record: records){
                mapAccConRelationsByKey.put(record.ContactId + '-' + record.AccountId, record);
            }
                    
            List<AccountContactRelation> upsertAccConRecords = new List<AccountContactRelation>();
            
            Set<String> notUpdated = new Set<String>();
            
            for(String contactId: contactsMap.keySet()){
                for(String accountId: contactsMap.get(contactId)){
                    // invalid accounts are put in the response map
                    if(invalidAccounts.containsKey(accountId)){
                        if(responseMap.containsKey(contactId)){
                            responseMap.get(contactId).put(accountId, invalidAccounts.get(accountId));
                        }else{
                            responseMap.put(contactId, new Map<Id,String>{accountId => invalidAccounts.get(accountId)});
                        }
                    // not invalid accounts are either existing account contact relations that have to be updated or a new ones that have to be created
                    }else{
                        String key = contactId + '-' + accountId;
                        if(!mapAccConRelationsByKey.containsKey(key)){
                            upsertAccConRecords.add(new AccountContactRelation(ContactId = contactId, AccountId = accountId));
                        }else{
                            AccountContactRelation record = mapAccConRelationsByKey.get(key);
                            if(record.MD_UserProfile__c == null ||  record.MD_AssignedPermissions__c == null || record.MD_MyDiageoEnabled__c == false || record.MD_Status__c != 'Active'){
                                upsertAccConRecords.add(mapAccConRelationsByKey.get(key));
                            }else{
                                notUpdated.add(record.ContactId + '-' + record.AccountId);
                            }
                        }
                    }             
                }
            }
              
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. notUpdated: ' + notUpdated);
            
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. upsertAccConRecords: ' + upsertAccConRecords);
            
            if(!upsertAccConRecords.isEmpty()){
                // creates new and updates existing Account Contact Relations
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS account contact relations creation/update.');
                Map<Id,Map<Id,String>> upsertResult = upsertAccountContactRelations(upsertAccConRecords, cluster, allOrNone, userProfile);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ERRORS: ' + upsertResult);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXITS account contact relations creation/update.');
                // adds errors to response map
                for(Id key: upsertResult.keySet()){
                    if(!responseMap.containsKey(key)){
                        responseMap.put(key,upsertResult.get(Key));
                    }else{
                        responseMap.get(key).putAll(upsertResult.get(Key));
                    }
                }
            }
            
            // checks the contacts that have no error to continue with creating user
            Set<Id> contactsCreateUser = new Set<Id>();
            for(Id contactId: contactsMap.keySet()){
                if(!responseMap.containsKey(contactId) || contactsMap.get(contactId).size() > responseMap.get(contactId).size()){
                    contactsCreateUser.add(contactId);
                }
            }
            
            Map<Id,User> mapUserByContactId = new Map<Id,User>();
            
            // retrieves from database which contacts have already a user and if they have the permission set assigned as well
            for(User record: [SELECT Id, ContactId, (SELECT Id FROM PermissionSetAssignments WHERE PermissionSet.Name =: cluster.MD_CommunityPermissionSet__c) FROM User WHERE ContactId IN: contactsCreateUser]){
                mapUserByContactId.put(record.ContactId,record);
            }
            
            List<Id> toCreateUser = new List<Id>();
            Set<Id> toCreatePSAssignment = new Set<Id>();
            Set<Id> contactsAlreadyRegistered = new Set<Id>();
    
            // if the contact has no user the ids are saved to create the user, and if the contact already existis but no permission set assign the ids are saved
            for(Id contactId: contactsCreateUser){
                if(!mapUserByContactId.containsKey(contactId)){
                    toCreateUser.add(contactId);
                }else if(mapUserByContactId.get(contactId).PermissionSetAssignments.isEmpty()){
                    toCreatePSAssignment.add(mapUserByContactId.get(contactId).Id);
                }else{
                    contactsAlreadyRegistered.add(contactId);
                }
            }
            
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. toCreateUser: ' + toCreateUser);
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. contactsAlreadyRegistered: ' + contactsAlreadyRegistered);
            
            // users are created and errors are saved in the responseMap
            if(!toCreateUser.isEmpty()){
                Integer listIndex = 0;
                Map<Id,String> createUsersErrors = new Map<Id,String>();
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS create users.');
                CreateUserResponse createUserResult = createUsers(mapAllContacts, toCreateUser, allOrNone);
                if(createUserResult.errorMsge != null){
                    for(Id contactId: contactsMap.keySet()){
                        if( listIndex < toCreateUser.size() ){
                            if(!responseMap.containsKey(toCreateUser[listIndex])){
                                responseMap.put(toCreateUser[listIndex], new Map<Id,String>());
                            }
                            for(Id accountId: contactsMap.get(contactId)){
                                if(!responseMap.get(toCreateUser[listIndex]).containsKey(accountId)){
                                    responseMap.get(toCreateUser[listIndex]).put(accountId, label.MD_RegistrationAPI_UnableToCreateUser + ' ' + createUserResult.errorMsge);
                                }
                            }
                            createUsersErrors.put(toCreateUser[listIndex],createUserResult.errorMsge);
                        }
                        listIndex ++;
                    }                    
                }else{
                    for(Database.SaveResult saveResult: createUserResult.saveResults){
                        if(!saveResult.isSuccess()){                    
                            for(Id contactId: contactsMap.keySet()){
                                if( listIndex < toCreateUser.size() ){
                                    if(!responseMap.containsKey(toCreateUser[listIndex])){
                                        responseMap.put(toCreateUser[listIndex], new Map<Id,String>());
                                    }
                                    for(Id accountId: contactsMap.get(contactId)){
                                        if(!responseMap.get(toCreateUser[listIndex]).containsKey(accountId)){
                                            responseMap.get(toCreateUser[listIndex]).put(accountId, label.MD_RegistrationAPI_UnableToCreateUser + ' ' + saveResult.getErrors()[0].getMessage());
                                        }
                                    }
                                    createUsersErrors.put(toCreateUser[listIndex],saveResult.getErrors()[0].getMessage());
                                }
                            }
                        }else{
                            toCreatePSAssignment.add(saveResult.getId());
                        }
                        listIndex ++;
                    }
                }
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ERRORS: ' + createUsersErrors);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXITS create users.');
            }
    
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. toCreatePSAssignment: ' + toCreatePSAssignment);
            
            // permission set assignments are created and errors are saved in the responseMap
            if(!toCreatePSAssignment.isEmpty()){
                PermissionSet myDiageoPermissionSet = [SELECT Id FROM PermissionSet WHERE Name =: cluster.MD_CommunityPermissionSet__c];
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS FUTURE METHOD create permission set assignment.');
                assignPermissionSet(toCreatePSAssignment, myDiageoPermissionSet.Id);
            }
            
            List<Contact> contactsUpdate = new List<Contact>();
            Map<Id,Account> accountsUpdate = new Map<Id,Account>();
            
            // contacts and accounts have to be updated
            for(Id key: mapAllContacts.keySet()){
                if(!responseMap.containsKey(key) || contactsMap.get(key).size() > responseMap.get(key).size()){
                    Boolean doUpdate = false;
                    Contact con = new Contact(Id = key);
                    if(mapAllContacts.get(key).MD_MyDiageoInitialInviteDate__c == null){
                        con.MD_MyDiageoInitialInviteDate__c = DateTime.now();
                        doUpdate = true;
                    }
                    if(mapAllContacts.get(key).Registration_Source__c == null){
                        con.Registration_Source__c = source;
                        doUpdate = true;
                    }
                    if(mapAllContacts.get(key).MD_SubscriptionSource__c == null){
                        con.MD_SubscriptionSource__c = subscriptionSource == null ? 'Backend' : subscriptionSource;
                        doUpdate = true;
                    }
                    if(doUpdate){
                        contactsUpdate.add(con);
                    }                	
                    for(Id accountId: contactsMap.get(key)){
                        if((!responseMap.containsKey(key) || !responseMap.get(key).containsKey(accountId)) && mapAccounts.containsKey(accountId) && !mapAccounts.get(accountId).MD_MyDiageoInvited__c && !accountsUpdate.containsKey(accountId)){
                            /* ECOM-3737 - BEGIN */
                            String aux = mapAccounts.get(accountId).Products_Enabled__c;

                            if(aux == null) {
                                aux = 'MyDiageo';
                            } else if(!aux.contains('MyDiageo')) {
                                aux = aux + ';MyDiageo';
                            }
                            /* ECOM-3737 -   END */

                            accountsUpdate.put(accountId, new Account(Id = accountId, MD_MyDiageoInvited__c = true, Products_Enabled__c = aux));
                        }
                    }
                }
            }
            
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. contactsUpdate: ' + contactsUpdate);
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. accountsUpdate: ' + accountsUpdate);
            
            Map<Id,String> updateContactsErrors = new Map<Id,String>();
            Map<Id,String> updateAccountsErrors = new Map<Id,String>();
            
            if(!contactsUpdate.isEmpty()){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS update contacts.');
                updateContactsErrors = updateContacts(contactsUpdate, allOrNone);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ERRORS: ' + updateContactsErrors);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXITS update contacts.');          
            }
    
            if(!accountsUpdate.isEmpty()){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS update accounts.');
                updateAccountsErrors = updateAccounts(accountsUpdate.values(), allOrNone);         
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ERRORS: ' + updateAccountsErrors);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXITS update accounts.');
            }
    
            // rollback if there are errors and allOrNone is true
            if(allOrNone && !responseMap.isEmpty()){
                Database.rollback(sp); 
            }
            
            for(Id contactId: contactsMap.keySet()){
                if(!responseMap.containsKey(contactId)){
                    responseMap.put(contactId,new Map<Id,String>());
                }
                for(Id accountId: contactsMap.get(contactId)){
                    if(!responseMap.get(contactId).containsKey(accountId)){
                        if(updateContactsErrors.containsKey(contactId)){
                            responseMap.get(contactId).put(accountId, label.MD_RegistrationAPI_UnableToCreateContact + ' ' + updateContactsErrors.get(contactId));
                        }
                        if(updateAccountsErrors.containsKey(contactId)){
                            String auxString = responseMap.get(contactId).containsKey(accountId) ? responseMap.get(contactId).get(accountId) + ' - ' : '';
                            responseMap.get(contactId).put(accountId, (auxString + label.MD_RegistrationAPI_UnableToCreateAccount + ' ' + updateAccountsErrors.get(contactId)));
                        }
                        if(!responseMap.get(contactId).containsKey(accountId)){
                            String key = contactId + '-' + accountId;
                            if(contactsAlreadyRegistered.contains(contactId) && notUpdated.contains(key)){
                                responseMap.get(contactId).put(accountId, label.MD_RegistrationAPI_AlreadyRegistered);
                            }else{
                                responseMap.get(contactId).put(accountId, label.MD_RegistrationAPI_Success);
                            }                        
                        }
                    }
                }
            }        
            
            if(caseHandling){
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. ENTERS case creation.');
                MD_RegistrationUtil.createCase(responseMap, source);
                System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXITS case creation.');
            }
            
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. responseMap: ' + responseMap);
            
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. END');
        
        }catch(Exception e){
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. EXCEPTION: ' + label.MD_RegistrationAPI_ExceptionMessage + ' ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.registerContacts() method. END');
            throw new registerContactsException(Label.MD_RegistrationAPI_ExceptionMessage + ' ' + e.getMessage());                    
        }
        
        return responseMap;
    }
    
    // END REGISTRATION API
    
    @TestVisible
    private static Map<Id,Map<Id,String>> upsertAccountContactRelations(List<AccountContactRelation> upsertAccConRecords, DiageoCMS__Cluster__c cluster, Boolean allOrNone, String userProfile){
        Map<Id,Map<Id,String>> errorsMap = new Map<Id,Map<Id,String>>();
        
        try {
                    
            for(AccountContactRelation record: upsertAccConRecords){
                if(record.MD_UserProfile__c == null){
                    record.MD_UserProfile__c = userProfile == null ? 'Primary User' : userProfile;
                }
                record.MD_AssignedPermissions__c = record.MD_AssignedPermissions__c == null ? cluster.MD_MyDiageoPermissions__c : record.MD_AssignedPermissions__c;
                record.MD_MyDiageoEnabled__c = !record.MD_MyDiageoEnabled__c ? true : record.MD_MyDiageoEnabled__c;
                record.MD_Status__c = record.MD_Status__c != 'Active' ? 'Active' : record.MD_Status__c;
            }
            
        	List<Database.upsertResult> saveResults = Database.upsert(upsertAccConRecords, allOrNone);
            
            Integer listIndex = 0;
        
            for(Database.upsertResult saveResult: saveResults){
                if(!saveResult.isSuccess()){
                    Id contactId = upsertAccConRecords[listIndex].ContactId;
                    Id accountId = upsertAccConRecords[listIndex].AccountId;
                    if(errorsMap.containsKey(contactId)){
                        errorsMap.get(contactId).put(accountId,saveResult.getErrors()[0].getMessage());
                    }else{
                        errorsMap.put(contactId, new Map<Id,String>{accountId => label.MD_RegistrationAPI_UnableToCreateAccConRelation + ' ' + saveResult.getErrors()[0].getMessage()});
                    }
                }
                listIndex ++;
            }
        }catch(Exception e){
            for(AccountContactRelation record: upsertAccConRecords){
                if(errorsMap.containsKey(record.ContactId)){
                    errorsMap.get(record.ContactId).put(record.AccountId,e.getDMLMessage(0));
                }else{
                    errorsMap.put(record.ContactId, new Map<Id,String>{record.AccountId => e.getDMLMessage(0)});
                }                
            }            
        }
        
        return errorsMap;
        
    }     
    
    @TestVisible
    private class CreateUserResponse {	
        private String errorMsge;
        private List<Database.SaveResult> saveResults;
    }    
    
    @TestVisible
    private static CreateUserResponse createUsers(Map<Id,Contact> mapAllContacts, List<Id> contactIds, Boolean allOrNone){

        Set<String> countryCodes = new Set<String>();
        for(Contact con: mapAllContacts.values()){
            countryCodes.add(con.Account.Country__r.Code__c);
        }

        Profile p = [SELECT Id FROM PROFILE WHERE Name = 'Customer Community Plus Login Custom'];

        Map<String,MD_CountryUserInformation__mdt> mapCountriesInfo = new Map<String,MD_CountryUserInformation__mdt>();
        List<MD_CountryUserInformation__mdt> countriesInfo = [SELECT Country__c, EmailEncodingKey__c, LanguageLocaleKey__c, LocaleSidKey__c, TimeZoneSidKey__c, DeveloperName, Grouping__c, AvailableCountry__c FROM MD_CountryUserInformation__mdt WHERE DeveloperName IN: countryCodes];
        if(countriesInfo.isEmpty() || countriesInfo.size() < countryCodes.size()){
            throw new registerContactsException(label.MD_CountryUserInformationMissing);
        }else{
            for(MD_CountryUserInformation__mdt countryInfo: countriesInfo){
                mapCountriesInfo.put(countryInfo.DeveloperName, countryInfo);
            }
        }
                
        List<User> usersInsert = new List<User>();
        
        for(Id contactId: contactIds){
            Contact con = mapAllContacts.get(contactId);
            String countryCode = con.Account.Country__r.Code__c;
            String communityNickNameRandomNumber = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3);
            con.FirstName = con.FirstName != null ? con.FirstName : '';
            String communityNickName = (con.FirstName + con.LastName).length() > 37 ? (con.FirstName + con.LastName).substring(0,36) + communityNickNameRandomNumber : (con.FirstName + con.LastName + communityNickNameRandomNumber);               

            Integer firstNameLength = con.FirstName.length();
            Integer lastNameLength = con.LastName.length();
            String alias = con.FirstName.substring(0, firstNameLength < 3 ? firstNameLength : 3) + con.LastName.substring(0, lastNameLength < 3 ? lastNameLength : 3);

            User newUser = new User(
                LastName                = con.LastName, 
                FirstName               = con.FirstName, 
                Department              = con.Department, 
                Title                   = con.Title,
                Street                  = con.MailingStreet, 
                City                    = con.MailingCity, 
                State                   = con.MailingState, 
                PostalCode              = con.MailingPostalCode, 
                Email                   = con.Email, 
                Phone                   = con.Phone, 
                Fax                     = con.Fax, 
                MobilePhone             = con.MobilePhone,
                Alias                   = alias,
                UserName                = con.Email, 
                CommunityNickname       = communityNickName, 
                ProfileId               = p.Id, 
                ContactId               = con.Id,
                Country                 = mapCountriesInfo.get(countryCode).Country__c,            
                LocaleSidKey            = mapCountriesInfo.get(countryCode).LocaleSidKey__c,
                TimeZoneSidKey          = mapCountriesInfo.get(countryCode).TimeZoneSidKey__c,
                EmailEncodingKey        = mapCountriesInfo.get(countryCode).EmailEncodingKey__c,
                LanguageLocaleKey       = (String.isNotBlank(con.Preferred_Language__c)?con.Preferred_Language__c:mapCountriesInfo.get(countryCode).LanguageLocaleKey__c),
                Available_Countries__c  = mapCountriesInfo.get(countryCode).AvailableCountry__c,
                Grouping__c             = mapCountriesInfo.get(countryCode).Grouping__c
                
            ); 
            usersInsert.add(newUser);           
        }
        CreateUserResponse response = new CreateUserResponse();
        try{
        	List<Database.SaveResult> results = Database.insert(usersInsert, allOrNone);
            response.saveResults = results;
        }catch(Exception e){
            response.errorMsge = e.getDMLMessage(0);       
        }
        return response;
    }    

    @TestVisible
    private static Map<Id,String> updateContacts(List<Contact> contacts, Boolean allOrNone){
        
        Map<Id,String> errorsMap = new Map<Id,String>();

        try{
        	List<Database.SaveResult> saveResults = Database.update(contacts, allOrNone);
            
            Integer listIndex = 0;
            
            for(Database.SaveResult saveResult: saveResults){
                if(!saveResult.isSuccess()){
                    errorsMap.put(contacts[listIndex].Id,saveResult.getErrors()[0].getMessage());
                }
                listIndex ++;
            }
            
        }catch(Exception e){
            for(Contact record: contacts){
                errorsMap.put(record.Id,e.getDMLMessage(0));              
            }            
        }
        
        return errorsMap;          
    }

    @TestVisible
    private static Map<Id,String> updateAccounts(List<Account> accounts, Boolean allOrNone){
        
        Map<Id,String> errorsMap = new Map<Id,String>();

        try{
        	List<Database.SaveResult> saveResults = Database.update(accounts, allOrNone);
            
            Integer listIndex = 0;
            
            for(Database.SaveResult saveResult: saveResults){
                if(!saveResult.isSuccess()){
                    errorsMap.put(accounts[listIndex].Id,saveResult.getErrors()[0].getMessage());
                }
                listIndex ++;
            }
            
        }catch(Exception e){
            for(Account record: accounts){
                errorsMap.put(record.Id,e.getDMLMessage(0));              
            }            
        }
                
        return errorsMap;          
    }
    
    @TestVisible
    @future
    private static void assignPermissionSet(Set<Id> userIds, Id psetId){
        System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. BEGIN ');
        List<PermissionSetAssignment> inserts = new List<PermissionSetAssignment>();

        for(Id userId : userIds) {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. userId: ' + userId + ' - psetId: ' + psetId);
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId,PermissionSetId = psetId);
            inserts.add(psa);
        }

        try {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. inserts: ' + inserts);
            upsert inserts;
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. END ');

        }catch(DmlException e) {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getMessage: ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getStackTraceString: ' + e.getStackTraceString());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. END ');
        }catch(Exception e) {
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getLineNumber: ' + e.getLineNumber());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getMessage: ' + e.getMessage());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. e.getStackTraceString: ' + e.getStackTraceString());
            System.debug('CG - in MD_RegistrationUtil.assignPermissions() method. END ');
        }
    }        
    
}