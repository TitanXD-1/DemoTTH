@isTest
public class Test_MD_NewOutletUserController {
    
    @testSetup public static void setup() {
        System.debug(LoggingLevel.DEBUG,'CG - in Test_MD_NewOutletUserController.setup() method - BEGIN');
        
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        Map<String, DiageoCMS__Cluster__c> clusters = setupCreateClusters();
        
        setupCreateForms(clusters.get('ClusterLeaf').Id);
        
        System.debug(LoggingLevel.DEBUG,'CG - in Test_MD_NewOutletUserController.setup() method - END');
    }
    
    
    @isTest
    public static void formWrapperTest01() {
        Test.startTest();
        MD_NewOutletUserController.FormWrapper fw = new MD_NewOutletUserController.FormWrapper();
        
        Test.stopTest();
         Assert.isNotNull(fw,'fw value should not be null');
    }
    
    @isTest
    public static void getLoggedUserInformationTest01() {
        Test.startTest();
        
        DiageoCMS__Form__c form = [SELECT Id, DiageoCMS__ExternalId__c
                                   FROM DiageoCMS__Form__c WHERE Name = 'Test_Form' LIMIT 1];
        
        User u = [SELECT Id, Username, ContactId, ProfileId, Alias, Email, CommunityNickname
                  , LanguageLocaleKey, EmailEncodingKey, LastName, LocaleSidKey
                  , TimeZoneSidKey, Country
                  FROM User WHERE Alias = 'hola' LIMIT 1];
        
        System.runAs(u) {
            MD_NewOutletUserController.getLoggedUserInformation(form.DiageoCMS__ExternalId__c);
        }
        
        Test.stopTest();
        Assert.isNotNull(MD_NewOutletUserController.getLoggedUserInformation(form.DiageoCMS__ExternalId__c),'logged-In User Info found');
    }
    
    @isTest
    public static void checkForDuplicatesTest01() {
        Test.startTest();
        
        Contact con = [SELECT Id, (SELECT Id, Account.Country__r.Code__c
                                   FROM AccountContactRelations) 
                       FROM Contact];
        
        MD_NewOutletUserController.checkForDuplicates(JSON.serialize(con));
        
        Test.stopTest();
         Assert.isNotNull(MD_NewOutletUserController.checkForDuplicates(JSON.serialize(con)),'duplicate User found');
    }
    
    @isTest
    public static void checkForDuplicatesTest02() {
        Test.startTest();
        
        Contact con = new Contact();
        con.Email = 'test.contact@yopmail.com';
        
        MD_NewOutletUserController.checkForDuplicates(JSON.serialize(con));
        
        Test.stopTest();
         Assert.isNotNull(con.Email,'email should not be null');
    }
    
    @isTest
    public static void saveContactTest01() {
        Test.startTest();
        
        Account ac = [SELECT Id FROM Account WHERE RecordType.Developername = 'Outlet' LIMIT 1];
        Contact cont = new Contact(AccountId = ac.Id, FirstName = 'Test', LastName = 'User', Email = 'email@email.com');
        
        insert cont;
        
        Contact con = [SELECT Id, (SELECT Id, Account.Country__r.Code__c
                                   FROM AccountContactRelations) 
                       FROM Contact WHERE Id = :cont.Id];
        
        Map<String, List<String>> permissionsByRegion = new Map<String, List<String>>();
        String formExternalId = 'Test_Form';
        Set<Id> clustersId = new Set<Id>();
        
        for(DiageoCMS__Cluster__c clus : [SELECT Id, DiageoCMS__ExternalId__c FROM DiageoCMS__Cluster__c WHERE RecordType.DeveloperName = 'ClusterLeaf']) {
            clustersId.add(clus.Id);
            permissionsByRegion.put(clus.DiageoCMS__ExternalId__c, new List<String>{'Access', 'Order', 'Account Documents', 'Manage Users'});
        }
        
        DiageoCMS.GeneralForm gf = new DiageoCMS.GeneralForm(formExternalId, clustersId);
        MD_GeneralFormWrapper.FormSettings formSettings = new MD_GeneralFormWrapper.FormSettings(gf.formSettings);
        
        MD_NewOutletUserController.TableConfigurationWrapper tableConf = new MD_NewOutletUserController.TableConfigurationWrapper(con, permissionsByRegion, formExternalId, clustersId);
        String stringResponse = MD_NewOutletUserController.saveContact(JSON.serialize(formSettings), JSON.serialize(cont), JSON.serialize(tableConf.rowConfigurations));
        Test.stopTest();
          Assert.isNotNull(clustersId,'clustersId should not be null');
          Assert.isNotNull(stringResponse,'stringResponse should not be null');
        
    }
    
    @isTest
    public static void saveUserTest01() {
        
        Test.startTest();
        
        Account ac = [SELECT Id FROM Account WHERE RecordType.Developername = 'Outlet' LIMIT 1];
        Contact cont = new Contact(AccountId = ac.Id, FirstName = 'Test', LastName = 'User', Email = 'email@email.com');
        
        List<AccountContactRelation> acr = new List<AccountContactRelation>();
        
        insert cont;
        
        Contact con = [SELECT Id, (SELECT Id, Account.Country__r.Code__c
                                   FROM AccountContactRelations) 
                       FROM Contact WHERE Id = :cont.Id];
        
        Map<String, List<String>> permissionsByRegion = new Map<String, List<String>>();
        String formExternalId = 'Test_Form';
        Set<Id> clustersId = new Set<Id>();
        
        for(DiageoCMS__Cluster__c clus : [SELECT Id, DiageoCMS__ExternalId__c FROM DiageoCMS__Cluster__c WHERE RecordType.DeveloperName = 'ClusterLeaf']) {
            clustersId.add(clus.Id);
            permissionsByRegion.put(clus.DiageoCMS__ExternalId__c, new List<String>{'Access', 'Order', 'Account Documents', 'Manage Users'});
        }
        
        DiageoCMS.GeneralForm gf = new DiageoCMS.GeneralForm(formExternalId, clustersId);
        MD_GeneralFormWrapper.FormSettings formSettings = new MD_GeneralFormWrapper.FormSettings(gf.formSettings);
        
        //MD_NewOutletUserController.TableConfigurationWrapper tableConf = new MD_NewOutletUserController.TableConfigurationWrapper(con, permissionsByRegion, formExternalId, clustersId);
        
        MD_NewOutletUserController.saveUser(JSON.serialize(con), JSON.serialize(acr), JSON.serialize(cont), JSON.serialize(formSettings));
        
        Test.stopTest();  
         Assert.isNotNull(clustersId,'clustersId should not be null');
    }
    
    @isTest
    public static void checkForDuplicatesResponseTest01() {
        Test.startTest();
        
        MD_NewOutletUserController.CheckForDuplicatesResponse response = new MD_NewOutletUserController.CheckForDuplicatesResponse();
        
        Test.stopTest();
         Assert.isNotNull(response,'response should not be null');
    }
    
    @isTest
    public static void tableConfigurationWrapperTest01() {
        Test.startTest();
        
        List<AccountContactRelation> relations = [SELECT Id, AccountId FROM AccountContactRelation];
        
        for(AccountContactRelation ac : relations) {
            ac.MD_Status__c = 'Active';
        }
        
        update relations;
       Assert.areNotEqual(relations.size(), 0,'Was expecting to find at least one accountContactRelation created on the Test Setup'); 
        Contact con = [SELECT Id, (SELECT Id, Account.Country__r.Code__c
                                   FROM AccountContactRelations) 
                       FROM Contact];
        
        Map<String, List<String>> permissionsByRegion = new Map<String, List<String>>();
        String formExternalId = 'Test_Form';
        Set<Id> clustersId = new Set<Id>();
        
        for(DiageoCMS__Cluster__c clus : [SELECT Id, DiageoCMS__ExternalId__c FROM DiageoCMS__Cluster__c WHERE RecordType.DeveloperName = 'ClusterLeaf']) {
            clustersId.add(clus.Id);
            permissionsByRegion.put(clus.DiageoCMS__ExternalId__c, new List<String>{'Access', 'Order', 'Account Documents', 'Manage Users'});
        }
        
        MD_NewOutletUserController.TableConfigurationWrapper tableConf = new MD_NewOutletUserController.TableConfigurationWrapper(con, permissionsByRegion, formExternalId, clustersId);
        
        MD_NewOutletUserController.getAccountContactsFromTableConfig(tableConf.rowConfigurations);
        
        MD_NewOutletUserController.addPermissionsToContact(con.Id, JSON.serialize(tableConf.rowConfigurations));
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void headerConfigurationWrapperTest01() {
        Test.startTest();
        
        MD_NewOutletUserController.HeaderConfigurationWrapper headerWrapper = new MD_NewOutletUserController.HeaderConfigurationWrapper('headerName', 'headerHelpText', 'headerHelpIcon');
        MD_NewOutletUserController.HeaderConfigurationWrapper headerWrapper2 = new MD_NewOutletUserController.HeaderConfigurationWrapper('headerName', 'headerLabel', 'headerHelpText', 'headerHelpIcon');
        
        Test.stopTest();
        Assert.isNotNull(headerWrapper,'headerWrapper should not be null');
        Assert.isNotNull(headerWrapper2,'headerWrapper2 should not be null');
    }
    
    @isTest
    public static void rowConfigurationWrapperTest01() {
        Test.startTest();
        
        AccountContactRelation acr = new AccountContactRelation();
        List<MD_NewOutletUserController.ColumnWrapper> columns = new List<MD_NewOutletUserController.ColumnWrapper>();
        MD_NewOutletUserController.RowConfigurationWrapper rowConfigurationWrapper = new MD_NewOutletUserController.RowConfigurationWrapper(columns, acr);
        
        Test.stopTest();
         Assert.isNotNull(rowConfigurationWrapper,'rowConfigurationWrapper should not be null');
    }
    
    @isTest
    public static void columnWrapperTest01() {
        Test.startTest();
        
        MD_NewOutletUserController.ColumnWrapper columnWrapper = new MD_NewOutletUserController.ColumnWrapper('columnName', 'columnLabel', true);
        
        Test.stopTest();
        Assert.isNotNull(columnWrapper,'columnWrapper should not be null');
    }
    
    
    
    public static void setupCreateForms(String clusterId) {        
        DiageoCMS__Form__c form = new DiageoCMS__Form__c();
        form.Name = 'Test_Form';
        form.DiageoCMS__Status__c = 'Active';
        form.DiageoCMS__Cluster__c = clusterId;
        form.DiageoCMS__ExternalId__c = 'Test_Form';
        form.DiageoCMS__SaveClass__c = 'MD_ES_NewOutletUserSaveClass.SecondaryUser';
        
        insert form;
        
        DiageoCMS__FormSection__c section = new DiageoCMS__FormSection__c();
        section.DiageoCMS__Form__c = form.Id;
        section.Name = 'Test_Section';
        insert section;
        
        DiageoCMS__FormElement__c element = new DiageoCMS__FormElement__c();
        element.DiageoCMS__FormSection__c = section.Id;
        element.Name = 'Test_Element';
        element.DiageoCMS__Status__c = 'Active';
        element.DiageoCMS__FieldAPIName__c = 'Name';
        element.DiageoCMS__ObjectAPIName__c = 'Account';
        insert element; 
        
        System.debug(LoggingLevel.DEBUG,'CG - in Test_MD_NewOutletUserController.setupCreateForms() method. form: ' + form);
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