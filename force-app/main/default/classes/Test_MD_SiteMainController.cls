@isTest(seeAllData=false)
public class Test_MD_SiteMainController {
    
    @testSetup
    public static void setup(){
        TestFactory_MD_Account.setup(true);
    }
    
    @isTest
    public static void initPageTemplateTest01() {
        Test.startTest();
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        System.runas(u){
            Object response = MD_SiteMainController.initPageTemplate(false);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void initPageTemplateTest02() {
        Test.startTest();
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        System.runas(u){
            Object response = MD_SiteMainController.initPageTemplate(true);
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void initPageTemplateGuestTest01() {
        Test.startTest();
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        System.runas(u){
            Object response = MD_SiteMainController.initPageTemplateGuest();
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void getClusterByIsCountryTest01() {
        Test.startTest();
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        System.runas(u){
            List<MD_SiteMainController.MD_ClusterWrapper> clusterList = MD_SiteMainController.getClusterByIsCountry();
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void clusterWrapperTest01() {
        Test.startTest();
        MD_SiteMainController.MD_ClusterWrapper CW = new MD_SiteMainController.MD_ClusterWrapper('TEST VALUE', 'test label', 'clusterId');
        Test.stopTest();
    }
    
    @isTest
    public static void clusterWrapperTest02() {
        Test.startTest();
        MD_SiteMainController.MD_ClusterWrapper wrapper = new MD_SiteMainController.MD_ClusterWrapper('', '', '');
        Test.stopTest();
    }
    
    @isTest
    public static void getRedirectURLTest() {
        Test.startTest();
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        System.runas(u){
            String url = MD_SiteMainController.getRedirectURL();
        }
        
        Test.stopTest();
    }
    
    @isTest
    public static void getSidebarExternalIdTest() {
        Test.startTest();
        User u = [SELECT Id, Username, ProfileId FROM User WHERE FirstName = 'hola' AND LastName = 'TestHola'];
        System.runas(u){
            String url = MD_SiteMainController.getSidebarExternalId('','','');
        }
        
        Test.stopTest();
    }
    
}