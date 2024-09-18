@isTest
public class CP_AgreementTriggerHandlerTest {
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        Map<String, DiageoCMS__Cluster__c> clusters = TestFactory_MD_Account.setupCreateClusters();
    }
    
    @isTest
    static void insertSuccess01() {
        Test.startTest();
        
        Map<String, DiageoCMS__Cluster__c> clusters = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c clus : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            clusters.put(clus.RecordType.DeveloperName, clus);
        }
        
        CP_Agreement__c ag = new CP_Agreement__c(RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId());
        ag.Portal__c = 'MyDiageo';
        ag.Type__c = 'Terms & Conditions';
        ag.Cluster__c = clusters.get('ClusterLeaf').Id;
        ag.Version__c = 1;
        
        insert ag;
        
        update ag;
        
        delete ag;
        
        Test.stopTest();
    }
    
    @isTest
    static void insertFailTest01() {
        Test.startTest();
        
        Map<String, DiageoCMS__Cluster__c> clusters = new Map<String, DiageoCMS__Cluster__c>();
        
        for(DiageoCMS__Cluster__c clus : [SELECT Id, RecordType.DeveloperName FROM DiageoCMS__Cluster__c]) {
            clusters.put(clus.RecordType.DeveloperName, clus);
        }
        
        String exceptionMessage;
        
        try {
            CP_Agreement__c ag = new CP_Agreement__c(RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId());
        	insert ag;
        }catch(Exception e) {
            exceptionMessage = e.getMessage();
        }
		
        System.assert(String.isNotEmpty(exceptionMessage));
        
        Test.stopTest();
    }

}