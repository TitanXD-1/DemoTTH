@isTest
public class Test_MD_LoginThemeController {
    
    @testSetup
    static void setup() {
        DiageoCMS__MediaElement__c md = new DiageoCMS__MediaElement__c();
        md.DiageoCMS__FileURLDesktop__c = 'asdf';
        md.DiageoCMS__FileURLTablet__c = 'asdf';
        md.DiageoCMS__FileURLMobile__c = 'asdf';
        md.DiageoCMS__ExternalId__c = 'loginBackgroundImage';
		md.DiageoCMS__Status__c = 'Active';
        
        insert md;
        
        System.debug('CG - Test_MD_LoginThemeController.setup() method - md.Id: ' + md.Id);
    }
    
    @isTest
    public static void testController() {
        Test.startTest();
        MD_LoginThemeController.getRedirectURL();
        Test.stopTest();
    }
    
    @isTest
    public static void testFetchBackgroundImageDesktop() {
        Test.startTest();
        
        MD_LoginThemeController.fetchBackgroundImage('DESKTOP');
        Test.stopTest();
    }
    
    @isTest
    public static void testFetchBackgroundImageTablet() {
        Test.startTest();
        
        MD_LoginThemeController.fetchBackgroundImage('TABLET');
        Test.stopTest();
    }
    
    @isTest
    public static void testFetchBackgroundImageMobile() {
        Test.startTest();
        
        MD_LoginThemeController.fetchBackgroundImage('MOBILE');
        Test.stopTest();
    }

}