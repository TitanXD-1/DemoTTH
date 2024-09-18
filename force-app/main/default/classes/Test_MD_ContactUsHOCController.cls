@isTest
public class Test_MD_ContactUsHOCController {
    
    
    static testMethod void initializeTest(){
        Test.startTest();
        String response = MD_ContactUsHOCController.initialize();
        System.assertNotEquals(null, response);
        Test.stopTest();
    }
    
    static testMethod void doSaveTest(){
        Test.startTest();
        String response = MD_ContactUsHOCController.doSave(JSON.serialize(new Case()));
        System.assertNotEquals(null, response);
        Test.stopTest();
    }
    
    static testMethod void doSaveFailTest(){
        Test.startTest();
        String response = MD_ContactUsHOCController.doSave('FAIL');
        System.assertNotEquals(null, response);
        Test.stopTest();
    }
    
    
    
}