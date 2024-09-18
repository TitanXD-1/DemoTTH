@isTest
public class D1_FlowNavigationControllerTest {
    /**
     * @Name : getCurrentTheme
	 * @description : This method is used to test the getUIThemeDescription() method of the  class D1_FlowNavigationController
	 */
    @isTest
    public static void getCurrentTheme() {
        
        Test.startTest();
        String themeDescription = D1_FlowNavigationController.getUIThemeDescription();
        Test.stopTest();
        
        System.assertNotEquals(null, themeDescription, 'Expected a non-null theme description');
        
        System.assert(
            themeDescription == 'Salesforce1 Mobile' ||
            themeDescription == 'Lightning Experience' ||
            themeDescription == 'Salesforce Classic',
            'Unexpected theme description: ' + themeDescription
        );
        }   
}