public without sharing class E7C_FogotPasswordCompController {
    @AuraEnabled
    public static boolean resetPassword(String userName){
        try{
            String uname = userName+'.7cs';
            Boolean userExits = false;
            For(User usr: [SELECT Id,UserName,UserType FROM User WHERE Email = :userName AND IsActive = true AND IsPortalEnabled = true]){
                if(usr.UserType == 'PowerCustomerSuccess' || usr.UserType == 'CustomerSuccess')
            		Site.forgotPassword(usr.UserName+'.7cs');
                //else
                  //  System.resetPassword(usr.Id, true);
                userExits = true;
            }
            return userExits;
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}