@isTest
public class E7C_ManagePasswordController_Test {
	
    @isTest static void testMethod1(){
        E7C_ManagePasswordController.managePassword('oldtestPwd', 'newtestPwd', 'newtestPwd');
        E7C_ManagePasswordController.getContactDetailsApex();
    }
}