/*
* @name: D1_MyProfileController
* @discription: D1_MyProfileController Class for My Profile page 
* @history
* VERSION     AUTHOR           DATE         DETAIL
* 1.0         Ajay            10/6/20       Initial Development(NCP-582, NCP-583)
* 2.0         Kapil Baliyan   01/03/2022    NCP-6210 ()
* 3.0         Prasanth        13/7/2023    	Push Notification(142507)-Introduced Push notification in Contact Subscription
* 4.0         Prasanth        11/9/2023     Role Field in My Profile Page(144526)
*/
public without sharing class D1_MyProfileController {
    final static String EMAIL ='Email';
    final static String PHONE = 'Phone';
    final static String SMS = 'SMS';
    final static String SURVEY = 'Survey';
    final static String PUSHNOTI = 'Push Notification';
    
    public class ProfileWrapper{
        @AuraEnabled public String firstName{get;set;}
        @AuraEnabled public String lastName{get;set;}
        @AuraEnabled public String emailId{get;set;}
        @AuraEnabled public String mobilePrefix{get;set;}
        @AuraEnabled public String mobileNumber{get;set;}
        @AuraEnabled public String availableCountries{get;set;}
        @AuraEnabled public String contactId{get;set;}
        @AuraEnabled public Boolean isEmailSubscribed{get;set;}
        @AuraEnabled public Boolean isPhoneSubscribed{get;set;}
        @AuraEnabled public Boolean isSMSSubscribed{get;set;}
        @AuraEnabled public Boolean isSurveySubscribed{get;set;}
        @AuraEnabled public Boolean isPushNotiSubscribed{get;set;}
        @AuraEnabled public String languageCode{get;set;}
        @AuraEnabled public String languageName{get;set;}
        @AuraEnabled public List<ProfileLanguageWrapper> applicableLanguages{get;set;}
        @AuraEnabled public String d1SettingId{get;set;}
        @AuraEnabled public String d1UserTypeId{get;set;}
        @AuraEnabled public String localeKey {get; set;} //NCP-6210
        @AuraEnabled public String outletRole{get;set;}//144526

        public void setSubscription(String allSubscriptionString){
            allSubscriptionString = allSubscriptionString == NULL ? '': allSubscriptionString;
            
            isEmailSubscribed = false;
            isPhoneSubscribed = false;
            isSMSSubscribed = false;
            isSurveySubscribed = false;
            isPushNotiSubscribed = false;
            
            for (String value : allSubscriptionString.split(';')) {
                if(value == EMAIL){
                    isEmailSubscribed = true;
                }else if(value == PHONE){
                    isPhoneSubscribed = true;
                }else if(value == SMS){
                    isSMSSubscribed = true;
                }else if(value == SURVEY){
                    isSurveySubscribed = true;
                }else if(value == PUSHNOTI){
                    isPushNotiSubscribed = true;
                }
            }
        }
        
        public String getSubscriptionString(){
            String resultString ='';
            
            if(isEmailSubscribed == true){
                resultString += ';' + EMAIL;
            }
            if(isPhoneSubscribed == true){
                resultString += ';' + PHONE;
            }
            if(isSMSSubscribed == true){
                resultString += ';' + SMS;
            }
            if(isSurveySubscribed == true){
                resultString += ';' + SURVEY;
            }
            if(isPushNotiSubscribed == true){
                resultString += ';' + PUSHNOTI;
            }
            resultString = resultString.removeStart(';');
            return String.isBlank(resultString) ? NULL : resultString;
        }
    }
    
    public class ProfileLanguageWrapper{
        @AuraEnabled public String languageName{get;set;}
        @AuraEnabled public String languageCode{get;set;}
        @AuraEnabled public String userTypeId{get;set;}
        @AuraEnabled public String d1SettingId{get;set;}
        @AuraEnabled public String localeKey {get;set;} //NCP-6210
        public ProfileLanguageWrapper(String languageName, String languageCode, String userTypeId, String d1SettingId, String localeKey){
            this.languageName = languageName;
            this.languageCode = languageCode;
            this.userTypeId = userTypeId;
            this.d1SettingId = d1SettingId;
            this.localeKey = localeKey; //NCP-6210
        }
    }

    /*  
    * @userstory: NCP-582
    * @discription: Fetch profile Details
    * @Param:Nil
    * @Return: ProfileWrapper Object
    * @Throws: AuraHandledException if any exception   
    */
    //144526
    @AuraEnabled
    public static Object getProfileDetails(){
        List<User> users = [SELECT Id, FirstName, LastName, Email, Mobile_Number__c, LanguageLocaleKey, LocaleSidKey, D1_User_Type_Id__c,
                            Mobile_Prefix__c, Available_Countries__c, ContactId, Contact.MD_ContactSubscriptions__c, toLabel(Contact.MD_CurrentRole__c)  
                            FROM User
                            WHERE Id=:UserInfo.getUserId()];
        if(users.isEmpty() == true){
            throw new AuraHandledException('Access Denied, User Cant access user object');
        }
        
        User currentUser = users[0];
        ProfileWrapper resultObj = new ProfileWrapper();
        resultObj.firstName = currentUser.firstName;
        resultObj.lastName = currentUser.lastName;
        resultObj.emailId = currentUser.Email;
        resultObj.mobilePrefix = currentUser.Mobile_Prefix__c;
        resultObj.mobileNumber = currentUser.Mobile_Number__c;
        resultObj.availableCountries = currentUser.Available_Countries__c;
        resultObj.contactId = currentUser.contactId;
        resultObj.setSubscription(currentUser.Contact.MD_ContactSubscriptions__c);
        resultObj.localeKey = currentUser.LocaleSidKey; //NCP-6210
        resultObj.outletRole = currentUser.Contact.MD_CurrentRole__c;//144526

        //NCP-6210 : Get locale Settings 
        Map<String, D1_User_Locale_Settings__mdt> localeMap = new Map<String, D1_User_Locale_Settings__mdt>();
        for(D1_User_Locale_Settings__mdt userLocaleSettings : [SELECT Country_Code__c,LocaleSidKey__c,LanguageLocaleKey__c,TimeZoneSidKey__c FROM D1_User_Locale_Settings__mdt 
                                                                WHERE Country_Code__c =:currentUser.Available_Countries__c])
        {
            localeMap.put(userLocaleSettings.LanguageLocaleKey__c, userLocaleSettings);
        }
        
        //changes for NCP-5687
        Contact conRec = [SELECT Id, D1_User_Type__r.User_Type__c, D1_Setting__c, D1_Setting__r.Market__c,toLabel(Contact.MD_CurrentRole__c) FROM Contact WHERE Id = :currentUser.contactId LIMIT 1];

        Map<String,String> langCodeLangNameMap = new Map<String,String>();
		for(Schema.PicklistEntry pickListVal : D1_Setting__c.Language__c.getDescribe().getPicklistValues() ){
			langCodeLangNameMap.put(pickListVal.getValue(), pickListVal.getLabel());
		}

        List<D1_User_Type__c> d1UserTypeList = [SELECT Id, D1_Setting__c, D1_Setting__r.Language__c FROM D1_User_Type__c WHERE User_Type__c = :conRec.D1_User_Type__r.User_Type__c 
                                                AND D1_Setting__r.Market__c = :conRec.D1_Setting__r.Market__c ORDER BY D1_Setting__r.Language__c ASC];

        Set<String> applicableLanguageCodes = new Set<String>();
        List<ProfileLanguageWrapper> applicableLanguages = new List<ProfileLanguageWrapper>();
        for(D1_User_Type__c userType : d1UserTypeList){
            string language = userType.D1_Setting__r.Language__c;
            string locale = localeMap.containsKey(language) ? localeMap.get(language).LocaleSidKey__c : currentUser.LocaleSidKey;
            applicableLanguages.add(new ProfileLanguageWrapper(langCodeLangNameMap.get(language), language, userType.Id, userType.D1_Setting__c, locale));
            applicableLanguageCodes.add(language);

            if(language == currentUser.LanguageLocaleKey){
                resultObj.languageCode = language;
                resultObj.languageName = langCodeLangNameMap.get(language);
            }
        }

        if(!applicableLanguageCodes.contains(currentUser.LanguageLocaleKey) && langCodeLangNameMap.containsKey(currentUser.LanguageLocaleKey)){
            applicableLanguages.add( new ProfileLanguageWrapper(langCodeLangNameMap.get(currentUser.LanguageLocaleKey), currentUser.LanguageLocaleKey, currentUser.D1_User_Type_Id__c, conRec.D1_Setting__c, currentUser.LocaleSidKey));
            resultObj.languageCode = currentUser.LanguageLocaleKey;
            resultObj.languageName = langCodeLangNameMap.get(currentUser.LanguageLocaleKey);
        }

        resultObj.applicableLanguages = applicableLanguages;
        return resultObj;
    }

    /*******************************************************************  
    * @userstory: NCP-582
    * @discription:  Update profile Details
    * @Param: JOSN ProfileWrapper Object
    * @Returns: true / Exception if any error
    * @Throws: AuraHandledException if any exception   
    */
    @AuraEnabled
    public static Boolean updateProfileDetails(String jsonProfileWrapper){
        try {
            ProfileWrapper profileObj = (ProfileWrapper)JSON.deserialize(jsonProfileWrapper, ProfileWrapper.class);
            updateUser(profileObj);
            updateRelatedContact(profileObj);
        } catch (Exception ex) {
            throw new AuraHandledException('Something Went wrong, Profile updation failed:' + ex.getMessage() );
        }
        return true;
    }

    /*  
    * @userstory: NCP-582
    * @discription:  Update User Object
    * @Param: ProfileWrapper Object
    * @Return: Nil
    * @Throws: Nil
    */
    private static void updateUser(ProfileWrapper profileObj){
        User userObj = new User(Id = UserInfo.getUserId());
        userObj.firstName = profileObj.firstName;
        userObj.lastName = profileObj.lastName;
        userObj.LanguageLocaleKey = profileObj.languageCode;//NCP-5687
        userObj.D1_User_Type_Id__c = profileObj.d1UserTypeId;//NCP-5687
        userObj.LocaleSidKey = profileObj.localeKey; //NCP-6210
        
        setUserMobileNumber(userObj, profileObj);
        
        update userObj;
    }

    /*  
    * @userstory: NCP-582
    * @discription:  Update Contact Object
    * @Param: ProfileWrapper Object
    * @Returns: Nil
    * @Throws: Nil
    */    
    private static void updateRelatedContact(ProfileWrapper profileObj){
        Contact contact = new Contact(Id=profileObj.contactId);
        contact.MD_ContactSubscriptions__c = profileObj.getSubscriptionString();
        contact.firstName = profileObj.firstName;
        contact.lastName = profileObj.lastName;
        contact.D1_Setting__c = profileObj.d1SettingId;//NCP-5687
        contact.D1_User_Type__c = profileObj.d1UserTypeId;//NCP-5687
        contact.Preferred_Language__c = profileObj.languageCode; //NCP-6210
        contact.MD_CurrentRole__c = profileObj.outletRole;//144526
        setContactMobileNumber(contact,profileObj);
        
        update contact;
    }

    /*  
    * @userstory: NCP-582
    * @discription:  Set User Mobile Number
    * @Param: User Object, ProfileWrapper Object
    * @Returns: Nil
    * @Throws: Nil
    */    
    private static User setUserMobileNumber(User target, ProfileWrapper source){
        target.Mobile_Prefix__c = null;
        target.Mobile_Number__c = null;
        target.mobilePhone = null;
        
        if(!String.isBlank(source.mobilePrefix) && !String.isBlank(source.mobileNumber)){
            target.Mobile_Prefix__c = source.mobilePrefix;
            target.Mobile_Number__c = source.mobileNumber;
            target.mobilePhone = source.mobilePrefix + source.mobileNumber;
        }
        return target;
    }

    /*  
    * @userstory: NCP-582
    * @discription:  Set Contact Mobile Number
    * @Param: Contact Object, ProfileWrapper Object
    * @Returns: Nil
    * @Throws: Nil
    */ 
    private static Contact setContactMobileNumber(Contact target, ProfileWrapper source){
        target.MobilePrefix__c = null;
        target.Mobile__c = null;
        target.MobilePhone = null;
        
        if(!String.isBlank(source.mobilePrefix) && !String.isBlank(source.mobileNumber)){
            target.MobilePrefix__c = source.mobilePrefix;
            target.Mobile__c = source.mobileNumber;
            target.MobilePhone = source.mobilePrefix + source.mobileNumber;
        }
        return target;
    }
    
    /*  
    * @userstory: NCP-584 || NCP-727
    * @discription :  Controller for changing password of Use
    * @Param: oldPassword,newPassword,verifyNewPassword
    * @Returns: Boolean
    * @Throws: Nil   
    */
    @AuraEnabled
    public static Boolean changeUserPassword(String oldPassword,String newPassword,String verifyNewPassword){
        
        pageReference pr;
        Boolean success = false;
        
        if(oldPassword !=Null && oldPassword !='' && newPassword !=Null && newPassword !='' && verifyNewPassword !=Null && verifyNewPassword !=''){
            pr = Site.changePassword(newPassword, verifyNewPassword, oldPassword);
            if(pr != null){
                success = true;
                sendEmail('D1_PasswordChangedMail');
            }else {
                success = false;
            }
        }
        
        return success;
    }

    public static void sendEmail(String templateName){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTemplateID(getEmailTemplate(templateName).Id);
        message.setTargetObjectId(userInfo.getUserId()); 
        message.setUseSignature(false); 
        message.setBccSender(false); 
        message.setSaveAsActivity(false);
        OrgWideEmailAddress orgWideObj = [select DisplayName,Id from OrgWideEmailAddress where DisplayName = 'DiageoOne'];
        message.setOrgWideEmailAddressId(orgWideObj.Id);          
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) 
        {
            System.debug(LoggingLevel.INFO, 'The email was sent successfully.');
        } else {
            System.debug(LoggingLevel.ERROR, results[0].errors[0].message);
        }
    }

    public static EmailTemplate getEmailTemplate(String templateName){
        EmailTemplate emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                       FROM EmailTemplate WHERE NAME =: templateName ]; //WITH SECURITY_ENFORCED
        return emailTemplate;                              
    }
}