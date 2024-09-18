/**************************************************************************************
Apex Class Name  :  Test_MD_RegistrationUtil
Version          :  1.0
Created Date     :  30/04/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         30/04/2019              Original Version
******************************************************************************/
@isTest
public class Test_MD_RegistrationUtil {
    
    /* 
    * @Author      :  Elena Schwarzbock     
    * @description :  Create an Account, Contact, AccountContactRelation and User used in the test method of the class               
    */
    @testSetup public static void createAccountContactAndRelation(){
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setupNoUser(true);
    }
    
    @isTest
    public static void createUserTest01() {
        
        Set<Id> contactsId = new Set<Id>();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        
        Account ac = new Account();
        
        System.runas(TestFactory_MD_Account.collabMDMUser){
            ac = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId()
                                         , name = 'AccountTest01_Test'
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
            
            insert ac;
        }
        
        Contact c = new Contact();
        c.Email = 'testlastname@email.com';
        c.LastName = 'TestLastName';
        c.AccountId = ac.Id;
        
        insert c;
        
        contactsId.add(c.Id);
        
        Test.startTest();
        MD_RegistrationUtil.createUser(contactsId);
        
        Test.stopTest();
    }
    
    static testMethod void insertContactAndAccContactsTest01() {
        Test.startTest();
		
		Map<String, Geography__c> geoMaps = new Map<String, Geography__c>();
        
        for(Geography__c geo : [SELECT Id, RecordType.DeveloperName FROM Geography__c]) {
            geoMaps.put(geo.RecordType.DeveloperName, geo);
        }
        
        RecordType outletRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Outlet' AND SObjectType = 'Account' LIMIT 1];
        
        Account acOwner = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Owner' LIMIT 1];
        
        Account newOutlet = new Account(RecordTypeId = outletRt.Id, Name = 'McDonalds'
                                        , Operator__c = acOwner.Id
                                        , Cluster__c = geoMaps.get('Cluster').Id
                                        , Country__c = geoMaps.get('Country').Id
                                        , Area__c = geoMaps.get('Area').Id
                                        , Hub__c = geoMaps.get('Hub').Id
                                        , Market__c = geoMaps.get('Market').Id
                                        , Region__c = geoMaps.get('Region').Id);
        insert newOutlet;
        
        Contact con = new Contact();
        con.FirstName = 'NewContact';
        con.LastName = 'ForTest';
        con.Email = 'newcontact.fortest@test.com';
        con.MobilePhone = '82374982137412';
        con.AccountId = newOutlet.Id;
        
        List<AccountContactRelation> accContacts = new List<AccountContactRelation>();
            
        MD_RegistrationUtil.insertContactAndAccContacts(con, accContacts, UserInfo.getUserId());
        
		Test.stopTest();
    }
    
    static testMethod void insertContactAndAccContactsTest02() {
        Test.startTest();
		
		Map<String, Geography__c> geoMaps = new Map<String, Geography__c>();
        
        for(Geography__c geo : [SELECT Id, RecordType.DeveloperName FROM Geography__c]) {
            geoMaps.put(geo.RecordType.DeveloperName, geo);
        }
        
        RecordType outletRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Outlet' AND SObjectType = 'Account' LIMIT 1];
        
        Account acOwner = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Owner' LIMIT 1];
        
        Account newOutlet = new Account(RecordTypeId = outletRt.Id, Name = 'McDonalds'
                                        , Operator__c = acOwner.Id
                                        , Cluster__c = geoMaps.get('Cluster').Id
                                        , Country__c = geoMaps.get('Country').Id
                                        , Area__c = geoMaps.get('Area').Id
                                        , Hub__c = geoMaps.get('Hub').Id
                                        , Market__c = geoMaps.get('Market').Id
                                        , Region__c = geoMaps.get('Region').Id);
        insert newOutlet;
        
        Contact con = new Contact();
        con.FirstName = 'NewContact';
        con.LastName = 'ForTest';
        con.Email = 'newcontact.fortest@test.com';
        con.MobilePhone = '82374982137412';
        con.AccountId = newOutlet.Id;
        
        List<AccountContactRelation> accContacts = new List<AccountContactRelation>();
            
        MD_RegistrationUtil.insertContactAndAccContacts(con, accContacts, UserInfo.getUserId());
        
		Test.stopTest();        
    }

    static testMethod void registerContacts() {
		
        Test.startTest();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner2', 10, geos, false);
        for(Account ownerAccount : ownerAccounts) {
            ownerAccount.Global_Segment__c = null;
            ownerAccount.Global_Sub_Segment__c = null;
            ownerAccount.IsOwner__c = true;
            ownerAccount.IsOperator__c  = true;
            ownerAccount.Status__c = 'Active';
        }
        insert ownerAccounts;
        
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet2', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            accToUpdate.add(a);
        }
                
        update accToUpdate;
        
        TestFactory_MD_Account.createContact(accToUpdate, null, null, true);
        
        TestFactory_MD_Account.setupCreateClusters();
        
        DiageoCMS__Cluster__c cluster = [SELECT Id, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = 'CO'];
        cluster.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        cluster.MD_CommunityPermissionSet__c = 'MD_MyDiageoUser';
        cluster.MD_RegistrationValidationsClass__c = 'MD_ES_RegistrationValidationsClass.SpainValidations';
        cluster.DiageoCMS__ExternalId__c = 'CO';
        
        update cluster;
            
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact];

        Map<Id,Set<Id>> contactMap = new Map<Id,Set<Id>>();
        for(Contact con: contacts){
        	contactMap.put(con.Id, new Set<Id>{con.AccountId});
        }
        
        
        Map<Id,Map<Id,String>> responseMap = MD_RegistrationUtil.registerContacts(contactMap, 'CO', false, true, 'MyDiageo', 'Backend', null);
        MD_RegistrationUtil.createCase(responseMap, 'Backend');
		
        Test.stopTest();
    }

    static testMethod void registerContacts2() {
		
        Test.startTest();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner2', 10, geos, false);
        for(Account ownerAccount : ownerAccounts) {
            ownerAccount.Global_Segment__c = null;
            ownerAccount.Global_Sub_Segment__c = null;
            ownerAccount.IsOwner__c = true;
            ownerAccount.IsOperator__c  = true;
            ownerAccount.Status__c = 'Active';
        }
        insert ownerAccounts;
        
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet2', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            a.Global_Channel__c = 'On Trade';
            accToUpdate.add(a);
        }

        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Oulet']){
            a.VAT_Number__c = '234567891';
            a.Global_Channel__c = 'On Trade';
            accToUpdate.add(a);
        }        
        
        update accToUpdate;
        
        TestFactory_MD_Account.createContact(accToUpdate, null, null, true);
        
        TestFactory_MD_Account.setupCreateClusters();
        
        DiageoCMS__Cluster__c cluster = [SELECT Id, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = 'CO'];
        cluster.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        cluster.MD_CommunityPermissionSet__c = 'MD_MyDiageoUser';
        cluster.MD_RegistrationValidationsClass__c = 'MD_ES_RegistrationValidationsClass.SpainValidations';
        cluster.DiageoCMS__ExternalId__c = 'CO';
        
        update cluster;

        Map<Id,Set<Id>> contactMap = new Map<Id,Set<Id>>();
        List<Contact> contacts = [SELECT Id FROM Contact];
        List<Account> accounts = [SELECT Id FROM Account];
        
        for(Contact con: contacts){
        	contactMap.put(con.Id, new Set<Id>());
            for(Account acc: accounts){
                contactMap.get(con.Id).add(acc.Id);
            }
        }
        
        Map<Id,Map<Id,String>> responseMap = MD_RegistrationUtil.registerContacts(contactMap, 'CO', false, true, 'MyDiageo', 'Backend', null);
        MD_RegistrationUtil.createCase(responseMap, 'Backend');
		
        Test.stopTest();
    }    
    
    static testMethod void upsertAccountContactRelationsTest01() {
		Test.startTest();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner2', 10, geos, false);
        for(Account ownerAccount : ownerAccounts) {
            ownerAccount.Global_Segment__c = null;
            ownerAccount.Global_Sub_Segment__c = null;
            ownerAccount.IsOwner__c = true;
            ownerAccount.IsOperator__c  = true;
            ownerAccount.Status__c = 'Active';
        }
        insert ownerAccounts;
        
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet2', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            accToUpdate.add(a);
        }
                
        update accToUpdate;
        
        TestFactory_MD_Account.createContact(accToUpdate, null, null, true);
        
        TestFactory_MD_Account.setupCreateClusters();
        
        DiageoCMS__Cluster__c cluster = [SELECT Id, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = 'CO'];
        cluster.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        cluster.MD_CommunityPermissionSet__c = 'MD_MyDiageoUser';
        cluster.MD_RegistrationValidationsClass__c = 'MD_ES_RegistrationValidationsClass.SpainValidations';
        cluster.DiageoCMS__ExternalId__c = 'CO';
        
        update cluster;
            
        List<AccountContactRelation> records = [SELECT Id, ContactId, AccountId, MD_UserProfile__c, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c, MD_Status__c FROM AccountContactRelation];

        MD_RegistrationUtil.upsertAccountContactRelations(records, cluster, false, null);
		
        Test.stopTest();
    }
    
    static testMethod void upsertAccountContactRelationsTest02() {
        Test.startTest();
		
		Map<String, Geography__c> geoMaps = new Map<String, Geography__c>();
        
        for(Geography__c geo : [SELECT Id, RecordType.DeveloperName FROM Geography__c]) {
            geoMaps.put(geo.RecordType.DeveloperName, geo);
        }
        
        RecordType outletRt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Outlet' AND SObjectType = 'Account' LIMIT 1];
        
        Account acOwner = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Owner' LIMIT 1];
        List<Account> outlets = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Outlet'];
        
        Account newOutlet = new Account(RecordTypeId = outletRt.Id, Name = 'McDonalds'
                                        , Operator__c = acOwner.Id
                                        , Cluster__c = geoMaps.get('Cluster').Id
                                        , Country__c = geoMaps.get('Country').Id
                                        , Area__c = geoMaps.get('Area').Id
                                        , Hub__c = geoMaps.get('Hub').Id
                                        , Market__c = geoMaps.get('Market').Id
                                        , Region__c = geoMaps.get('Region').Id);
        insert newOutlet;
        
        Contact con = new Contact();
        con.FirstName = 'NewContact';
        con.LastName = 'ForTest';
        con.Email = 'newcontact.fortest@test.com';
        con.MobilePhone = '82374982137412';
        con.AccountId = newOutlet.Id; 
        
        insert con;
        
        List<AccountContactRelation> accountContacts = [SELECT Id, ContactId, AccountId, MD_UserProfile__c, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c, MD_Status__c FROM AccountContactRelation];
        AccountContactRelation ac = new AccountContactRelation();
        ac.AccountId = newOutlet.Id;
        ac.ContactId = con.Id;
        ac.Contact_Type__c = 'Secondary';
        accountContacts.add(ac);
		
        ac = new AccountContactRelation();
        ac.AccountId = outlets.get(0).Id;
        ac.ContactId = con.Id;
        ac.Contact_Type__c = 'Secondary';
        accountContacts.add(ac);
        
        TestFactory_MD_Account.setupCreateClusters();
        
        DiageoCMS__Cluster__c cluster = [SELECT Id, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = 'CO'];
        cluster.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        cluster.MD_CommunityPermissionSet__c = 'MD_MyDiageoUser';
        cluster.MD_RegistrationValidationsClass__c = 'MD_ES_RegistrationValidationsClass.SpainValidations';
        cluster.DiageoCMS__ExternalId__c = 'CO';
        
        update cluster;
        
        MD_RegistrationUtil.upsertAccountContactRelations(accountContacts, cluster, false,'Primary');
        
		Test.stopTest();
    }
    
    static testMethod void createUsers() {
		Test.startTest();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner2', 10, geos, false);
        for(Account ownerAccount : ownerAccounts) {
            ownerAccount.Global_Segment__c = null;
            ownerAccount.Global_Sub_Segment__c = null;
            ownerAccount.IsOwner__c = true;
            ownerAccount.IsOperator__c  = true;
            ownerAccount.Status__c = 'Active';
        }
        insert ownerAccounts;
        
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet2', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            accToUpdate.add(a);
        }
                
        update accToUpdate;
        
        TestFactory_MD_Account.createContact(accToUpdate, null, null, true);
        
        TestFactory_MD_Account.setupCreateClusters();
        
        DiageoCMS__Cluster__c cluster = [SELECT Id, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = 'CO'];
        cluster.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        cluster.MD_CommunityPermissionSet__c = 'MD_MyDiageoUser';
        cluster.MD_RegistrationValidationsClass__c = 'MD_ES_RegistrationValidationsClass.SpainValidations';
        cluster.DiageoCMS__ExternalId__c = 'CO';
        
        update cluster;
            
        Map<Id,Contact> mapRecords = new Map<Id,Contact>([SELECT Id, MD_SubscriptionSource__c, MD_MyDiageoInitialInviteDate__c, AccountId, Account.Country__c, Account.Country__r.Code__c, FirstName, LastName, Department, Title, MailingStreet, MailingCity, MailingState, MailingPostalCode, Email, Phone, Fax, MobilePhone,Preferred_Language__c FROM Contact]);

        List<Id> contactIds = new List<Id>();
        contactIds.addALL(mapRecords.keySet());
        
        MD_RegistrationUtil.createUsers(mapRecords, contactIds, true);
		
        Test.stopTest();
    }    

    static testMethod void updateContacts() {
		Test.startTest();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner2', 10, geos, false);
        for(Account ownerAccount : ownerAccounts) {
            ownerAccount.Global_Segment__c = null;
            ownerAccount.Global_Sub_Segment__c = null;
            ownerAccount.IsOwner__c = true;
            ownerAccount.IsOperator__c  = true;
            ownerAccount.Status__c = 'Active';
        }
        insert ownerAccounts;
        
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet2', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            accToUpdate.add(a);
        }
                
        update accToUpdate;
        
        TestFactory_MD_Account.createContact(accToUpdate, null, null, true);
            
        Map<Id,Contact> mapRecords = new Map<Id,Contact>([SELECT Id, MD_SubscriptionSource__c, MD_MyDiageoInitialInviteDate__c, AccountId, Account.Country__c, Account.Country__r.Code__c, FirstName, LastName, Department, Title, MailingStreet, MailingCity, MailingState, MailingPostalCode, Email, Phone, Fax, MobilePhone FROM Contact]);
        
        MD_RegistrationUtil.updateContacts(mapRecords.values(), false);
		
        Test.stopTest();
    } 

    static testMethod void updateAccounts() {
		Test.startTest();
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.getGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner2', 10, geos, false);
        for(Account ownerAccount : ownerAccounts) {
            ownerAccount.Global_Segment__c = null;
            ownerAccount.Global_Sub_Segment__c = null;
            ownerAccount.IsOwner__c = true;
            ownerAccount.IsOperator__c  = true;
            ownerAccount.Status__c = 'Active';
        }
        insert ownerAccounts;
        
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet2', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            accToUpdate.add(a);
        }
                
        update accToUpdate;
        
        MD_RegistrationUtil.updateAccounts(accToUpdate, false);
        
        Test.stopTest();
    } 

    static testMethod void assignPermissionSet() {
		Test.startTest();
        
		Id psId = [SELECT Id FROM PermissionSet WHERE Name = 'MD_MyDiageoUser'].Id;
        
        MD_RegistrationUtil.assignPermissionSet(new Set<Id>{UserInfo.getUserId()}, psId);
        
        Test.stopTest();
                        
    }

    static testMethod void removePermissions() {
        Test.startTest();
        MD_RegistrationUtil.removePermissions(new Set<Id>{UserInfo.getUserId()}, 'MD_MyDiageoUser');
        Test.stopTest();   
    }
    
    @isTest
    public static void upsertAccountContactRelationsPublicMethodTest01() {
        Test.startTest();
        List<AccountContactRelation> accContacts = new List<AccountContactRelation>();
        
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Account a = [SELECT Id FROM Account LIMIT 1];
        
        List<AccountContactRelation> existingAccountContactRelations = [SELECT Id, ContactId, AccountId FROM AccountContactRelation];
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = existingAccountContactRelations.get(0).ContactId;
        acr.AccountId = existingAccountContactRelations.get(0).AccountId;
        accContacts.add(acr);
        
        MD_RegistrationUtil.upsertAccountContactRelations(accContacts, existingAccountContactRelations);
            
        Test.stopTest();
    }
    
    @isTest
    public static void upsertAccountContactRelationsPublicMethodTest02() {
        Test.startTest();
        List<AccountContactRelation> accContacts = new List<AccountContactRelation>();
        
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Account a = [SELECT Id FROM Account LIMIT 1];
        
        List<AccountContactRelation> existingAccountContactRelations = [SELECT Id, ContactId, AccountId FROM AccountContactRelation];
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = c.Id;
        acr.AccountId = a.Id;
        accContacts.add(acr);
        
        MD_RegistrationUtil.upsertAccountContactRelations(accContacts, existingAccountContactRelations);
            
        Test.stopTest();
    }
}