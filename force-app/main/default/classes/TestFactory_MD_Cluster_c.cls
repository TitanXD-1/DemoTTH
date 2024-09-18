@isTest
public class TestFactory_MD_Cluster_c {

    public static Map<String, DiageoCMS__Cluster__c> createTestClusterStructure() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        
        Map<String, DiageoCMS__Cluster__c> result = new Map<String, DiageoCMS__Cluster__c>();
        
        Map<String, String> mapClusterRecordTyeps = getClusterRecordTypes();
        
        DiageoCMS__Cluster__c clusterRoot = new DiageoCMS__Cluster__c();
        clusterRoot.DiageoCMS__ExternalId__c = 'ZCR';
        clusterRoot.RecordTypeId = mapClusterRecordTyeps.get('ClusterRoot');
        clusterRoot.Name = 'ZClusterRoot';
        
        insert clusterRoot;
        result.put('ClusterRoot', clusterRoot);
        
        DiageoCMS__Cluster__c clusterGroup = new DiageoCMS__Cluster__c();
        clusterGroup.DiageoCMS__ExternalId__c = 'ZCG';
        clusterGroup.Name = 'ZClusterGroup';
        clusterGroup.RecordTypeId = mapClusterRecordTyeps.get('ClusterGroup');
        clusterGroup.DiageoCMS__ParentCluster__c = clusterRoot.Id;
        
        insert clusterGroup;
        result.put('ClusterGroup', clusterGroup);
        
        DiageoCMS__Cluster__c clusterLeaf = new DiageoCMS__Cluster__c();
        clusterLeaf.DiageoCMS__ExternalId__c = 'ZCL';
        clusterLeaf.Name = 'ZClusterLeaf';
        clusterLeaf.RecordTypeId = mapClusterRecordTyeps.get('ClusterLeaf');
        clusterLeaf.DiageoCMS__ParentCluster__c = clusterGroup.Id;
        
        insert clusterLeaf;
        result.put('ClusterLeaf', clusterLeaf);
        
        return result;
    }
    
    
    public static Map<String, String> getClusterRecordTypes() {
        Map<String, String> result = new Map<String, String>();
        
        result.put('ClusterRoot', Schema.SObjectType.DiageoCMS__Cluster__c.getRecordTypeInfosByDeveloperName().get('ClusterRoot').getRecordTypeId());
        result.put('ClusterGroup', Schema.SObjectType.DiageoCMS__Cluster__c.getRecordTypeInfosByDeveloperName().get('ClusterGroup').getRecordTypeId());
        result.put('ClusterLeaf', Schema.SObjectType.DiageoCMS__Cluster__c.getRecordTypeInfosByDeveloperName().get('ClusterLeaf').getRecordTypeId());
        
        return result;
    }
}