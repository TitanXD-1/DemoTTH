/*
* @name: D1_TransferPrimaryUser
* @discription: D1_TransferPrimaryUser Class for Transfer Primary User functionality 
* @History
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Gaurav           1/9/20     Initial Development(NCP-4310)
* 2.0         Sayan            17/9/21    NCP-4303(When Primary user is the only user in the Account)
* 3.0         Kapil Baliyan    19/08/2022 NCP-7209 
*/
public without sharing class D1_TransferPrimaryUser {
	public static final String SOLDTO = 'Sold-To';
    public static final String PAYER = 'Payer';
    public static final String ACCOUNT_BALANCES = 'Account Balances';
    public static final String USER_MANAGEMENT = 'User Management';
    public static final String DEFAULT_ACCESS = 'Default Access';

    @AuraEnabled
    public static Map<String,Object> getPrimaryAccountInfo(Id contactId){
        if( contactId == null ){
            contactId = [Select id,ContactId from User where Id = :UserInfo.getUserId() limit 1].ContactId;
        }
        Contact contactRec = getContact(contactId);

        Set<Id> acRelationAccountIds = new Set<Id>();
        List<AccountContactRelation> acrListForSelectedContact = [SELECT Id, AccountId, Account.Direct_Customer__c, ContactId, D1_Roles__c,Contact_Type__c, IsDirect,
                                                                  Account.Name, Account.AccountNumber, Account.District__c,
                                                                  Contact.Name, Contact.FirstName, Contact.LastName 
                                                                  FROM AccountContactRelation 
                                                                  WHERE ContactId =:contactId 
                                                                  AND D1_Active__c = true
                                                                  AND D1_User_Role__c = 'Primary'];

        for(AccountContactRelation accConSelectedConRel : acrListForSelectedContact){
            acRelationAccountIds.add(accConSelectedConRel.AccountId);
        }

        Set<Id> accountIdsEligibleForTransfer = new Set<Id>();
        if( contactRec.Account.Direct_Customer__c ){
            List<PNR_Partner_Function__c> partnerFunctions =    [SELECT id, PNR_Customer_No__c
                                                                FROM PNR_Partner_Function__c
                                                                WHERE PNR_Customer_No__c  IN: acRelationAccountIds
                                                                AND (PNR_Type__c =: SOLDTO)
                                                                AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c = false //NCP-3799
                                                                ];
            
            for(PNR_Partner_Function__c partner: partnerFunctions){
                accountIdsEligibleForTransfer.add(partner.PNR_Customer_No__c);
            }
        }
        else{
            accountIdsEligibleForTransfer.addAll(acRelationAccountIds);
        }

        List<AccountContactRelation> acrListForEligibleContact = [SELECT Id, D1_Roles__c, Contact_Type__c, IsDirect,
                                                                    AccountId, Account.Name, Account.AccountNumber, Account.District__c,Account.KUNNR__c,Account.BillingCity,
                                                                    ContactId, Contact.Name, Contact.FirstName, Contact.LastName 
                                                                    FROM AccountContactRelation 
                                                                    WHERE AccountId IN :accountIdsEligibleForTransfer
                                                                    AND ContactId != :contactId 
                                                                    AND D1_Active__c = true
                                                                    AND D1_User_Role__c = 'Member of Staff'];

        Map<Id,AccountInfoWrapper> accountInfoMap = new Map<Id,AccountInfoWrapper>();
        for( AccountContactRelation acr : acrListForEligibleContact ){
            if( !accountInfoMap.containsKey(acr.AccountId) ){
                accountInfoMap.put(acr.AccountId, new AccountInfoWrapper((Account)acr.getsObject('Account')));
                accountIdsEligibleForTransfer.remove(acr.AccountId);//NCP-4303
            }         
            accountInfoMap.get(acr.AccountId).addACR(acr);
        }
        
        for( AccountContactRelation acr : acrListForSelectedContact ){//NCP-4303
            if( accountIdsEligibleForTransfer.contains(acr.AccountId) ){
                accountInfoMap.put(acr.AccountId,new AccountInfoWrapper((Account)acr.getsObject('Account')));
            }
        }

        List<AccountInfoWrapper> accountInfoList = accountInfoMap.values();
        accountInfoList.sort();
        Map<String,Object> result = new Map<String,Object>();
        result.put('contactId',contactId);
        result.put('accountInfoList',accountInfoList);
        return result;
    }

    @AuraEnabled
    public static void updatePrimaryAccountInfo(Id contactId, Boolean deactivateUserAccount, List<Id> selectedACRIds){
        System.Savepoint sp = Database.setSavepoint();
        try{
            Contact contactRec = getContact(contactId);

            //get User Type and User Roles applicable for that
            D1_User_Type__c usrType = getUserType(contactRec.Account.Country_Code__c, (contactRec.Account.Direct_Customer__c? 'Direct Buyer':'Outlet/Retailers'),contactRec.Account.Global_Channel__c );//143286 passing channel param
            Map<String, D1_User_Types_Role__c> userRoleMap = getUserRoleFromUserType(usrType.Id);
            
            //Get ACR which are selected as new Primary contacts
            List<AccountContactRelation> newPrimaryACRList = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE Id IN :selectedACRIds];
            
            //colleact Account Ids for which new Primary contact is Selected
            List<Id> accountIdsToTransfer = new List<Id>();
            for(AccountContactRelation acr : newPrimaryACRList){
                accountIdsToTransfer.add(acr.AccountId);
            }

            //Get Payer partner functions for all Accounts for which new primary contact is selected
            List<PNR_Partner_Function__c> partnerFunctions = [  SELECT id,PNR_Sold_To__c,PNR_Customer_No__c,PNR_Type__c 
                                                                FROM PNR_Partner_Function__c
                                                                WHERE PNR_Sold_To__c  IN: accountIdsToTransfer
                                                                AND PNR_Type__c =: PAYER ];

            //Map of Primary Account Id and Payer Account Ids for that Account
            Map<Id, List<Id>> soldToPayerListMap = new Map<Id, List<Id>>();
            List<Id> payerAccountIds = new List<Id>();
            for( PNR_Partner_Function__c pf : partnerFunctions ){
                payerAccountIds.add(pf.PNR_Customer_No__c);

                if( !soldToPayerListMap.containsKey(pf.PNR_Sold_To__c) ){
                    soldToPayerListMap.put(pf.PNR_Sold_To__c, new List<Id>());
                }
                soldToPayerListMap.get(pf.PNR_Sold_To__c).add(pf.PNR_Customer_No__c);
            }
            
            //Map of Account Id -> Map of contacts for that Account and ACR Id for Account and Contact combination
            Map<Id, Map<Id,AccountContactRelation>> accIdContactIdACRMap = new Map<Id, Map<Id,AccountContactRelation>>();
            for( AccountContactRelation acr : [SELECT   Id, AccountId, Account.Direct_Customer__c, 
                                                        ContactId, D1_Roles__c,Contact_Type__c, IsDirect,
                                                        D1_Active__c
                                                FROM AccountContactRelation 
                                                WHERE AccountId IN :accountIdsToTransfer
                                                OR AccountId IN :payerAccountIds] ){
                if( !accIdContactIdACRMap.containsKey(acr.AccountId) ){
                    accIdContactIdACRMap.put(acr.AccountId, new Map<Id,AccountContactRelation>());
                }
                accIdContactIdACRMap.get(acr.AccountId).put(acr.contactId, acr);
            }

            Set<String> solToRolesSet = userRoleMap.keySet();
            if( contactRec.Account.Direct_Customer__c ){
                solToRolesSet.remove('Account Balances');
            }
            

            Map<Id,AccountContactRelation> acrToUpdateMap = new Map<Id,AccountContactRelation>();
            for( AccountContactRelation acrSelected : newPrimaryACRList ){
                AccountContactRelation newPrimary = accIdContactIdACRMap.get(acrSelected.AccountId).get(acrSelected.ContactId);
                AccountContactRelation olderPrimary = accIdContactIdACRMap.get(acrSelected.AccountId).get(contactId);
                
                //Updates for Older Primary ACR Sold To
                olderPrimary.D1_User_Role__c = 'Member of Staff';
                olderPrimary.D1_Roles__c = DEFAULT_ACCESS;
                if( deactivateUserAccount ){
                    olderPrimary.D1_Active__c = false;
                    olderPrimary.D1_User_Role__c = '';
                    olderPrimary.D1_Roles__c = '';
                }

                //Updates for New Primary ACR Sold To
                newPrimary.D1_User_Role__c = 'Primary';
                newPrimary.D1_Roles__c = String.join(new List<String>(userRoleMap.keySet()),';');

                acrToUpdateMap.put(olderPrimary.Id, olderPrimary);
                acrToUpdateMap.put(newPrimary.Id, newPrimary);

                //check if SoldTo account has Payers
                if( soldToPayerListMap.containsKey(acrSelected.AccountId) ){
                    for( Id payerAccId : soldToPayerListMap.get(acrSelected.AccountId) ){
                        AccountContactRelation olderPrimaryPayerACR;
                        if( accIdContactIdACRMap.containsKey(payerAccId) && accIdContactIdACRMap.get(payerAccId).containsKey(contactId) && accIdContactIdACRMap.get(payerAccId).get(contactId).D1_Active__c ){
                            olderPrimaryPayerACR = accIdContactIdACRMap.get(payerAccId).get(contactId);
                            
                            AccountContactRelation newPrimaryPayerACR;
                            if( accIdContactIdACRMap.containsKey(payerAccId) && accIdContactIdACRMap.get(payerAccId).containsKey(acrSelected.ContactId) ){
                                newPrimaryPayerACR = accIdContactIdACRMap.get(payerAccId).get(acrSelected.ContactId);

                                //Updates for New Primary ACR Payer
                                if( acrToUpdateMap.containsKey(newPrimaryPayerACR.Id) ){
                                    //If payer and sold to are same the sold to permission are already added just add Account Balances
                                    newPrimaryPayerACR.D1_Roles__c += ';'+ACCOUNT_BALANCES;
                                }else{
                                    //If payer and sold to are different add Account Balances, Default Access
                                    newPrimaryPayerACR.D1_User_Role__c = 'Primary';
                                    newPrimaryPayerACR.D1_Roles__c = ACCOUNT_BALANCES+';'+DEFAULT_ACCESS+';'+USER_MANAGEMENT;
                                    newPrimaryPayerACR.D1_Active__c = olderPrimaryPayerACR.D1_Active__c;
                                    acrToUpdateMap.put(newPrimaryPayerACR.Id, newPrimaryPayerACR);
                                }
                            }

                            //Updates for Older Primary ACR payer
                            olderPrimaryPayerACR.D1_User_Role__c = 'Member of Staff';
                            olderPrimaryPayerACR.D1_Roles__c = DEFAULT_ACCESS;
                            if( deactivateUserAccount ){
                                olderPrimaryPayerACR.D1_Active__c = false;
                                olderPrimaryPayerACR.D1_User_Role__c = '';
                                olderPrimaryPayerACR.D1_Roles__c = '';
                            }
                            acrToUpdateMap.put(olderPrimaryPayerACR.Id, olderPrimaryPayerACR);
                        }
                    }
                }
            }
			
            update acrToUpdateMap.values();
            
            if( deactivateUserAccount ){
                List<AccountContactRelation> remaningActiveACRContact = [  SELECT  Id, AccountId, Account.Direct_Customer__c, 
                                                                        ContactId, D1_Roles__c,Contact_Type__c, IsDirect,
                                                                        D1_Active__c
                                                                FROM AccountContactRelation 
                                                                WHERE ContactId = :contactId
                                                                AND D1_Active__c = true];
                for( AccountContactRelation acr : remaningActiveACRContact ){
                    acr.D1_Active__c = false;
                    acr.D1_User_Role__c = '';
                    acr.D1_Roles__c = '';
                }
                update remaningActiveACRContact;

                //NCP-7209
                Set<Id> conIdSet = new Set<Id>{contactId};
                D1_RegistrationUtility.updateDeactivatedContact(conIdSet);

                deactivateContactUser(contactId);
            }
        }catch( Exception e ){
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    //method to deactivate user
    @future
    public static void deactivateContactUser(Id contactId){
        User usr = getUser( contactId );
        //usr.IsPortalEnabled = false;
        usr.IsActive = false;
        usr.Effective_Account_Id__c = '';
        if( !Test.isRunningTest() ){ //US 150154:PMD Fix
        	update usr;
        }
    }

    //Method to get User Details
    public static User getUser( Id contactId ){
        User usr = [SELECT Id, ContactId, D1_User_Type__c, D1_User_Type_Id__c, AccountId, Account.Direct_Customer__c,Effective_Account_Id__c FROM User WHERE ContactId =:contactId LIMIT 1];
        return usr;
    }

    public static Contact getContact( Id contactId ){
        Contact contactRec = [Select id,D1_Login_Counter__c, FirstName, LastName, Email, MobilePrefix__c, Mobile__c, AccountId,Account.Country_Code__c, Account.Direct_Customer__c, D1_Setting__c, D1_User_Type__c,Account.Global_Channel__c, //143286 added Global Channel field
        D1_Login_Reminder_Status__c,MD_SubscriptionDate__c,D1_Invite_sent__c,D1_Contact_Last_Login_Date__c,Next_Action_Date__c,Registration_Source__c,MD_ContactSubscriptions__c,MD_SubscriptionSource__c
        from Contact where id = :contactId limit 1];
        return contactRec;
    }

    //Method to get Contact Details
    public static D1_User_Type__c getUserType( String language, String userType, String outletChannel ){  //143286 passing Channel parameter
        D1_User_Type__c availableUserType = new D1_User_Type__c();
        List<D1_User_Type__c> availableUserTypeList =  [SELECT Id, Name, D1_Setting__c, User_Type__c,D1_Setting__r.Market__c, D1_Setting__r.Market__r.Code__c,Customer_Service_Group__c,Channel__c  //143286 added Channel field
                                        FROM D1_User_Type__c 
                                        where D1_Setting__r.Market__r.Code__c = :language 
                                        AND D1_Setting__r.Default__c = true
                                        AND User_Type__c = :userType];
        //143286                                
        for(D1_User_Type__c usrType : availableUserTypeList){
            if(usrType.Channel__c != Null && usrType.Channel__c == outletChannel){
                availableUserType = usrType;
                break;
            }
            else{
                availableUserType = usrType;
            }
        }
        return availableUserType;
    }

    //Method to get User Role Details
    //NCP-3485
    public static Map<String, D1_User_Types_Role__c> getUserRoleFromUserType(string userTypeId){
        Map<String, D1_User_Types_Role__c> userRoleMap = new Map<String, D1_User_Types_Role__c>();
        if(userTypeId != null){
            for(D1_User_Types_Role__c utr: [SELECT Id, D1_User_Type__c, D1_User_Role__c, Name,D1_User_Role__r.Name,D1_User_Role__r.Access_Type__c,D1_User_Role__r.IsDefault__c,Description__c,Display_Name__c FROM D1_User_Types_Role__c WHERE D1_User_Type__c=:userTypeId ORDER By D1_User_Role__r.IsDefault__c DESC, Display_Name__c ASC]){
                userRoleMap.put(utr.D1_User_Role__r.Access_Type__c, utr);
            }
        }
        return userRoleMap;
    }
    
    public class AccountInfoWrapper implements Comparable{
        @AuraEnabled public Account accountInfo;
        @AuraEnabled public List<AccountContactRelation> acrInfoList;
        @AuraEnabled public List<ContactOptions> contactOptionsList;

        @AuraEnabled
        public Boolean isSelected;
        @AuraEnabled
        public String selectedACRId;

        AccountInfoWrapper(Account accountInfo){
            this.isSelected = false;
            this.accountInfo = accountInfo;
            this.acrInfoList = new List<AccountContactRelation>();
            this.contactOptionsList = new List<ContactOptions>();
        }

        public void addACR( AccountContactRelation acrInfo ){
            this.acrInfoList.add(acrInfo);
            this.contactOptionsList.add(new ContactOptions(acrInfo.Contact.FirstName+' '+acrInfo.Contact.LastName,acrInfo.Id));
        }

        public Integer compareTo(Object compareTo) {
            if( this.accountInfo.Name < ((AccountInfoWrapper)compareTo).accountInfo.Name ){
                return 0;
            }else if( this.accountInfo.Name > ((AccountInfoWrapper)compareTo).accountInfo.Name ){
                return 1;
            }else{
                return -1;
            }
        }
    }

    public class ContactOptions{
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public ContactOptions(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}