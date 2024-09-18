public class E7C_ManagePasswordController {
    
    @AuraEnabled
    public static void managePassword(String oldPass, String newPassword, String verifyPass)
    {
		System.PageReference url = Site.changePassword(newPassword, verifyPass, oldPass);
        System.debug('Result:: '+url);
    }
    
    @AuraEnabled
    public static User getContactDetailsApex(){
        try{
            Id usrId = UserInfo.getUserId();
            User usr = [SELECT Id, Email FROM User
                       WHERE Id =: usrId];
            return usr;
        }
        catch(Exception e){
            System.debug('Exception>>> '+e.getStackTraceString());
            return null;
        }
    }

}