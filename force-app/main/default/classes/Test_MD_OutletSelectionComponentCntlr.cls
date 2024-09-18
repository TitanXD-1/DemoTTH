/**************************************************************************************
Apex Class Name  :  Test_MD_OutletSelectionComponentCntlr
Version          :  1.0
Created Date     :  17/12/2018
Release          :  R1
Function         :  Test class for MD_OutletSelectionComponentController
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Shwarzböck           17/12/2018              Original Version
******************************************************************************/
@isTest
public class Test_MD_OutletSelectionComponentCntlr{
    
    @testSetup 
    public static void createAccountContactAccountcontact(){
        TestFactory_MD_Account.setup(true);
        
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
        
        List<DiageoCMS__Cluster__c> clusters = [SELECT Id FROM DiageoCMS__Cluster__c];
        System.debug('clusters.size(): ' + clusters.size());
    }
       
    static testMethod void testNavigateAsOutlet1() {
        Test.startTest();
        
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                     		LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey, Country
                    	FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        
        System.runAs(user) {
            MD_OutletSelectionComponentController.navigateAsOutlet(accountContact.Id);
            System.assert(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c == accountContact.Id);
        }
        Test.stopTest();
    }
    
    static testMethod void testNavigateAsOutlet2() {
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                
        
        Account acc = [SELECT Id, BillingCountry FROM Account WHERE Id = :accountContact.AccountId];
        acc.BillingCountry = 'NIR';
        
        update acc;
        
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        
        System.runAs(user) {
            MD_OutletSelectionComponentController.navigateAsOutlet(accountContact.Id);
        }       
        System.assert(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c == accountContact.Id);
    }
    
    static testMethod void testGetAvailableOutlets() {
        User user = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname,
                    LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey, TimeZoneSidKey,
                    Country/*, CountryCode__c*/ FROM User WHERE Alias = 'hola' LIMIT 1];

        AccountContactRelation accountContact = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId =:user.ContactId LIMIT 1];                                
        
        Account acc = [SELECT Id, BillingCountry FROM Account WHERE Id = :accountContact.AccountId];
        acc.BillingCountry = 'NIR';
        
        update acc;
        
        MD_SessionSettings__c settings = TestFactory_MD_Account.createSettingsForUser(user.Id, accountContact.Id);
        
        System.runAs(user) {
            MD_OutletSelectionComponentController.getAvailableOutlets();
        }
    }


}