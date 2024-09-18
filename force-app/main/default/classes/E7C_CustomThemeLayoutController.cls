public class E7C_CustomThemeLayoutController {
	@AuraEnabled 
    public static Boolean fetchUserType() {
        Boolean isLoggedIn = false;
        String userType = UserInfo.getUserType();
        if (userType != 'Guest') {
            isLoggedIn = true;
        }
        return isLoggedIn;
    }
}