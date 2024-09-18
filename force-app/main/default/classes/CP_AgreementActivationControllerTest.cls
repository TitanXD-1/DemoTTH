@isTest
public class CP_AgreementActivationControllerTest {
    
    @testSetup 
    public static void setup() {
        TestFactory_MD_Account.setup(true);
       // insert new DiageoCMS__CMSSettings__c(DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c', DiageoCMS__SalesforceDomain__c = 'https://edge--edgedev3.lightning.force.com');
    
        insert new DiageoCMS__CMSSettings__c(
            DiageoCMS__ClusterFieldForPublicGroups__c = 'DiageoCMS__ExternalId__c',
            DiageoCMS__SalesforceDomain__c = URL.getCurrentRequestUrl().getHost() //366446
            
        );
    }
    
    @isTest
    static void doScheduledActivationTest01() {
        Test.startTest();
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
		insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo', AgreementBody__c = 'Agreement body');
        insert agreement;
        
        List<String> agreementsId = new List<String>();
        agreementsId.add(agreement.Id);
        
        CP_AgreementActivationController.doScheduledActivation(agreementsId);
        
        Test.stopTest();
    }
    
    @isTest
    static void doActivationTest01() {
        Test.startTest();
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
		insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo', AgreementBody__c = 'Agreement body');
        insert agreement;
        
        CP_Agreement__c agreement2 = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo', RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordtypeId(), Version__c = 1);
        insert agreement2;
        
        CP_AgreementActivationController.doActivation(agreement.Id);
        
        System.debug('MD - agreement.Recordtype.DeveloperName - POST ACTIVATION : ' + [SELECT Id, RecordType.DeveloperName FROM CP_Agreement__c WHERE Id = :agreement.Id].RecordType.DeveloperName);
        
        Test.stopTest();
    }
    
    @isTest
    static void doActivationTest02() {
        Test.startTest();
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
		insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo');
        insert agreement;
        
        CP_AgreementActivationController.doActivation(agreement.Id);
        
        Test.stopTest();
    }
    
    @isTest
    static void doActivationTest03() {
        Test.startTest();
        
        User u = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'hola' LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE Id = :u.ContactId];
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
		insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo', AgreementBody__c = 'Test Body');
        insert agreement;
        
        System.debug('MD - agreement.Id: ' + agreement.Id);
        
        CP_AgreementActivationController.doActivation(agreement.Id);
        
        System.debug('MD - agreement.Recordtype.DeveloperName - POST ACTIVATION : ' + [SELECT Id, RecordType.DeveloperName FROM CP_Agreement__c WHERE Id = :agreement.Id].RecordType.DeveloperName);
        
        CP_ContactAgreement__c conAg = new CP_ContactAgreement__c(Contact__c = c.Id, CurrentAgreement__c = agreement.Id);
        insert conAg;
        
        System.debug('MD - ContactAgreements.size() : ' + [SELECT Id FROM CP_ContactAgreement__c].size());
        
        CP_Agreement__c agreement2 = new CP_Agreement__c(Name = 'Test2', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo', RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Draft').getRecordtypeId(), AgreementBody__c = 'Put a body here.');
        insert agreement2;
		
		System.debug('MD - agreement2.Id: ' + agreement2.Id);
        
        CP_AgreementActivationController.doActivation(agreement2.Id);
        
        System.debug('MD - agreement2.Recordtype.DeveloperName - POST ACTIVATION : ' + [SELECT Id, RecordType.DeveloperName FROM CP_Agreement__c WHERE Id = :agreement2.Id].RecordType.DeveloperName);
        
        Test.stopTest();
    }
    
    @isTest
    static void doCloneTest01() {
        Test.startTest();
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
		insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo');
        insert agreement;
        
        CP_AgreementActivationController.doClone(agreement.Id);
        CP_AgreementActivationController.doClone(null);
        
        Test.stopTest();
    }
    
    @isTest
    static void doCloneTest02() {
        Test.startTest();
        
        CP_AgreementActivationController.doClone(null);
        
        Test.stopTest();
    }
    
    @isTest
    static void doScheduleTest01() {
        Test.startTest();
        
        DiageoCMS__Cluster__c cluster = new DiageoCMS__Cluster__c(
            Name = 'NIR', DiageoCMS__ExternalId__c = 'NIR',
            DiageoCMS__PublicGroupRWName__c = 'NIR_RW',
            DiageoCMS__PublicGroupROUpName__c = 'NIR_ROViewUp', 
            DiageoCMS__PublicGroupRODownName__c = 'NIR_ROViewDown',
            CP_AvailableAgreements__c = 'Terms & Conditions;Privacy Policies'
        );
		insert cluster;
        
        CP_Agreement__c agreement = new CP_Agreement__c(Name = 'Test', Cluster__c = cluster.Id, Type__c = 'Terms & Conditions', Portal__c = 'MyDiageo');
        
        CP_AgreementActivationController.doSchedule(agreement);
        
        Test.stopTest();
    }
}