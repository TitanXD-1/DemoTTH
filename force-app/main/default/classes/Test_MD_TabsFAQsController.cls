@isTest
public with sharing class Test_MD_TabsFAQsController {
    
    @testSetup
    public static void setup() {
        
        Map<String, DiageoCMS__Cluster__c> clusters = TestFactory_MD_Cluster_c.createTestClusterStructure();
            
        List<DiageoCMS__Component__c> comps = new List<DiageoCMS__Component__c>();
        
        DiageoCMS__Component__c c1 = new DiageoCMS__Component__c();
        c1.DiageoCMS__ExternalId__c = 'ComponentTest1';
        c1.DiageoCMS__Title__c = 'Title ComponentTest1';
        c1.DiageoCMS__Cluster__c = clusters.get('ClusterRoot').Id;
        c1.RecordTypeId = Schema.SObjectType.DiageoCMS__Component__c.getRecordTypeInfosByDeveloperName().get('FAQ').getRecordTypeId();
        comps.add(c1);
        
        DiageoCMS__Component__c c2 = new DiageoCMS__Component__c();
        c2.DiageoCMS__ExternalId__c = 'ComponentTest2';
        c2.DiageoCMS__Title__c = 'Title ComponentTest2';
        c2.DiageoCMS__Cluster__c = clusters.get('ClusterRoot').Id;
        c2.RecordTypeId = Schema.SObjectType.DiageoCMS__Component__c.getRecordTypeInfosByDeveloperName().get('FAQ').getRecordTypeId();
        comps.add(c2);
        
        DiageoCMS__Component__c c3 = new DiageoCMS__Component__c();
        c3.DiageoCMS__ExternalId__c = 'ComponentTest3';
        c3.DiageoCMS__Title__c = 'Title ComponentTest3';
        c3.DiageoCMS__Cluster__c = clusters.get('ClusterRoot').Id;
        c3.RecordTypeId = Schema.SObjectType.DiageoCMS__Component__c.getRecordTypeInfosByDeveloperName().get('FAQ').getRecordTypeId();
        comps.add(c3);
        
        insert comps;
    }
    
    @isTest
    public static void testgetFAQsTitles() {
        Test.startTest();
        
        List<DiageoCMS__Component__c> comps = [SELECT Id, DiageoCMS__Title__c, DiageoCMS__ExternalId__c 
                                               	FROM DiageoCMS__Component__c
                                              	ORDER BY DiageoCMS__ExternalId__c];
        
        List<DiageoCMS__Translation__c> translations = new List<DiageoCMS__Translation__c>();
        DiageoCMS__Translation__c transC1 = new DiageoCMS__Translation__c();
        transC1.DiageoCMS__ExternalId__c = 'TComponentTest1';
        transC1.DiageoCMS__LanguageCode__c = 'es';
        transC1.DiageoCMS__FieldApiName__c = 'DiageoCMS__Title__c';
        transC1.DiageoCMS__Component__c = comps.get(0).Id;
        translations.add(transC1);
        
        DiageoCMS__Translation__c transC2 = new DiageoCMS__Translation__c();
        transC2.DiageoCMS__ExternalId__c = 'TComponentTest2';
        transC2.DiageoCMS__LanguageCode__c = 'es';
        transC2.DiageoCMS__FieldApiName__c = 'DiageoCMS__Title__c';
        transC2.DiageoCMS__Component__c = comps.get(1).Id;
        translations.add(transC2);
        
        DiageoCMS__Translation__c transC3 = new DiageoCMS__Translation__c();
        transC3.DiageoCMS__ExternalId__c = 'TComponentTest3';
        transC3.DiageoCMS__LanguageCode__c = 'es';
        transC3.DiageoCMS__FieldApiName__c = 'DiageoCMS__Title__c';
        transC3.DiageoCMS__Component__c = comps.get(2).Id;
        translations.add(transC3);
        
        insert translations;
        
        List<String> tabIds = new List<String>{'ComponentTest1','ComponentTest2','ComponentTest3'};
        
        String result = MD_TabsFAQsController.getFAQsTitles(JSON.serialize(tabIds));
        Map<String, String> resultList = (Map<String, String>)JSON.deserialize(result, Map<String, String>.class);
        
        System.debug('resultList: ' + resultList);
        
        System.assert(resultList.size() == tabIds.size());
        
        Test.stopTest();
    }
}