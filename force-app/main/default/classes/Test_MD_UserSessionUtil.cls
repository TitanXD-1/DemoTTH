@isTest(seeAllData=false)
public class Test_MD_UserSessionUtil {
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setup(true); 
    }
    
    @isTest
    public static void outletInfoWrapperTest01() {
        MD_UserSessionUtil.OutletInfo info1 = new MD_UserSessionUtil.OutletInfo();
        MD_UserSessionUtil.OutletInfo info2 = new MD_UserSessionUtil.OutletInfo('outletName', '');
    }
    
    @isTest 
    static void getOutletContactTest(){
        Test.startTest();      
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            AccountContactRelation ac = MD_UserSessionUtil.getOutletContact();
        }
        Test.stopTest();
    }
    
    @isTest 
    static void getOutletTest(){
        Test.startTest();
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            Account ac = MD_UserSessionUtil.getOutlet();
        }
        Test.stopTest();
    }
    
    @isTest 
    static void getUserTest(){
        Test.startTest();
        
        User u = [SELECT Id, ContactId, Alias FROM User WHERE Alias='hola' LIMIT 1];
        
        System.runAs(u) {
            User result = MD_UserSessionUtil.getUser();
            System.debug('CG - in Test_MD_UserSessionUtil.getUserTest() method. result: ' + result);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void getUserFromContactIdTest(){
        Test.startTest();
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<Contact> contact = [SELECT Id FROM Contact LIMIT 1];
            User usr = MD_UserSessionUtil.getUserFromContactId(contact[0].Id);
            System.assertNotEquals(null, usr);
        }
        Test.stopTest();
        
        
    }
    
    @isTest
    static void getContactInformationTest01(){
        Test.startTest();
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<Contact> contact = [SELECT Id FROM Contact LIMIT 1];
            Contact con = MD_UserSessionUtil.getContactInformation(contact[0].Id);
            System.assertNotEquals(null, con);
        }
        Test.stopTest();
    }
    
    @isTest
    static void getContactInformationTest02(){
        Test.startTest();
        User u = [SELECT Id, ContactId, Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(u){
            List<Contact> contact = [SELECT Id FROM Contact LIMIT 1];
            Contact con = MD_UserSessionUtil.getContactInformation(u.ContactId);
            System.assertNotEquals(null, con);
        }
        Test.stopTest();
    }
    
    @isTest
    static void setSessionSettingsFields(){
        Test.startTest();
        User user = MD_UserSessionUtil.getUser();
        MD_UserSessionUtil.setSessionSettingsFields(user.Id);
        Test.stopTest();
    }
    
    @isTest
    static void checkForOutletsInfoCommunityTest(){
        Test.startTest();
        User user = [SELECT Id,Alias FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            MD_UserSessionUtil.MD_CheckOutletInformationResponse response = MD_UserSessionUtil.checkForOutletsInfo();
            System.assertNotEquals(null, response);
            Test.stopTest();
        }
        
    }
    
    @isTest
    static void checkForOutletsInfoTest(){
        Test.startTest();
        MD_UserSessionUtil.MD_CheckOutletInformationResponse response = MD_UserSessionUtil.checkForOutletsInfo();
        System.assertNotEquals(null, response);
        Test.stopTest();
        
        
    }
    
    
    @isTest
    static void getDefaultCookieValueCommunityTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            String cookie = MD_UserSessionUtil.getDefaultCookieValue(user.Id);
            System.assertNotEquals(null, cookie);
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void getDefaultCookieValueTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        String cookie = MD_UserSessionUtil.getDefaultCookieValue(user.Id);
        System.assertNotEquals(null, cookie);
        Test.stopTest();
        
    }
    
    
    @isTest
    static void getAvailableOutletsTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<AccountContactRelation> acr = MD_UserSessionUtil.getAvailableOutlets();
            System.assertNotEquals(null, acr);
        }
        Test.stopTest();
        
    }
    
    
    
    @isTest
    static void getAvailableOutletsForContactTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<Contact> contact = [SELECT Id FROM Contact LIMIT 1];
            List<AccountContactRelation> acr = MD_UserSessionUtil.getAvailableOutletsForContact(contact[0].Id);
            System.assertNotEquals(null, acr);
        }
        Test.stopTest();
        
    }
    
    
    @isTest
    static void getAvailableContactsTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<AccountContactRelation> acr = MD_UserSessionUtil.getAvailableContacts();
            System.assertNotEquals(null, acr);
        }
        Test.stopTest();
        
    }
    
    @isTest
    static void navigateAsOutletTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<AccountContactRelation> outlet = [SELECT Id FROM AccountContactRelation];
            MD_UserSessionUtil.navigateAsOutlet(outlet[0].Id);
        }
        Test.stopTest();
    }
    
    @isTest
    static void getClustersTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            List<String> clusters = MD_UserSessionUtil.getClusters('');
        }
        Test.stopTest();
    }
    
    @isTest
    static void getClusterLocationCodeTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            String locationCode = MD_UserSessionUtil.getClusterLocationCode('');
        }
        Test.stopTest();
    }
    
    @isTest
    static void getCurrencySimbolTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            String currencySimbol = MD_UserSessionUtil.getCurrencySimbol();
        }
        Test.stopTest();
    }
    
    @isTest
    static void isLoggedUserTest(){
        Test.startTest();
        User user = [SELECT Id FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            MD_UserSessionUtil.isLoggedUser();
        }
        Test.stopTest();
    }
    
    @isTest
    static void setContactFieldsTest(){
        Test.startTest();
        User user = [SELECT Id, ContactId FROM User WHERE Alias='hola' LIMIT 1];
        System.runas(user){
            MD_UserSessionUtil.setContactFields(true);
        }
        Test.stopTest();
    }
    
    @isTest
    static void getClustersTest2() {
        Test.startTest();
        
        MD_UserSessionUtil.getClusters();
        
        Test.stopTest();
    }
}