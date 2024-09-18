@isTest
public class Test_MD_PostLoginController {
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        Map<String, DiageoCMS__Cluster__c> clusters = TestFactory_MD_Account.setupCreateClusters();
        createAgreements();
    }
    
    static Map<String, DiageoCMS__Cluster__c> getExistingClusters() {
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c cls : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            result.put(cls.RecordType.DeveloperName, cls);
        }
        
        return result;
    }
    
    static void createAgreements() {
        Map<String, DiageoCMS__Cluster__c> clusters = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c cls : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            clusters.put(cls.RecordType.DeveloperName, cls);
        }
        
        List<CP_Agreement__c> agreements = new List<CP_Agreement__c>();
        
        CP_Agreement__c tt = new CP_Agreement__c();
        tt.Type__c = 'Terms & Conditions';
        tt.Portal__c = 'MyDiageo';
        tt.Cluster__c = clusters.get('ClusterLeaf').Id;
        tt.RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();
        agreements.add(tt);
        
        CP_Agreement__c pp = new CP_Agreement__c();
        pp.Type__c = 'Privacy Policies';
        pp.Portal__c = 'MyDiageo';
        pp.Cluster__c = clusters.get('ClusterLeaf').Id;
        pp.RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();
        agreements.add(pp);
        
        insert agreements;
    }
    
    @isTest 
    static void initPostLoginTrueTest(){
        Test.startTest();
        
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c cls : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            result.put(cls.RecordType.DeveloperName, cls);
        }
        
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        DiageoCMS__Cluster__c clusterLeaf = result.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user){
            String response = MD_PostLoginController.initPostLogin();
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void initPostLoginFalseTest(){
        Test.startTest();      
        List<CP_Agreement__c> terms = [SELECT Id FROM CP_Agreement__c WHERE RecordType.DeveloperName = 'Active' AND Type__c = 'Terms & Conditions'] ;
        List<CP_Agreement__c> policies = [SELECT Id FROM CP_Agreement__c WHERE RecordType.DeveloperName = 'Active' AND Type__c = 'Privacy Policies'] ;
        
        User user = [SELECT Id,Alias, ContactId FROM User WHERE Alias='hola' LIMIT 1];
        Contact contact = [SELECT Id, MD_ContactSubscriptions__c FROM Contact WHERE Id =: user.ContactId];
        
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c cls : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            result.put(cls.RecordType.DeveloperName, cls);
        }
        
        DiageoCMS__Cluster__c clusterLeaf = result.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user) {
            MD_PostLoginController.confirmTerms(terms[0].Id);
            MD_PostLoginController.confirmPrivacyPolicies(policies[0].Id, contact.MD_ContactSubscriptions__c);
            String response = MD_PostLoginController.initPostLogin();
        }
        
        Test.stopTest();
    }
    
    @isTest 
    static void confirmTermsTest(){
        Test.startTest();      
        
        Map<String, DiageoCMS__Cluster__c> clusters = getExistingClusters();
            
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = clusters.get('ClusterLeaf').Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo');
        insert agreement;
        
        User user = [SELECT Id, ContactId, Alias FROM User WHERE Alias='hola' LIMIT 1];
        
        System.runas(user){
            MD_PostLoginController.confirmTerms(agreement.Id);
        }
        Test.stopTest();
    }
    @isTest 
    static void confirmPrivacyPoliciesTest(){
        Test.startTest();      
        
        Map<String, DiageoCMS__Cluster__c> clusters = getExistingClusters();
            
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = clusters.get('ClusterLeaf').Id, Type__c = 'Privacy Policies', Portal__c = 'MyDiageo');
        insert agreement;
        
		User user = [SELECT Id,Alias,ContactId FROM User WHERE Alias='hola' LIMIT 1];
        Contact contact = [SELECT Id, MD_ContactSubscriptions__c FROM Contact WHERE Id =: user.ContactId];
        
        System.runas(user){
			MD_PostLoginController.confirmPrivacyPolicies(agreement.Id, contact.MD_ContactSubscriptions__c);
        }
        Test.stopTest();
    }
    
    @isTest 
    static void getAvailableOutletsTest(){
        Test.startTest();      
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            String response = MD_PostLoginController.getAvailableOutlets();
        }
        Test.stopTest();
    }
    
    @isTest
    static void evaluatePostLoginConditionsTest() {
        Test.startTest();
        
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c cls : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            result.put(cls.RecordType.DeveloperName, cls);
        }
        
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        DiageoCMS__Cluster__c clusterLeaf = result.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user){
            MD_PostLoginController.evaluatePostLoginConditions();
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getActualTermsAndAgreementWithAgreementIdTest() {
        Test.startTest();
        
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user) {
            String agreementId = '';
            
            MD_PostLoginController.getActualTermsAndAgreement(agreementId, null);
        }
        
        Test.stopTest();
    }
	
    @isTest
    static void getActualTermsAndAgreementWithCountryCodeTest() {
        Test.startTest();
        
        Map<String, DiageoCMS__Cluster__c> clusters = getExistingClusters();
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusters.get('ClusterLeaf').Id, null, null, user.Id);
        
        System.runas(user) {
            MD_PostLoginController.getActualTermsAndAgreement(null, 'CO');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getActiveAgreementFromIdTest() {
        Test.startTest();
        Map<String, DiageoCMS__Cluster__c> clusters = getExistingClusters();
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test'
                                                        , RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId()
                                                        , Cluster__c = clusters.get('ClusterLeaf').Id, Type__c = 'Terms & Conditions'
                                                        , Portal__c = 'MyDiageo', AgreementBody__c = 'Agreement body');
        insert agreement;
        
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusters.get('ClusterLeaf').Id, null, null, user.Id);
        
        System.runas(user) {
            MD_PostLoginController.getActiveAgreementFromId(agreement.Id);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getPrivacyPoliciesDataTestWithAgreementId() {
        Test.startTest();
        
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user) {
            String agreementId = '';
            
            MD_PostLoginController.getPrivacyPoliciesData(null, agreementId);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getPrivacyPoliciesDataTestWithCountryCode() {
        Test.startTest();
        
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user) {
            MD_PostLoginController.getPrivacyPoliciesData('ES', null);
        }
        
        Test.stopTest();
    }
	
    @isTest
    static void setMyDiageoSuscribedTest() {
        Test.startTest();
        
        User user = [SELECT Id, ContactId, Alias FROM User WHERE Alias='hola' LIMIT 1];
        
        System.runas(user){
            Set<Id> contactIds = new Set<Id>();
            contactIds.add(user.ContactId);
            
            MD_PostLoginController.setMyDiageoSuscribed(contactIds);
        }
        
        Test.stopTest();
    }
	
    @isTest
    static void postLoginControllerResponseConstructorTest() {
        Test.startTest();
        
        MD_PostLoginController.PostLoginControllerResponse resp = new MD_PostLoginController.PostLoginControllerResponse();
        
        Test.stopTest();
    }
    
    @isTest
    static void PostLoginControllerResponseTest() {
        MD_PostLoginController.PostLoginControllerResponse resp = new MD_PostLoginController.PostLoginControllerResponse();
        resp.doPostLogin = false;
        resp.agreementsToAccept = new List<CP_AgreementUtil.AgreementWrapper>();
        resp.availableOutlets = new List<AccountContactRelation>();
    }
}