@isTest
public class MD_ChangePasswordPageControllerTest {
	   
   	public static testMethod void testChangePasswordController01() {
        Test.startTest();
        
        // Instantiate a new controller with all parameters in the page
        MD_ChangePasswordPageController controller = new MD_ChangePasswordPageController();
        controller.newPassword = 'qwerty01';
        controller.verifyNewPassword = 'qwerty01';
        
        Test.stopTest();
        
        System.assertEquals(controller.changePassword(),null);                           
    }
    
    public static testMethod void testChangePasswordController02() {
		Test.startTest();
        
        // Instantiate a new controller with all parameters in the page
        MD_ChangePasswordPageController controller = new MD_ChangePasswordPageController();
        controller.newPassword = 'qwerty01';
        controller.verifyNewPassword = 'qwerty02';
        
        Test.stopTest();
        
        System.assertEquals(controller.changePassword(),null);                           
    }
    
    public static testMethod void testChangePasswordController03() {
        Test.startTest();
        
        // Instantiate a new controller with all parameters in the page
        MD_ChangePasswordPageController controller = new MD_ChangePasswordPageController();
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';
        
        Test.stopTest();
        
        System.assertEquals(controller.changePassword(),null);
    }
}