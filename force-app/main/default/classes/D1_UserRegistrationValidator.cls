/**
* @name : D1_UserRegistrationValidator
* @description : Controller Class for validating user's registration request
* @history
* VERSION      AUTHOR          DATE            DETAIL
* 1.0          Sagar Barman    09/07/2020      Initial Development
* 2.0          Sagar Barman    26/09/2020      NCP-516,517
* 3.0          Kapil Baliyan   28/04/2021      NCP-2805 (updateACRReInvite, sendEmailToUser)
* 4.0          Kapil Baliyan   23/08/2021      NCP-
* 5.0          Kapil Baliyan   02/12/2021      NCP-5517 (convertUserRegistrationDetailWrapper)
* 6.0          Narayana        01/02/2022      sendEmailToUser(NCP-5931)
* 7.0          Kapil Baliyan   04/04/2022      NCP-6506
* 8.0			Subhrojit 		12/05/2022		NCP-6638
* 9.0 			Rubeena			27/05/2022		NCP-6759
* 10.0			Subhrojit		09/06/2022		NCP-6847
* 11.0         Kapil Baliyan   19/08/2022      NCP-7209
* 12.0         Mukesh/Mayukh   09/08/2023      143281 - Calculate the Channel info during D1 Registration
* 13.0         Prasanth T      10/05/2024      151942 - Introduced Subscription to Lead record.
*/
public without sharing class D1_UserRegistrationValidator {
    
    public static final String DIAGEOONE_EXTERNAL_PROFILE = 'DiageoOne External User';
    public static final String UNSUCCESSFUL_ETEMPLATE_EXISTING = 'D1_RegistrationUnsuccessful_Existing';
    public static final String REINVITE_ETEMPLATE = 'D1_ReInvite_Email_to_Customers_Registration';
    public static final String FRONTEND = 'Frontend'; 
    public static final String FRONTEND_APP = 'FrontendApp'; 
    public static final String APP_INVITED = 'AppInvited';    
    public static final String APP_SUBSCRIBED = 'AppSubscribed'; 
    public static final String BACKEND = 'Backend';
    public static final String DIAGEO_ONE = 'Diageo One';
    public static final String EDGE365 = 'EDGE 365';
    
    /**
* @description method to validate user details from Registration 
* @param userRegWrapper 
* @return  `UserValidationResultWrapper`
*/    
    @AuraEnabled
    public static UserValidationResultWrapper validateUser(D1_UserRegistrationDetailWrapper userRegWrapper) {
        string accountId = userRegWrapper.accountId;
        UserValidationResultWrapper userResultWrapper  = new UserValidationResultWrapper(); 
        if(string.isNotBlank(accountId)){
            Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, D1_Registration_Status__c, BillingCountryCode, Country_ISO_Code__c,PhonePrefix__c, Phone__c, Phone, KUNNR__c, SAP_Ship_to__c FROM Account WHERE Id =:accountId LIMIT 1];
            userRegWrapper.outletName = acc.Name != null ? acc.Name : '';
            userRegWrapper.street = acc.BillingStreet != null ? acc.BillingStreet : '';
            userRegWrapper.city = acc.BillingCity != null ? acc.BillingCity : '';
            userRegWrapper.postalCode = acc.BillingPostalCode != null ? acc.BillingPostalCode : '';
            userRegWrapper.countryCode = acc.BillingCountryCode != null ? acc.BillingCountryCode : '';
            userRegWrapper.phoneNumberPrefix = acc.PhonePrefix__c != null ? acc.PhonePrefix__c : '';
            userRegWrapper.phoneNumber = acc.Phone__c != null ? acc.Phone__c : '';
            userRegWrapper.phone = acc.Phone != null ? acc.Phone : '';
            userRegWrapper.customerSAPCode = acc.KUNNR__c != null ? acc.KUNNR__c : acc.SAP_Ship_to__c; //NCP-5517
            userRegWrapper.leadType = userRegWrapper.userType == D1_AddUserPermissionsController.DIRECTBUYER ? D1_AddUserPermissionsController.DIRECTCUSTOMERREGISTRATION : D1_AddUserPermissionsController.INDIRECTCUSTOMERREGISTRATION;
            userRegWrapper.registrationType = String.isNotBlank(acc.D1_Registration_Status__c) ? 'Secondary' : 'Primary';
            
            //NCP-6759: Removed IsActive = true Condition so that already existing user will be considered as well
            List<User> userList = [SELECT ID,Name,Email,Account.D1_Registration_Status__c, D1_User_Type_Id__c, D1_User_Type__c,IsActive FROM User WHERE  Email =: userRegWrapper.email  AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE ]; //WITH SECURITY_ENFORCED 
            //Check User Exist
            if(userList.size() > 0 && userList[0].IsActive){ //NCP-6759:Included user active check
                userResultWrapper.isSuccess = false;
                userResultWrapper.isUserExists = true;
                //send email to existing user 
                sendEmailToUser(userRegWrapper,userList[0],null);                                  
            }
            //Check User Email contains diageo.com
            else if(userRegWrapper.email.toLowerCase().contains('@diageo.com')){
                userResultWrapper.isSuccess = false;  
                //userResultWrapper.isAutomaticRegistration = true;
                userResultWrapper.isEmailDiageoDomain = true;
            }
            //Check Whether Outlet is already registered
            else if(String.isNotBlank(acc.D1_Registration_Status__c)){
                Id primaryContactId = [SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountId AND D1_User_Role__c = 'Primary' AND D1_Active__c = True LIMIT 1].ContactId;
                Contact primaryContact = [SELECT Id, FirstName, Email FROM Contact WHERE Id = :primaryContactId];
                userResultWrapper.isSuccess = false;
                userResultWrapper.isPrimaryUserExist = true;
                if (!Test.isRunningTest()) {
                    D1_UnknownOutletRegistrationController.sendEmailToPrimaryContact(userRegWrapper, primaryContact);
                }
            }else{
                List<Contact> contactList = [SELECT Id FROM Contact WHERE Email =:userRegWrapper.email];
                if(contactList.size() > 0){
                    List<AccountContactRelation> accConRelationList = [SELECT Id, ContactId, Contact.Email, Contact.MD_SubscriptionDate__c, Contact_Type__c, Account.Last_POS_Order_Date__c, Last_POS_Order_Date__c, D1_Roles__c, D1_User_Role__c,isActive FROM AccountContactRelation WHERE  IsActive = true AND accountId =:userRegWrapper.accountId AND Contact.Email =: userRegWrapper.email]; //
                    if(accConRelationList.size() > 0){
                        //assign contact id to wrapper class to proceed further
                        userRegWrapper.contactId = accConRelationList.get(0).ContactId;
                        userResultWrapper.isAutomaticRegistration = true;
                        userResultWrapper.isSuccess = true;
                        //NCP-6759: Check if user exists then activate it, else create it
                        if(userList.size() > 0 && (!userList[0].isActive)){
                            updateUser(new List<Id>{userList[0].Id});    
                        }
                        else{
                            //Create User
                            createUser(userRegWrapper, accConRelationList.get(0).ContactId);
                        }
                        //Update ACR
                        updateAccountContact(accConRelationList[0], 'Primary', userRegWrapper);
                        userRegWrapper.isSecondaryRegistration = FALSE;
                        if(userRegWrapper.subscriptionSource == FRONTEND){
                            userRegWrapper.regSource = DIAGEO_ONE;
                            updateRegistrationFields(userRegWrapper, APP_INVITED);    //NCP-2266
                        }else if(userRegWrapper.subscriptionSource == FRONTEND_APP){
                            userRegWrapper.regSource = EDGE365;
                            updateRegistrationFields(userRegWrapper, APP_INVITED); // AppInvited doubt //NCP-2266
                        }
                    }else{
                        string leadWrapper = convertUserRegistrationDetailWrapper(userRegWrapper);
                        //Create Lead
                        userResultWrapper = D1_UnknownOutletRegistrationController.createLead(leadWrapper);     
                    }
                }else{
                    string leadWrapper = convertUserRegistrationDetailWrapper(userRegWrapper);
                    //Create Lead
                    userResultWrapper = D1_UnknownOutletRegistrationController.createLead(leadWrapper);  
                }
            }
        }
        return userResultWrapper;   
    }
    
    //NCP-6759: Method to update all the users async
    @future
    public static void updateUser(List<Id> userIds){
        List<User> userList = new List<User>();
        for(Id userId: userIds){
            User userRecord = new User();
            userRecord.Id = userId;
            userRecord.IsActive = true;
            userList.add(userRecord);   
        }
        if(!userList.isEmpty()){
            update userList;
        }
        
    }
    
    /**
* @description method to send Email to user NCP-5931
* @param userRegWrapper 
* @param userDetails 
* @param conWrapper 
*/    
    @AuraEnabled
    public static void sendEmailToUser(D1_UserRegistrationDetailWrapper userRegWrapper,User userDetails,ContactWrapper conWrapper){
        if(userDetails != null ){          
            if(userDetails.Account.D1_Registration_Status__c == APP_SUBSCRIBED){
                OrgWideEmailAddress orgWideObj = [select DisplayName,Id from OrgWideEmailAddress where DisplayName = 'DiageoOne'];
                
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(userDetails.Id); 
                message.setTemplateID(getEmailTemplate(UNSUCCESSFUL_ETEMPLATE_EXISTING).Id);
                message.setOrgWideEmailAddressId(orgWideObj.Id);
                message.setUseSignature(false); 
                message.setBccSender(false); 
                message.setSaveAsActivity(false);
                
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();        
                messages.add(message);
                
                if (!Test.isRunningTest()) {
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    if (results[0].success){
                        System.debug(LoggingLevel.INFO,'The email was sent successfully.');
                    } else {
                        System.debug(LoggingLevel.ERROR, results[0].errors[0].message);
                    }
                }
            }
            else if(userDetails.Account.D1_Registration_Status__c == APP_INVITED){
                //NCP-5931
                if (!Test.isRunningTest()){
                    System.resetPasswordWithEmailTemplate(userDetails.Id, true, REINVITE_ETEMPLATE);
                }
                //Update D1 Invite Date on ACR NCP-2805
                updateACRReInvite(userRegWrapper, userDetails);
            }
        }
    }
    
    /**
* @description method to get the related email template Id
* @param templateName 
* @return  `EmailTemplate`
*/    
    @AuraEnabled
    public static EmailTemplate getEmailTemplate(String templateName){
        EmailTemplate emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                       FROM EmailTemplate WHERE NAME =: templateName ]; //WITH SECURITY_ENFORCED
        return emailTemplate;                              
    }
    
    /**
* @description method to get the related email Profile Id
* @param profileName 
* @return  `Id`
*/    
    @AuraEnabled
    public static Id getProfileId(String profileName){
        Profile userProfile = [SELECT Id FROM Profile WHERE NAME =: profileName]; // WITH SECURITY_ENFORCED
        return userProfile.Id;                              
    }
    
    /**
* @description method to create user 
* @param userRegWrapper 
* @param contactId 
*/    
    @AuraEnabled
    public static void createUser(D1_UserRegistrationDetailWrapper userRegWrapper,Id contactId){
        User u = new user();
        u.FirstName = userRegWrapper.firstName;
        u.LastName = userRegWrapper.lastName;
        u.Email = userRegWrapper.email;      
        if(userRegWrapper.lastName.length()>3){
            String tempstring = userRegWrapper.firstName.substring(0,1) + userRegWrapper.lastName.substring(0,4);
            u.Alias = tempstring;
            u.CommunityNickname = tempstring+String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3)+'d1'+String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3);
        }else{
            String tempstring = userRegWrapper.firstName.substring(0,1) + userRegWrapper.lastName.substring(0,1);
            u.Alias = tempstring; 
            u.CommunityNickname = tempstring+String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3)+'d1'+String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3);   
        }  
        u.Username = userRegWrapper.email;    
        u.ContactId = contactId;        
        u.ProfileID = getProfileId(DIAGEOONE_EXTERNAL_PROFILE);
        //call getUserLocaleSetting to get country wise User locale settings
        D1_User_Locale_Settings__mdt userLocaleSetting = getUserLocaleSetting(userRegWrapper.userCountryCode, userRegWrapper.languageLocaleKey); //NCP-6212
        u.LocaleSidKey = userLocaleSetting!=null ? userLocaleSetting.LocaleSidKey__c : '' ;
        u.TimeZoneSidKey = userLocaleSetting!=null ? userLocaleSetting.TimeZoneSidKey__c : '';        
        u.LanguageLocaleKey = userRegWrapper.languageLocaleKey;
        u.EmailEncodingKey = 'UTF-8';        
        u.Mobile_Prefix__c = userRegWrapper.mobileCountryCode;
        u.Mobile_Number__c = userRegWrapper.mobile;
        u.MobilePhone = userRegWrapper.mobileCountryCode + userRegWrapper.mobile;
        //Code Refactor Done by Kapil NCP-6506
        u.D1_User_Type__c = userRegWrapper.userType;
        u.D1_User_Type_Id__c = userRegWrapper.userTypeId;
        u.Available_Countries__c = userRegWrapper.userCountryCode;
        
        D1_User_Type__c d1UserType = getD1UserTypeById(userRegWrapper.userTypeId);
        if(null != d1UserType){    
            u.D1_UserType_CSG_Email__c = d1UserType.Customer_Service_Group__c;
        }
        if(Schema.sObjectType.User.isCreateable() && !Test.isRunningTest()){
            insert u;
        }
        
    }
    
    /**
* NCP-6212
* @description method is for getting D1 User Locale Setting
* @param countryCode 
* @return  `D1_User_Locale_Settings__mdt`
*/    
    public static D1_User_Locale_Settings__mdt getUserLocaleSetting(String countryCode, String language){       
        D1_User_Locale_Settings__mdt userLocaleSettings;
        if( !Test.isRunningTest() ){
            userLocaleSettings = [SELECT Country_Code__c,LocaleSidKey__c,TimeZoneSidKey__c
                                  FROM D1_User_Locale_Settings__mdt WHERE Country_Code__c =:countryCode AND LanguageLocaleKey__c = :language]; 
        }else{
            userLocaleSettings = new D1_User_Locale_Settings__mdt();
        }
        return userLocaleSettings;
    } 
    
    /**	
* @description method is for getting D1 User Type	
* @param contryCode 	
* @param userType 	
* @return  `D1_User_Type__c`	
*/    	
    public static D1_User_Type__c getD1UserType(String d1SettingId, String userType, String outletChannel){
        D1_User_Type__c availableUserType = new D1_User_Type__c();
        List<D1_User_Type__c> availableUserTypeList = [SELECT D1_Setting__c,Id,Name,User_Type__c,D1_Setting__r.Market__c,Customer_Service_Group__c,Channel__c //143281
                                                       FROM D1_User_Type__c where D1_Setting__c =:d1SettingId AND User_Type__c =:userType]; //NCP-6506: Change Method Parameter from CountryCode to D1SettingId	
        //143281
        for(D1_User_Type__c usrType : availableUserTypeList){
            if(usrType.Channel__c != Null && usrType.Channel__c == outletChannel){
                availableUserType = usrType;
                break;
            }	
            else{
                availableUserType = usrType;
            }
        }
        /*if(availableUserType!=null){
return availableUserType;
}*/
        return availableUserType;
    }
    
    /**
* @description method is for getting D1 User Type by Id
* @param Uid 
* @return  `D1_User_Type__c`
*/    
    public static D1_User_Type__c getD1UserTypeById(Id uId){
        List<D1_User_Type__c> availableUserType = [SELECT D1_Setting__c,Id,Name,User_Type__c,D1_Setting__r.Market__c,Customer_Service_Group__c 
                                                   FROM D1_User_Type__c WHERE Id =:uId];
        if(availableUserType.size()>0){
            return availableUserType[0];
        }
        return null;
    }
    
    /**
* @description method is for Update accountContact method
* @param accountContactReln 
* @param role 
* @param userRegWrapper 
*/    
    public static void updateAccountContact(AccountContactRelation accountContactReln, String role, D1_UserRegistrationDetailWrapper userRegWrapper ){
        accountContactReln.D1_Active__c = true;
        accountContactReln.D1_User_Role__c = role;
        accountContactReln.D1_Roles__c = getUserRoles(userRegWrapper);// changes for NCP-925
        
        //NCP-6847
        if(userRegWrapper.subscriptionSource == FRONTEND)
        {
            if(accountContactReln.D1_Roles__c.contains('POS & Equipment Ordering'))
            {
                if(accountContactReln.Account.Last_POS_Order_Date__c != null)
                {
                    accountContactReln.Last_POS_Order_Date__c = accountContactReln.Account.Last_POS_Order_Date__c;
                }
                else
                {
                    accountContactReln.Last_POS_Order_Date__c = System.now(); 
                }  
            }
        }
        update accountContactReln;
    }
    
    /**
* @description getD1Setting
* @param countryCode 
* @return  `String`
*/    
    public static D1_Setting__c getD1Setting(String countryCode, String language){
        //NCP-6506 : Code Refactor done by Kapil
        List<D1_Setting__c> d1Settings = new List<D1_Setting__c>();
        if(String.isNotBlank(language)){
            d1Settings = [SELECT Id, Language__c, Default__c, Market__c FROM D1_Setting__c WHERE Market__r.Code__c =:countryCode AND Language__c =:language];
        }else{
            d1Settings = [SELECT Id, Language__c, Default__c, Market__c FROM D1_Setting__c WHERE Market__r.Code__c =:countryCode AND Default__c = true];
        }
        
        if(d1Settings != null && d1Settings.size()>0){
            return d1Settings.get(0);
        }else{
            return null;
        }
    }
    
    /**
* @description method to update all fields related to registration
* @param userRegWrapper 
* @param regStatus 
* @param regSource 
* @param d1 
*/    
    public static void updateRegistrationFields(D1_UserRegistrationDetailWrapper userRegWrapper, String regStatus){
        Account account = new Account(Id=userRegWrapper.accountId,D1_Registration_Status__c = regStatus);//NCP-1827
        update account;
        
        //Code Refactor Done by Kapil - NCP-6506
        D1_RegistrationUtility.updateRegisteredContact(userRegWrapper.contactId, userRegWrapper); //NCP-7209
    }
    
    /**
* @description method id used to create the case
* @param caseWrap 
* @return  `UserValidationResultWrapper`
*/    
    @AuraEnabled
    public static UserValidationResultWrapper createCase(D1_UserRegistrationDetailWrapper caseWrap){
        string accountId = caseWrap.accountId;
        Account acc = new Account();
        UserValidationResultWrapper userResWrapper  = new UserValidationResultWrapper(); 
        
        if(string.isNotBlank(accountId)){
            acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, D1_Registration_Status__c, BillingCountryCode, Country_ISO_Code__c,PhonePrefix__c, Phone__c, Phone, KUNNR__c, SAP_Ship_to__c FROM Account WHERE Id =:accountId LIMIT 1];
            caseWrap.outletName = acc.Name != null ? acc.Name : '';
            caseWrap.street = acc.BillingStreet != null ? acc.BillingStreet : '';
            caseWrap.city = acc.BillingCity != null ? acc.BillingCity : '';
            caseWrap.postalCode = acc.BillingPostalCode != null ? acc.BillingPostalCode : '';
            caseWrap.countryCode = acc.BillingCountryCode != null ? acc.BillingCountryCode : '';
            caseWrap.phoneNumberPrefix = acc.PhonePrefix__c != null ? acc.PhonePrefix__c : '';
            caseWrap.phoneNumber = acc.Phone__c != null ? acc.Phone__c : '';
            caseWrap.phone = acc.Phone != null ? acc.Phone : '';
            caseWrap.customerSAPCode = acc.KUNNR__c != null ? acc.KUNNR__c : acc.SAP_Ship_to__c; //NCP-5517
            caseWrap.leadType = caseWrap.userType == D1_AddUserPermissionsController.DIRECTBUYER ? D1_AddUserPermissionsController.DIRECTCUSTOMERREGISTRATION : D1_AddUserPermissionsController.INDIRECTCUSTOMERREGISTRATION; //NCP-5517
            caseWrap.registrationType = String.isNotBlank(acc.D1_Registration_Status__c) ? 'Secondary' : 'Primary';
        }
        
        List<User> userList = [SELECT ID,Name,Email,Account.D1_Registration_Status__c, D1_User_Type_Id__c, D1_User_Type__c FROM User WHERE Email =: caseWrap.email AND isActive = true AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE ]; //WITH SECURITY_ENFORCED
        //Check User Exist
        if(userList.size() > 0){
            userResWrapper.isSuccess = false;
            userResWrapper.isUserExists = true;
            //send email to existing user 
            sendEmailToUser(caseWrap,userList[0],null);                 
        }
        //Check User Email contains diageo.com
        else if(caseWrap.email.toLowerCase().contains('@diageo.com')){
            userResWrapper.isSuccess = false;  
            //userResultWrapper.isAutomaticRegistration = true;
            userResWrapper.isEmailDiageoDomain = true;
        }else if(!String.isBlank(acc.D1_Registration_Status__c)){
            Id primaryContactId = [SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountId AND D1_User_Role__c = 'Primary' AND D1_Active__c = True LIMIT 1].ContactId;
            Contact primaryContact = [SELECT Id, FirstName, Email FROM Contact WHERE Id = :primaryContactId];
            userResWrapper.isSuccess = false;
            userResWrapper.isPrimaryUserExist = true;
            if (!Test.isRunningTest()) {
                D1_UnknownOutletRegistrationController.sendEmailToPrimaryContact(caseWrap, primaryContact);
            }
        }else{        
            string leadWrap = convertUserRegistrationDetailWrapper(caseWrap);
            //Create Lead
            userResWrapper = D1_UnknownOutletRegistrationController.createLead(leadWrap);
        }    
        return userResWrapper; 
    }
    
    public static List<Contact> getContact(String email,Id accountId){
        List<Contact> contactList = [SELECT Id,Name,FirstName,LastName,Mobile__c,Email,AccountId from Contact where Email=:email and AccountId =:accountId];
        return  contactList;
    }
    
    /**
* @userStory NCP-3485
* @description Get D1 User Roles 
* @param userRegWrapp 
* @return  `String`
*/    
    public static String getUserRoles(D1_UserRegistrationDetailWrapper userRegWrapp){
        Set<string> roleAccessType = new Set<string>();
        for(D1_User_Types_Role__c utr: [SELECT Id, D1_User_Type__c, D1_User_Role__c, Name,D1_User_Role__r.Name,D1_User_Role__r.Access_Type__c,D1_User_Role__r.IsDefault__c,Description__c,Display_Name__c FROM D1_User_Types_Role__c 
                                        WHERE D1_User_Type__c = : userRegWrapp.userTypeId  AND D1_User_Role__r.Access_Type__c Not in ('My Contracts','Contract Management')]){
                                            roleAccessType.add(utr.D1_User_Role__r.Access_Type__c);
                                        }
        
        //NCP-2805 : If EDGE is sending permission from mobile than based on what we receive either we need to remove the permission or include
        if(userRegWrapp.permissionList != null && !userRegWrapp.permissionList.isEmpty()){
            for(MD_RegistrationREST.RegistrationPermissionInputs permission : userRegWrapp.permissionList){
                if(permission.accessLevel){
                    roleAccessType.add(permission.permissionName);
                }else{
                    if(roleAccessType.contains(permission.permissionName)){
                        roleAccessType.remove(permission.permissionName);
                    }
                }
            }
        }
        List<String> roleAccessTypeList = new List<String>(roleAccessType);
        string allRoles = String.join(roleAccessTypeList,';');
        return allRoles;
    }
    
    /**
* @userStory NCP-1979
* @description getD1SettingsByCountry
* @param country 
* @param language 
* @return  `D1_Setting__c`
*/    
    @AuraEnabled(cacheable = true)
    public static D1_Setting__c getD1SettingsByCountry(String country, string language) {
        List<D1_Setting__c> d1SettingList = new List<D1_Setting__c>();
        if(string.isNotBlank(country) && string.isNotBlank(language)){
            d1SettingList = [SELECT Id, UIN_Field__c, UIN_Label__c, UIN_Setting__c, 
                             Hide_Registration_First_Screen__c,CS_Notification_email__c, Contact_Us_Email__c,Enable_Survey_Preference__c,
                             Geo_Area_Label__c, Geo_Region_Label__c, Postal_Code_Setting__c,Enable_Push_Notification__c
                             FROM D1_Setting__c 
                             WHERE Market__r.Code__c =:country AND Language__c =:language LIMIT 1];
        }
        
        return d1SettingList.isEmpty() ? null : d1SettingList.get(0);
    }
    /**
* @userStory NCP-2805
* @description updateACRReInvite
* @param userRegWrapper 
* @param userDetails 
*/    
    public static void updateACRReInvite(D1_UserRegistrationDetailWrapper userRegWrapper, User userDetails){
        List<Contact>contactList = [select D1_Login_Reminder_Status__c, D1_Invite_sent__c from Contact where Email =:userRegWrapper.email];//NCP-6112
        if(contactList.size()>0)
        {
            contactList.get(0).D1_Login_Reminder_Status__c ='Invite Resent' ;//NCP-6112
            contactList.get(0).D1_Invite_sent__c =Date.Today();//NCP-6112
            update contactList;
        } 
        List<AccountContactRelation> accConRelationList = [SELECT Id, ContactId, Contact.Email, Contact_Type__c, D1_Roles__c, D1_User_Role__c
                                                           FROM AccountContactRelation WHERE IsActive = true
                                                           AND accountId =:userRegWrapper.accountId
                                                           AND Contact.Email =: userRegWrapper.email]; //WITH SECURITY_ENFORCED                                                                                                                                                                     
        if(accConRelationList.size()>0){
            //Update userRegWrapper to include userTypeId
            userRegWrapper.userTypeId = userDetails.D1_User_Type_Id__c;
            
            //Update ACR
            AccountContactRelation accountContactReln = new AccountContactRelation();
            accountContactReln.Id = accConRelationList[0].Id;
            accountContactReln.D1_Roles__c = getUserRoles(userRegWrapper);
            update accountContactReln;
        }
    }
    
    //Method to convert D1_UserRegistrationDetailWrapper to LeadWrapper
    public static string convertUserRegistrationDetailWrapper(D1_UserRegistrationDetailWrapper userRegWrapper){
        Map<string, string> leadWrapperMap = new Map<string, string>();
        leadWrapperMap.put('outletName', userRegWrapper.outletName);
        leadWrapperMap.put('street', userRegWrapper.street);
        leadWrapperMap.put('city', userRegWrapper.city);
        leadWrapperMap.put('postalCode', userRegWrapper.postalCode);
        leadWrapperMap.put('countryCode', userRegWrapper.countryCode);
        leadWrapperMap.put('countryISOCode', userRegWrapper.userCountryCode);
        leadWrapperMap.put('phoneNumberPrefix', userRegWrapper.phoneNumberPrefix);
        leadWrapperMap.put('phoneNumber', userRegWrapper.phoneNumber);
        leadWrapperMap.put('phone', userRegWrapper.phone);
        leadWrapperMap.put('firstName', userRegWrapper.firstName);
        leadWrapperMap.put('lastName', userRegWrapper.lastName);
        leadWrapperMap.put('email', userRegWrapper.email);
        leadWrapperMap.put('outletRole', userRegWrapper.outletRole);
        leadWrapperMap.put('mobileNumberPrefix', userRegWrapper.mobileCountryCode);
        leadWrapperMap.put('mobileNumber', userRegWrapper.mobile);
        leadWrapperMap.put('mobile', userRegWrapper.mobileCountryCode + userRegWrapper.mobile);
        leadWrapperMap.put('registrationType', userRegWrapper.registrationType);
        leadWrapperMap.put('uin',userRegWrapper.uin);
        leadWrapperMap.put('description',userRegWrapper.description != null ? userRegWrapper.description : '');
        leadWrapperMap.put('customerSAPCode',userRegWrapper.customerSAPCode != null ? userRegWrapper.customerSAPCode : ''); //NCP-5517
        leadWrapperMap.put('leadType',userRegWrapper.leadType != null ? userRegWrapper.leadType : ''); //NCP-5517
        leadWrapperMap.put('language',userRegWrapper.languageLocaleKey);//NCP-6212
        leadWrapperMap.put('subscription',userRegWrapper.subscriptionValue);//151942
        
        string leadWrapper = JSON.serialize(leadWrapperMap);
        return leadWrapper;
    }
    
    /**Wrapper Classes */
    public class UserValidationResultWrapper{
        @AuraEnabled public Boolean isSuccess;
        @AuraEnabled public Boolean isUserExists;
        @AuraEnabled public Boolean isNoPrimaryContact;
        @AuraEnabled public Boolean isManualRegistration;
        @AuraEnabled public Boolean isAutomaticRegistration;
        @AuraEnabled public Boolean isEmailDiageoDomain;//NCP-2273
        @AuraEnabled public String caseId;//NCP-2367
        @AuraEnabled public String leadId;
        @AuraEnabled public Boolean isUnknownOutletSuccess;
        @AuraEnabled public Boolean isUnknownOutletDuplicate;
        @AuraEnabled public Boolean isPrimaryUserExist;
    }  
    public class ContactWrapper{
        public Id contactId;
        public String firstName;
        public String lastName;
        public String mobile;
        public String email;
        public String accountName;
        public string accountAddress;
    }      
}