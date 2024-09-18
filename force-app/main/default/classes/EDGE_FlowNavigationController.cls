/**
* @Name: EDGE_FlowNavigationController
* @Req: 
* @ES20-10353 - Flow to create a Call, Case, Case Task_GL_SFDC_Quality
* @History 
                                                        
* @VERSION   AUTHOR            		DATE              DETAIL
* 1.0        Subhodeep Sarkar       02/09/2021        Initial Development 
*/

public class EDGE_FlowNavigationController {
@AuraEnabled
    public static String getUIThemeDescription() {
        String themedesc;
        String theme = UserInfo.getUiThemeDisplayed();
        if(theme=='Theme4t'){
            themedesc='Salesforce1 Mobile';
        } else if(theme=='Theme4d'){
            themedesc='Lightning Experience';
        } else if(theme=='Theme3' || theme=='Theme2'){
            themedesc='Salesforce Classic';
        }
        return themedesc;
    }
}