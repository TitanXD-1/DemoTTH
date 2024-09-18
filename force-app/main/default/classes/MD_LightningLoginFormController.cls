public without sharing class MD_LightningLoginFormController {

    public static integer passwordLockTimePeriod;
    public static integer loginAttemptsAllowed;
    public static String InvalidPassword;
    public static String NoAccountFound;
    public static String LastAttemptLeft;
    public static String accountLockedMessage1;
    public static String accountLockedMessage2;
    public static String LockedUserEmailTemplateDeveloperName;
    
    public MD_LightningLoginFormController() {

    }
    public static List<MD_Org_wide_settings__mdt> orgSettings{
        public get{return [SELECT DeveloperName, MasterLabel, Value__c FROM MD_Org_wide_settings__mdt];}
        private set;
    }

    @AuraEnabled
    public static String login(String username, String password, String startUrl, String errorMessage) {
        System.debug('Value of errorMessage ::'+errorMessage);
        init(errorMessage);        
        
        try {
            
            List<User> users = getUserByUsername(username);            
            
            //if an active user is found then process further
            if(!users.isEmpty()) {
                //if(Site.isValidUsername(username)) {
                User u = users[0];
                System.debug('## login() -- '+u.Id);
                Datetime lastLogintime;
                String errorMsg = '';
                CP_UserLoginWrapper userLoginWrapperWithErros = new CP_UserLoginWrapper();
                if(getIsPasswordLockedForUserId(u.Id)){
                    System.debug('## getIsPasswordLockedForUserId() called-- ');
                    
                    errorMsg = replaceStringByTime(getLockedTimeOfUser(u,passwordLockTimePeriod),accountLockedMessage1,accountLockedMessage2);
                    return JSON.serialize(setWrapperByLockedErrorMessage(userLoginWrapperWithErros,errorMsg));
                    /*List<LoginHistory> LoginHistoryObj = [SELECT Id, LoginTime, Status, UserId FROM LoginHistory WHERE UserId=:u.Id ORDER BY LoginTime DESC LIMIT 1];
                    if(LoginHistoryObj[0].Status == 'Invalid Password'){
                        lastLogintime = LoginHistoryObj[0].LoginTime; lastLogintime = lastLogintime.addMinutes(passwordLockTimePeriod);
                        errorMsg+= accountLockedMessage1.replace('[time]', lastLogintime.format('HH:mm')); errorMsg+=accountLockedMessage2;
                    }*/
                    /*else{
                        errorMsg+= accountLockedMessage1.replace(' (until [time] )',''); errorMsg+=accountLockedMessage2;
                    }*/
                    /*userLoginWrapperWithErros.setErrorMessage(errorMsg); 
                    userLoginWrapperWithErros.setWithError(true);
                    userLoginWrapperWithErros.showResetPasswordLink = true;
                    userLoginWrapperWithErros.showModal = true;
                    return JSON.serialize(userLoginWrapperWithErros);*/
                }
                
                try{
                    System.debug('## try -- ');
                    ApexPages.PageReference lgn = Site.login(username, password, startUrl);
                    aura.redirect(lgn);
                    return JSON.serialize(successLoginActions(u));
                }
                catch(Exception ex){
                    System.debug('## catch -- ');
                    return JSON.serialize(failureLoginActions(u,ex));
                }
            }
            //if no active user is found, then display user not found error
            else {
                System.debug('## NoAccountFound -- ');
                CP_UserLoginWrapper userLoginWrapperWithErros = new CP_UserLoginWrapper();
                userLoginWrapperWithErros.setErrorMessage(NoAccountFound);
                userLoginWrapperWithErros.setWithError(true);
                userLoginWrapperWithErros.showRegistrationLink = true;
                return JSON.serialize(userLoginWrapperWithErros);
            }
            
        } catch (Exception ex) {
            System.debug('CG - in LightningLoginFormController. ERROR!! ');
            System.debug(ex.getMessage());
            System.debug(ex.getCause());
            System.debug(ex.getLineNumber());
            
            CP_UserLoginWrapper userLoginWrapperWithErros = new CP_UserLoginWrapper();
            userLoginWrapperWithErros.setErrorMessage(ex.getMessage());
            userLoginWrapperWithErros.setWithError(true);
            return JSON.serialize(userLoginWrapperWithErros);
        }
        //FIN ECOM-814 - Analytics - Advanced Analytics Tracking for MyDiageo
    } 
    
    
    public static void init(String errorMessage){
        for(MD_Org_wide_settings__mdt orgSetting: orgSettings){
            if(orgSetting.DeveloperName == 'CustomerProfileLockoutEffectivePeriod'){passwordLockTimePeriod = Integer.valueOf(orgSetting.Value__c);}
            if(orgSetting.DeveloperName == 'CustomerProfileMaxInvalidLoginAttempts'){loginAttemptsAllowed = Integer.valueOf(orgSetting.Value__c);}            
            if(orgSetting.DeveloperName == 'LockedUserEmailTemplateDeveloperName'){LockedUserEmailTemplateDeveloperName = orgSetting.Value__c;}
             
        }
        InvalidPassword = System.Label.MD_Invalid_Password_Message;
        LastAttemptLeft = System.Label.MD_Last_Attempt_Left_Message;
        accountLockedMessage1 = System.Label.MD_Account_Locked_Message_Header;
        if(errorMessage != null)
        {            
            System.debug('Value of errorMessage inside the assignment loop ::'+errorMessage);
            //accountLockedMessage2 = errorMessage;
        }
        
        NoAccountFound = System.Label.MD_No_Account_Found_Message;
    }
    public static List<User> getUserByUsername(String username){
        System.debug('## in getUserByUsername(str) -- '+username);
        return [SELECT Id, ContactId, LanguageLocaleKey,NumberOfFailedLogins,Username
                FROM User
                WHERE Username =: username 
                AND IsActive = true
                LIMIT 1];
    }
    public static boolean getIsPasswordLockedForUserId(Id uid){
        System.debug('## in getIsPasswordLockedForUserId(id) -- '+uid);
        return [SELECT Id, UserId, IsFrozen, IsPasswordLocked, LastModifiedDate, LastModifiedById 
                FROM UserLogin 
                WHERE UserId=:uid].IsPasswordLocked;
    }
    @TestVisible
    public static Datetime getLockedTimeOfUser(User u,Integer passwordLockTimePeriod){
        Datetime lastLogintime;
        List<LoginHistory> loginHistoryObj = [SELECT Id, LoginTime, Status, UserId FROM LoginHistory WHERE UserId=:u.Id ORDER BY LoginTime DESC LIMIT 1];
        if(loginHistoryObj !=null && !loginHistoryObj.isEmpty() && loginHistoryObj[0].Status == 'Invalid Password'){
            lastLogintime = loginHistoryObj[0].LoginTime; lastLogintime = lastLogintime.addMinutes(passwordLockTimePeriod);
        }
        return lastLogintime;
    }
    
    @TestVisible
    public static CP_UserLoginWrapper setWrapperByLockedErrorMessage(CP_UserLoginWrapper obj, String errorMsg){
        obj.setErrorMessage(errorMsg); 
        obj.setWithError(true); 
        obj.showModal = true; 
        obj.showResetPasswordLink = true;
        return obj;
    }
    
    @TestVisible
    public static CP_UserLoginWrapper setWrapperByInvalidPasswordMessage(CP_UserLoginWrapper obj, String errorMsg){
        obj.setErrorMessage(errorMsg); 
        obj.setWithError(true); 
        obj.showResetPasswordLink = true;
        return obj;
    }
    
    @TestVisible
    public static CP_UserLoginWrapper setWrapperByLastAttemptLeftMessage(CP_UserLoginWrapper obj, String errorMsg){
        obj.setErrorMessage(errorMsg); 
        obj.setWithError(true); 
        obj.lastAttempt = true;
        return obj;
    }
    
    @TestVisible
    public static String replaceStringByTime(Datetime lastLogintime, String str1, String str2){
        String errorMsg = '';
        errorMsg+= str1.replace('[time]',lastLogintime.format('HH:mm'));
        system.debug('str2 before if'+str2);
        if(string.isNotBlank(str2)){
            system.debug('str2 after if'+str2);
          errorMsg+=str2;  
        }
        return errorMsg;
    }
    
    @TestVisible
    public static CP_UserLoginWrapper failureLoginActions(User u, Exception ex)
    {
        System.debug('## in failureLoginActions(u, ex) -- ');
        CP_UserLoginWrapper userLoginWrapperWithErros = new CP_UserLoginWrapper();
        Integer loginAttempts = getUserByUsername(u.Username)[0].NumberOfFailedLogins;
        System.debug('## loginAttempts -- '+loginAttempts);        
        
        Datetime lastLogintime;
        String errorMsg = '';
        if(loginAttempts == 0 ){
            System.debug('##1 loginAttempts -- '+loginAttempts);
            if(getIsPasswordLockedForUserId(u.Id)){

                //CP_EmailHandler.sendAccountLockNotification(u.id, u.ContactId, LockedUserEmailTemplateDeveloperName);
                //Site.forgotPassword(u.username);//site.forgotPassword after user locked out will send the LockedOut email
                errorMsg = replaceStringByTime(getLockedTimeOfUser(u,passwordLockTimePeriod),accountLockedMessage1,accountLockedMessage2);
                setWrapperByLockedErrorMessage(userLoginWrapperWithErros,errorMsg);
                
                /*List<LoginHistory> LoginHistoryObj = [SELECT Id, LoginTime, Status, UserId FROM LoginHistory WHERE UserId=:u.Id ORDER BY LoginTime DESC LIMIT 1];
                
                if(LoginHistoryObj[0].Status == 'Invalid Password'){
                    lastLogintime = LoginHistoryObj[0].LoginTime; lastLogintime = lastLogintime.addMinutes(passwordLockTimePeriod);
                    errorMsg+= accountLockedMessage1.replace('[time]',lastLogintime.format('HH:mm'));errorMsg+=accountLockedMessage2;
                }
                userLoginWrapperWithErros.setErrorMessage(errorMsg); userLoginWrapperWithErros.setWithError(true); userLoginWrapperWithErros.showModal = true; userLoginWrapperWithErros.showResetPasswordLink = true;
*/
            }
        }
        else if(loginAttempts < loginAttemptsAllowed-1){
            System.debug('## Invalid Password -- '+loginAttempts);
            setWrapperByInvalidPasswordMessage(userLoginWrapperWithErros,InvalidPassword);
            //userLoginWrapperWithErros.setErrorMessage(InvalidPassword); userLoginWrapperWithErros.setWithError(true); userLoginWrapperWithErros.showResetPasswordLink = true;
        }
        else if(loginAttempts == loginAttemptsAllowed-1){
            System.debug('## LastAttemptLeft -- '+loginAttempts);
            setWrapperByLastAttemptLeftMessage(userLoginWrapperWithErros,LastAttemptLeft);
            /*userLoginWrapperWithErros.setErrorMessage(LastAttemptLeft); 
            userLoginWrapperWithErros.setWithError(true);
            userLoginWrapperWithErros.showResetPasswordLink = true;
            userLoginWrapperWithErros.lastAttempt=true;*/
        }
        else {
            System.debug('## other Error-- '+ex.getMessage());
            userLoginWrapperWithErros.setErrorMessage(ex.getMessage());
            userLoginWrapperWithErros.setWithError(true);
        }
        return userLoginWrapperWithErros;
    } 
    
    @TestVisible
    public static CP_UserLoginWrapper successLoginActions(User u){
        CP_UserLoginWrapper userLoginWrapper = new CP_UserLoginWrapper();
        userLoginWrapper.userId = u.Id;
        
        if(u != null){
            userLoginWrapper.setWithError(false);
            System.debug('CG - in MD_LightningLoginFormController.login() method. after setSessionSettingsFields. u.Id: ' + u.Id);
        MD_UserSessionUtil.userIdlogin = u.Id;
            MD_UserSessionUtil.setSessionSettingsFields(u.Id);
            MD_UserSessionUtil.updateUserSessionSettings();
            MD_UserSessionUtil.setContactFields(true);  
            String countryCode = MD_UserSessionUtil.getDefaultCookieValue(u.Id);

            System.debug('CG - in MD_LightningLoginFormController.login() method. countryCode: ' + countryCode);

            /* harakaki - CMS integration - BEGIN */
            if(String.isNotEmpty(countryCode)) {
                List<DiageoCMS__Cluster__c> clusters = [SELECT Id FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = :countryCode LIMIT 1];
                if(clusters.size() > 0) {
                    userLoginWrapper.clusterId = clusters.get(0).Id;
                }
            }
            /* harakaki - CMS integration - END */

            AccountContactRelation accountContact = MD_UserSessionUtil.getOutletContact();
            String outletContactId = '';
            if(accountContact != null){
                outletContactId = accountContact.Id;
            }

            System.debug('CG - in MD_LightningLoginFormController.login() method. after getDefaultCookieValue. countryCode: ' + countryCode);
            
            if(String.isNotEmpty(u.Id)) {
                userLoginWrapper.userId = u.Id;
            }

            if(String.isNotEmpty(u.ContactId)) {
                userLoginWrapper.contactId = u.ContactId;
            }

            if(String.isNotEmpty(accountContact.AccountId)) {
                userLoginWrapper.outletId = accountContact.AccountId;
            }

            if(String.isNotEmpty(outletContactId)){
                userLoginWrapper.outletContactId = outletContactId;
            }

            if(String.isNotEmpty(accountContact.MD_Role__c)) {
                userLoginWrapper.outletType = accountContact.MD_Role__c;
            }

            if(String.isNotEmpty(countryCode)) {
                userLoginWrapper.countryCode = countryCode;
            }

            if(String.isNotEmpty(u.LanguageLocaleKey)) {
                userLoginWrapper.languageCode = u.LanguageLocaleKey;
            }
        }
        
        return userLoginWrapper;
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

    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

    @AuraEnabled
    public static String getForgotPasswordUrl() {Auth.AuthConfiguration authConfig = getAuthConfig();return authConfig.getForgotPasswordUrl();}

    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }

    @AuraEnabled
    public static String setExperienceId(String expId) {try {if (expId != null) {Site.setExperienceId(expId);}return null; } catch (Exception ex) {return ex.getMessage();            }}

    public class CP_UserLoginWrapper {

        public String userId{get;set;}
        public String contactId {get;set;}
        public String outletId {get;set;}
        public String outletType {get;set;}
        public String outletContactId {get;set;}
        public String clusterId {get;set;}
        public String countryCode {get;set;}
        public String languageCode {get;set;}
        public boolean showResetPasswordLink ;
        public boolean showRegistrationLink ;
        public boolean showModal ;
        public String softwareVersion {get;set;}
        public boolean lastAttempt{get;set;}

        public Boolean withError {get;set;}
        public String errorMessage {get;set;}

        public CP_UserLoginWrapper(){
            this.userId = System.UserInfo.getUserId();
            this.softwareVersion = 'v1';
        }

        public void setErrorMessage(String errorMessage){
            this.errorMessage = errorMessage;
        }
        public void setWithError(boolean withError){
            this.withError = withError;
        }
    }
    @auraEnabled
    public static void setDynamicHeight(double bannerheight,String ComponentExternalId)
    {
        //system.debug('Entered Dynamic Height Method');
        DiageoCMS__Component__c Getlogincomponent=[select DiageoCMS__ExternalId__c,DiageoCMS__CustomHeight__c from DiageoCMS__Component__c where 
                                                  DiageoCMS__ExternalId__c=:ComponentExternalId];
        Getlogincomponent.DiageoCMS__CustomHeight__c=bannerheight;
        system.debug('BannerHeight:::'+bannerheight);
        //system.debug('Getlogincomponent::::'+Getlogincomponent);
        update Getlogincomponent;
        
    }


}