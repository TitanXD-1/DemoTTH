/**
* @Name: EDGE_FlowNavigationControllerTest
* @Req: 
* @ES20-10353 - Flow to create a Call, Case, Case Task_GL_SFDC_Quality
* @History 
                                                        
* @VERSION   AUTHOR            		DATE              DETAIL
* 1.0        Subhodeep Sarkar       02/09/2021        Initial Development 
  */

@isTest
public class EDGE_FlowNavigationControllerTest {
    @isTest
    static void getCurrentTheme() {
        integer cnt = 0;
        string myTheme = EDGE_FlowNavigationController.getUIThemeDescription();
        if (myTheme == 'Salesforce Classic') {
            cnt = cnt+1;
        }
        if (myTheme == 'Lightning Experience') {
            cnt = cnt+1;
        }
        if (myTheme == 'Salesforce1 Mobile') {
            cnt = cnt+1;
        }
        system.assertEquals(1, cnt,'null');     
    }
    
}