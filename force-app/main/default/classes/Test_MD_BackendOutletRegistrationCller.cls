@isTest
public class Test_MD_BackendOutletRegistrationCller {
    
    @testSetup 
    public static void setup(){
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setupNoUser(true);
        Map<String, DiageoCMS__Cluster__c> clusters = setupCreateClusters();
    }
    
    static testMethod void validateAccountNoCountryTest(){
        Contact conn = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Test.startTest();
        DiageoCMS.FormResponseWrapper response = MD_BackendOutletRegistrationController.validateAccount(conn.AccountId);
        Test.stopTest();
    }
    
    
    static testMethod void validateAccountNoChannelTest(){
        Contact conn = [SELECT Id, AccountId, Account.Operator__c FROM Contact LIMIT 1];
        Geography__c geo = [SELECT Id, Code__c FROM Geography__c WHERE Code__c='CO'];
        geo.Code__c ='ES';
        update geo;
        
        Account newAccount = new Account(Id = conn.Account.Operator__c, Global_Channel__c = 'Off Trade');
        update newAccount;
        
        Test.startTest();
        DiageoCMS.FormResponseWrapper response = MD_BackendOutletRegistrationController.validateAccount(conn.AccountId);
        Test.stopTest();
    }
    
    static testMethod void validateAccountTest(){
        Contact conn = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Geography__c geo = [SELECT Id, Code__c FROM Geography__c WHERE Code__c='CO'];
        geo.Code__c ='ES';
        update geo;
        
        Test.startTest();
        DiageoCMS.FormResponseWrapper response = MD_BackendOutletRegistrationController.validateAccount(conn.AccountId);
        Test.stopTest();
    }
    
    static testMethod void getCustomerContactsTest(){
        Contact conn = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Test.startTest();
        List<AccountContactRelation> acrs = MD_BackendOutletRegistrationController.getCustomerContacts(conn.AccountId);
        Test.stopTest();
    }
    
    static testMethod void getContactsTest(){
        Test.startTest();
        List<Contact> contacts = MD_BackendOutletRegistrationController.getContacts('a', 'Name');
        Test.stopTest();
    }
    
    static testMethod void registerContactToAccountTest(){
        Contact conn = [SELECT Id, AccountId, Account.Country__c FROM Contact LIMIT 1];
        
        
        DiageoCMS__Cluster__c cluster = [SELECT Id, DiageoCMS__ExternalId__c, MD_MyDiageoPermissions__c, MD_CommunityPermissionSet__c, MD_RegistrationValidationsClass__c FROM DiageoCMS__Cluster__c WHERE RecordType.DeveloperName = 'ClusterLeaf'];
        
        cluster.MD_CommunityPermissionSet__c = 'MD_MyDiageoUser';
        cluster.MD_RegistrationValidationsClass__c = 'MD_ES_RegistrationValidationsClass.SpainValidations';
        
        update cluster;
        
        
        System.debug(cluster);
        Test.startTest();
        DiageoCMS.FormResponseWrapper response = MD_BackendOutletRegistrationController.registerContactToAccount(conn.AccountId, conn.Id);
        Test.stopTest(); 
    }
    
    private static Map<String, DiageoCMS__Cluster__c> setupCreateClusters() {
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