@isTest
public without sharing class CP_AgreementUtilTest {
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        Map<String, DiageoCMS__Cluster__c> clusters = TestFactory_MD_Account.setupCreateClusters();
        
        CP_Agreement__c ag = new CP_Agreement__c(RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId());
        ag.Portal__c = 'MyDiageo';
        ag.Type__c = 'Terms & Conditions';
        ag.Cluster__c = clusters.get('ClusterLeaf').Id;
        ag.Version__c = 1;
        
        insert ag;
    }
    
    static Map<String, DiageoCMS__Cluster__c> getExistingClusters() {
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c cls : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            result.put(cls.RecordType.DeveloperName, cls);
        }
        
        return result;
    }
    
    @isTest
    static void userHasUnacceptedAgreementsTest() {
        Test.startTest();
        
        User user = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'hola' LIMIT 1];
        Map<String, DiageoCMS__Cluster__c> existingClusters = getExistingClusters();
        
        DiageoCMS__Cluster__c clusterLeaf = existingClusters.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user){            
            CP_AgreementUtil.userHasUnacceptedAgreements(user, 'MyDiageo');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getAgreementsToAcceptTest() {
        Test.startTest();
        
        User user = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'hola' LIMIT 1];
        Map<String, DiageoCMS__Cluster__c> existingClusters = getExistingClusters();
        
        DiageoCMS__Cluster__c clusterLeaf = existingClusters.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user){
            CP_AgreementUtil.getAgreementsToAccept(user, 'MyDiageo');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getContactAcceptedAgreementsTest() {
        Test.startTest();
        
        User user = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'hola' LIMIT 1];
        Map<String, DiageoCMS__Cluster__c> existingClusters = getExistingClusters();
        
        DiageoCMS__Cluster__c clusterLeaf = existingClusters.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user){
            CP_AgreementUtil.getContactAcceptedAgreements(user, new Set<String>(), 'MyDiageo');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getClusterActiveAgreementsTest() {
        Test.startTest();
        
        User user = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'hola' LIMIT 1];
        Map<String, DiageoCMS__Cluster__c> existingClusters = getExistingClusters();
        
        DiageoCMS__Cluster__c clusterLeaf = existingClusters.get('ClusterLeaf');
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        System.runas(user){
            CP_AgreementUtil.getClusterActiveAgreements(user, 'MyDiageo');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void agreementWrapperTest() {
        Test.startTest();
        
        new CP_AgreementUtil.AgreementWrapper();
        
        Test.stopTest();
    }

}