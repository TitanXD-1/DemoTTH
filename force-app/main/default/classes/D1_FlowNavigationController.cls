public class D1_FlowNavigationController {
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