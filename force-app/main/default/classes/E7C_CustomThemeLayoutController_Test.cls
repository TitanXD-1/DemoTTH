@isTest
public class E7C_CustomThemeLayoutController_Test {
	
    @isTest static void testMethod1(){
        Test.startTest();
        E7C_CustomThemeLayoutController.fetchUserType();
        
        E7C_MenuController.toTestCoverage();
        
        E7C_SurveyLocationComponentController.toTestCoverage();
        Test.stopTest();
    }
}