/**
* @Author: Cloudgaia.
* @Description: Test the MD_AccountDetailsComponent Class.
*/
@isTest(seeAllData=false)
public class Test_MD_AccountDetailsController {
    @testSetup
    public static void setup(){
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        Map<String, DiageoCMS__Cluster__c> clusters = setupCreateClusters();
	}
    
    static testMethod void subscriptions1() {
        //Comment: use the MD_AccountDetailsController.updateContactWithSubscriptions() for add more subscriptions
        //Given
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    	LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey, Country
                     FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                       
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getmap();
        List<Schema.Picklistentry> subscriptions = fieldMap.get('MD_ContactSubscriptions__c').getDescribe().getpicklistValues();
        
        List<String> subscriptionsValidatedList = new List<String>();
        
        for (Schema.PicklistEntry subscription : subscriptions) {
            
            subscriptionsValidatedList.add(subscription.getValue());
        }

        String subscriptionsTestValues = '';
        
        if(subscriptionsValidatedList.size()>0){
            for (Integer j = 0; j < subscriptionsValidatedList.size(); j++) {
                if(j == subscriptionsValidatedList.size()-1){
                    subscriptionsTestValues += subscriptionsValidatedList.get(j);
                }else{
                    subscriptionsTestValues += subscriptionsValidatedList.get(j) + ';';
                }
            }
        }
        
        DiageoCMS__Cluster__c clusterLeaf = [SELECT Id FROM DiageoCMS__Cluster__c WHERE Name = 'Test_CO_Cluster'];
        
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        //When
        System.runAs(user) {
            Test.startTest();
            
            System.debug('CG - in Test_MD_AccountDetailsController.subscriptions1() method. clusterLeaf: ' + clusterLeaf );
            
            MD_AccountDetailsController.updateContactWithSubscriptions(subscriptionsTestValues, String.valueOf(accountContact.ContactId));
            Test.stopTest();
        }
		        
        //Then
        Contact contact = [SELECT Id, MD_Subscribed__c, MD_ContactSubscriptions__c FROM Contact WHERE Id =: accountContact.ContactId];
        System.assert(String.isNotBlank(contact.MD_ContactSubscriptions__c));
    }
    static testMethod void subscriptions2() {
        //Comment: use the MD_AccountDetailsController.updateContactWithSubscriptions() for remove all subscriptions
        //Given
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                        
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);

        Id nullId = null;
        //when
        System.runAs(user) {
            Test.startTest();
            MD_AccountDetailsController.updateContactWithSubscriptions('', String.valueOf(accountContact.ContactId));
            Test.stopTest();
        }
        //Then
        Contact contact = [SELECT Id, MD_Subscribed__c, MD_ContactSubscriptions__c FROM Contact WHERE Id =: accountContact.ContactId];
        System.assert(String.isBlank(contact.MD_ContactSubscriptions__c));
    }
    
    static testMethod void testUpdateUserPassword() {
        //Comment: use the MD_AccountDetailsController.doUpdateUserPassword() for change user password successfully
        //Given
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                        
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        //When
        String response;
        System.runAs(user) {
            Test.startTest();
            response  = MD_AccountDetailsController.doUpdateUserPassword('newPassword123');
            Test.stopTest();
        } 
        //Then
        MD_JSONResponse result = (MD_JSONResponse)JSON.deserialize(response, MD_JSONResponse.class);
    }
    
    static testMethod void testUpdateUserPasswordWithError() {
        //Comment: use the MD_AccountDetailsController.doUpdateUserPassword() for change user password unsuccessfully
        //Given
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                     LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                     Country/*, CountryCode__c */ FROM User WHERE Alias = 'hola' LIMIT 1];
        
        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                        
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        //When
        String response;
        System.runAs(user) {
            Test.startTest();
            response  = MD_AccountDetailsController.doUpdateUserPassword('newPassword');
            Test.stopTest();
        } 
        //Then
       MD_JSONResponse result = (MD_JSONResponse)JSON.deserialize(response, MD_JSONResponse.class);
       System.assert(result.type == MD_JSONResponse.MD_JSONResponseType.ERROR);
    }
    
    static testMethod void accountDetailWrapper1() {
        //Comment: use the MD_AccountDetailsController.getWrapper() for get null variable
        //Given
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];
		
        DiageoCMS__Cluster__c clusterLeaf = [SELECT Id FROM DiageoCMS__Cluster__c WHERE Name = 'Test_CO_Cluster'];
        
        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                        
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        Object accDetWrapper;
        
        DiageoCMS.CMSUserSettingsUtils.updateUserSettings(user.Id, clusterLeaf.Id, null, null, user.Id);
        
        //When
        System.runAs(user) {
            Test.startTest();
            
            accDetWrapper = MD_AccountDetailsController.getWrapper();
            Test.stopTest();
        }
        //Then
        system.assertNotEquals(null, accDetWrapper);
    }
    static testMethod void accountDetailWrapper() {
        //Comment: use the MD_AccountDetailsController.getWrapper() for get the wrapper
        //Given
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, FirstName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];

        //MD_Cluster__c cluster = [SELECT Id FROM MD_Cluster__c WHERE LocationCode__c = 'NIR'];
       
        AccountContactRelation accContact = [SELECT Id FROM AccountContactRelation WHERE ContactId =: user.ContactId LIMIT 1];        
        //TestFactory_MD_Account.createSettingsForUserWithCluster(user.Id, accContact.Id, new List<Id>{cluster.Id});
        Object accDetWrapper;
        //When
        System.runAs(user) {
            Test.startTest();
            accDetWrapper = MD_AccountDetailsController.getWrapper();
            Test.stopTest();
        }
        //Then
        System.assertNotEquals(null, accDetWrapper);
    }
    
    @isTest
    public static void getAccordionSettingTest01() {
        Test.startTest();
        
        MD_AccountDetailsController.getAccordionSetting('CommunicationsPreferences;Outlets');
        
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
        leafCluster.MD_MyDiageoPermissions__c = 'Access;Order;Account Documents;Manage Users';
        insert leafCluster;
        result.put('ClusterLeaf', leafCluster);
        
        return result;
    }
}