/**
 * @name : D1_AddUserPermissionsController
 * @description : Controller Class for Primary/Secondary User Registration via D1/Register to D1 Button
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Kapil Baliyan   16/09/2021      Initial Development (NCP-4192)
 * 2.0          Kapil Baliyan   16/09/2021      (NCP-4295)
 * 3.0          Kapil Baliyan   06/10/2021      NCP-4394 (createLead)
 * 4.0          Kapil Baliyan   17/10/2021      NCP-4305 (validateUserAccess, validateContact)
 * 5.0          Kapil Baliyan   01/12/2021      NCP-5077 (createAccountWrapper, addUserPermissions)
 * 6.0          Kapil Baliyan   02/12/2021      NCP-5517 (createLead)
 * 7.0          Narayana        27/01/2022      NCP-5931(checkUserForResendInvite,validateUserForResend,resendRegistrationInvite)
 * 8.0          Kapil Baliyan   01/03/2022      DGD-430
 * 9.0          Rubeena         10/03/2022      NCP-6348
 * 10.0			Rubeena			22/03/2022		NCP-6408
 * 11.0         Kapil Baliyan   12/04/2022      NCP-6447
 * 12.0			Sayan Samaddar	12/07/2022		NCP-7157
 * 13.0         Kapil Baliyan   18/08/2022      NCP-7209
 * 14.0         Pratap Sen      23/11/2022      NCP-7665
 * 15.0         Kapil Baliyan   16/12/2022      NCP-7681(Remove createCase Method)
 * 16.0         Subhrojit       24/12/2022      NCP-7668(Remove checkPartnerPlusStatus call)
 * 17.0         Pratap          01/02/2023      NCP-7927
 * 18.0			Prasanth T		11/08/2023		143257(UserType decision based on Channel)
 * 19.0         Prasanth T      19/09/2023      114761 Commented D1 Lite code
 */
public without sharing class D1_AddUserPermissionsController {
   
    //Constants
    public static final string DIRECTBUYER = 'Direct Buyer';
    public static final string INDIRECTBUYER = 'Outlet/Retailers';
    public static final string USERMANAGEMENT = 'User Management';
    public static final String SOLDTO = 'Sold-To';
    public static final String PAYER = 'Payer';
    public static final String DIAGEOONE_EXTERNAL_PROFILE = 'DiageoOne External User';
    public static final String DIAGEOONE = 'Diageo One';
    public static final String FRONTEND = 'Frontend';
    public static final String BACKEND = 'Backend';
    public static final String APPINVITED = 'AppInvited';
    public static final String PRIMARY = 'Primary';
    public static final String MEMBEROFSTAFF = 'Member Of Staff';
    public static final string ACCOUNTBALANCES = 'Account Balances';
    public static final string PAYERPERMISSION = 'Default Access;Account Balances;User Management;';
    public static string effectiveAccountId; //NCP-5077
    public static final string DIRECTCUSTOMERREGISTRATION = 'Direct Customer Registration'; //NCP-5517
    public static final string INDIRECTCUSTOMERREGISTRATION = 'Indirect Customer Registration'; //NCP-5517
    public final static String B2B_USER_PERMISSION = 'B2B Commerce User'; 
    public final static String ORDER_PERMISSION = 'Ordering';
    public static final String MANAGEPARTNERPLUS = Label.D1_ManagePartnerPlusVal;

    @AuraEnabled
    public static List<UserPermissionWrapper> getAccountPermissions(String contactId, Boolean isSecondaryRegistration){
        try {
            List<UserPermissionWrapper> userPermissionWrapperList = new List<UserPermissionWrapper>();
            //Get Contact
            Contact con = D1_AddUserPermissionsNewController.getContact(contactId);
            
            Boolean isDirect = con.Account.Direct_Customer__c;
            String countryCode = con.Account.Country_Code__c;
            String accountChannel = con.Account.Global_Channel__c;
            //143257
            String userTypeId = D1_AddUserPermissionsNewController.getUserTypeId(isSecondaryRegistration, countryCode, isDirect ,con.Preferred_Language__c,accountChannel);
            User usr = D1_AddUserPermissionsNewController.getUser();//NCP-7872
            effectiveAccountId = usr.Effective_Account_Id__c;//NCP-7872
            //Get User Type Role
            Map<String, D1_User_Types_Role__c> userTypeRoleMap = D1_AddUserPermissionsNewController.getUserTypeRole(userTypeId);

            //Check for Account if its Ship-To, then check for Sold-To and create ACR for Sold-To
            if(isDirect && !isSecondaryRegistration){
                List<String> accountType = con.Account?.Account_Type__c == null ? new List<String>() : con.Account?.Account_Type__c.split(';');            
                if(accountType.size() == 1 && accountType.contains('Ship-To')){
                    PNR_Partner_Function__c soldTosRecd = D1_AddUserPermissionsNewController.getSoldToId(con.AccountId);
                    Id soldToIds = soldTosRecd.PNR_Sold_To__c;

                    //Update Contact
                    con.AccountId = soldToIds;
                    update con;
                }
            }            
            //Get Account Contact Relationship Records
            List<AccountContactRelation> accContactRelationList = D1_AddUserPermissionsNewController.getAccountContactRelation(contactId, isSecondaryRegistration);

            //Process Account Contact Relationship
            Map<Id, AccountContactRelation> acrMap = D1_AddUserPermissionsNewController.processAccountContactRelation(accContactRelationList, isSecondaryRegistration);

            //Get Account Details based on Direct/InDirect
            if(isDirect){
                userPermissionWrapperList = createDirectUserPermissionWrapper(acrMap, userTypeRoleMap, isSecondaryRegistration);
            }else{
                userPermissionWrapperList = createInDirectUserPermissionWrapper(acrMap, userTypeRoleMap, isSecondaryRegistration);
            }
            return userPermissionWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<UserPermissionWrapper> getEditAccountPermissions(String contactId, String primaryContactId, Boolean isSecondaryEdit){
        try {
            List<UserPermissionWrapper> userPermissionWrapperList = new List<UserPermissionWrapper>();
            //Get Contact
            Contact con = D1_AddUserPermissionsNewController.getContact(contactId);
            //String userType = con.Account.Direct_Customer__c ? DIRECTBUYER : INDIRECTBUYER;
            Boolean isDirect = con.Account.Direct_Customer__c;
            String countryCode = con.Account.Country_Code__c;
            //143257
            String accountChannel = con.Account.Global_Channel__c;
            String userTypeId = D1_AddUserPermissionsNewController.getUserTypeId(isSecondaryEdit, countryCode, isDirect,con.Preferred_Language__c,accountChannel);
            //Get User Type Role
            Map<String, D1_User_Types_Role__c> userTypeRoleMap = D1_AddUserPermissionsNewController.getUserTypeRole(userTypeId);
            //Get Account Contact Relationship Records
            List<AccountContactRelation> accContactRelationList = D1_AddUserPermissionsNewController.getAccountContactRelation(contactId, isSecondaryEdit);
            //Process Account Contact Relationship
            Map<Id, AccountContactRelation> acrMap = D1_AddUserPermissionsNewController.processAccountContactRelation(accContactRelationList, false);
            //Get Primary User(Logged-In) Permissions
            List<AccountContactRelation> primaryAccContactRelationList = new List<AccountContactRelation>();
            Map<Id, AccountContactRelation> primaryAcrMap = new Map<Id, AccountContactRelation>();

            if(isSecondaryEdit){
                //Get Account Contact Relationship Records
                primaryAccContactRelationList = D1_AddUserPermissionsNewController.getAccountContactRelation(primaryContactId, isSecondaryEdit);

                //Process Account Contact Relationship
                primaryAcrMap = D1_AddUserPermissionsNewController.processAccountContactRelation(primaryAccContactRelationList, true);

                //Remove Accounts from acrMap which dont exist in primaryAcrMap because primary user can edit access to account to which they hv access
                for(Id accId : acrMap.keySet()){
                    if(!primaryAcrMap.containsKey(accId)){
                        acrMap.remove(accId);
                    }
                }
            }else{
                primaryAcrMap = acrMap;
            }
            //Get Account Details based on Direct/InDirect
            if(isDirect){
                userPermissionWrapperList = editDirectUserPermissionWrapper(acrMap, primaryAcrMap, userTypeRoleMap, isSecondaryEdit);
            }else{
                userPermissionWrapperList = editInDirectUserPermissionWrapper(acrMap, primaryAcrMap, userTypeRoleMap, isSecondaryEdit);
            }

            return userPermissionWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }   
    //Method to get Indirect Accounts Details
    public static List<UserPermissionWrapper> createInDirectUserPermissionWrapper(Map<Id, AccountContactRelation> acrMap, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryRegistration){
        List<UserPermissionWrapper> userPermissionWrapperList = new List<UserPermissionWrapper>();
        List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();

        for(Account acc : [SELECT Id, Name, KUNNR__c, BillingCity FROM Account WHERE Id IN :acrMap.keySet() AND Deletion_Flag_from_SAP__c = false]){ //DGD-430 : Added Deletion_Flag_from_SAP__c = false
            accountWrapperList.add(createAccountWrapper(acc, acrMap.get(acc.Id), userTypeRoleMap, isSecondaryRegistration));
        }
        //Create userPermissionWrapperList
        userPermissionWrapperList.add(createUserPermissionWrapper(System.Label.D1_Accounts, accountWrapperList, null, null, 0)); //'Accounts'
        return userPermissionWrapperList;
    }
    //Method to get Indirect Accounts Details
    public static List<UserPermissionWrapper> createDirectUserPermissionWrapper(Map<Id, AccountContactRelation> acrMap, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryRegistration){
        List<UserPermissionWrapper> userPermissionWrapperList = new List<UserPermissionWrapper>();
        Map<Id, AccountWrapper> payerAccountWrapperMap = new Map<Id, AccountWrapper>();
        Map<Id, AccountWrapper> soldAccountWrapperMap = new Map<Id, AccountWrapper>();
        Map<Id, List<AccountWrapper>> payerSoldToWrapperMap = new Map<Id, List<AccountWrapper>>();
        Map<Id, Set<Id>> payerSoldToMap = new Map<Id, Set<Id>>();
        Integer i = 0;
        //Get Partner Functions
        for(PNR_Partner_Function__c pnr : [SELECT Id, PNR_Sold_To__c, PNR_Customer_No__c, PNR_Customer_No__r.KUNNR__c, PNR_Customer_No__r.Name, PNR_Customer_No__r.BillingCity, PNR_Type__c FROM PNR_Partner_Function__c 
                                            WHERE PNR_Sold_To__c IN :acrMap.keySet() AND (PNR_Type__c =: SOLDTO OR PNR_Type__c =: PAYER) AND PNR_Sold_To__r.Deletion_Flag_from_SAP__c = false ORDER BY PNR_Sold_To__c, PNR_Type__c])
        {
            //Creating Map of Payer Account Wrapper
            if(pnr.PNR_Type__c == PAYER && (acrMap.containsKey(pnr.PNR_Customer_No__c) || !isSecondaryRegistration)){
                payerAccountWrapperMap.put(pnr.PNR_Customer_No__c, createAccountWrapper(pnr, acrMap.get(pnr.PNR_Customer_No__c), userTypeRoleMap, isSecondaryRegistration));
                if(payerSoldToMap.containsKey(pnr.PNR_Customer_No__c)){
                    payerSoldToMap.get(pnr.PNR_Customer_No__c).add(pnr.PNR_Sold_To__c);
                }else{
                    payerSoldToMap.put(pnr.PNR_Customer_No__c, new Set<Id>{pnr.PNR_Sold_To__c});
                }
            }
            //Creating Map of SoldTo Account Wrapper
            else if(pnr.PNR_Type__c == SOLDTO){
                soldAccountWrapperMap.put(pnr.PNR_Sold_To__c, createAccountWrapper(pnr, acrMap.get(pnr.PNR_Customer_No__c), userTypeRoleMap, isSecondaryRegistration));
            }
        }
        //Merge payerSoldToMap & soldAccountWrapperMap
        if(payerSoldToMap.size()>0){
            for(Id payerId : payerSoldToMap.keySet()){
                List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
                for(Id soldToId : payerSoldToMap.get(payerId)){
                    if(soldAccountWrapperMap.containsKey(soldToId)){
                        accountWrapperList.add(soldAccountWrapperMap.get(soldToId));
                        //check sold is selected, if yes make payer checkbox as enabled
                        if(soldAccountWrapperMap.get(soldToId).isSelected){
                            payerAccountWrapperMap.get(payerId).isDisabled = false;
                        }                        
                        //Remove added sold to from soldAccountWrapperMap
                        soldAccountWrapperMap.remove(soldToId);
                    }
                }
                //Add to payerSoldToWrapperMap only if we have sold-to related to payer, else ignore
                if(accountWrapperList.size()>0){
                    payerSoldToWrapperMap.put(payerId, accountWrapperList);
                }
            }
        }
        //Create userPermissionWrapperList
        if(payerSoldToWrapperMap.size()>0){
            for(Id payerId : payerSoldToWrapperMap.keySet()){
                userPermissionWrapperList.add(createUserPermissionWrapper(System.Label.D1_Accounts, payerSoldToWrapperMap.get(payerId), System.Label.D1_Associated_Payer , payerAccountWrapperMap.get(payerId), i));//'Accounts'
                i++;
            }
        }
        //Add remaining sold-to where we dont have any payer to userPermissionWrapperList
        if(soldAccountWrapperMap != null && soldAccountWrapperMap.size()>0){
            userPermissionWrapperList.add(createUserPermissionWrapper(System.Label.D1_Accounts, soldAccountWrapperMap.values(), null, null, i));//'Accounts'
        }
        return userPermissionWrapperList;
    }
    //Method to get Indirect Accounts Details
    public static List<UserPermissionWrapper> editInDirectUserPermissionWrapper(Map<Id, AccountContactRelation> acrMap, Map<Id, AccountContactRelation> primaryACRMap, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryEdit){
        List<UserPermissionWrapper> userPermissionWrapperList = new List<UserPermissionWrapper>();
        List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();

        for(Account acc : [SELECT Id, Name, KUNNR__c, BillingCity FROM Account WHERE Id IN :primaryACRMap.keySet()]){
            AccountWrapper accountWrapper = createEditAccountWrapper(acc, acrMap.containsKey(acc.Id) ? acrMap.get(acc.Id) : null, primaryACRMap.containsKey(acc.Id) ? primaryACRMap.get(acc.Id) : null, userTypeRoleMap, isSecondaryEdit);
            accountWrapperList.add(accountWrapper);
        }
        //Create userPermissionWrapperList
        userPermissionWrapperList.add(createUserPermissionWrapper(System.Label.D1_Accounts, accountWrapperList, null, null, 0));//'Accounts'

        return userPermissionWrapperList;
    }
    //Method
    public static List<UserPermissionWrapper> editDirectUserPermissionWrapper(Map<Id, AccountContactRelation> acrMap, Map<Id, AccountContactRelation> primaryACRMap, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryEdit){
        List<UserPermissionWrapper> userPermissionWrapperList = new List<UserPermissionWrapper>();
        Map<Id, AccountWrapper> payerAccountWrapperMap = new Map<Id, AccountWrapper>();
        Map<Id, AccountWrapper> soldAccountWrapperMap = new Map<Id, AccountWrapper>();
        Map<Id, List<AccountWrapper>> payerSoldToWrapperMap = new Map<Id, List<AccountWrapper>>();
        Map<Id, Set<Id>> payerSoldToMap = new Map<Id, Set<Id>>();
        Integer i = 0;
        //Get Partner Functions
        for(PNR_Partner_Function__c pnr : [SELECT Id, PNR_Sold_To__c, PNR_Customer_No__c, PNR_Customer_No__r.KUNNR__c, PNR_Customer_No__r.Name, PNR_Customer_No__r.BillingCity, PNR_Type__c FROM PNR_Partner_Function__c 
                                            WHERE PNR_Sold_To__c IN :primaryACRMap.keySet() AND (PNR_Type__c =: SOLDTO OR PNR_Type__c =: PAYER) AND PNR_Sold_To__r.Deletion_Flag_from_SAP__c = false ORDER BY PNR_Sold_To__c, PNR_Type__c])
        {
            //Creating Map of Payer Account Wrapper
            if(pnr.PNR_Type__c == PAYER && (primaryACRMap.containsKey(pnr.PNR_Customer_No__c) || !isSecondaryEdit)){
                payerAccountWrapperMap.put(pnr.PNR_Customer_No__c, createEditAccountWrapper(pnr, acrMap.containsKey(pnr.PNR_Customer_No__c) ? acrMap.get(pnr.PNR_Customer_No__c) : null, primaryACRMap.containsKey(pnr.PNR_Customer_No__c) ? primaryACRMap.get(pnr.PNR_Customer_No__c) : null, userTypeRoleMap, isSecondaryEdit));
                if(payerSoldToMap.containsKey(pnr.PNR_Customer_No__c)){
                    payerSoldToMap.get(pnr.PNR_Customer_No__c).add(pnr.PNR_Sold_To__c);
                }else{
                    payerSoldToMap.put(pnr.PNR_Customer_No__c, new Set<Id>{pnr.PNR_Sold_To__c});
                }
            }
            //Creating Map of SoldTo Account Wrapper
            else if(pnr.PNR_Type__c == SOLDTO){
                soldAccountWrapperMap.put(pnr.PNR_Sold_To__c, createEditAccountWrapper(pnr, acrMap.containsKey(pnr.PNR_Customer_No__c) ? acrMap.get(pnr.PNR_Customer_No__c) : null, primaryACRMap.containsKey(pnr.PNR_Customer_No__c) ? primaryACRMap.get(pnr.PNR_Customer_No__c) : null, userTypeRoleMap, isSecondaryEdit));
            }
        }
        //Merge payerSoldToMap & soldAccountWrapperMap
        if(payerSoldToMap.size()>0){
            for(Id payerId : payerSoldToMap.keySet()){
                List<AccountWrapper> accountWrapperList = new List<AccountWrapper>();
                for(Id soldToId : payerSoldToMap.get(payerId)){
                    if(soldAccountWrapperMap.containsKey(soldToId)){
                        accountWrapperList.add(soldAccountWrapperMap.get(soldToId));

                        //check sold is selected, if yes make payer checkbox as enabled
                        if(soldAccountWrapperMap.get(soldToId).isSelected){
                            payerAccountWrapperMap.get(payerId).isDisabled = false;
                        }

                        //Remove added sold to from soldAccountWrapperMap
                        soldAccountWrapperMap.remove(soldToId);
                    }
                }
                //Add to payerSoldToWrapperMap only if we have sold-to related to payer, else ignore
                if(accountWrapperList.size()>0){
                    payerSoldToWrapperMap.put(payerId, accountWrapperList);
                }
            }
        }
        //Create userPermissionWrapperList
        if(payerSoldToWrapperMap.size()>0){
            for(Id payerId : payerSoldToWrapperMap.keySet()){
                userPermissionWrapperList.add(createUserPermissionWrapper(System.Label.D1_Accounts, payerSoldToWrapperMap.get(payerId), System.Label.D1_Associated_Payer , payerAccountWrapperMap.get(payerId), i));//'Accounts'
                i++;
            }
        }
        //Add remaining sold-to where we dont have any payer to userPermissionWrapperList
        if(soldAccountWrapperMap != null && soldAccountWrapperMap.size()>0){
            userPermissionWrapperList.add(createUserPermissionWrapper(System.Label.D1_Accounts, soldAccountWrapperMap.values(), null, null, i));//'Accounts'
        }

        return userPermissionWrapperList;
    }

    //Method to create Permission Wrapper
    public static PermissionWrapper createPermissionWrapper(D1_User_Types_Role__c userTypeRole){
        PermissionWrapper permissionWrapper = new PermissionWrapper();
        permissionWrapper.permissionWrapperKey = userTypeRole.D1_User_Role__r.Access_Type__c;
        permissionWrapper.permissionLabel = userTypeRole.Display_Name__c != null ? userTypeRole.Display_Name__c : userTypeRole.D1_User_Role__r.Access_Type__c;
        permissionWrapper.permissionName = userTypeRole.D1_User_Role__r.Access_Type__c;
        permissionWrapper.isDefault = userTypeRole.D1_User_Role__r.IsDefault__c;
        permissionWrapper.isDisabled = false;
        permissionWrapper.isSelected = false;

        return permissionWrapper;
    }

    //Method to create AccountWrapper
    public static AccountWrapper createAccountWrapper(Account acc, AccountContactRelation acr, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryRegistration){
        AccountWrapper accountWrapper = new AccountWrapper();
        accountWrapper.accountId = acc.Id;
        accountWrapper.accountWrapperKey = acc.Id + '_' + SOLDTO;
        accountWrapper.accountNumber = acc.KUNNR__c;
        accountWrapper.accountName = acc.Name;
        accountWrapper.accountCity = acc.BillingCity;
        accountWrapper.accountType = SOLDTO;
        accountWrapper.isSelected = (acr!= null && acr.IsDirect && !isSecondaryRegistration) ? true : false; //NCP-5077
        //NCP-5077: Mark isSelected for Primary Account of Contact
        if(acr!= null && acr.IsDirect && !isSecondaryRegistration){ //this is for Backend Registration
            accountWrapper.isSelected = true;
        }else if(acr != null && acr.AccountId == effectiveAccountId && isSecondaryRegistration){ //this is for secondary user registration
            accountWrapper.isSelected = true;
        }else{
            accountWrapper.isSelected = false;
        }
        accountWrapper.isDisabled = accountWrapper.isSelected ? true : false; //NCP-5077
        accountWrapper.permissionWrapperList = new List<PermissionWrapper>();
        //Create Permission Wrapper List
        if(String.isNotBlank(acr.D1_Roles__c) || !isSecondaryRegistration){
            List<String> roleList = String.isNotBlank(acr.D1_Roles__c) ? acr.D1_Roles__c.split(';') : new List<String>();
            for(string role : userTypeRoleMap.keySet()){
                if(roleList.contains(role) || !isSecondaryRegistration){
                    D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                    PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRoleMap.get(role));
                    permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                    permissionWrapper.isSelected = (accountWrapper.isSelected && userTypeRole.D1_User_Role__r.IsDefault__c) ? true : false; //NCP-5077
                    permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c; //NCP-5077
                    accountWrapper.permissionWrapperList.add(permissionWrapper);
                }
            }
        }
        return accountWrapper;
    }
    //Method to create AccountWrapper
    public static AccountWrapper createAccountWrapper(PNR_Partner_Function__c pnr, AccountContactRelation acr, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryRegistration){
        AccountWrapper accountWrapper = new AccountWrapper();
        accountWrapper.accountId = pnr.PNR_Customer_No__c;
        accountWrapper.accountWrapperKey = pnr.PNR_Customer_No__c + '_' + pnr.PNR_Type__c;
        accountWrapper.accountNumber = pnr.PNR_Customer_No__r.KUNNR__c;
        accountWrapper.accountName = pnr.PNR_Customer_No__r.Name;
        accountWrapper.accountCity = pnr.PNR_Customer_No__r.BillingCity;
        accountWrapper.accountType = pnr.PNR_Type__c;
        //NCP-5077: Mark isSelected for Primary Account of Contact
        if(pnr.PNR_Type__c == SOLDTO && acr!= null && acr.IsDirect && !isSecondaryRegistration){ //this is for Backend Registration
            accountWrapper.isSelected = true;
        }else if(pnr.PNR_Type__c == SOLDTO && acr != null && acr.AccountId == effectiveAccountId && isSecondaryRegistration){ //this is for secondary user registration
            accountWrapper.isSelected = true;
        }else{
            accountWrapper.isSelected = false;
        }
        accountWrapper.isDisabled = (pnr.PNR_Type__c == PAYER || accountWrapper.isSelected) ? true : false; //NCP-5077
        accountWrapper.permissionWrapperList = new List<PermissionWrapper>();
        //Create Permission Wrapper List
        if(acr != null && String.isNotBlank(acr.D1_Roles__c)){
            List<String> roleList = acr.D1_Roles__c.split(';');
            for(string role : userTypeRoleMap.keySet()){
                if(roleList.contains(role)){
                    if((pnr.PNR_Type__c == PAYER && PAYERPERMISSION.contains(role)) || (pnr.PNR_Type__c == SOLDTO && role != ACCOUNTBALANCES)){
                        D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                        PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRoleMap.get(role));
                        permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                        permissionWrapper.isSelected = (accountWrapper.isSelected && userTypeRole.D1_User_Role__r.IsDefault__c) ? true : false; //NCP-5077
                        permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c; //NCP-5077
                        accountWrapper.permissionWrapperList.add(permissionWrapper);
                    }
                }
            }
        }else{
            for(string role : userTypeRoleMap.keySet()){
                if((pnr.PNR_Type__c == PAYER && PAYERPERMISSION.contains(role)) || (pnr.PNR_Type__c == SOLDTO && role != ACCOUNTBALANCES)){
                    D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                    PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRoleMap.get(role));
                    permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                    permissionWrapper.isSelected = (accountWrapper.isSelected && userTypeRole.D1_User_Role__r.IsDefault__c) ? true : false; //NCP-5077
                    permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c; //NCP-5077
                    accountWrapper.permissionWrapperList.add(permissionWrapper);
                }
            }
        }
        return accountWrapper;
    }
    //Method to create AccountWrapper
    public static AccountWrapper createEditAccountWrapper(Account acc, AccountContactRelation acr, AccountContactRelation primaryACR, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryEdit){
        AccountWrapper accountWrapper = new AccountWrapper();
        accountWrapper.accountId = acc.Id;
        accountWrapper.accountWrapperKey = acc.Id + '_' + SOLDTO;
        accountWrapper.accountNumber = acc.KUNNR__c;
        accountWrapper.accountName = acc.Name;
        accountWrapper.accountCity = acc.BillingCity;
        accountWrapper.accountType = SOLDTO;
        accountWrapper.isSelected = acr != null && acr.D1_Active__c ? true : false;
        accountWrapper.isDisabled = false;
        accountWrapper.permissionWrapperList = new List<PermissionWrapper>();
        //Create Permission Wrapper List
        if(primaryACR != null && String.isNotBlank(primaryACR.D1_Roles__c)){
            List<String> roleList = String.isNotBlank(primaryACR.D1_Roles__c) ? primaryACR.D1_Roles__c.split(';') : new List<String>();
            List<String> userRoleList = new List<String>();
            if(acr != null && acr.D1_Active__c && String.isNotBlank(acr.D1_Roles__c)){
                userRoleList = acr.D1_Roles__c.split(';');
            }
            for(string role : userTypeRoleMap.keySet()){
                if((roleList.contains(role) && isSecondaryEdit) || !isSecondaryEdit){
                    D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                    PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRole);
                    permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                    //Check if permission is selected for user or not
                    if(userRoleList != null && userRoleList.size()>0 && userRoleList.contains(role)){
                        permissionWrapper.isSelected = true;
                        permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                    }else{
                        permissionWrapper.isSelected = false;
                        permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                    }
                    accountWrapper.permissionWrapperList.add(permissionWrapper);
                }
            }
        }else{
            List<String> userRoleList = new List<String>();
            if(acr != null && acr.D1_Active__c && String.isNotBlank(acr.D1_Roles__c)){
                userRoleList = acr.D1_Roles__c.split(';');
            }
            for(string role : userTypeRoleMap.keySet()){
                D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRole);
                permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                //Check if permission is selected for user or not
                if(userRoleList != null && userRoleList.size()>0 && userRoleList.contains(role)){
                    permissionWrapper.isSelected = true;
                    permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                }else{
                    permissionWrapper.isSelected = false;
                    permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                }
                accountWrapper.permissionWrapperList.add(permissionWrapper);
            }
        }
        return accountWrapper;
    }
    //Method to create AccountWrapper
    public static AccountWrapper createEditAccountWrapper(PNR_Partner_Function__c pnr, AccountContactRelation acr, AccountContactRelation primaryACR, Map<String, D1_User_Types_Role__c> userTypeRoleMap, Boolean isSecondaryEdit){
        AccountWrapper accountWrapper = new AccountWrapper();
        accountWrapper.accountId = pnr.PNR_Customer_No__c;
        accountWrapper.accountWrapperKey = pnr.PNR_Customer_No__c + '_' + pnr.PNR_Type__c;
        accountWrapper.accountNumber = pnr.PNR_Customer_No__r.KUNNR__c;
        accountWrapper.accountName = pnr.PNR_Customer_No__r.Name;
        accountWrapper.accountCity = pnr.PNR_Customer_No__r.BillingCity;
        accountWrapper.accountType = pnr.PNR_Type__c;
        accountWrapper.isSelected = acr != null && acr.D1_Active__c ? true : false;
        accountWrapper.isDisabled = (pnr.PNR_Type__c == PAYER && acr != null && acr.D1_Active__c) || pnr.PNR_Type__c == SOLDTO ? false : true;
        accountWrapper.permissionWrapperList = new List<PermissionWrapper>();

        //Create Permission Wrapper List
        if(primaryACR != null && String.isNotBlank(primaryACR.D1_Roles__c)){
            List<String> roleList = primaryACR.D1_Roles__c.split(';');
            List<String> userRoleList = new List<String>();
            if(acr != null && acr.D1_Active__c && String.isNotBlank(acr.D1_Roles__c)){
                userRoleList = acr.D1_Roles__c.split(';');
            }
            for(string role : userTypeRoleMap.keySet()){
                if((roleList.contains(role) && isSecondaryEdit) || !isSecondaryEdit){
                    if((pnr.PNR_Type__c == PAYER && PAYERPERMISSION.contains(role)) || (pnr.PNR_Type__c == SOLDTO && role != ACCOUNTBALANCES)){
                        D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                        PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRole);
                        permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                        //Check if permission is selected for user or not
                        if(userRoleList != null && userRoleList.size()>0 && userRoleList.contains(role)){
                            permissionWrapper.isSelected = true;
                            permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                        }else{
                            permissionWrapper.isSelected = false;
                            permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                        }
                        accountWrapper.permissionWrapperList.add(permissionWrapper);
                    }
                }
            }
        }else{
            List<String> userRoleList = new List<String>();
            if(acr != null && acr.D1_Active__c && String.isNotBlank(acr.D1_Roles__c)){
                userRoleList = acr.D1_Roles__c.split(';');
            }
            for(string role : userTypeRoleMap.keySet()){
                if((pnr.PNR_Type__c == PAYER && PAYERPERMISSION.contains(role)) || (pnr.PNR_Type__c == SOLDTO && role != ACCOUNTBALANCES)){
                    D1_User_Types_Role__c userTypeRole = userTypeRoleMap.get(role);
                    PermissionWrapper permissionWrapper = createPermissionWrapper(userTypeRole);
                    permissionWrapper.permissionWrapperKey = accountWrapper.accountWrapperKey + '_' + permissionWrapper.permissionName;
                    //Check if permission is selected for user or not
                    if(userRoleList != null && userRoleList.size()>0 && userRoleList.contains(role)){
                        permissionWrapper.isSelected = true;
                        permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                    }else{
                        permissionWrapper.isSelected = false;
                        permissionWrapper.isDisabled = userTypeRole.D1_User_Role__r.IsDefault__c;
                    }
                    accountWrapper.permissionWrapperList.add(permissionWrapper);
                }
            }
        }
        return accountWrapper;
    }
    //Method to create User Permission Wrapper
    public static UserPermissionWrapper createUserPermissionWrapper(string accountLabel, List<AccountWrapper> accountWrapperList, string payerLabel, AccountWrapper payerAccountWrapper, Integer index){
        UserPermissionWrapper userPermissionWrapper = new UserPermissionWrapper();
        userPermissionWrapper.index = index;
        userPermissionWrapper.accountLabel = accountLabel;
        userPermissionWrapper.accountWrapperList = accountWrapperList;
        userPermissionWrapper.payerLabel = payerLabel;
        userPermissionWrapper.payerAccountWrapper = payerAccountWrapper;        
        return userPermissionWrapper;
    }
    @AuraEnabled
    public static ResponseWrapper addUserPermissions(D1_UserRegistrationDetailWrapper userRegWrapper, List<UserPermissionWrapper> userPermissionWrapperList, Boolean isSecondaryRegistration){
        try {
            ResponseWrapper responseWrapper = new ResponseWrapper();
            Id contactId;
            Map<Id, String> accountPermissionMap = new Map<Id, String>();
            Map<Id, String> accountNameMap = new Map<Id, String>();            
            Set<Id> selectedAccIdSet = new Set<Id>(); //NCP-6447
            //Set<Id> partnerPlusEnbldAcc = new Set<Id>();
            //Get Logged In User Details
            User usr = D1_AddUserPermissionsNewController.getUser();            
            //Parse userPermissionWrapperList to get required permissions
            for(UserPermissionWrapper userPermissionWrapper : userPermissionWrapperList){
                //Get Account Permissions
                for(AccountWrapper accountWrapper : userPermissionWrapper.accountWrapperList){
                    //check Account is selected
                    if(accountWrapper.isSelected){
                        string permission = '';
                        for(PermissionWrapper permissionWrapper : accountWrapper.permissionWrapperList){
                            if(permissionWrapper.isSelected){
                                permission += permissionWrapper.permissionName + ';';
                            }
                        }
                        //Add account selected permission to map
                        accountPermissionMap.put(accountWrapper.accountId, permission);
                        accountNameMap.put(accountWrapper.accountId, accountWrapper.accountName);
                        selectedAccIdSet.add(accountWrapper.accountId); //NCP-6477
                    }
                }
                //Get Payer Permissions
                if(userPermissionWrapper.payerAccountWrapper != null){
                    AccountWrapper payerAccountWrapper = userPermissionWrapper.payerAccountWrapper;
                    if(payerAccountWrapper.isSelected){
                        string permission = accountPermissionMap.containsKey(payerAccountWrapper.accountId) ? accountPermissionMap.get(payerAccountWrapper.accountId) : '';
                        for(PermissionWrapper permissionWrapper : payerAccountWrapper.permissionWrapperList){
                            if(permissionWrapper.isSelected){
                                if(!permission.contains(permissionWrapper.permissionName)){
                                    permission += permissionWrapper.permissionName + ';';
                                }  
                            }
                        }
                        //Add account selected permission to map
                        accountPermissionMap.put(payerAccountWrapper.accountId, permission);
                        accountNameMap.put(payerAccountWrapper.accountId, payerAccountWrapper.accountName);
                    }
                }
            }
            //NCP-7665 : If Account is Partner Plus Enabled then add specific permission
            // partnerPlusEnbldAcc = D1_AddUserPermissionsNewController.checkPartnerPlusStatus(selectedAccIdSet);
            // String prMsn;
            // for(Id accId: partnerPlusEnbldAcc){
            //     prMsn = accountPermissionMap.get(accId);
            //     prMsn = prMsn + Label.D1_ManagePartnerPlusVal + ';';
            //     accountPermissionMap.put(accId,prMsn);
            // }

            //Update userRegWrapper
            if(isSecondaryRegistration){
                userRegWrapper.userType = usr.D1_User_Type__c;
                userRegWrapper.userTypeId = usr.D1_User_Type_Id__c;
                userRegWrapper.userCountryCode = usr.Available_Countries__c;
                if(usr.D1_User_Type_Id__c != null){
                    userRegWrapper.d1SettingId = [SELECT Id, D1_Setting__c FROM D1_User_Type__c WHERE Id =:usr.D1_User_Type_Id__c LIMIT 1].D1_Setting__c;
                }
                userRegWrapper.LanguageLocaleKey = usr.LanguageLocaleKey;
            }

            //Update Subscription Source
            string subscriptionSource = isSecondaryRegistration ? FRONTEND : BACKEND;
            userRegWrapper.subscriptionSource = subscriptionSource;
            userRegWrapper.regSource = DIAGEOONE;
            userRegWrapper.isSecondaryRegistration = isSecondaryRegistration;

            //Validate for Email Domain Check
            if(isSecondaryRegistration && D1_AddUserPermissionsNewController.checkEmailDoaminRequired(usr.D1_User_Type_Id__c) && !D1_AddUserPermissionsNewController.validEmailDomain(usr.Email, userRegWrapper.email)){
                responseWrapper = createLead(userRegWrapper, accountPermissionMap, accountNameMap); //NCP-4394

                return responseWrapper;
            }
            //Check for contact
            if(isSecondaryRegistration){
                contactId = checkContact(userRegWrapper, userRegWrapper.accountId); //NCP-5077: Use User's Effective Account Id
            }else{
                contactId = userRegWrapper.contactId;
            }

            Boolean isUserFound = false;
            //Check for User
            List<User> usrList = validateUser(userRegWrapper, contactId);
            //Create User
            if(usrList == null || usrList.size()==0){
                D1_UserRegistrationValidator.createUser(userRegWrapper, contactId);
            }else if(usrList.size()>0 && !usrList.get(0).IsActive){                
                //Check if we have any InActive User in system, then activate it else create it
                for(User us : usrList){
                    if(!us.IsActive && us.ContactId != null){
                        isUserFound = true;
                        D1_AddUserPermissionsNewController.updateUser(us.Id);//NCP-6024:update synchronously if user found.
                        //NCP-6024:update other data async with queueable
                        System.enqueueJob(new D1_ACRRegistrationUpdateQueueable(contactId,accountPermissionMap,isSecondaryRegistration,userRegWrapper,selectedAccIdSet));

                        break;
                    }
                }
                if(!isUserFound){
                    D1_UserRegistrationValidator.createUser(userRegWrapper, contactId);
                }
            }            
            //NCP-6024:if user is not found update other related data
            if(!isUserFound){
                D1_AddUserPermissionsNewController.addUserRelatedRecordUpdate(contactId,accountPermissionMap,isSecondaryRegistration,userRegWrapper,selectedAccIdSet);
            }
            //Update Response
            responseWrapper.isSuccess = true;
            responseWrapper.isUserCreated = true;
            return responseWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + 'line Number'+e.getLineNumber());
        }
    }

/*
 * //114761
    //NCP-7157
    @AuraEnabled
    public static void addOrderPermission(String contactId, String accountId){
        User u1 = [SELECT Id, ContactId FROM User WHERE contactId =:contactId LIMIT 1];
        List<String> permissions = new List<String>();
        for(AccountContactRelation relation: [SELECT id, D1_Roles__c FROM AccountContactRelation WHERE D1_Active__c = true AND accountId =: accountId AND ContactId =: contactId LIMIT 1])
        {
            permissions = relation.D1_Roles__c == null ? new List<String>() : relation.D1_Roles__c.split(';');
        }
        Set<String> permissionsToAdd = new Set<String>();
        for(String permission: permissions){
            permissionsToAdd.add(permission.trim());
        }                
        Set<String> orderPermissionsToAdd = new Set<String>();
        if(permissionsToAdd.contains(ORDER_PERMISSION)){
            orderPermissionsToAdd.add(B2B_USER_PERMISSION);
            orderPermissionsToAdd.add(ORDER_PERMISSION);
        }
        Map<String,Id> mapOfPermissionSetNameToId = new Map<String,Id>();
        for(PermissionSet psObj : [SELECT Id,Name,Label FROM PermissionSet WHERE Label IN ('B2B Commerce User', 'Ordering')]) {
            mapOfPermissionSetNameToId.put(psObj.Label,psObj.Id); 
        }
        if(!orderPermissionsToAdd.isEmpty()){
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for(String permission: orderPermissionsToAdd){
                assignments.add(new PermissionSetAssignment(AssigneeId = u1.Id, PermissionSetId = mapOfPermissionSetNameToId.get(permission)));
            }          
            insert assignments;
        }
    }
    */
    @AuraEnabled
    public static ResponseWrapper editUserPermissions(Id contactId, List<UserPermissionWrapper> userPermissionWrapperList, Boolean isSecondaryEdit){
        try {
            ResponseWrapper responseWrapper = new ResponseWrapper();
            Map<Id, String> accountPermissionMap = new Map<Id, String>();
            Map<Id, String> accountNameMap = new Map<Id, String>();
            List<AccountContactRelation> insertACRList = new List<AccountContactRelation>();
            List<AccountContactRelation> updateACRList = new List<AccountContactRelation>();
            Set<Id> unselectedAccIdSet = new Set<Id>();
            Set<Id> conIdSet = new Set<Id>{contactId};
            Boolean updateContact = false;
            String exstingPerms; //NCP-7668
            
            //Get Contact
            Contact con = D1_AddUserPermissionsNewController.getContact(contactId);
            Boolean isDirect = con.Account.Direct_Customer__c;
            //143257
            String accountChannel = con.Account.Global_Channel__c;
            //Parse userPermissionWrapperList to get required permissions
            for(UserPermissionWrapper userPermissionWrapper : userPermissionWrapperList){
                //Get Account Permissions
                for(AccountWrapper accountWrapper : userPermissionWrapper.accountWrapperList){
                    //check Account is selected
                    if(accountWrapper.isSelected){
                        string permission = '';
                        for(PermissionWrapper permissionWrapper : accountWrapper.permissionWrapperList){
                            if(permissionWrapper.isSelected){
                                permission += permissionWrapper.permissionName + ';';
                            }
                        }

                        //Add account selected permission to map
                        accountPermissionMap.put(accountWrapper.accountId, permission);
                        accountNameMap.put(accountWrapper.accountId, accountWrapper.accountName);
                    }else{
                        unselectedAccIdSet.add(accountWrapper.accountId);
                    }
                }

                //Get Payer Permissions
                if(userPermissionWrapper.payerAccountWrapper != null){
                    AccountWrapper payerAccountWrapper = userPermissionWrapper.payerAccountWrapper;
                    if(payerAccountWrapper.isSelected){
                        string permission = accountPermissionMap.containsKey(payerAccountWrapper.accountId) ? accountPermissionMap.get(payerAccountWrapper.accountId) : '';
                        for(PermissionWrapper permissionWrapper : payerAccountWrapper.permissionWrapperList){
                            if(permissionWrapper.isSelected){
                                if(!permission.contains(permissionWrapper.permissionName)){
                                    permission += permissionWrapper.permissionName + ';';
                                }  
                            }
                        }
                        //Add account selected permission to map
                        accountPermissionMap.put(payerAccountWrapper.accountId, permission);
                        accountNameMap.put(payerAccountWrapper.accountId, payerAccountWrapper.accountName);
                    }else{
                        //Add account ids which are not part of updated permission map(happens only in case sold-to/payer are same)
                        if(!accountPermissionMap.containsKey(payerAccountWrapper.accountId)){
                            unselectedAccIdSet.add(payerAccountWrapper.accountId);
                        }
                    }
                }
            }

            //Check If Secondary User is trying to remove Primary User Access
            for(AccountContactRelation acr : [SELECT Id, D1_User_Role__c FROM AccountContactRelation WHERE ContactId =:contactId AND AccountId IN :unselectedAccIdSet]){
                if(acr.D1_User_Role__c == PRIMARY && isSecondaryEdit){
                    responseWrapper.isSuccess = false;
                    responseWrapper.isPrimaryAccess = true;
                    return responseWrapper;
                }
            }
            
            //Check for AutoPermissions & Partner Plus Enable status for Accounts : NCP-7665, NCP-7668, NCP-7927,143257
            String userTypeId = D1_AddUserPermissionsNewController.getUserTypeId(isSecondaryEdit, con.Account.Country_Code__c, isDirect, con.Preferred_Language__c,accountChannel);

            Map<Id,Account> accMap = D1_AddUserPermissionsNewController.getPartnerEnableStatus(userTypeId, accountPermissionMap.keySet());
            Map<String,String> autoPermissions = D1_AddUserPermissionsNewController.getAutoPermissions(userTypeId);
            String autoPermForPrimary = autoPermissions.containsKey(D1_AddUserPermissionsNewController.PRIMARY) ? autoPermissions.get(D1_AddUserPermissionsNewController.PRIMARY) : '';
            String autoPermForSecondary = autoPermissions.containsKey(D1_AddUserPermissionsNewController.MEMBEROFSTAFF) ? autoPermissions.get(D1_AddUserPermissionsNewController.MEMBEROFSTAFF) : '';

            //Process Update Permission
            if(accountPermissionMap != null && accountPermissionMap.size()>0){
                //check Account Contact Relation records for contact which we enabling for D1
                Map<Id, AccountContactRelation> existingACRMap = D1_AddUserPermissionsNewController.getAccountContactRelation(contactId, accountPermissionMap.keySet());
                
                //Get Primary ACR
                Map<Id, AccountContactRelation> primaryACRMap = D1_AddUserPermissionsNewController.getPrimaryAccountContactRelation(accountPermissionMap.keySet());

                //Check for which Account ACR needs to created and for which ACR needs to updated
                for(Id accId : accountPermissionMap.keySet()){
                    String userRole = primaryACRMap.containsKey(accId) ? MEMBEROFSTAFF : PRIMARY;
                    
                    //NCP-7668: Add Primary AutoPermissions
                    exstingPerms = accountPermissionMap.get(accId);
                    if((userRole == PRIMARY || (existingACRMap.containsKey(accId) && String.isNotBlank(existingACRMap.get(accId).D1_User_Role__c) && existingACRMap.get(accId).D1_User_Role__c == PRIMARY)) && String.isNotBlank(autoPermForPrimary)){
                        exstingPerms = exstingPerms + ';' + autoPermForPrimary;
                    }

                    //NCP-7927: Add Secondary AutoPermissions
                    if((userRole == MEMBEROFSTAFF || (existingACRMap.containsKey(accId) && String.isNotBlank(existingACRMap.get(accId).D1_User_Role__c) && existingACRMap.get(accId).D1_User_Role__c == MEMBEROFSTAFF)) && String.isNotBlank(autoPermForSecondary)){
                        exstingPerms = exstingPerms + ';' + autoPermForSecondary;
                    }

                    //NCP-7665: Add Partner Plus
                    if(accMap.containsKey(accId) && accMap.get(accId).Partner_Plus_Enabled__c && !exstingPerms.contains(MANAGEPARTNERPLUS)){
                        exstingPerms = exstingPerms + ';' + MANAGEPARTNERPLUS;
                    }
                    
                    if(existingACRMap.containsKey(accId)){
                        updateACRList.add(D1_AddUserPermissionsNewController.updateACR(existingACRMap.get(accId).Id, exstingPerms, existingACRMap.containsKey(accId) && String.isNotBlank(existingACRMap.get(accId).D1_User_Role__c) ? existingACRMap.get(accId).D1_User_Role__c : userRole));
                    }else{
                        insertACRList.add(D1_AddUserPermissionsNewController.createACR(contactId, accId, exstingPerms, userRole));
                    }
                }
            }

            //Process Remove Permission/Access from Account
            if(unselectedAccIdSet != null && unselectedAccIdSet.size()>0){
                //Get Account Contact Relation records for contact which we disabling for D1
                Map<Id, AccountContactRelation> deactivateACRMap = D1_AddUserPermissionsNewController.getAccountContactRelation(contactId, unselectedAccIdSet);
                for(AccountContactRelation acr : deactivateACRMap.values()){
                    acr.D1_Active__c = false;
                    acr.D1_User_Role__c = '';
                    acr.D1_Roles__c = '';

                    updateACRList.add(acr);

                    //Check if Direct Account is marked for deletion. If yes we need to transfer Contact to another Account
                    if(acr.IsDirect){
                        updateContact = true;
                    }
                }
            }

            //Update ACR
            if(updateACRList.size()>0){
                update updateACRList;
            }

            //Insert ACR
            if(insertACRList.size()>0){
                insert insertACRList;
            }

            //Update Contact
            if(updateContact){
                List<AccountContactRelation> acrList;
                if(isDirect){
                    acrList = [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE ContactId =:contactId AND D1_Active__c = true AND AccountId IN (SELECT PNR_Sold_To__c FROM PNR_Partner_Function__c WHERE PNR_Type__c = 'Sold-To') ORDER By CreatedDate, Account.Name DESC LIMIT 1];
                }else{
                    acrList = [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE ContactId =:contactId AND D1_Active__c = true ORDER By CreatedDate, Account.Name DESC LIMIT 1];
                }               
                if(acrList != null && acrList.size()>0){
                    for(AccountContactRelation acr : acrList){
                        //con.Id = acr.ContactId;
                        con.AccountId = acr.AccountId;

                        break;
                    }
                    update con;
                }
            }
            //Deactivate User //NCP-6408
            Set<Id> deactivateContact = D1_MyUserDetailsCtrl.deactivateUserContact(conIdSet);
            List<Contact> updateContactList = new List<Contact>();
            if(!deactivateContact.isEmpty()){
                D1_RegistrationUtility.updateDeactivatedContact(deactivateContact); //NCP-7209
            }
            if(!updateContactList.isEmpty()){
                update updateContactList;
            }
            //Update Response
            responseWrapper.isSuccess = true;
            return responseWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Method to Create Lead (NCP-4394)
    public static ResponseWrapper createLead(D1_UserRegistrationDetailWrapper userRegWrapper, Map<Id, String> accountPermissionMap, Map<Id, String> accountNameMap){
        ResponseWrapper responseWrapper = new ResponseWrapper();

        string accountId = userRegWrapper.accountId;
        D1_UserRegistrationValidator.UserValidationResultWrapper userResultWrapper = new D1_UserRegistrationValidator.UserValidationResultWrapper();

        Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingPostalCode, D1_Registration_Status__c, BillingCountryCode, Country_ISO_Code__c,PhonePrefix__c, Phone__c, Phone, KUNNR__c, SAP_Ship_to__c FROM Account WHERE Id =:accountId LIMIT 1];
        userRegWrapper.outletName = acc.Name;
        userRegWrapper.street = acc.BillingStreet;
        userRegWrapper.city = acc.BillingCity;
        userRegWrapper.postalCode = acc.BillingPostalCode;
        userRegWrapper.countryCode = acc.BillingCountryCode;
        userRegWrapper.phoneNumberPrefix = acc.PhonePrefix__c;
        userRegWrapper.phoneNumber = acc.Phone__c;
        userRegWrapper.phone = acc.Phone;
        userRegWrapper.registrationType = 'Secondary';
        userRegWrapper.description = D1_AddUserPermissionsNewController.createCaseDescription(accountPermissionMap, accountNameMap);
        userRegWrapper.customerSAPCode = acc.KUNNR__c != null ? acc.KUNNR__c : acc.SAP_Ship_to__c; //NCP-5517
        userRegWrapper.leadType = userRegWrapper.userType == DIRECTBUYER ? DIRECTCUSTOMERREGISTRATION : INDIRECTCUSTOMERREGISTRATION;

        string leadWrap = D1_UserRegistrationValidator.convertUserRegistrationDetailWrapper(userRegWrapper);
        //Create Lead
        userResultWrapper = D1_UnknownOutletRegistrationController.createLead(leadWrap);
        //convert userResultWrapper into responseWrapper
        if(userResultWrapper.isSuccess){
            responseWrapper.isSuccess = true;
            responseWrapper.isNotValidEmailDomain = userResultWrapper.isUnknownOutletSuccess != null ? userResultWrapper.isUnknownOutletSuccess : false;
            responseWrapper.isUnknownOutletDuplicate = userResultWrapper.isUnknownOutletDuplicate != null ? userResultWrapper.isUnknownOutletDuplicate : false;
            if(responseWrapper.isUnknownOutletDuplicate){
                responseWrapper.isSuccess = false;
            }
        }else{
            responseWrapper.isSuccess = false;
        }
        return responseWrapper;
    }
    //Check Contact
    public static Id checkContact(D1_UserRegistrationDetailWrapper userRegWrapper, Id accId){
        List<Contact> contactList = [SELECT Id FROM Contact WHERE Email = :userRegWrapper.email];
        if(contactList != null && contactList.size()>0){
            return contactList.get(0).Id;
        }else{
            //Create New Contact
            return createNewContact(userRegWrapper, accId);
        }
    }
    //Method to create new contact
    public static Id createNewContact(D1_UserRegistrationDetailWrapper userRegWrapper, Id accId) {
        Contact newContact = new Contact();
        newContact.FirstName = userRegWrapper.firstName;
        newContact.LastName = userRegWrapper.lastName;
        newContact.Email = userRegWrapper.email;
        newContact.MobilePrefix__c = userRegWrapper.mobileCountryCode;
        newContact.Mobile__c = userRegWrapper.mobile;
        newContact.Contact_Type__c = 'Secondary';
        newContact.AccountId = accId;
        newContact.D1_User_Type__c = userRegWrapper.userTypeId;
        newContact.D1_Setting__c = userRegWrapper.d1SettingId;
        newContact.Preferred_Language__c = userRegWrapper.languageLocaleKey; //NCP-6348
        insert newContact;
        return newContact.Id;
    }
    //Method to Validate User
    public static List<User> validateUser(D1_UserRegistrationDetailWrapper userRegWrapper, Id contactId){
        List<User> usrList = [SELECT Id, IsActive, ContactId FROM User WHERE (Email =:userRegWrapper.email OR ContactId =:contactId) AND Profile.Name =: DIAGEOONE_EXTERNAL_PROFILE ORDER BY IsActive DESC, ContactId DESC NULLS LAST];
	    return usrList;
    }
   
    //Method to check whether user has valid profile or not
    @AuraEnabled
    public static Boolean checkProfile(){        
        Boolean isValid = false;
        String allowedProfile = System.Label.D1_Profiles_for_User_creation;
        String allowedPermission = System.Label.D1_Resend_Invite_Accessible_Permission_Sets;
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
    //NCP-5931
    @AuraEnabled
    public static Map<String,String> validateUserForResend(String contactId){        
        Map<String,String> checkUserForResendInviteResult = new Map<String,String>();
        checkUserForResendInviteResult = D1_AddUserPermissionsNewController.checkUserForResendInvite(contactId);
        if(checkProfile()){
            checkUserForResendInviteResult.put('isProfileAccessible', 'true');
        }
        else{
            checkUserForResendInviteResult.put('isProfileAccessible', 'false');
        }
        return checkUserForResendInviteResult;
    }   

    @AuraEnabled
    public static void resendRegistrationInvite(String userId){
        System.resetPasswordWithEmailTemplate(userId, true, 'D1_ReInvite_Email_to_Customers_Registration');
    }
    
    //Wrapper Class
    public class UserPermissionWrapper {
        @AuraEnabled public integer index {get;set;}
        @AuraEnabled public string accountLabel {get; set;}
        @AuraEnabled public List<AccountWrapper> accountWrapperList {get; set;}
        @AuraEnabled public string payerLabel {get; set;}
        @AuraEnabled public AccountWrapper payerAccountWrapper {get; set;}
    }
    public class AccountWrapper {
        @AuraEnabled public string accountId {get; set;}
        @AuraEnabled public string accountWrapperKey {get;set;}
        @AuraEnabled public string accountNumber {get; set;}
        @AuraEnabled public string accountName {get; set;}
        @AuraEnabled public string accountCity {get; set;}
        @AuraEnabled public string accountType {get; set;}
        @AuraEnabled public boolean isSelected {get; set;}
        @AuraEnabled public boolean isDisabled {get; set;}
        @AuraEnabled public List<PermissionWrapper> permissionWrapperList {get; set;}
    }
    public class PermissionWrapper {
        @AuraEnabled public string permissionWrapperKey {get; set;}
        @AuraEnabled public string permissionLabel {get; set;}
        @AuraEnabled public string permissionName {get; set;}
        @AuraEnabled public boolean isDefault {get; set;}
        @AuraEnabled public boolean isDisabled {get; set;}
        @AuraEnabled public boolean isSelected {get; set;}
    }
    public class ResponseWrapper{
        @AuraEnabled public boolean isSuccess {get; set;}
        @AuraEnabled public boolean isUserCreated {get; set;}
        @AuraEnabled public boolean isNotValidEmailDomain {get; set;}
        @AuraEnabled public boolean isUserExist {get; set;}
        @AuraEnabled public boolean isPrimaryAccess {get; set;}
        @AuraEnabled public boolean isUnknownOutletDuplicate {get; set;}
    }
}