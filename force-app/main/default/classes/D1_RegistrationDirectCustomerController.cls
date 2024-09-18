/**
@name D1_RegistrationDirectCustomerController
@description D1_RegistrationDirectCustomerController Class for Contact registration request.
@history
VERSION     AUTHOR           DATE           DETAIL
1.0        Ayush Kumar      09/11/2020   
2.0        Sudipta  Nandi   09/11/2020
3.0        Saurav Paul   	09/11/2020	    Email functionality for Bulk Registration
4.0		   Praveen			11/02/2021	    NCP-1954
5.0        Praveen          22/05/2021      NCP-3341
6.0        Kapil Baliyan    31/05/2021 
7.0        Narayana         09/02/2021      NCP-4307
8.0        Kapil Baliyan    01/10/2021      NCP-4773/NCP-4863
9.0        Rubeena          10/03/2022      NCP-6348
10.0       Rubeena          25/05/2022      NCP-6759
11.0       Kapil Baliyan    30/05/2022      NCP-6701
12.0       Kapil Baliyan    19/08/2022      NCP-7209
13.0       Pratap Sen       23/11/2022      NCP-7665
14.0       Subhrojit        24/12/2022      NCP-7668
15.0       Kapil Baliyan    03/01/2023      NCP-7682(Remove outdated method validateContacts, setupD1User, getUserRoles)
16.0       Pratap Sen       01/02/2023      NCP-7927 (autoPrimaryUserRoleMap & autoSecondaryUserRoleMap)
17.0       Kapil Baliyan    13/08/2023      143257 (validateContact)
18.0       Prasanth T       25/08/2023      143258 (picking user type based on channel in Bulk D1 Registeration)
**/
public without sharing class D1_RegistrationDirectCustomerController {
    public static final String DIAGEOONE_EXTERNAL_PROFILE = D1_Constants.DIAGEOONE_EXTERNAL_PROFILE;
    public static final String APP_INVITED = D1_Constants.APP_INVITED; 
    public static final String PRIMARY_TEXT = D1_Constants.PRIMARY_TEXT; 
    public static final String DIAGEO_ONE = D1_Constants.DIAGEO_ONE;
    public static final String BACKEND = 'Backend';
    public static final String PAYERPERMISSION = 'User Management;Default Access;Account Balances';
    public static final String MEMBEROFSTAFF = 'Member Of Staff';
    public static final String MANAGEWHOLESALER = 'Manage Wholesalers';
    public static final String AUTOKEY = 'Autoassigned';
    public static Map<Id, Id> existingUserMap = new Map<Id, Id>(); //NCP-6759
    public static Map<string, string> userRoleMap = new Map<string, string>(); //NCP-7668
    public static Map<string, string> autoPrimaryUserRoleMap = new Map<string, string>(); //NCP-7668
    public static Map<string, string> autoSecondaryUserRoleMap = new Map<string, string>(); //NCP-7927
    //143258
    public static final String DIRECTBUYER = D1_Constants.DIRECTBUYER;
    public static final String OUTLETRETAILER = D1_Constants.OUTLETRETAILER;
    public static final String PAYER = D1_Constants.PAYER;
    public static final String SHIPTO = D1_Constants.SHIPTO;
    public static final String SECONDARY_TEXT = D1_Constants.PRIMARY_TEXT;
    //Method to check whether user has valid profile or not
    @AuraEnabled
    public static Boolean checkProfile(){
        Boolean isValid = false;
        String allowedProfile = System.Label.D1_Profiles_for_User_creation;
        String allowedPermission = System.Label.D1_permission_sets_for_user_deactivation;
        List<String> strList = new List<String>();
        List<String> permList = new List<String>();
        permList = allowedPermission.split(',');
        strList = allowedProfile.split(',');
        List<User> usr = [SELECT Id FROM User WHERE id =:UserInfo.getUserId() AND Profile.Name IN :strList];
        if(usr.size()>0){
            isValid = true;
        }
        else{
            List<PermissionSetAssignment> psa=[SELECT PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId =:UserInfo.getUserId() AND PermissionSet.Name IN : permList];
            if(psa.size()>0){
                isValid = true;
            }
        }
        return isValid;
    }

    @AuraEnabled
    public static Boolean checkPrimary(string contactId){
        List<AccountContactRelation> acrListForEligibleContact = [SELECT Id, AccountId, Account.Direct_Customer__c, ContactId, D1_Roles__c,Contact_Type__c, IsDirect
                                                                  FROM AccountContactRelation WHERE ContactId = :contactId AND D1_Active__c = true AND D1_User_Role__c=:PRIMARY_TEXT];
        if(acrListForEligibleContact.size()>0){
            return true;
        }
        else {
            return false;
        }
    }

    @AuraEnabled
    public static Map<String,Object> validateContact(string contactId){
        Map<Id, DirectRegistrationWrapper> directRegistrationWrapperMap = processContacts(new List<String>{contactId}, false);
        DirectRegistrationWrapper  directCustomerRegistrationWrapper = directRegistrationWrapperMap.values()[0];
        Contact contactRec = D1_MyUserDetailsCtrl.getContact(contactId);
        
        //NCP-6212 - consider language while fetching D1_Setting__c and D1_User_Type__c
        D1_Setting__c d1Setting;
        D1_User_Type__c usrType;
        if( String.isNotBlank(contactRec.Preferred_Language__c) ){
            d1Setting = [SELECT Id,Language__c,Default__c,Market__c, Market__r.Code__c FROM D1_Setting__c 
                            WHERE Market__r.Code__c = :contactRec.Account.Country_Code__c AND Language__c = :contactRec.Preferred_Language__c limit 1];

            usrType =  D1_MyUserDetailsCtrl.getUserType(contactRec.Account.Country_Code__c, contactRec.Preferred_Language__c, (contactRec.Account.Direct_Customer__c? DIRECTBUYER:OUTLETRETAILER), contactRec.Account.Global_Channel__c);
        }else{ 
            d1Setting = [SELECT Id,Language__c,Default__c,Market__c, Market__r.Code__c FROM D1_Setting__c 
                            WHERE Market__r.Code__c = :contactRec.Account.Country_Code__c AND Default__c = true limit 1];

            usrType =  D1_MyUserDetailsCtrl.getUserType(contactRec.Account.Country_Code__c, (contactRec.Account.Direct_Customer__c? DIRECTBUYER:OUTLETRETAILER), contactRec.Account.Global_Channel__c);
        }
        
        D1_UserRegistrationDetailWrapper directUserWrapper = new D1_UserRegistrationDetailWrapper();
        directUserWrapper.accountId = contactRec.AccountId;
        directUserWrapper.contactId = contactRec.Id;
        directUserWrapper.firstName = contactRec.FirstName;
        directUserWrapper.lastName = contactRec.LastName;
        directUserWrapper.email = contactRec.Email;
        directUserWrapper.mobileCountryCode = contactRec.MobilePrefix__c;
        directUserWrapper.mobile = contactRec.Mobile__c;
        directUserWrapper.userTypeId = usrType.Id;
        directUserWrapper.userType = usrType.User_Type__c;
        directUserWrapper.d1SettingId = d1Setting.Id;
        directUserWrapper.userCountryCode = contactRec.Account.Country_Code__c;
        directUserWrapper.languageLocaleKey = d1Setting.Language__c;
        directUserWrapper.subscriptionSource = BACKEND;
        directUserWrapper.outletRole = contactRec.MD_CurrentRole__c;//143285
        
        Map<String,Object> result = new Map<String,Object>();
        result.put('directCustomerRegistrationWrapper', directCustomerRegistrationWrapper);
        result.put('directUserWrapper', directUserWrapper);
        return result;
    }
    
    //Method to process contacts
    public static Map<Id, DirectRegistrationWrapper> processContacts(List<string> contactIdList, Boolean isBulkRegistration){
        Map<Id, DirectRegistrationWrapper> directRegistrationWrapperMap = new Map<Id, DirectRegistrationWrapper>();
        Map<Id, Set<Id>> accContactMap = new Map<Id, Set<Id>>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>();
        Set<Id> payerIdSet = new Set<Id>();

        if(!contactIdList.isEmpty()){
            set<string> contactIdSet = new set<string>(contactIdList);
            
            //Check User Exist for this Contact
            for(User usr : [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Phone, 
                            AccountId, Account.Name, Account.AccountNumber, Account.Country__c,isActive FROM User 
                            WHERE ContactId IN :contactIdSet  
                            AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE]) //AND isActive = true //NCP-6759: Removed active condition so that existing users would be reactivated if needed
            {
                if(contactIdSet.contains(usr.ContactId)){
                    if(usr.isActive){
                        DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(usr);
                        directRegistrationWrapper.isSuccess = false;
                        if(isBulkRegistration){
                            directRegistrationWrapper.errorMessage = System.Label.D1_Bulk_UserExists;
                        }else{
                            directRegistrationWrapper.errorMessage = System.Label.D1_UserExists;
                        }
                        
                        directRegistrationWrapperMap.put(usr.ContactId, directRegistrationWrapper);
                        
                        //Remove Contact Id from Set for further validation
                        contactIdSet.remove(usr.ContactId);
                    }
                    else{
                        existingUserMap.put(usr.ContactId,usr.Id); //NCP-6759: Checking if there exists a user already whic is inactive
                    }  
                }
            }
            
            if(!contactIdSet.isEmpty()){
                //Check Account exist for this Contact 
                for(Contact con : [SELECT Id, Name, Email, Phone, AccountId, Account.Name, Account.AccountNumber, Account.Country__c, Account.Deletion_Flag_from_SAP__c 
                                   FROM Contact WHERE Id IN :contactIdSet])
                {
                    if(con.AccountId != null){
                        //NCP-2273 - Below condition to check correct email domain
                        //Updated by KB
                        String contactEmail = con.Email;
                        if(contactEmail.toLowerCase().contains('@diageo.com')){
                            DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(con);
                            directRegistrationWrapper.isSuccess = false;
                            if(isBulkRegistration){
                                directRegistrationWrapper.errorMessage = System.Label.D1_Invalid_Email_Domain_Bulk;
                            }else{
                                directRegistrationWrapper.errorMessage = System.Label.D1_Invalid_Email_Domain_Single;
                            }                        
                            directRegistrationWrapperMap.put(con.Id, directRegistrationWrapper);
                            
                            //Remove Contact Id from Set for further validation
                            contactIdSet.remove(con.Id);
                        }else if(con.Account.Deletion_Flag_from_SAP__c){ //NCP-4773/NCP-4863 : Checking whether Contact Account is marked for deletion or not
                            DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(con);
                            directRegistrationWrapper.isSuccess = false;
                            directRegistrationWrapper.errorMessage = System.Label.D1_Account_Marked_As_Deleted;
                            directRegistrationWrapperMap.put(con.Id, directRegistrationWrapper);
                            
                            //Remove Contact Id from Set for further validation
                            contactIdSet.remove(con.Id);
                        }
                        else{
                            if(accContactMap.containsKey(con.AccountId)){
                                accContactMap.get(con.AccountId).add(con.Id);    
                            }else{
                                accContactMap.put(con.AccountId, new Set<Id>{con.Id});
                            }
                            contactMap.put(con.Id, con);
                        }
                    }else{
                        DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(con);
                        directRegistrationWrapper.isSuccess = false;
                        directRegistrationWrapper.errorMessage = System.Label.D1_No_Account_Exist;
                        
                        directRegistrationWrapperMap.put(con.Id, directRegistrationWrapper);
                        
                        //Remove Contact Id from Set for further validation
                        contactIdSet.remove(con.Id);
                    }
                }
                
                //Check for Multiple Contact Selected
                if(accContactMap.size()>0){
                    //NCP-6701 : Get Primary D1 User for selected Accounts
                    Set<Id> primaryAccConIdSet = new Set<Id>();
                    for(AccountContactRelation accRelation : [SELECT Id, ContactId, AccountId, D1_Active__c FROM AccountContactRelation 
                                                                WHERE AccountId IN :accContactMap.keySet() AND D1_Active__c = TRUE AND D1_User_Role__c = :PRIMARY_TEXT])
                    {
                        primaryAccConIdSet.add(accRelation.AccountId);
                    }

                    for(Id accId : accContactMap.keySet()){
                        Set<Id> conIdSet = accContactMap.get(accId);
                        //NCP-6701 : Added primaryUserMap condition to check if Primary User
                        if(conIdSet.size()>1 && !primaryAccConIdSet.contains(accId)){
                            for(Id conId : conIdSet){
                                DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(contactMap.get(conId));
                                directRegistrationWrapper.isSuccess = false;
                                directRegistrationWrapper.errorMessage = System.Label.D1_Multiple_User_Selected;
                                
                                directRegistrationWrapperMap.put(conId, directRegistrationWrapper);
                                
                                //Remove Contact Id from Set for further validation
                                contactIdSet.remove(conId);
                            }
                            //Remove Account Id from Map
                            accContactMap.remove(accId);
                        }
                    }
                }
            }
            //Added by KB
            accContactMap.clear();
            
            //Process Contacts for Bulk Registration
            if(!contactIdSet.isEmpty() && isBulkRegistration){
                Map<Id, Id> soldToPayerMap = new Map<Id, Id>();
                Set<Id> directCustomerIdSet = new Set<Id>();
                Map<Id, Id> contactAccountMap = new Map<Id, Id>();
                Map<Id, Id > shipToSoldToMap = new Map<Id, Id >();
                
                //Identify which contacts are for Direct and which are for In Direct
                for(Contact con : [SELECT Id, AccountId, Account.Direct_Customer__c, Account.Account_Type__c FROM Contact WHERE Id IN :contactIdSet]){
                    if(con.Account.Direct_Customer__c){
                        directCustomerIdSet.add(con.AccountId);
                        List<String> accountType = con.Account?.Account_Type__c == null ? new List<String>() : con.Account?.Account_Type__c.split(';');
                        if(accountType.size() == 1 && accountType.contains(SHIPTO)){
                            contactAccountMap.put(con.Id , con.AccountId);
                        }                     
                    }
                }

                if(contactAccountMap != null){
                    for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Sold_To__c, PNR_Sold_To__r.D1_Account_Last_Login_Date__c, PNR_Sold_To__r.D1_Registration_Status__c, PNR_Customer_No__c FROM PNR_Partner_Function__c 
                                                      WHERE PNR_Customer_No__c IN :contactAccountMap.values() AND PNR_Type__c =:SHIPTO])
                    {
                        shipToSoldToMap.put(pf.PNR_Customer_No__c, pf.PNR_Sold_To__c);
                    }
                }
                
                //Check Payer Details
                if(directCustomerIdSet.size()>0){
                    for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__c FROM PNR_Partner_Function__c 
                                                      WHERE PNR_Sold_To__c IN :directCustomerIdSet AND PNR_Type__c =:PAYER])
                    {
                        soldToPayerMap.put(pf.PNR_Sold_To__c, pf.PNR_Customer_No__c);
                        if(!soldToPayerMap.containsKey(pf.PNR_Customer_No__c)){
                            payerIdSet.add(pf.PNR_Customer_No__c);
                        }
                    }
                }               

                List<AccountContactRelation> accConRelList = [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Phone,D1_Roles__c,
                                                              AccountId, Account.Name, Account.AccountNumber, Account.Country__c, Account.Direct_Customer__c, 
                                                              D1_Active__c, D1_User_Role__c, IsDirect
                                                              FROM AccountContactRelation 
                                                              WHERE ContactId IN :contactIdSet AND AccountId NOT IN :payerIdSet ORDER BY ContactId];
                //KB: Check for if Contact has Multiple Sold To than dont process via Bulk
                Map<Id, AccountContactRelation> contactACRMap = new Map<Id, AccountContactRelation>();
                for(AccountContactRelation accRelation : accConRelList){
                    if(!contactACRMap.containsKey(accRelation.ContactId)){
                        contactACRMap.put(accRelation.ContactId, accRelation);
                    }
                    else{
                        DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(accRelation);
                        directRegistrationWrapper.isSuccess = false;
                        directRegistrationWrapper.errorMessage = System.Label.D1_Bulk_Sold_To;
                        directRegistrationWrapperMap.put(accRelation.ContactId, directRegistrationWrapper);
                        contactIdSet.remove(accRelation.ContactId);
                    }
                }
                List<Contact> contactListToUpdate = new List<Contact>();
                for(Id contactId :contactIdSet){
                    Contact contactRecd = new Contact(Id = contactId );
                    if(contactAccountMap != null && contactAccountMap.containsKey(contactRecd.Id)){
                        Id key = contactAccountMap.get(contactRecd.Id);
                        contactRecd.AccountId = shipToSoldToMap.get(key); 
                        contactListToUpdate.add(contactRecd);
                    }
                } 

                if(contactListToUpdate.size()>0){
                    Database.update(contactListToUpdate,false);
                }
            }

            //KB: I think it will be better to re-parent contact here and the proceed further so that existing code can be utilise as it is.
            //KB: The way its handled now it will miss payer permission
            //Process remaining contacts
            if(!contactIdSet.isEmpty()){
                List<AccountContactRelation> accConRelList = [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Phone,D1_Roles__c,
                                                              AccountId, Account.Name, Account.AccountNumber, Account.Country__c, D1_Active__c, D1_User_Role__c 
                                                              FROM AccountContactRelation 
                                                              WHERE ContactId IN :contactIdSet AND AccountId NOT IN :payerIdSet];

                //Update by KB
                for(AccountContactRelation accRelation : accConRelList)
                {
                    DirectRegistrationWrapper directRegistrationWrapper = createDirectRegistrationWrapper(accRelation);
                    directRegistrationWrapper.isSuccess = true;
                    directRegistrationWrapper.errorMessage = '';
                    
                    directRegistrationWrapperMap.put(accRelation.ContactId, directRegistrationWrapper);
                }
            }
        }
        return directRegistrationWrapperMap;
    }
    
    //Method to setup user
    public static Map<Id, DirectRegistrationWrapper> setupD1Users(List<String> accountContactRelationId, List<string> userRoleList){
        Map<Id, User> usrMap = new Map<Id, User>();
        Map<Id, Account> accMap = new Map<Id, Account>();
        Map<Id, Contact> conMap = new Map<Id, Contact>();
        Map<string, AccountContactRelation> accConRelationMap = new Map<string, AccountContactRelation>();
        Map<Id, DirectRegistrationWrapper> directRegistrationWrapperMap = new Map<Id, DirectRegistrationWrapper>();        
        if(accountContactRelationId.size()>0){
            set<string> countryCodeSet = new set<string>();
            set<Id> payerIdSet = new set<Id>();
            set<string> conPayerKeySet = new set<string>();
            Map<Id, AccountContactRelation> accContactRelationMap = new Map<Id, AccountContactRelation>();
            Map<Id, Id> acrContactmap = new Map<Id, Id>();
            Map<Id, Set<Id>> directAccConIdMap = new Map<Id, Set<Id>>();
            Map<string, Id> payerACRMap = new Map<string, Id>();
            Map<Id, Boolean> accPrimaryMap = new Map<Id, Boolean>();

           for(AccountContactRelation accConRel : [SELECT Id, AccountId, ContactId, D1_Roles__c, Contact_Type__c, D1_Active__c, Account.Direct_Customer__c, 
                                                    Account.AccountNumber, Account.Name, Account.Country__c, Contact.Name, Contact.Email, Contact.Phone,
                                                    Contact.FirstName, Contact.LastName, Account.Country_Code__c, Contact.Mobile__c,
                                                    Contact.Phone__c, Contact.MobilePrefix__c,Contact.Preferred_Language__c, IsDirect, Account.Account_Type__c, 
                                                    Account.D1_Registration_Status__c, Account.Partner_Plus_Enabled__c,Account.Global_Channel__c
                                                    FROM AccountContactRelation WHERE Id IN :accountContactRelationId])
            {
                accContactRelationMap.put(accConRel.Id, accConRel);
                countryCodeSet.add(accConRel.Account.Country_Code__c);
                acrContactmap.put(accConRel.ContactId,accConRel.Id);
                if(directAccConIdMap.containsKey(accConRel.AccountId)){
                    directAccConIdMap.get(accConRel.AccountId).add(accConRel.ContactId);
                }else{
                    directAccConIdMap.put(accConRel.AccountId, new Set<Id>{accConRel.ContactId});
                }
            }
   
            //Process Direct Customer
            if(directAccConIdMap.size()>0){
                //Check Whether Account has Primary D1 User or not
                for(AccountContactRelation accRelation : [SELECT Id, ContactId, AccountId, D1_User_Role__c FROM AccountContactRelation WHERE AccountId IN :directAccConIdMap.keySet() AND D1_Active__c = true]){
                    if(accRelation.D1_User_Role__c == PRIMARY_TEXT){
                        accPrimaryMap.put(accRelation.AccountId, true);
                    }
                }

                //Check Payer Details
                for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__c FROM PNR_Partner_Function__c 
                                                  WHERE PNR_Sold_To__c IN :directAccConIdMap.keySet() AND PNR_Type__c =:PAYER])
                {
                    payerIdSet.add(pf.PNR_Customer_No__c);
                    if(directAccConIdMap.containsKey(pf.PNR_Sold_To__c)){
                        //NCP-6701
                        for(Id conId : directAccConIdMap.get(pf.PNR_Sold_To__c)){
                            string key = pf.PNR_Customer_No__c + '_' + conId;
                            conPayerKeySet.add(key);
                        }
                    }
                }
  
                //Create/Update ACR for Payer
                if(payerIdSet.size()>0){
                    for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId IN :acrContactmap.keySet() 
                                                      AND AccountId IN :payerIdSet])
                    {
                        string key = acr.AccountId + '_' + acr.ContactId;
                        payerACRMap.put(key, acr.Id);
                    }
    
                    for(string key : conPayerKeySet){
                        if(payerACRMap.containsKey(key)){
                            AccountContactRelation acr = getAccountContact(payerACRMap.get(key), PAYERPERMISSION, '', false);
                            accConRelationMap.put(payerACRMap.get(key), acr);
                        }else{
                            List<string> tempStr = key.split('_');
                            AccountContactRelation acr = new AccountContactRelation();
                            acr.D1_User_Role__c = MEMBEROFSTAFF;
                            acr.D1_Roles__c = PAYERPERMISSION;
                            acr.D1_Active__c = true;
                            acr.AccountId = tempStr[0];
                            acr.ContactId = tempStr[1];
                            acr.Contact_Type__c ='Secondary';
                            accConRelationMap.put(key, acr);
                        }
                    }
                }
            }
            
            if(accContactRelationMap.size()>0){
                List<AccountContactRelation> accContactRelationList = accContactRelationMap.values();
                
                //call getUserLocaleSetting to get country wise User locale settings
                Map<String, List<D1_User_Locale_Settings__mdt>> userLocaleSettingMap = getUserLocaleSetting(countryCodeSet);
                
                //Get Profile Id
                Id profileId = D1_UserRegistrationValidator.getProfileId(DIAGEOONE_EXTERNAL_PROFILE);
                
                //Get Language
                Map<string, List<D1_Setting__c>> marketLanguageMap = getD1Setting(countryCodeSet);
                List<String> languageList = new List<String>();
                for(List<D1_Setting__c> d1Settings: marketLanguageMap.values()){
                    for( D1_Setting__c d1Setting : d1Settings ){
                        languageList.add(d1Setting.Language__c);
                    }
                }
                
                //Get User Type
                Map<string, D1_User_Type__c> userTypeMap = getD1UserType(countryCodeSet, languageList);
                
                //Create Map of Manual & Automatic Assigned User Role. Maps are defined at class level
                //Map<string, string> userRoleMap = getUserRoles(countryCodeSet, languageList);
                getUserRoles(countryCodeSet, languageList);
                
                for(AccountContactRelation accConRel : accContactRelationList){
                    String userRole = '';
                    String autoUserRolePrimary = ''; //NCP-7668
                    String autoUserRoleSecondary = ''; //NCP-7927
                    String counrtyCode = accConRel.Account.Country_Code__c ;
                    List<D1_Setting__c> d1Settings = marketLanguageMap.get(counrtyCode);//NCP-2266
                    D1_Setting__c d1Settin;
                    if( d1Settings != NULL ){
                        for( D1_Setting__c d1s : d1Settings ){
                            if( d1s.Default__c ){
                                d1Settin = d1s;
                            }else if( d1s.Language__c == accConRel.Contact.Preferred_Language__c ){
                                d1Settin = d1s;
                                break;
                            }
                        }
                    }
                    string language = d1Settin?.Language__c;
                    D1_User_Type__c userType = new D1_User_Type__c();
                    
                    //Get User Type & User Role
                    //143258 - introduced channel
                    //if(accConRel.Account.Direct_Customer__c){
                        String outletType = accConRel.Account.Direct_Customer__c? DIRECTBUYER : OUTLETRETAILER;
                        string key = counrtyCode + '_' + language + '_' + outletType+ '_' + accConRel.Account.Global_Channel__c;
                        if(!userRoleMap.containsKey(key) && !autoPrimaryUserRoleMap.containsKey(key) && !autoSecondaryUserRoleMap.containsKey(key) && !userTypeMap.containsKey(key)){
                            key  = counrtyCode + '_' + language + '_' + outletType + '_';
                    }
                        userRole = userRoleMap.get(key);
                        autoUserRolePrimary = autoPrimaryUserRoleMap.get(key); //NCP-7668
                        autoUserRoleSecondary = autoSecondaryUserRoleMap.get(key); //NCP-7927
                        userType = userTypeMap.get(key);
                    /*}else{
                        string key = counrtyCode + '_' + language + '_' + OUTLETRETAILER + '_' + accConRel.Account.Global_Channel__c;
                        if(!userRoleMap.containsKey(key) && !autoPrimaryUserRoleMap.containsKey(key) && !autoSecondaryUserRoleMap.containsKey(key) && !userTypeMap.containsKey(key)){
                            key  = counrtyCode + '_' + language + '_' + OUTLETRETAILER + '_';
                        }
                        userRole = userRoleMap.get(key);
                        autoUserRolePrimary = autoPrimaryUserRoleMap.get(key); //NCP-7668
                        autoUserRoleSecondary = autoSecondaryUserRoleMap.get(key); //NCP-7927
                        userType = userTypeMap.get(key);
                        
                    }*/
                    
                    //If userRoleList is not null, it means it coming from D1_RegistrationDirectCustomer and use this
                    if(userRoleList != null && userRoleList.size()>0){
                        userRole = string.join(userRoleList, ';'); 
                    }

                    //NCP-7665 : Add Manage Partner Plus Permission for PartnerPlus Enabled Accounts
                    if(accConRel.Account.Partner_Plus_Enabled__c && d1Settin.Partner_Plus_Enabled__c){
                        userRole = userRole + Label.D1_ManagePartnerPlusVal + ';';
                    }

                    D1_User_Locale_Settings__mdt userLocaleSetting;
                    if( userLocaleSettingMap.containsKey(counrtyCode) ){
                        for( D1_User_Locale_Settings__mdt ls : userLocaleSettingMap.get(counrtyCode) ){
                            userLocaleSetting = ls;
                            if( ls.LanguageLocaleKey__c == accConRel.Contact.Preferred_Language__c ){
                                userLocaleSetting = ls;
                                break;
                            }
                        }
                    }
                    
                    //NCP-6759 : Creating new user only if no  user exists with name email
                    if(!existingUserMap.containsKey(accConRel.ContactId)){
                        //Create User
                        User usr = createUser(accConRel, userLocaleSetting, profileId, language, userType);
                        usrMap.put(accConRel.Id, usr);
                    }
                                       
                    
                    //Update Account Contact Relationship
                    string existingUserRole = accConRelationMap.containsKey(accConRel.Id) ? accConRelationMap.get(accConRel.Id).D1_Roles__c : '';
                    Boolean isPrimary = accPrimaryMap.containsKey(accConRel.AccountId) ? !accPrimaryMap.get(accConRel.AccountId) : true;

                    //NCP-7668 : If User is primary Add Auto Assign Permissions for Primary
                    if(isPrimary && String.isNotBlank(autoUserRolePrimary)){
                        userRole = userRole + ';' + autoUserRolePrimary;
                    }

                    //NCP-7927 : If User is Secondary Add Auto Assign Permissions for Secondary
                    if(!isPrimary && String.isNotBlank(autoUserRoleSecondary)){
                        userRole = userRole + ';' + autoUserRoleSecondary;
                    }

                    AccountContactRelation accContact = getAccountContact(accConRel.Id, userRole, existingUserRole, isPrimary);
                    accConRelationMap.put(accConRel.Id, accContact);                    
                    
                    //Update Account
                    if(String.isBlank(accConRel.Account.D1_Registration_Status__c)){
                        Account acc = createAccount(accConRel.AccountId, APP_INVITED);
                        accMap.put(accConRel.Id, acc);
                    }
                    
                    //Update Contact
                    Contact con = D1_RegistrationUtility.updateRegisteredContactFields(accConRel.ContactId, DIAGEO_ONE, BACKEND, userType?.Id, d1Settin?.Id, d1Settin?.Language__c); //NCP-7209
                    conMap.put(accConRel.Id, con);
                }
                
                if(usrMap.size()>0){
                    Database.SaveResult[] srList = Database.insert(usrMap.values(), false);
                    Integer index = 0;
                    for(Id accConRelId : usrMap.keySet()){
                        Database.SaveResult sr = srList[index];
                        
                        string errorMessage = '';
                        if(sr.isSuccess()){
                            DirectRegistrationWrapper drw = createDirectRegistrationWrapper(accContactRelationMap.get(accConRelId));
                            drw.isSuccess = true;
                            directRegistrationWrapperMap.put(accContactRelationMap.get(accConRelId).ContactId, drw);
                        }else{
                            for(Database.Error err : sr.getErrors()) {
                                errorMessage += err.getStatusCode() + ': ' + err.getMessage();
                            }
                            
                            DirectRegistrationWrapper drw = createDirectRegistrationWrapper(accContactRelationMap.get(accConRelId));
                            drw.isSuccess = false;
                            drw.errorMessage = errorMessage;
                            directRegistrationWrapperMap.put(accContactRelationMap.get(accConRelId).ContactId, drw);
                            
                            //Remove Account, Contact & AccountContactRelationship Data from Map so that they wont gets update
                            accConRelationMap.remove(accConRelId);
                            accMap.remove(accConRelId);
                            conMap.remove(accConRelId);
                        }
                        index++;
                    }
                }

                
                //NCP-6759 : Checking the already existing inactive user list to reactivate them.
                if(!existingUserMap.isEmpty() && !acrContactmap.isEmpty()){

                    for(Id conId : existingUserMap.keyset()){
                        DirectRegistrationWrapper drw = createDirectRegistrationWrapper(accContactRelationMap.get(acrContactmap.get(conId)));
                        drw.isSuccess = true;
                        directRegistrationWrapperMap.put(accContactRelationMap.get(acrContactmap.get(conId)).ContactId, drw);
                    }                    

                    //Passing the list of users to be activated to future method
                    List<Id> userIds = existingUserMap.values();
                    D1_UserRegistrationValidator.updateUser(userIds);
                }

                //NCP-6759: Moved related record update out of the above new user scope.
                //Update Account, Contact & AccountContactRelationship
                if(accConRelationMap.size()>0){
                    upsert accConRelationMap.values();
                }
                if(conMap.size()>0){
                    Database.update(conMap.values(), false);
                }
                if(accMap.size()>0){
                    Database.update(accMap.values(), false);                       
                }        
                
            }													   
        }
        
        return directRegistrationWrapperMap;
    }
    
    //Method to create DirectRegistrationWrapper from AccountContactRelation
    public static DirectRegistrationWrapper createDirectRegistrationWrapper(AccountContactRelation accConRelation){
        DirectRegistrationWrapper drw = new DirectRegistrationWrapper();
        drw.accountContactId = accConRelation.Id;
        drw.contactId = accConRelation.ContactId;
        drw.contactName = accConRelation.Contact.Name;
        drw.accNo = accConRelation.Account.AccountNumber;
        drw.accName = accConRelation.Account.Name;
        drw.email = accConRelation.Contact.Email;
        drw.phoneVal = accConRelation.Contact.Phone;
        drw.marketId = accConRelation.Account.Country__c;
        
        return drw;
    } 
    
    //Method to create DirectRegistrationWrapper from Contact
    public static DirectRegistrationWrapper createDirectRegistrationWrapper(Contact con){
        DirectRegistrationWrapper drw = new DirectRegistrationWrapper();
        drw.contactId = con.Id;
        drw.contactName = con.Name;
        drw.accNo = con.Account.AccountNumber;
        drw.accName = con.Account.Name;
        drw.email = con.Email;
        drw.phoneVal = con.Phone;
        drw.marketid = con.Account.Country__c;
        
        return drw;
    }
    
    //Method to create DirectRegistrationWrapper from User
    public static DirectRegistrationWrapper createDirectRegistrationWrapper(User usr){
        DirectRegistrationWrapper drw = new DirectRegistrationWrapper();
        drw.contactId = usr.ContactId;
        drw.contactName = usr.Contact.Name;
        drw.accNo = usr.Account.AccountNumber;
        drw.accName = usr.Account.Name;
        drw.email = usr.Contact.Email;
        drw.phoneVal = usr.Contact.Phone;
        drw.marketId = usr.Account.Country__c;
        
        return drw;
    }
    
    //Method to process bulk registration
    public static void processBulkRegistration(List<string> contactIdList){
        Map<Id, DirectRegistrationWrapper> directRegistrationWrapperMap = processContacts(contactIdList, true);
        List<string> accountContactRelationId = new List<string>();
        for(string conId : directRegistrationWrapperMap.keySet()){
            DirectRegistrationWrapper directRegistrationWrapper = directRegistrationWrapperMap.get(conId);
            if(directRegistrationWrapper.isSuccess){
                accountContactRelationId.add(directRegistrationWrapper.accountContactId);
            }
        }
        //Process Success Contacts
        if(accountContactRelationId.size()>0){
            Map<Id, DirectRegistrationWrapper> directRegistrationWrapperMapp = setupD1Users(accountContactRelationId, null);
            directRegistrationWrapperMap.putAll(directRegistrationWrapperMapp);
        }
        
        //Send Email
        sendEmail(directRegistrationWrapperMap.values());
    }
    
    //Details: method to create user
    public static User createUser(AccountContactRelation accountContactReln, D1_User_Locale_Settings__mdt userLocaleSetting, 
                                  Id profileId, String language, D1_User_Type__c userType)
    {
        
        //Create User Instance
        User u = new user();
        u.FirstName = accountContactReln.Contact.FirstName;
        u.LastName = accountContactReln.Contact.LastName;
        u.Email = accountContactReln.Contact.Email;
        //Integer randomNumber = Integer.valueof((Math.random() * 100));//adding to make nick name unique
        String randomNumber = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3) + 'd1' + String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0, 3);
        if( accountContactReln.Contact.LastName.length()>3){
            String tempstring = accountContactReln.Contact.FirstName.substring(0,1) + accountContactReln.Contact.LastName.substring(0,4);
            u.Alias = tempstring;
            u.CommunityNickname = tempstring + randomNumber;
        }else{
            String tempstring = accountContactReln.Contact.FirstName.substring(0,1) + accountContactReln.Contact.LastName.substring(0,1);
            u.Alias = tempstring; 
            u.CommunityNickname = tempstring + randomNumber;   
        }  
        u.Username = accountContactReln.Contact.Email;    
        u.ContactId = accountContactReln.ContactId;        
        u.Available_Countries__c = accountContactReln.Account.Country_Code__c;
        u.ProfileID = profileId; 
        u.LocaleSidKey = userLocaleSetting!=null ? userLocaleSetting.LocaleSidKey__c : '' ;
        u.TimeZoneSidKey = userLocaleSetting!=null ? userLocaleSetting.TimeZoneSidKey__c : '';        
        u.LanguageLocaleKey = language;
        u.EmailEncodingKey = 'UTF-8';        
        u.Mobile_Prefix__c = accountContactReln.Contact.MobilePrefix__c !=Null ? accountContactReln.Contact.MobilePrefix__c:'';
        u.Mobile_Number__c = accountContactReln.Contact.Mobile__c !=Null ? accountContactReln.Contact.Mobile__c : '';
        u.MobilePhone = u.Mobile_Prefix__c + u.Mobile_Number__c;
        
        if(null != userType){                
            u.D1_User_Type__c = userType.User_Type__c;
            u.D1_User_Type_Id__c = userType.Id;
            u.D1_UserType_CSG_Email__c = userType.Customer_Service_Group__c;//NCP-2366
        }
        
        return u;
    }
    
    //Method to Get Locale's Setting
    public static Map<String, List<D1_User_Locale_Settings__mdt>> getUserLocaleSetting(Set<string> countryCodeSet){
        Map<String, List<D1_User_Locale_Settings__mdt>> userLocaleSettingMap = new Map<String, List<D1_User_Locale_Settings__mdt>>();
        for(D1_User_Locale_Settings__mdt userLocale : [SELECT Country_Code__c,LocaleSidKey__c,TimeZoneSidKey__c,LanguageLocaleKey__c
                                                       FROM D1_User_Locale_Settings__mdt WHERE Country_Code__c IN :countryCodeSet])
        {
            if( !userLocaleSettingMap.containsKey(userLocale.Country_Code__c) ){
                userLocaleSettingMap.put(userLocale.Country_Code__c, new List<D1_User_Locale_Settings__mdt>{userLocale});
            }else{
                userLocaleSettingMap.get(userLocale.Country_Code__c).add(userLocale);
            }
        }
        
        return userLocaleSettingMap;
    }
    
    //Method to Get Default 
    public static Map<string, List<D1_Setting__c>> getD1Setting(set<String> countryCodeSet){
        Map<string, List<D1_Setting__c>> marketLanguageMap = new Map<string, List<D1_Setting__c>>();
        
        for(D1_Setting__c d1Settings : [SELECT Id,Language__c,Default__c,Market__c, Market__r.Code__c,Partner_Plus_Enabled__c
                                        FROM D1_Setting__c 
                                        WHERE Market__r.Code__c IN :countryCodeSet])
        {
            if( !marketLanguageMap.containsKey(d1Settings.Market__r.Code__c) ){
                marketLanguageMap.put(d1Settings.Market__r.Code__c, new List<D1_Setting__c>{d1Settings});
            }else{
                marketLanguageMap.get(d1Settings.Market__r.Code__c).add(d1Settings);
            }
        }
        
        return marketLanguageMap;                           
    }
    //143258 - introduced channel
    //Method is for getting D1 User Type
    public static Map<string, D1_User_Type__c> getD1UserType(Set<string> contryCodeSet, List<String> languageList){
        Map<string, D1_User_Type__c> availableUserTypeMap = new Map<string, D1_User_Type__c>();
        for(D1_User_Type__c usrType : [SELECT D1_Setting__c, Id, Name, User_Type__c,D1_Setting__r.Market__c, D1_Setting__r.Market__r.Code__c,Customer_Service_Group__c, D1_Setting__r.Language__c,Channel__c
                                       FROM D1_User_Type__c where D1_Setting__r.Market__r.Code__c IN :contryCodeSet 
                                       AND D1_Setting__r.Language__c IN :languageList])
        {
            String channel = usrType.Channel__c == null ? '' : usrType.Channel__c;
            String key = usrType.D1_Setting__r.Market__r.Code__c + '_' + usrType.D1_Setting__r.Language__c + '_' + usrType.User_Type__c + '_' + channel;
            availableUserTypeMap.put(key, usrType);
        }
        return availableUserTypeMap;
    }
    
    //NCP-3485 //NCP-7668
    //143258 - introduced channel
    //public static Map<string, string> getUserRoles(Set<string> contryCodeSet, List<String> languageList){
    public static void getUserRoles(Set<string> contryCodeSet, List<String> languageList){
        //Map<string, string> userRoleMap = new Map<string, string>();        
        for(D1_User_Types_Role__c utr: [SELECT Id, D1_User_Type__c, D1_User_Role__c, Name,D1_User_Type__r.D1_Setting__r.Market__r.Code__c,
                                        D1_User_Type__r.User_Type__c,D1_User_Role__r.Name,D1_User_Role__r.Access_Type__c,D1_User_Role__r.IsDefault__c,
                                        Description__c,Display_Name__c, D1_User_Type__r.D1_Setting__r.Language__c,D1_User_Role__r.Autoassignment__c,
                                        D1_User_Role__r.Autoassignment_for_Secondary_Contact__c,D1_User_Type__r.Channel__c
                                        FROM D1_User_Types_Role__c 
                                        WHERE D1_User_Type__r.D1_Setting__r.Language__c =:languageList
                                        AND D1_User_Type__r.D1_Setting__r.Market__r.Code__c  IN:contryCodeSet ORDER BY Display_Name__c])
        {   
            String channel = utr.D1_User_Type__r.Channel__c == null ? '' : utr.D1_User_Type__r.Channel__c;
            String key = utr.D1_User_Type__r.D1_Setting__r.Market__r.Code__c + '_' + utr.D1_User_Type__r.D1_Setting__r.Language__c + '_' + utr.D1_User_Type__r.User_Type__c + '_' +channel;
            //NCP-7927
            if(utr.D1_User_Role__r.Access_Type__c != 'Account Balances'){
                if(utr.D1_User_Role__r.Autoassignment__c){
                    autoPrimaryUserRoleMap.put(key, autoPrimaryUserRoleMap.containsKey(key) ? autoPrimaryUserRoleMap.get(key) + utr.D1_User_Role__r.Access_Type__c + ';' : utr.D1_User_Role__r.Access_Type__c + ';');
                }
                if(utr.D1_User_Role__r.Autoassignment_for_Secondary_Contact__c){
                    autoSecondaryUserRoleMap.put(key, autoSecondaryUserRoleMap.containsKey(key) ? autoSecondaryUserRoleMap.get(key) + utr.D1_User_Role__r.Access_Type__c + ';' : utr.D1_User_Role__r.Access_Type__c + ';');
                }
                if(!utr.D1_User_Role__r.Autoassignment__c && !utr.D1_User_Role__r.Autoassignment_for_Secondary_Contact__c){
                    userRoleMap.put(key, userRoleMap.containsKey(key) ? userRoleMap.get(key) + utr.D1_User_Role__r.Access_Type__c + ';' : utr.D1_User_Role__r.Access_Type__c + ';');
                }
            }
        }
    }
    
    //Method to create Account Contact Relationship Instance
    public static AccountContactRelation getAccountContact(Id accConId, string userRole, string existingUserRole, boolean isPrimary){
        
        AccountContactRelation accCon = new AccountContactRelation();
        accCon.Id = accConId;
        accCon.D1_Active__c = true;
        accCon.D1_User_Role__c = isPrimary ? PRIMARY_TEXT : MEMBEROFSTAFF;
        accCon.D1_Roles__c = removeDuplicateRoles(userRole,existingUserRole);
        return accCon;
    }

    //Method to remove duplicate roles
    public static string removeDuplicateRoles(string userRole, string existingUserRole){
        if(existingUserRole == null || existingUserRole == '') {
            return userRole;
        }
        Set<String> uniqueRoles = new Set<String>();
        List<String> tempRoles = new List<String>();
        List<String> existingUserRoleList = existingUserRole.contains(';') ? existingUserRole.split(';') : new List<String>{existingUserRole};
        List<String> userRoleList = (String.isNotBlank(userRole) && userRole.contains(';')) ? userRole.split(';') : new List<String>{userRole};
        if(existingUserRoleList == null){
            return userRoleList.size()>1 ? String.join(userRoleList, ';') : userRole;
        }
        uniqueRoles.addAll(existingUserRoleList);
        uniqueRoles.addAll(userRoleList);
        tempRoles.addAll(uniqueRoles);
        return tempRoles.size()>1 ? string.join(tempRoles, ';') : string.join(tempRoles, '');
    }
    
    //Method to create Account Instance
    //NCP-6701 : Uncommented this method
    public static Account createAccount(String accountId, String regStatus){
        Account account = new Account(Id = accountId, 
                                      D1_Registration_Status__c = regStatus
                                     );
        return account;
    }

    public static Account updateShipToAccount(Id shipTo, String registrationStatus, datetime lastLoginDate){
        Account accRecd = new Account(Id = shipTo, 
                                      D1_Registration_Status__c = registrationStatus,
                                      D1_Account_Last_Login_Date__c = lastLoginDate
                                     );
        return accRecd;
    }
    
    //Method to send Email
    public static void sendEmail(List<D1_RegistrationDirectCustomerController.DirectRegistrationWrapper> wrapList){
        //String header = ' '+'\t'+ 'Contact name '+'\t' +'Account No '+'\t'+ 'Account Name '+'\t'+ 'Email '+'\t'+ 'Phone '+'\t'+'Status '+'\t'+ 'Date and Time '+'\n';
        String header = '<th style="background-color:#FFF2CC">Sl.no.</th>'+'<th style="background-color:#FFF2CC">Contact name </th>'+'<th style="background-color:#FFF2CC">Account No </th>';
        header=header+'<th style="background-color:#FFF2CC">Account Name </th>'+'<th style="background-color:#FFF2CC">Email</th>'+'<th style="background-color:#FFF2CC">Phone</th>';
        header=header+'<th style="background-color:#FFF2CC">Status</th>'+'<th style="background-color:#FFF2CC">Date and Time </th>';
        String finalstr = '<table border="1">'+ header;
        Integer rowCount = 1;
        Date dateVal = Date.today();
        String str = String.valueof(DateTime.now());
        String sDate = String.valueof(dateVal.day())+ '/' + String.valueof(dateVal.month()) + '/'+String.valueof(dateVal.year()) +' '+ str.substringAfter(' ');
        Set<String> marketIdSet = new Set<String>();
        List<String> address = new List<String>();
        
        for(D1_RegistrationDirectCustomerController.DirectRegistrationWrapper wrapObj : wrapList){
            marketIdSet.add(wrapObj.marketId);
            finalstr = finalstr + '<tr><td>'+ rowCount ;
            finalstr = finalstr + '</td><td>' + wrapObj.contactName + '</td><td>' + wrapObj.accNo + '</td><td>' + wrapObj.accName + '</td><td>' + wrapObj.email + '</td><td>' + wrapObj.phoneVal + '</td><td>';
            if(wrapObj.isSuccess!= null && wrapObj.isSuccess){
                finalstr = finalstr + 'Success' + '</td><td>' + sDate + '</td></tr>';
            }else{
                finalstr = finalstr+wrapObj.errorMessage + '</td><td>' + sDate + '</td></tr>';
            }
            rowCount++;    
        }
        finalstr=finalstr+'</table>';
        
        //Get Email Ids
        address = getEmail(marketIdSet);
        
        //Get Blob Value of data
        Blob b = blob.valueOf(finalstr);
        
        //Creating Message
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(address);
        Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
        a.setBody(b);
        a.setContentType('application/vnd.ms-excel');
        a.setFileName('Bulk Registration Report.xls');
        a.setInline(false);
        m.setFileAttachments(new Messaging.EmailFileAttachment[] { a } );
        m.setSubject(Label.D1_Bulk_Registration_Email_Subject);
        m.setPlainTextBody(Label.D1_Bulk_Registration_Email_Body);
        OrgWideEmailAddress orgWideObj = [select DisplayName,Id from OrgWideEmailAddress where DisplayName = 'DiageoOne'];
        m.setOrgWideEmailAddressId(orgWideObj.Id);
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { m } );
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { m } );
        if (results[0].success) {
            System.debug(LoggingLevel.INFO, '@@The email was sent successfully.');
        } else {
            System.debug(LoggingLevel.ERROR, results[0].errors[0].message);
        }
    }
    
    //Method to get Market Email
    public static List<String> getEmail(Set<String> countryIdSet){
        List<String> emailList = new List<String>();
        string currentUserEmail = UserInfo.getUserEmail();
        emailList.add(currentUserEmail);
        
        for(D1_User_Type__c userType : [SELECT Id, Customer_Service_Group__c FROM D1_User_Type__c 
                                        WHERE D1_Setting__c IN (SELECT Id 
                                                                FROM D1_Setting__c
                                                                WHERE Market__c IN :countryIdSet) 
                                        AND Customer_Service_Group__c !=''])
        {
            emailList.add(userType.Customer_Service_Group__c);
        }
        
        return emailList;
    }       

    //NCP-4174
    @AuraEnabled
    public static boolean checkDuplicates(string contactId){
        //Get Contacts Details
        Contact contactRec = D1_MyUserDetailsCtrl.getContact(contactId);

        //Check User
        List<User> userList = [SELECT Id, ContactId FROM User WHERE ContactId !=:contactId AND Email=:contactRec.email AND isActive = true 
                                AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE ORDER BY ContactId NULLS LAST];
        
        return (userList.size() > 0) ? true : false;
    }
    
    public static Boolean checkUser(string contactId){
        Boolean isActiveUser = false;
        List<User> usrList = [SELECT Id, ContactId, IsActive FROM User WHERE ContactId =:contactId AND IsActive = true AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE];
        if(usrList != null && usrList.size()>0){
            isActiveUser = usrList.get(0).IsActive;
        }
        return isActiveUser;
    }
    //NCP-5931
    public static Boolean checkUserForResendInvite(string email){
        Boolean isActiveUser = false;
        List<User> usrList = [SELECT Id, IsActive, ContactId,FirstName,Username FROM User WHERE Email =:email AND IsActive = true AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE];
        if(usrList != null && usrList.size()>0){
            isActiveUser = usrList.get(0).IsActive;
        }
        return isActiveUser;
    }
    
    //Wrapper Class
    public class DirectRegistrationWrapper {
        @AuraEnabled public String accountContactId {get; set;}
        @AuraEnabled public String contactId {get; set;}
        @AuraEnabled public String contactName {get; set;}
        @AuraEnabled public String errorMessage {get; set;}
        @AuraEnabled public String email {get; set;}
        @AuraEnabled public Boolean isSuccess {get; set;}
        @AuraEnabled public String accNo {get; set;}
        @AuraEnabled public String accName {get; set;}
        @AuraEnabled public String phoneVal {get; set;}
        @AuraEnabled public String marketId {get; set;}
    }
}