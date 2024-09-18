/**************************************************************************************
Apex Class Name  :  TestFactory_MD_Account 
Version          :  1.0
Created Date     :  15/07/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         15/07/2019              Original Version
* Anamika Shukla            22/01/2024              350972
******************************************************************************/
@isTest
public class TestFactory_MD_Account { 
    
    public static void setup(Boolean createUserAsCommunity) {
        
        Contact contact;
        
        system.runas(collabMDMUser){
            Map<String, Geography__c> geos = createGeographies();
            
            Map<String, RecordType> accountsRt = new Map<String, RecordType>();
            
            for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
                accountsRt.put(art.DeveloperName, art);
            }
            
            List<Account> ownerAccounts = createAccounts(accountsRt.get('Owner'), 'TestAccountOwner', 1, geos, false);
            for(Account ownerAccount : ownerAccounts) {
                ownerAccount.Global_Segment__c = null;
                ownerAccount.Global_Sub_Segment__c = null;
                ownerAccount.IsOwner__c = true;
                ownerAccount.IsOperator__c = true;
                ownerAccount.Status__c = 'Active'; 
            }
            insert ownerAccounts;
            
            List<Account> outletsAccounts = createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet', 1, geos, false);
            
            for(Account outletAccount : outletsAccounts) {
                outletAccount.ParentId = ownerAccounts.get(0).Id;
                outletAccount.Operator__c = ownerAccounts.get(0).Id;
            }
            
            insert outletsAccounts;
            
            contact = createContact(outletsAccounts
                                    , createAgreement('MD_TermsAndConditions', true).Id
                                    , createAgreement('MD_PrivacyPolicy', true).Id, true);
            
            List<AccountContactRelation> accountContactRelations = [SELECT Id, MD_Status__c FROM AccountContactRelation WHERE ContactId =: contact.Id];
            List<AccountContactRelation> toUpdate = new List<AccountContactRelation>();
            
            for (AccountContactRelation acr : accountContactRelations){
                acr.MD_Status__c = 'Active';
                acr.MD_AssignedPermissions__c = 'Access;Manage Users';
                toUpdate.add(acr);
            }
            
            update toUpdate;
        }
        
        createUser(contact.Id, createUserAsCommunity);
    }
    
    public static void setupNoUser(Boolean createUserAsCommunity) {
        
        Contact contact;
        
        system.runas(collabMDMUser){
            Map<String, Geography__c> geos = createGeographies();
            
            Map<String, RecordType> accountsRt = new Map<String, RecordType>();
            
            for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
                accountsRt.put(art.DeveloperName, art);
            }
            
            List<Account> ownerAccounts = createAccounts(accountsRt.get('Owner'), 'TestAccountOwner', 1, geos, false);
            for(Account ownerAccount : ownerAccounts) {
                ownerAccount.Global_Segment__c = null;
                ownerAccount.Global_Sub_Segment__c = null;
                ownerAccount.IsOwner__c = true;
                ownerAccount.IsOperator__c  = true;
                ownerAccount.Status__c = 'Active';
            }
            insert ownerAccounts;
            
            List<Account> outletsAccounts = createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet', 1, geos, false);
            
            for(Account outletAccount : outletsAccounts) {
                outletAccount.ParentId = ownerAccounts.get(0).Id;
                outletAccount.Operator__c = ownerAccounts.get(0).Id;
            }
            
            insert outletsAccounts;
            
            contact = createContact(outletsAccounts
                                    , createAgreement('MD_TermsAndConditions', true).Id
                                    , createAgreement('MD_PrivacyPolicy', true).Id, true);
            
            List<AccountContactRelation> accountContactRelations = [SELECT Id, MD_Status__c FROM AccountContactRelation WHERE ContactId =: contact.Id];
            List<AccountContactRelation> toUpdate = new List<AccountContactRelation>();
            for (AccountContactRelation acr : accountContactRelations){
                acr.MD_Status__c = 'Active';
                toUpdate.add(acr);
            }
            
            update toUpdate;
            
        }
        
    }
    public static List<Account> createAccounts(RecordType recordType, String name, Integer nOfAccounts, Map<String, Geography__c> geos, boolean insertRecords) {
        List<Account> accounts = new List<Account>();
        
        for(Integer i = 0; i < nOfAccounts; i++) {
            Account ac = new Account(RecordTypeId = recordType.Id
                                     , name = name + recordType.DeveloperName + '_Test'
                                     , BillingStreet = '123 Main St'
                                     , BillingCity = 'Madrid'
                                     , BillingCountry = 'Spain'
                                     , Global_Channel__c = 'On Trade'
                                     , Global_Sub_Channel__c = 'On trade'
                                     , Global_Segment__c = 'Bar'
                                     , Global_Sub_Segment__c = 'Modern Bar'
                                     , Area__c = geos.get('Area').Id
                                     , Region__c = geos.get('Region').Id
                                     , Cluster__c = geos.get('Cluster').Id
                                     , Country__c = geos.get('Country').Id
                                     , Hub__c = geos.get('Hub').Id
                                     , Market__c = geos.get('Market').Id
                                    );
            
            accounts.add(ac);
        }
        
        if(insertRecords) {
            insert accounts;
        }
        
        System.debug(LoggingLevel.DEBUG,'TestFactory_CP_Account :: createAccounts :: accounts :: ' + accounts);     
        return accounts;
    }
    
    public static User collabMDMUser{get{
        if(collabMDMUser == null){
            collabMDMUser = [select id from user where profile.name = 'System Administrator' and isactive=true and userroleid != null limit 1][0];
        } 
        return collabMDMUser;
    }set;}
    
    public static User integrationUser{get{
        if(integrationUser == null){
            integrationUser = [select id from user where profile.name = 'System Administrator' and isactive=true and userroleid != null limit 1][0];
        }
        return integrationUser;
    }set;}      
    
    public static Map<String, Geography__c> createGeographies() {
        Map<String, Id> geosRTs = new Map<String, Id>();
        Map<String, Geography__c> result = new Map<String, Geography__c>();
        
        for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Geography__c']) {
            geosRTs.put(rt.DeveloperName, rt.Id);
        }
        
        Geography__c globalG = new Geography__c();
        globalG.Name = 'Global';
        globalG.Code__c = 'GL';
        globalG.RecordTypeId = geosRTs.get('Global');
        insert globalG;
        result.put('Global', globalG);
        
        Geography__c marketG = new Geography__c();
        marketG.Name = 'Market';
        marketG.Code__c = 'MA';
        marketG.RecordTypeId = geosRTs.get('Market');
        marketG.Parent_Geography__c = globalG.Id;
        insert marketG;
        result.put('Market', marketG);
        
        Geography__c hubG = new Geography__c();
        hubG.Name = 'Hub';
        hubG.Code__c = 'HU';
        hubG.RecordTypeId = geosRTs.get('Hub');
        hubG.Parent_Geography__c = marketG.Id;
        insert hubG;
        result.put('Hub', hubG);
        
        Geography__c clusterG = new Geography__c();
        clusterG.Name = 'Cluster';
        clusterG.Code__c = 'CL';
        clusterG.RecordTypeId = geosRTs.get('Cluster');
        clusterG.Parent_Geography__c = hubG.Id;
        insert clusterG;
        result.put('Cluster', clusterG);
        
        Geography__c countryG = new Geography__c();
        countryG.Name = 'Country';
        countryG.Code__c = 'CO';
        countryG.RecordTypeId = geosRTs.get('Country');
        countryG.Parent_Geography__c = clusterG.Id;
        insert countryG;
        result.put('Country', countryG);
        
        Geography__c areaG = new Geography__c();
        areaG.Name = 'Area';
        areaG.Code__c = 'AR';
        areaG.RecordTypeId = geosRTs.get('Area');
        areaG.Parent_Geography__c = countryG.Id;
        insert areaG;
        result.put('Area', areaG);
        
        Geography__c regionG = new Geography__c();
        regionG.Name = 'Region';
        regionG.Code__c = 'RE';
        regionG.RecordTypeId = geosRTs.get('Region');
        regionG.Parent_Geography__c = areaG.Id;
        insert regionG;
        result.put('Region', regionG);
        
        return result;
    }
    
    public static Map<String, Geography__c> getGeographies() {
        Map<String, Geography__c> result = new Map<String, Geography__c>();
        for (Geography__c geo: [SELECT Id, Name, Code__c, RecordTypeId FROM Geography__c]){
            result.put(geo.Name, geo);
        }
        System.debug(LoggingLevel.DEBUG,'result'+result );
        return result; 
    }
    
    
    public static MD_Agreement__c createAgreement(String recordTypeName, Boolean insertRecord) {
        RecordType recordType;
        
        if (recordTypeName == 'MD_PrivacyPolicy') {
            recordType = [SELECT Id, DeveloperName 
                          FROM RecordType 
                          WHERE SobjectType = 'MD_Agreement__c' AND DeveloperName = 'MD_PrivacyPolicy' LIMIT 1];
        } else if (recordTypeName == 'MD_TermsAndConditions') {
            recordType  = [SELECT Id, DeveloperName FROM RecordType 
                           WHERE SobjectType = 'MD_Agreement__c' AND DeveloperName = 'MD_TermsAndConditions' LIMIT 1];
        }
        MD_Agreement__c agreement = new MD_Agreement__c(RecordTypeId=recordType.Id, Status__c = 'Published'
                                                        , Version__c = 1, RichText__c = 'Agreement for testing');
        
        if (insertRecord) {
            insert agreement;
        }
        
        return agreement;
    }
    
    public static Contact createContact(List<Account> accounts, Id termsAndConditionsId, Id privacyPolicyId, Boolean insertRecord) {
        
        Contact contact = new Contact(FirstName = 'FirstName', LastName = 'LastName for testing'
                                      , AccountId = accounts.get(0).Id
                                      , MobilePhone = '112134'
                                      , Email = System.now().millisecond() + 'test@test.com');
        
        if (insertRecord) {
            insert contact;
            System.debug(LoggingLevel.DEBUG,'TestFactory_CP_Account :: createContact :: contact:: ' + contact);
            
            List<AccountContactRelation> accountContacts = new List<AccountContactRelation>();
            
            System.debug(LoggingLevel.DEBUG,'TestFactory_CP_Account :: createContact :: accounts size:: ' + accounts.size());
            
            for(Integer i = 0; i < accounts.size() ; i ++) {
                if(i != 0) {
                    Account acc = accounts.get(i);
                    AccountContactRelation accountContact = new AccountContactRelation();
                    accountContact.ContactId = contact.Id;
                    accountContact.AccountId = acc.Id;
                    accountContact.MD_Status__c = 'Active';
                    accountContact.MD_AssignedPermissions__c = 'Access';
                    accountContacts.add(accountContact);
                }
            }
            
            insert accountContacts;
            
            System.debug(LoggingLevel.DEBUG,'TestFactory_CP_Account :: createContact :: accountContact:: ' + accountContacts);
        }          
        return contact;
    }
    
    @future
    public static void createUser(Id conId, Boolean createUserAsCommunity){
        Id profileId;
        
        if(createUserAsCommunity) {
            profileId = [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus Login Custom' LIMIT 1].Id;
        }else {
            profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        }
        
        
        User u = createnewUser('hola', conId, profileId);
        insert u;
        
        if(createUserAsCommunity) {
            PermissionSet myDiageoPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'MD_MyDiageoUser'];
            insert new PermissionSetAssignment(PermissionSetId = myDiageoPermissionSet.Id, AssigneeId = u.Id);
        }
    }
    
    public static User createnewUser(String uniquekey, Id conId, Id profileId){        
        return new User (
            ContactId = conId,
            Alias = uniqueKey,
            Email = uniqueKey + '@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test' + uniqueKey,
            FirstName = uniqueKey,
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Chicago',
            Username = uniqueKey + '@test' + Math.round(Math.random() * 10000) + '.com',
            Country = 'Spain',
            Grouping__c = 'On Trade',
            Available_Countries__c = 'ES'
        );
    }
    
    
    public static MD_SessionSettings__c createSettingsForUser(Id userId, Id accountContactId) {
        MD_SessionSettings__c settings = new MD_SessionSettings__c(SetupOwnerId = userId, NavigateAsOutlet__c = accountContactId);
        insert settings;
        
        return settings;
    }
    
    public static MD_SessionSettings__c createSettingsForUserWithCluster(Id userId, Id accountContactId, List<Id> clusterIds) {
        MD_SessionSettings__c settings = new MD_SessionSettings__c(SetupOwnerId = userId, NavigateAsOutlet__c = accountContactId, Clusters__c = clusterIds[0]);
        insert settings;
        
        return settings; 
    }
    
    public static Map<String, DiageoCMS__Cluster__c> setupCreateClusters() {
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        Map<String, Id> recordTypeNames = new Map<String, Id>();
        
        for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'DiageoCMS__Cluster__c']) {
            recordTypeNames.put(rt.DeveloperName, rt.Id);
        }
        System.debug(LoggingLevel.DEBUG,'recordTypeNames'+recordTypeNames );
        DiageoCMS__Cluster__c rootCluster = new DiageoCMS__Cluster__c();
        rootCluster.Name = 'Test_CR_Cluster';
        rootCluster.DiageoCMS__ExternalId__c = 'CR';
        rootCluster.RecordTypeId = recordTypeNames.get('ClusterRoot');
        insert rootCluster;
        result.put('ClusterRoot', rootCluster);
        
        DiageoCMS__Cluster__c groupCluster = new DiageoCMS__Cluster__c();
        groupCluster.Name = 'Test_CG_Cluster';
        groupCluster.DiageoCMS__ParentCluster__c = rootCluster.Id;
        groupCluster.DiageoCMS__ExternalId__c = 'CG';
        groupCluster.RecordTypeId = recordTypeNames.get('ClusterGroup');
        insert groupCluster;
        result.put('ClusterGroup', groupCluster);
        
        DiageoCMS__Cluster__c leafCluster = new DiageoCMS__Cluster__c();
        leafCluster.Name = 'Test_CO_Cluster';
        leafCluster.DiageoCMS__ParentCluster__c = groupCluster.Id;
        leafCluster.RecordTypeId = recordTypeNames.get('ClusterLeaf');
        leafCluster.DiageoCMS__ExternalId__c = 'CO';
        leafCluster.MD_MyDiageoPermissions__c = 'Access;Order;Account Documents;Manage Users';
        leafCluster.CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies';
        insert leafCluster;
        result.put('ClusterLeaf', leafCluster);
        
        return result;
    }
}