@isTest
public class Test_MD_ManageUsersController {
	
    @testSetup
    public static void setup(){
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true);
        
        List<DiageoCMS__Cluster__c> globalClusters = DiageoCMS.MockupFactory.createCluster('GlobalClusterTest', null, 1, 'ClusterRoot', 'GlobalClusterTest');
        List<DiageoCMS__Cluster__c> leafClusters = DiageoCMS.MockupFactory.createCluster('CO', globalClusters.get(0).Id, 1, 'ClusterLeaf', 'CO');  
        leafClusters[0].Name='CO';
        leafClusters[0].DiageoCMS__ExternalId__c='CO';
        leafClusters[0].MD_MyDiageoPermissions__c = 'Access;Order;Manage Users';
        update leafClusters;
    }
    
    @isTest
    public static void getDifferentColumnsToDisplayTest01() {
        Test.startTest();
        
        List<AccountContactRelation> accountContacts = [SELECT Id, Account.Country__r.Code__c FROM AccountContactRelation WHERE Account.Country__r.Code__c = 'CO'];
        
        Map<String, List<String>> permissionsByRegion = new Map<String, List<String>>();
        permissionsByRegion.put('CO', new List<String>{'Access'});
        
        List<AccountContactRelation> relations = [SELECT Id, AccountId, ContactId FROM AccountContactRelation];
        
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        
        System.runas(u) {
            /*
            MD_ManageUsersController.TableConfigurationWrapper tcw = new MD_ManageUsersController.TableConfigurationWrapper();
            tcw.getDifferentColumnsToDisplay(accountContacts, permissionsByRegion);
			*/
        }
        Test.stopTest();
    }
    
    @isTest
    public static void getAccountContactsTest01() {
        Test.startTest();
        
        List<AccountContactRelation> relations = [SELECT Id, AccountId, ContactId FROM AccountContactRelation];
        
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        
        System.runas(u) {
            MD_SessionSettings__c sett = MD_UserSessionUtil.getSessionSettings();
        	sett.NavigateAsOutlet__c = relations.get(0).Id;
			MD_UserSessionUtil.updateUserSessionSettings();        
            
        	String result = MD_ManageUsersController.getAccountContacts();
            MD_ManageUsersController.saveChangesToSF(result);
        }
        Test.stopTest();
    }
    
    @isTest
    public static void headerConfigurationWrapperTest01() {
        MD_ManageUsersController.HeaderConfigurationWrapper wrapper = new MD_ManageUsersController.HeaderConfigurationWrapper('headerName', 'headerHelpText', 'headerHelpIcon');
    }
    
    @isTest
    public static void headerConfigurationWrapperTest02() {
        MD_ManageUsersController.HeaderConfigurationWrapper wrapper = new MD_ManageUsersController.HeaderConfigurationWrapper('headerName', 'headerLabel', 'headerHelpText', 'headerHelpIcon');
    }
    
    @isTest
    public static void rowConfigurationWrapperTest01() {
        MD_ManageUsersController.RowConfigurationWrapper rw = new MD_ManageUsersController.RowConfigurationWrapper(new List<MD_ManageUsersController.ColumnWrapper>(), new AccountContactRelation());
    }
    
    @isTest
    public static void columnWrapperTest01() {
        MD_ManageUsersController.ColumnWrapper cw = new MD_ManageUsersController.ColumnWrapper('columnName', 'columnLabel', true, true);
    }
}