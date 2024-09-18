@isTest
public class Test_MD_MultiCountryUtils {
    
	@testSetup
    public static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        
        Map<String, Id> rtsMap = new Map<String, Id>();
        for(RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'DiageoCMS__Cluster__c']) {
            rtsMap.put(rt.DeveloperName, rt.Id);
        }
        
        DiageoCMS__Cluster__c clusterRoot = new DiageoCMS__Cluster__c();
        clusterRoot.Name = 'Root';
        clusterRoot.RecordTypeId = rtsMap.get('ClusterRoot');
        clusterRoot.DiageoCMS__ExternalId__c = 'RT';
        insert clusterRoot;
        
        DiageoCMS__Cluster__c clusterLeaf = new DiageoCMS__Cluster__c();
        clusterLeaf.RecordTypeId = rtsMap.get('ClusterLeaf');
        clusterLeaf.Name = 'Country';
        clusterLeaf.DiageoCMS__ParentCluster__c = clusterRoot.Id;
        clusterLeaf.DiageoCMS__ExternalId__c = 'CO';
        clusterLeaf.MD_MyDiageoPermissions__c = 'Access;Manage Users';
        
        insert clusterLeaf;
    }
    
    @isTest
    public static void getClusterPermissions() {
        Test.startTest();
        List<String> regions = new List<String>();
        regions.add('CO');
        
        MD_MultiCountryUtils.getClusterPermissions(regions);
        Test.stopTest();
    }
        
    @isTest    
    public static void getRegionPermissions() {
        Test.startTest();
        MD_MultiCountryUtils.getRegionPermissions('CO');
        Test.stopTest();
    }
    
}