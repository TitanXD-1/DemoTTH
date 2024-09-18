@isTest
public class Test_MD_ClusterTriggerHandler {
	@testSetup 
    static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
    }
    
    @isTest
    static void clusterCreationTest() {
        Map<String, DiageoCMS__Cluster__c> clusters = TestFactory_MD_Account.setupCreateClusters();
    }
}