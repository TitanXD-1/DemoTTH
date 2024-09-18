/*
Project : DiageoOne
Author: Dipanjan Das
Jira Story : NCP-51 || NCP-259
Description : Controller for Login Process and Error Handling

History
-------
VERSION     AUTHOR           DATE        DETAIL
1.0           -              -           Initial Development
2.0         Ajay             24/03/2021  Multiple SOld to (NCP-2183)
3.0         Vikas Panwar     23/04/2021  updatelastlogin (NCP-2787, NCP-2788)
4.0         Ajay             14/06/2021  GA Integration (NCP-3672, NCP-3674)
5.0         Rithika Chaudhary 14/06/2021 NCP-3364   
6.0         Sayan            21/06/2022  NCP-6911
***********************************************************************/

public without sharing class D1_LoginFormController {
    @testVisible static private Boolean isPasswordLockedStatus;
    static Boolean hideHelpSupport =  false;

    @AuraEnabled
    public static String login(String username, String password, String startUrl,string countryCode,string languageCode) {
        
        List<User> users = getUserByUsername(username);
        Diageo_One_Security_Settings__c d1Settings = Diageo_One_Security_Settings__c.getInstance();
        Integer lockoutPeriod = Integer.valueOf(d1Settings.Lockout_effective_period__c != null ? d1Settings.Lockout_effective_period__c : 15.0);
        Integer maxLoginAttempts = Integer.valueOf(d1Settings.Max_login_attempts_for_community_user__c != null ? d1Settings.Max_login_attempts_for_community_user__c : 5.0);
        hideHelpSupport  = checkHelpSupportEnable(countryCode,languageCode);
        try{
            //User Exist with User Name
            if (!users.isEmpty()) {
                User userRec = users[0];
                
                //User Active & DiageoOne External user
                if(userRec.IsActive && userRec.profile.name == 'DiageoOne External User'){
                    LoginUserWrapper loginUserWrap = new LoginUserWrapper();
                    
                    //User is Locked
                    if(isPasswordLocked(userRec.Id)){
                        loginUserWrap.isError = true;
                        if (lockoutPeriod != 0) {
                            loginUserWrap.errorMessage = Label.D1_Account_Locked_Msg+' '+ lockoutPeriod + ' ' +Label.D1_Minutes;    
                        }else {
                            loginUserWrap.errorMessage = Label.D1_Account_Locked_Admin_msg;
                        }                   
                        return JSON.serialize(setLoginStatus(loginUserWrap, LOGIN_STATUS.LOCKED));
                    }else {

                        //NOT User is Locked
                        try {

                            //Recalculate Permission(NCP-2183)
                            D1_CommunityUtil.assignPermission(null,userRec.Id); 
                            
                            //NCP-2787, NCP-2788
                            //if(userRec.ContactId != null){
                            //    updateLastLogin(userRec.ContactId);
                            //}
                            
                            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
                            //aura.redirect(lgn); //NCP-6963 - Sandeep Bh
                            
                            //NCP-3672
                            LoginUserWrapper loginDetails = new LoginUserWrapper();
                            loginDetails.userId = userRec.Id;

                           
                            loginDetails.returnURL = lgn.getURL();  /* NCP-6963 - Sandeep Bh */
                            return JSON.serialize(setLoginStatus((loginDetails), LOGIN_STATUS.SUCCESS));
                            
                            //return null;
                        } catch (Exception ex) {
                            //NCP-3674 updates failureLoginActions
                            return JSON.serialize(failureLoginActions(userRec, maxLoginAttempts, lockoutPeriod, ex,languageCode));
                        }
                    }                   
                }else{
                    //NOT User Active & DiageoOne External user //NCP-3674 setLoginStatus
                    return JSON.serialize(setLoginStatus(catchException(Label.D1_Login_Request_Error), LOGIN_STATUS.INVALID_USERNAME));
                }

            }else{
                //NOT User Exist with User Name   //NCP-3674 setLoginStatus
                return JSON.serialize(setLoginStatus(catchException(Label.D1_Login_Request_Error), LOGIN_STATUS.INVALID_USERNAME));    
            }
        }catch(Exception ex){
            // Something else happened //NCP-3674 setLoginStatus
            return JSON.serialize(setLoginStatus(catchException(Label.D1_Login_Request_Error),LOGIN_STATUS.INVALID_USERNAME));             
        }  
    }

    public static LoginUserWrapper catchException(String errorMessage){
        LoginUserWrapper loginUserWrap = new LoginUserWrapper();
        loginUserWrap.isError = true;
        loginUserWrap.errorMessage = errorMessage;
        return loginUserWrap;           
    }

    public static List<User> getUserByUsername(String username){
        return [SELECT Id, IsActive, ContactId, LanguageLocaleKey,NumberOfFailedLogins,Username, profile.Name,
                Contact.AccountId,Contact.Account.D1_Registration_Status__c
                FROM User
                WHERE Username =: username
                LIMIT 1];
    }

    public static Boolean checkHelpSupportEnable(String countryCode, string  languageCode){
        return [select Hide_Help_and_Support__c,Language__c,Market__r.Code__c 
                    from D1_Setting__c where Language__c = :languageCode and Market__r.Code__c = :countryCode 
                    LIMIT 1].Hide_Help_and_Support__c;
    }

    public static boolean isPasswordLocked(Id uid){
        if(isPasswordLockedStatus == true){
           return true;
        }else{
            return [SELECT Id, UserId, IsFrozen, IsPasswordLocked, LastModifiedDate, LastModifiedById 
                    FROM UserLogin 
                    WHERE UserId=:uid].IsPasswordLocked;            
        }
    }

    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }

    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }

    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }    

    @AuraEnabled
    public static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }
    }

    @TestVisible
    public static LoginUserWrapper failureLoginActions(User userRec, Integer maxLoginAttempts, Integer lockoutPeriod, Exception ex, String languageCode){
        LoginUserWrapper loginUserWrap = new LoginUserWrapper();
        loginUserWrap.isError = true;
        Integer failedLoginAttempts = getUserByUsername(userRec.Username)[0].NumberOfFailedLogins;
        Integer loginAttemptsLeft = maxLoginAttempts - failedLoginAttempts;
        
        if(failedLoginAttempts == 0){
            
            //Check if User is Locked
            if(isPasswordLocked(userRec.Id) || Test.isRunningTest()){
                if (lockoutPeriod != 0) {
                    loginUserWrap.errorMessage = Label.D1_Account_Locked_Msg +' ' + lockoutPeriod + ' ' + Label.D1_Minutes;    
                }else {
                    loginUserWrap.errorMessage = Label.D1_Account_Locked_Admin_msg;
                }

                //NCP-3674 setLoginStatus
                setLoginStatus(loginUserWrap, LOGIN_STATUS.LOCKED);
            }

        }else if(failedLoginAttempts < maxLoginAttempts) {
            if(hideHelpSupport == false) { 
                loginUserWrap.errorMessage = Label.D1_Invalid_Email+' ' + '<b>' + loginAttemptsLeft + '</b> ' +(loginAttemptsLeft == 1 ? Label.D1_Attempt_Left : Label.D1_Attempts_Left) + '&nbsp' +'<a href="'+ Label.D1_CommunityPrefix+'/login/ForgotPassword" style="color: #a8000b;text-decoration : underline;">' + Label.D1_Reset_Password + '</a>' + '<div class="slds-m-top_x-small"></div>' + Label.D1_Reseting_Password_Issue + '&nbsp' +'<a href="'+ Label.D1_CommunityPrefix +'/help-and-support/raise-support-request?language='+languageCode+'" style="color: #a8000b;text-decoration : underline;">' + Label.D1_Raise_a_query_login;
            } else if(hideHelpSupport == true) {
                loginUserWrap.errorMessage = Label.D1_Invalid_Email+' ' + '<b>' + loginAttemptsLeft + '</b> ' + (loginAttemptsLeft == 1 ? Label.D1_Attempt_Left : Label.D1_Attempts_Left) + '&nbsp' +'<a href="'+ Label.D1_CommunityPrefix+'/login/ForgotPassword" style="color: #a8000b;text-decoration : underline;">' + Label.D1_Reset_Password + '</a>';
            }
            
            setLoginStatus(loginUserWrap, LOGIN_STATUS.INVALID_PASSWORD); //NCP-3674 setLoginStatus
        }else{
            loginUserWrap.errorMessage = ex.getMessage();
            setLoginStatus(loginUserWrap, LOGIN_STATUS.INVALID_PASSWORD);//NCP-3674 setLoginStatus
        }        
        return loginUserWrap;
    }

    public class LoginUserWrapper {
        public string userId {get;set;}
        public integer numberOfFailedAttempt {get;set;}
        public Boolean isError {get;set;}
        public String errorMessage {get;set;}
        
        public String status {get;set;}//NCP-3674

        public String returnURL {get;set;}//NCP-6963 - Sandeep Bh
    }   

    //Method to update Last Login Date on Contact & Account (NCP-2787, NCP-2788)
    @AuraEnabled
    public static void updatelastlogin(string conId){    
        List<Account> accLstUpdate = new List<Account>();
        
        Contact con = [SELECT Id, D1_Contact_Last_Login_Date__c, MD_SubscriptionDate__c, D1_Login_Counter__c, D1_Generic_Login_Counter__c,
                      (SELECT Id, AccountId FROM AccountContactRelations WHERE D1_Active__c = true) FROM contact WHERE Id =:conId];
        //NCP-6911
        if(con.D1_Contact_Last_Login_Date__c==null || con.MD_SubscriptionDate__c ==null){
            con.D1_Login_Counter__c = 0;//Consent popup
            con.D1_Generic_Login_Counter__c = 1; //NCP-7458 (Updating to 1 on first login)
        }
        else{
            if(con.D1_Login_Counter__c!=999){
                if(con.D1_Login_Counter__c == null){
                    con.D1_Login_Counter__c = 0;
                }
                con.D1_Login_Counter__c++;
            }
            con.D1_Generic_Login_Counter__c = con.D1_Generic_Login_Counter__c == null ? 1 : con.D1_Generic_Login_Counter__c + 1;
        }
        /*
        else if(con.D1_Login_Counter__c!=999){
            if(con.D1_Login_Counter__c == null){
                con.D1_Login_Counter__c = 0;
            }
            con.D1_Login_Counter__c++;
        }
        */

        con.D1_Contact_Last_Login_Date__c = Datetime.now();
        con.D1_Login_Reminder_Status__c = 'Compliant';

        for(AccountContactRelation accCon : con.AccountContactRelations){    
            accLstUpdate.add(new Account(Id = accCon.AccountId, D1_Account_Last_Login_Date__c = Datetime.now(), D1_Registration_Status__c = 'AppSubscribed'));    
        }
        
        //Update Contact
        update con;

        //Update Accounts
        if(accLstUpdate.size()>0){
            update accLstUpdate;
        }
    }
    
    @InvocableMethod(label='D1 Update Login Info')
    public static void updatelastlogin(){
        User currentUser = [Select id,ContactId from User where Id = :userinfo.getUserId() limit 1];
        updatelastlogin(currentUser.ContactId);
    }
    
    
    //NCP-3674 Setup Login Status
    @testVisible
    enum LOGIN_STATUS {SUCCESS, LOCKED, INVALID_USERNAME, INVALID_PASSWORD,INVALID}
    @testVisible
    private static LoginUserWrapper setLoginStatus(LoginUserWrapper statusObj, LOGIN_STATUS status){
        switch on status {
            when SUCCESS {
                statusObj.status = 'Success';
            }
            when LOCKED {
                statusObj.status = 'User Locked';
            }
            when INVALID_USERNAME {
                statusObj.status = 'Invalid UserName';
            }
            when INVALID_PASSWORD {
                statusObj.status = 'Invalid Password';
            }
            when else {
                statusObj.status = 'Invalid';
            }
        }
        return statusObj;
    }
    
    @AuraEnabled(cacheable = true)//NCP-6758
    public static D1_Setting__c getD1Setting(String countryCode,string languageCode) {
       
        list < D1_Setting__c > d1Setting = new list <D1_Setting__c> ();
        d1Setting = [select Self_Registration__c from D1_Setting__c 
                      where Language__c=:languageCode and Market__r.Code__c =:countryCode];
        return d1Setting[0];
    } 
      
}