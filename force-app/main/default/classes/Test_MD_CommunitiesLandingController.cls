/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
@IsTest 
public with sharing class Test_MD_CommunitiesLandingController{
    
    @TestSetup
    public static void setup() {
        TestFactory_MD_Account.setup(true);
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        Map<String, DiageoCMS__Cluster__c> clusters = setupCreateClusters();
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
        leafCluster.MD_MyDiageoPermissions__c = 'Access;Order;Account Documents;Manage Users';
        insert leafCluster;
        result.put('ClusterLeaf', leafCluster);
        
        return result;
    }
    
    @IsTest 
    public static void testCommunitiesLandingController() {
        Test.startTest();
        
        // Instantiate a new controller with all parameters in the page
        MD_CommunitiesLandingController controller = new MD_CommunitiesLandingController();
        PageReference pageRef = controller.forwardToStartPage();
        //PageRef is either null or an empty object in test context
        if(pageRef != null){
            String url = pageRef.getUrl();
            if(url != null){
                System.assertEquals(true, String.isEmpty(url));
                //show up in perforce
            }
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void successLoginActionsTest01() {

        Test.startTest();

        User u = [SELECT Id, FirstName, LastName FROM User WHERE FirstName = 'hola' AND LastName = 'Testhola'];
        
        System.runAs(u) {
            MD_CommunitiesLandingController controller = new MD_CommunitiesLandingController();
            controller.successLoginActions(u.Id);
        }
        
		Test.stopTest();
    }
}