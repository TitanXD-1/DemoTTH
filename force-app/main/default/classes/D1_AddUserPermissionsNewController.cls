/**
 * @name
 * @description
 * @history
 * VERSION          AUTHOR                      DATE            DETAIL 
 * 1.0              Syed Ali                    16/12/2022      NCP-7681
 * 1.1              Subhrojit                   24/12/2022      NCP-7668(getAutoPermissions)
 * 1.2              Pratap                      01/02/2023      NCP-7927(getAutoPermissions)
 * 1.3				Prasanth T					11/08/2023		143257(UserType decision based on Channel)
 */
public without sharing class D1_AddUserPermissionsNewController{

    public static final String DIAGEOONE_EXTERNAL_PROFILE = 'DiageoOne External User'; 
    public static string effectiveAccountId; //NCP-5077
    public static final string DIRECTBUYER = 'Direct Buyer';
    public static final string INDIRECTBUYER = 'Outlet/Retailers';
    public static final String APPINVITED = 'AppInvited';
    public static final string USERMANAGEMENT = 'User Management';
    public static final String PRIMARY = 'Primary';
    public static final String MEMBEROFSTAFF = 'Member Of Staff';
    public static final String MANAGEPARTNERPLUS = Label.D1_ManagePartnerPlusVal;
 
    /**
    * @description : NCP-7665 : Fetch Partner Plus Reg details from Account
    * @param : {String} userTypeId, {Set<Id>} accIdSet
    * @return : {Map<Id,Account>}
    */
    public static Map<Id,Account> getPartnerEnableStatus(String userTypeId, Set<Id> accIdSet){
        Map<Id,Account> accMap = new Map<Id,Account>();
        Boolean partnerEnbled = [SELECT D1_Setting__r.Partner_Plus_Enabled__c FROM D1_User_Type__c WHERE Id =: userTypeId LIMIT 1].D1_Setting__r.Partner_Plus_Enabled__c;
        if(partnerEnbled){
            accMap = new Map<Id,Account>([SELECT Id,Partner_Plus_Enabled__c FROM Account WHERE Id IN: accIdSet]);
        }
        return accMap;
    }
    
    /**
    * @description : NCP-7668 : Query all autoassigned permissions wrt d1usertypeId 
    *                NCP-7927 : facilitating AutoAssigned permissions for both primary & secondary contact
    * @param : {String} userTypeId
	* @return : `Map<String,Sring>`
    */
    public static Map<String,String> getAutoPermissions(String userTypeId){
        Set<String> autoPermsForPrimary = new Set<String>();
        Set<String> autoPermsForSecondary = new Set<String>();
        Map<String,String> autoPerms = new Map<String,String>();

        for(D1_User_Types_Role__c usrTypeRole : [SELECT Id,D1_User_Role__r.Access_Type__c, D1_User_Role__r.Autoassignment__c, 
                                                 D1_User_Role__r.Autoassignment_for_Secondary_Contact__c
                                                 FROM D1_User_Types_Role__c
                                                 WHERE D1_User_Type__c =: userTypeId
                                                 AND (D1_User_Role__r.Autoassignment__c = true OR D1_User_Role__r.Autoassignment_for_Secondary_Contact__c = true)])
        {
            if(usrTypeRole.D1_User_Role__r.Autoassignment__c == true){
                autoPermsForPrimary.add(usrTypeRole.D1_User_Role__r.Access_Type__c);
            }
            if(usrTypeRole.D1_User_Role__r.Autoassignment_for_Secondary_Contact__c == true){
                autoPermsForSecondary.add(usrTypeRole.D1_User_Role__r.Access_Type__c);
            }
            
        }
        if(!autoPermsForPrimary.isEmpty()){
            autoPerms.put(PRIMARY, String.join(new List<String>(autoPermsForPrimary),';'));
        }
        if(!autoPermsForSecondary.isEmpty()){
            autoPerms.put(MEMBEROFSTAFF, String.join(new List<String>(autoPermsForSecondary),';'));
        }
        return autoPerms;
    }
    
    //NCP-5931
    public static Map<String,String> checkUserForResendInvite(string contactId){
        Boolean isActiveUser = false;
        Map<String,String> resultMap = new Map<String,String>();
        List<User> usrList = [SELECT Id, IsActive, ContactId,FirstName,Username,Contact.MD_SubscriptionDate__c,
                                Contact.D1_Contact_Last_Login_Date__c,Contact.D1_Invite_sent__c,Contact.D1_Login_Reminder_Status__c
                                 FROM User WHERE ContactId  =:contactId AND IsActive = true AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE];
        if(usrList != null && usrList.size()>0){
            isActiveUser = usrList.get(0).IsActive;
            if(isActiveUser){
                resultMap.put('isUserActive','true');
                resultMap.put('userId',usrList.get(0).Id);
                if(D1_BulkResendInviteController.isValidUser(usrList.get(0))){
                    resultMap.put('isValidUser','true');
                }
                else{
                    resultMap.put('isValidUser','false');
                }
            }
            else{
                resultMap.put('isUserActive','false');
                resultMap.put('userId',usrList.get(0).Id);
            }
        }
        else{
            resultMap.put('isUserActive','false');
            resultMap.put('userId','');
        }
        return resultMap;
    }

    //Get User Type Id
    public static string getUserTypeId(Boolean isSecondaryRegistration, String countryCode, Boolean isDirect, String preferredLanguage,String accountChannel){
        string userTypeId;
        if(isSecondaryRegistration){
            User usr = getUser();
            userTypeId = usr.D1_User_Type_Id__c;
            effectiveAccountId = usr.Effective_Account_Id__c;
        }else{
            string userType = isDirect ? DIRECTBUYER : INDIRECTBUYER;
            if(preferredLanguage == null){
                List<D1_Setting__c> defaultLanguage = [SELECT Language__c FROM D1_Setting__c WHERE Market__r.Code__c =:countryCode AND Default__c = true WITH SECURITY_ENFORCED];
                preferredLanguage = String.valueOf(defaultLanguage[0].Language__c);
            }
            //condition to compare channel and assign usertype US-143257
            for(D1_User_Type__c userTypeObj : [SELECT Id, Channel__c, User_Type__c FROM D1_User_Type__c WHERE D1_Setting__c IN (SELECT Id FROM D1_Setting__c WHERE Market__r.Code__c =:countryCode AND Language__c =:preferredLanguage) AND User_Type__c =:userType WITH SECURITY_ENFORCED]){
                if(String.isNotBlank(accountChannel) && String.isNotBlank(userTypeObj.Channel__c) && userTypeObj.Channel__c == accountChannel){
                    userTypeId = userTypeObj.Id;
                    break;
                }else{
                    userTypeId = userTypeObj.Id;
                }   
            }
        }
        return userTypeId;
    }

	//Method to get logged in user details
    public static User getUser(){
        User usr = [SELECT Id, Email, AccountId, ContactId, D1_User_Type__c, D1_User_Type_Id__c, Available_Countries__c, LanguageLocaleKey, Effective_Account_Id__c FROM User WHERE Id =:UserInfo.getUserId()];

        return usr;
    }

    //Method to update Account
    public static void updateAccount(Set<Id> shipTosSetIds){
        List<Account> updateAccountList = new List<Account>();
        for(Account acc : [SELECT Id, D1_Registration_Status__c FROM Account WHERE Id IN:shipTosSetIds]){
            if(String.isBlank(acc.D1_Registration_Status__c)){
                acc.D1_Registration_Status__c = APPINVITED;
                updateAccountList.add(acc);
            }
        }
        if(updateAccountList.size() > 0){
            update updateAccountList;

        }
    } 
   
    public static PNR_Partner_Function__c getSoldToId(string accId){
       
        PNR_Partner_Function__c partnerFunction = [SELECT Id, PNR_Sold_To__c, PNR_Sold_To__r.D1_Account_Last_Login_Date__c, PNR_Sold_To__r.D1_Registration_Status__c FROM PNR_Partner_Function__c WHERE PNR_Customer_No__c =:accId AND PNR_Sold_To__c != :accId AND PNR_Type__c = 'Ship-To' LIMIT 1];
        return partnerFunction;
    }

    //NCP-6024 : Removed Future
    public static void updateUser(Id userId){
        User userRecord = new User();
        userRecord.Id = userId;
        userRecord.IsActive = true;
        
        update userRecord;
    }
    
    //Get Contact Details
    //143257 introduced Global_Channel__c from Account
    public static Contact getContact(string contactId){
        Contact con = [SELECT Id, AccountId, Account.Direct_Customer__c, Account.Country_Code__c, Account.Account_Type__c,Preferred_Language__c,Account.Global_Channel__c FROM Contact WHERE Id =:contactId LIMIT 1];

        return con;
    }

    //Method to get User Type
    public static D1_User_Type__c getUserType(string userType){
        D1_User_Type__c userTypeRec = [SELECT Id, User_Type__c FROM D1_User_Type__c WHERE User_Type__c =:userType];

        return userTypeRec;
    }

    //Method to get User Type Role
    public static Map<String, D1_User_Types_Role__c> getUserTypeRole(string userTypeId){
        Map<String, D1_User_Types_Role__c> userTypeRoleMap = new Map<String, D1_User_Types_Role__c>();
        //NCP-7668: Added AutoAssigned filter
        for(D1_User_Types_Role__c utr: [SELECT Id, D1_User_Type__c, D1_User_Role__c, D1_User_Role__r.Access_Type__c, D1_User_Role__r.IsDefault__c, Display_Name__c, D1_User_Role__r.Autoassignment__c  
                                        FROM D1_User_Types_Role__c 
                                        WHERE D1_User_Type__c =:userTypeId AND D1_User_Role__r.Autoassignment__c = false
                                        ORDER By D1_User_Role__r.IsDefault__c DESC, Display_Name__c ASC]){
            userTypeRoleMap.put(utr.D1_User_Role__r.Access_Type__c, utr);
        }
        return userTypeRoleMap;
    }

    //Method to process ACR
    public static Map<Id, AccountContactRelation> processAccountContactRelation(List<AccountContactRelation> accContactRelationList, Boolean isSecondaryRegistration){
        Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>();
        for(AccountContactRelation acr : accContactRelationList){
            if(isSecondaryRegistration){
                if(acr.D1_Roles__c.contains(USERMANAGEMENT)){
                    acrMap.put(acr.AccountId, acr);
                }
            }else{
                acrMap.put(acr.AccountId, acr);
            }
        }

        return acrMap;
    }

    //Method to get Account Contact Relationship
    public static List<AccountContactRelation> getAccountContactRelation(string contactId, Boolean isSecondaryRegistration){
        List<AccountContactRelation> accContactRelationList = new List<AccountContactRelation>();
        if(isSecondaryRegistration){
            accContactRelationList = [SELECT Id, AccountId, ContactId, D1_Roles__c, IsDirect, D1_Active__c FROM AccountContactRelation WHERE ContactId =:contactId AND D1_Active__c = true];
        }else{
            accContactRelationList = [SELECT Id, AccountId, ContactId, D1_Roles__c, IsDirect, D1_Active__c FROM AccountContactRelation WHERE ContactId =:contactId];
        }
        return accContactRelationList;
    }

    /**
    * @description : NCP-6024:Related Data to be updated from this method
    * @param : {Id}contactId , {Map<Id,String>}accountPermissionMap , {Boolean}isSecondaryRegistration , {D1_UserRegistrationDetailWrapper}userRegWrapper , {Set<Id>} selectedAccIdSet 
    * @return : void
    */
    public static void addUserRelatedRecordUpdate(Id contactId,Map<Id, String> accountPermissionMap,Boolean isSecondaryRegistration,D1_UserRegistrationDetailWrapper userRegWrapper,Set<Id> selectedAccIdSet){
        List<AccountContactRelation> insertACRList = new List<AccountContactRelation>();
        List<AccountContactRelation> updateACRList = new List<AccountContactRelation>();
        String exstingPerms;
        
        //Fetch D1_User_Type_Id__c - NCP-7665 & NCP-7668
        String userTypeId = (userRegWrapper.userTypeId != null && userRegWrapper.userTypeId != '') ? userRegWrapper.userTypeId : '';
        if(userTypeId == ''){
            Contact con = getContact(contactId);
            //143257
            String accountChannel = con.Account.Global_Channel__c;
            userTypeId = getUserTypeId(isSecondaryRegistration, con.Account.Country_Code__c, con.Account.Direct_Customer__c, con.Preferred_Language__c,accountChannel);
        }
        
        //Fetch autopermissions and partnerplus registration status from accounts
        Map<Id,Account> accMap = getPartnerEnableStatus(userTypeId, accountPermissionMap.keySet());
        Map<String,String> autoPermissions = getAutoPermissions(userTypeId);
        String autoPermForPrimary = autoPermissions.containsKey(PRIMARY) ? autoPermissions.get(PRIMARY) : '';
        String autoPermForSecondary = autoPermissions.containsKey(MEMBEROFSTAFF) ? autoPermissions.get(MEMBEROFSTAFF) : '';
        
        //check Account Contact Relation records for contact which we enabling for D1
        Map<Id, AccountContactRelation> existingACRMap = getAccountContactRelation(contactId, accountPermissionMap.keySet());

        //Get Primary ACR
        Map<Id, AccountContactRelation> primaryACRMap = getPrimaryAccountContactRelation(accountPermissionMap.keySet());

        //Check for which Account ACR needs to created and for which ACR needs to updated
        for(Id accId : accountPermissionMap.keySet()){
            String userRole = primaryACRMap.containsKey(accId) ? MEMBEROFSTAFF : PRIMARY;
            
            //NCP-7668 & NCP-7927: Add Autoassigned permissions
            exstingPerms = accountPermissionMap.get(accId);
            exstingPerms = (userRole == PRIMARY) ? exstingPerms + ';' + autoPermForPrimary : exstingPerms + ';' + autoPermForSecondary;

            //NCP-7665: Add Partner Plus
            if(accMap.containsKey(accId) && accMap.get(accId).Partner_Plus_Enabled__c && !exstingPerms.contains(MANAGEPARTNERPLUS)){
                exstingPerms = exstingPerms + ';' + MANAGEPARTNERPLUS;
            }

            if(existingACRMap.containsKey(accId)){
                updateACRList.add(updateACR(existingACRMap.get(accId).Id,exstingPerms, userRole));
            }else{
                insertACRList.add(createACR(contactId, accId, exstingPerms, userRole));
            }
        }

        //Update Contact
        //updateContact(contactId,  subscriptionSource, userRegWrapper); //NCP-6348
        D1_RegistrationUtility.updateRegisteredContact(contactId, userRegWrapper); //NCP-7209

        //Update Account
        //KB: This needs change. If we are re-parenting contact then we need to update that account not the old associated. Also we need to modify this method to include ship-to for updating Reg Status
        if(!isSecondaryRegistration){
            //NCP-6447
            //Get List of Ship To for Direct Customers
            contact conRecd = getContact(contactId); 
            if(conRecd != null && conRecd.Account.Direct_Customer__c){
                //Set<Id> shipTosSetIds = new Set<Id>(); 
                for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Customer_No__c FROM PNR_Partner_Function__c WHERE PNR_Sold_To__c IN :selectedAccIdSet AND PNR_Type__c = 'Ship-To']){
                    selectedAccIdSet.add(pf.PNR_Customer_No__c);
                }
            }
            updateAccount(selectedAccIdSet);
        }

        //Create or Update ACR
        if(insertACRList.size()>0){
            insert insertACRList;
        }

        if(updateACRList.size()>0){
            update updateACRList;
        }                
    }

    //Method to get Primary ACR for Account which is enabled for D1
    public static Map<Id, AccountContactRelation> getPrimaryAccountContactRelation(Set<Id> accIdSet){
        Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>();
        
        for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE AccountId IN :accIdSet AND D1_Active__c = true]){
            acrMap.put(acr.AccountId, acr);
        }

        return acrMap;
    }
     //Method to create ACR Instance
    public static AccountContactRelation createACR(Id contactId, Id accId, String permission, String userRole){
        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = contactId;
        acr.AccountId = accId;
        acr.Contact_Type__c ='Secondary';
        acr.D1_Active__c = true;
        acr.D1_Roles__c = permission;
        acr.D1_User_Role__c = userRole;

        return acr;
    }

    //Method to Update ACR Instance
    public static AccountContactRelation updateACR(Id acrId, String permission, String userRole){
        AccountContactRelation acr = new AccountContactRelation();
        acr.Id = acrId;
        acr.D1_Active__c = true;
        acr.D1_Roles__c = permission;
        acr.D1_User_Role__c = userRole;

        return acr;
    }
   //Create Case Description
    public static string createCaseDescription(Map<Id, String> accountPermissionMap, Map<Id, String> accountNameMap){
        string caseDescription = System.Label.D1_User_Permission_Msg;

        for(Id key : accountPermissionMap.keySet()){
            string accountPermission = accountPermissionMap.get(key);
            List<String> permissionList =  accountPermission.split(';');
            caseDescription += '\n' + accountNameMap.get(key) + ' ';
            for(Integer i=0; i<permissionList.size(); i++){
                caseDescription += (i+1)+') ' + permissionList[i] + ' ';
            }
        }
        return caseDescription;
    }

    //Method to check whether email domain check is required or not
    public static Boolean checkEmailDoaminRequired(string userTypeId){
        D1_User_Type__c userType = [SELECT Id, Email_Domain_Check__c FROM D1_User_Type__c WHERE Id =:userTypeId LIMIT 1];
        if(userType != null && userType.Email_Domain_Check__c){
            return true;
        }else{
            return false;
        }
    }
     //Method to validate email domains
    public static Boolean validEmailDomain(String primaryEmail, String secondaryEmail){
        if(primaryEmail.substringAfter('@') == secondaryEmail.substringAfter('@')){
            return true;
        }else{
            return false;
        }
    }
       //Method to get ACR Record
    public static Map<Id, AccountContactRelation> getAccountContactRelation(Id contactId, Set<Id> accIdSet){
        Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>();
        for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId, D1_Active__c, D1_User_Role__c, IsDirect FROM AccountContactRelation WHERE ContactId =:contactId AND AccountId IN :accIdSet]){
            acrMap.put(acr.AccountId, acr);
        }
        return acrMap;
    }

    @AuraEnabled
    public static Map<String,Boolean> validateUserAccess(String contactId, Boolean isRegistration){
        Map<String, Boolean> validateUserMap = new Map<String, Boolean>();
        validateUserMap.put('isProfileAccessible', D1_RegistrationDirectCustomerController.checkProfile());
        validateUserMap.put('isUserActive', D1_RegistrationDirectCustomerController.checkUser(contactId));
        if(isRegistration){
            validateUserMap.put('isDuplicateUser', D1_RegistrationDirectCustomerController.checkDuplicates(contactId));
        }
        return validateUserMap;
    }
    
    @AuraEnabled
    public static Map<String,Object> validateContact(string contactId){
        Map<String,Object> result = D1_RegistrationDirectCustomerController.validateContact(contactId);
        return result;
    }
}