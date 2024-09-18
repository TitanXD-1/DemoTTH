/**************************************************************************************
Apex Class Name  :  Test_MD_ES_RegistrationUtil 
Version          :  1.0
Created Date     :  15/07/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock          15/07/2019              Original Version
******************************************************************************/
@isTest
public class Test_MD_ES_RegistrationUtil {
    @testSetup
    public static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        Map<String, DiageoCMS__Cluster__c> clusters = setupCreateClusters();
    }
    
    @isTest
    public static void getMasterDataManagerIdTest(){
        DiageoCMS__Cluster__c cluster = [SELECT Id, DiageoCMS__ExternalId__c FROM DiageoCMS__Cluster__c LIMIT 1];
        Map<String,DiageoCMS__Cluster__c> clusterMap = MD_ES_RegistrationUtil.getMapClusterByCountry(cluster.DiageoCMS__ExternalId__c);
    }
    
    @isTest
    public static void contactExistsTest01() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        
		Test.startTest();
        MD_ES_RegistrationUtil.contactExists(c.Id, null);
        Test.stopTest();
    }
    
    @isTest
    public static void notExistingVAT(){
        Map<String, Geography__c> geographies = getGeographies();
        Account accountData = createOutlet(false, geographies, 'Outlet',false);
        Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
        Map<String, SObject> formData = new Map<String, SObject>();
        formData.put('Account', accountData);
        formData.put('Geography__c', countryData);
        
        Test.startTest();
        MD_JSONResponse response = MD_ES_RegistrationUtil.checkVATNumber(formData);
        Test.stopTest();
        
        
    }
    
    @istest
    public static void vatAlreadyUsedTest() {
        Test.startTest();
        MD_ES_RegistrationUtil.vatAlreadyUsed(null);
        Test.stopTest();
    }
    
    @isTest
    public static void VATAlreadyExists(){
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner', false);
            Contact contactData = createContacts(false, accountData, geographies,true).get(0);
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            
            
            Test.startTest();
            MD_ES_RegistrationUtil.vatAlreadyExists(formData);   
            Test.stopTest();      
            
        }
    }
    
    
    @isTest
    public static void notUsedVAT(){
        //Creacion de outlet, creacion de contacto con relacion deshabilitada sin permission set.
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner', false);
            Contact contactData = createContacts(false, accountData, geographies,true).get(0);
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            MD_JSONResponse response;
            
            Test.startTest();
            response = MD_ES_RegistrationUtil.checkVATNumber(formData);   
            Test.stopTest();
            
            
        }
    }
    
    @isTest
    public static void notUsedVAT2(){
        //Creacion de outlet, creacion de contacto con relacion habilitada.
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner', false);
            Contact contactData = createContacts(true, accountData, geographies,true).get(0);
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            MD_JSONResponse response;
            
            Test.startTest();
            response = MD_ES_RegistrationUtil.checkVATNumber(formData);   
            Test.stopTest();
            
            
        }
    }
    
    
    @isTest
    public static void notUsedVAT3(){
        //Creacion de outlet, sin creación de contacto sin permission set
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner', false);
            Contact contactData = createContacts(true, accountData, geographies,false).get(0);
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            MD_JSONResponse response;
            
            Test.startTest();
            response = MD_ES_RegistrationUtil.checkVATNumber(formData);   
            Test.stopTest();
            
            
        }
    }
    
    
    @isTest
    public static void notUsedVAT4(){
        //Creacion de outlet, creacion de contacto con relacion deshabilitada con permission set.
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner',false);
            
            Contact contactData = createContactAccount(accountData,geographies).get(0);
            Test.startTest();
            Set<Id> sets = MD_RegistrationUtil.createUser(new Set<Id>{contactData.Id});
            Test.stopTest();
            
            
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            MD_JSONResponse response;
            
            
            response = MD_ES_RegistrationUtil.checkVATNumber(formData);
            
            
        }
    }
    
     @isTest
    public static void notUsedVAT5(){
        //Creacion de outlet Off Trade
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner', false);
            accountData.Global_Channel__c = 'Off Trade';
            update accountData;
            Contact contactData = createContacts(false, accountData, geographies,true).get(0);
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            MD_JSONResponse response;
            
            Test.startTest();
            response = MD_ES_RegistrationUtil.checkVATNumber(formData);   
            Test.stopTest();
            
            
        }
    }
    
    
    
       @isTest
    public static void submitRequest(){
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies, 'Owner', false);
            Contact contactData = createContacts(true, accountData, geographies,true).get(0);
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            MD_JSONResponse response;
            
            Test.startTest();
            response = MD_ES_RegistrationUtil.submitRequestForApproval(formData);   
            Test.stopTest();
            
            
        }
    }
    
    @isTest
    public static void generateErrorCaseTest(){
        
        System.runAs(TestFactory_MD_Account.collabMDMUser){
            Map<String, Geography__c> geographies = getGeographies();
            Account accountData = createOutlet(true, geographies,'Outlet',false);
            
            Contact contactData = createContactAccount(accountData,geographies).get(0);
            
            Geography__c countryData = [SELECT Id, Code__c FROM Geography__c WHERE RecordType.Name = 'Country'];
            Map<String, SObject> formData = new Map<String, SObject>();
            formData.put('Account', accountData);
            formData.put('Contact', contactData);
            formData.put('Geography__c', countryData);
            try{
                String test = null;
                test.length();
            }catch(Exception ex){
                MD_ES_RegistrationUtil.generateErrorCase(ex, formData);
            }            
        }
    }
    
    
    
    public static Map<String, Geography__c> getGeographies() {
        Map<String, Geography__c> geos = new Map<String, Geography__c>();
        
        for(Geography__c g : [SELECT Id, RecordType.DeveloperName FROM Geography__c]) {
            geos.put(g.RecordType.DeveloperName, g);
        }
        
        Geography__c geography = geos.get('Country');
        insert new Pick_Up_Options__c(Name = 'N0[ES]', Geography__c = geography.Id, Type__c = 'Outlet Visit Prioritization');
        return geos;
    }
    
    public static Map<String, Id> getAccountRecordTypes(){
        Map<String, Id> accountRecordTypes = new Map<String, Id>();
        for(RecordType recordType : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']){
            accountRecordTypes.put(recordType.DeveloperName, recordType.Id);
        }
        System.debug(accountRecordTypes);
        return accountRecordTypes;
    }
    
    public static Account createOutlet(Boolean toInsert, Map<String, Geography__c> geographies, String recordType, Boolean IsIndependent){
        Map<String, Id> accountRecordTypes = getAccountRecordTypes();
        Account newAccount = new Account(RecordTypeId = accountRecordTypes.get(recordType)
                                         , VAT_Number__c = '1234567890'
                                         , AccountNumber = 'TestAccount'
                                         , Name = IsIndependent == true ? 'Independientes' : 'TestAccount'); 
        newAccount = setAccountRequiredFields(newAccount, geographies);
        if (toInsert == true) insert newAccount;
        return newAccount;
    }
    
    public static List<Contact> createContactAccount(Account owner, Map<String, Geography__c> geographies){
        List<Contact> contacts = new List<Contact>();        
        Map<String, Id> accountRecordTypes = getAccountRecordTypes();
        
        Account enabledOutlet = new Account(RecordTypeId = accountRecordTypes.get('Outlet'), VAT_Number__c = owner.VAT_Number__c, Name = 'enabledOutlet'); 
        enabledOutlet = setAccountRequiredFields(enabledOutlet, geographies);
        insert enabledOutlet;
        
        Contact enabledContact = new Contact(
            FirstName = 'enabledContact',
            LastName = 'enabledContact',
            Email = 'enabledContact@test.com',
            Mobile__c = '345353543',
            MobilePrefix__c = '+34',
            Contact_Type__c = 'Primary',
            Registration_Source__c = 'MyDiageo',
            AccountId = enabledOutlet.Id
        );
        
        insert enabledContact;
        contacts.add(enabledContact);
        return contacts;
        
    }
    
    public static List<Contact> createContacts(Boolean isEnabled, Account owner, Map<String, Geography__c> geographies, Boolean ins){
        List<Contact> contacts = new List<Contact>();        
        Map<String, Id> accountRecordTypes = getAccountRecordTypes();
        Account enabledOutlet = new Account(RecordTypeId = accountRecordTypes.get('Outlet'), VAT_Number__c = owner.VAT_Number__c, Operator__c = owner.Id, Name = 'enabledOutlet'); 
        enabledOutlet = setAccountRequiredFields(enabledOutlet, geographies);
        insert enabledOutlet;
        
        Contact enabledContact = new Contact(
            FirstName = 'enabledContact',
            LastName = 'enabledContact',
            Email = 'enabledContact@test.com',
            Mobile__c = '345353543',
            MobilePrefix__c = '+34',
            Contact_Type__c = 'Primary',
            Registration_Source__c = 'MyDiageo',
            AccountId = enabledOutlet.Id
        );
        if (ins==true) insert enabledContact;
        
        contacts.add(enabledContact);
        
        if (ins==true){
            AccountContactRelation enabledACR = [SELECT Id, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c, MD_Status__c, MD_Role__c, MD_UserProfile__c
                                                 FROM AccountContactRelation WHERE ContactId =: enabledContact.Id];
            
            enabledACR.MD_AssignedPermissions__c = 'Access;Manage Users';
            enabledACR.MD_MyDiageoEnabled__c = isEnabled;
            enabledACR.MD_Status__c = 'Active';
            enabledACR.MD_Role__c = 'Owner';
            enabledACR.MD_UserProfile__c = 'Primary User';
            
            
            update enabledACR;
        }
        return contacts;
    }
    
    public static Account setAccountRequiredFields(Account account, Map<String, Geography__c> geos){
        account.Region__c = geos.get('Region').Id;
        account.Area__c = geos.get('Area').Id;
        account.Country__c = geos.get('Country').Id;
        account.Cluster__c = geos.get('Cluster').Id;
        account.Hub__c = geos.get('Hub').Id;
        account.Market__c = geos.get('Market').Id;
        account.BillingStreet = 'Evergreen 123';
        account.BillingPostalCode = '1111';
        account.BillingCity = 'Madrid';
        account.Global_Channel__c = 'On Trade';
        account.Global_Sub_Channel__c = 'On Trade';
        account.Global_Segment__c = 'Bars';
        account.Global_Sub_Segment__c = 'Modern Bars';
        return account;
    }
    
    
    public static testMethod void resolveResponseNonVat(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message='NON EXISTING VAT';
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    public static testMethod void resolveResponseCaseCreated(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message='CASE CREATED';
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    public static testMethod void resolveResponseContactCreated(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message='CONTACT CREATED';
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    
    public static testMethod void resolveResponseRelationshipAdded(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message='RELATIONSHIP ADDED';
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    
    public static testMethod void resolveResponseSuccess(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message = Label.MD_SuccessfullySubmitted;
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    
    public static testMethod void resolveResponseFailed(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message = Label.MD_FailedSubmitting;
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    
    public static testMethod void resolveResponseError(){
        MD_JSONResponse response = new MD_JSONResponse();
        response.message = 'ERROR';
        Test.startTest();
        MD_ES_RegistrationUtil.resolveResponse(response);
        Test.stopTest();
        
    }
    
    public static Map<String, DiageoCMS__Cluster__c> setupCreateClusters() {
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        Map<String, Id> recordTypeNames = new Map<String, Id>();
        
        for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'DiageoCMS__Cluster__c']) {
            recordTypeNames.put(rt.DeveloperName, rt.Id);
        }
        
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
        leafCluster.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        leafCluster.MD_ClusterMasterDataManager__c = TestFactory_MD_Account.collabMDMUser.Id;
        insert leafCluster;
        result.put('ClusterLeaf', leafCluster);
        
        return result;
    }
}