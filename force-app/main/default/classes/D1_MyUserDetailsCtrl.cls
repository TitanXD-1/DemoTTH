/**
@name D1_MyUserDetailsCtrl
@description GTM Helper
@history
VERSION     AUTHOR           DATE           DETAIL
1.0         Sai Kumar  				        NCP-679,NCP-683,NCP-681
2.0 	    Manikant         08/10/2020     NCP-579, getUserRole 
3.0			Ajay             11/24/2020		NCP-1133 - User Permission
4.0         Mukesh Kanth     25/03/2021     NCP-2042:Updated getmyuserdetails,isHaveManageUserPermission methods
5.0         Vikas Panwar     25/04/2021     NCP-
6.0         Kapil Baliyan    25/04/2021     NCP-2796 (deactivateUsers, updateAccountContactRelation, deactivateCommunityUsers)
7.0         Vikas Panwar     21/05/2021     NCP-3325
8.0			Rubeena			 22/03/2022		NCP-6408
9.0         Kapil Baliyan    19/08/2022     NCP-7209
10.0		Subhrojit 		 07/11/2022		NCP-7386
11.0        Kapil Baliyan    21/12/2022     NCP-7681(Re-factor class)
12.0        Kapil Baliyan    13/08/2023     143257(getUserType)
13.0        Mayukh           04/09/2023     143282 - BE_Populate contacts under Registered and Non-Registered Tab on My users page
14.0		Prasanth T		 07/09/2023     143941 - Added Role with picklist values in my users tab added MD_CurrentRole__c in queries
15.0        Kapil Baliyan    05/12/2023     148957 - Added D1_RegistrationUtility Method and commented redundant code
**/
public without sharing class D1_MyUserDetailsCtrl {
    
    public static final String SOLDTO = 'Sold-To' ;
    public static Map<Id, Set<Id>> mapOfDeactiveACRAccounts = new Map<Id, Set<Id>>(); //NCP-6408

    /**
     * 
     * @return  `list < AccountContactRelation >`
     * @exception 
     */
    @AuraEnabled(cacheable = true)
    public static List<AccountContactRelation> getmyuserdetails() {
        try {
            if(isHaveManageUserPermission()!=true){
                throw new AuraHandledException('Access Denied!');
            }

            Id currentuserId = UserInfo.getUserId();
            //NCP-2042 Change: added Effective_Account_Id__c in query for multiple sold to
            User userdetails = [select id, Contactid,Effective_Account_Id__c from User where id =: currentuserId];
		
            List < AccountContactRelation > accountContactRelationDetails = new list < AccountContactRelation > ();
            //NCP-2042 Change: Commented code and added Effective_Account_Id__c instead of AccoutId in query for multiple sold to
            accountContactRelationDetails = [SELECT Id, ContactId, AccountId, Contact.Name, Contact_Type__c, Contact.phone,
                                             Contact.Email, D1_Active__c, D1_User_Role__c,
                                             Contact.FirstName, Contact.LastName, Contact.MobilePrefix__c, Contact.Mobile__c, D1_Roles__c,
                                             toLabel(Contact.MD_CurrentRole__c)
                                             FROM AccountContactRelation 
                                             WHERE AccountId =:userdetails.Effective_Account_Id__c
                                             AND D1_Active__c = true
                                             AND ContactId !=:userdetails.Contactid	 
                                             ORDER BY Contact.FirstName, Contact.LastName];
            return accountContactRelationDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method to get whether user exist or not
     */
    @AuraEnabled
    public static Boolean getExistingContact( string contactEmail ){
        Boolean isUserExist = false;
        Set<Id> accountIds = new Set<Id>();
        Id contactId = null;
        List<User> users = [SELECT Id, Email, ContactId, AccountId FROM User WHERE Email =:contactEmail AND isActive = true LIMIT 1];
        if(!users.isEmpty()){
            contactId = users[0].ContactId;
        }

        User logedInUser = getUser();
        List<AccountContactRelation> logedInUserACR = getAccountContactRelation(logedInUser.contactId, false);
        List<AccountContactRelation> existingACR = getAccountContactRelation(contactId, false);
        
        for(AccountContactRelation  acr: existingACR){
            accountIds.add(acr.AccountId);
        }
        
        for(AccountContactRelation  acr: logedInUserACR){
            if(acr.D1_Roles__c != null && acr.D1_Roles__c.contains('User Management') && accountIds.contains(acr.AccountId)){
                isUserExist = true;
                break;
            }
        }
        return isUserExist;
    }

    @AuraEnabled
    public static User getUser(){
        User usr = [SELECT Id, ContactId, D1_User_Type__c, D1_User_Type_Id__c, AccountId, Account.Direct_Customer__c,Effective_Account_Id__c,Available_Countries__c,LanguageLocaleKey FROM User 
                    WHERE Id =:UserInfo.getUserId() LIMIT 1];
        return usr;
    }

    //Method to get Contact Details
    public static D1_User_Type__c getUserType( String language, String userType, String channel ){
        D1_User_Type__c usrType;
        for(D1_User_Type__c uType : [SELECT Id, Name, D1_Setting__c, User_Type__c,D1_Setting__r.Market__c, D1_Setting__r.Market__r.Code__c,Customer_Service_Group__c, Channel__c 
                                        FROM D1_User_Type__c 
                                        WHERE D1_Setting__r.Market__r.Code__c = :language 
                                        AND D1_Setting__r.Default__c = true
                                        AND User_Type__c = :userType])
        {
            if(String.isNotBlank(channel) && String.isNotBlank(uType.Channel__c) && uType.Channel__c == channel){
                usrType = uType;
                break;
            }else{
                usrType = uType;
            }
        }
        return usrType;
    }

    //NCP-6212
    //Method to get User Type
    public static D1_User_Type__c getUserType( String contryCode, String language, String userType, String channel ){
        D1_User_Type__c usrType;
        for(D1_User_Type__c uType : [SELECT Id, Name, D1_Setting__c, User_Type__c,D1_Setting__r.Market__c, D1_Setting__r.Market__r.Code__c,Customer_Service_Group__c, Channel__c 
                                        FROM D1_User_Type__c 
                                        WHERE D1_Setting__r.Market__r.Code__c = :contryCode
                                        AND D1_Setting__r.Language__c = :language
                                        AND User_Type__c = :userType])
        {
            if(String.isNotBlank(channel) && String.isNotBlank(uType.Channel__c) && uType.Channel__c == channel){
                usrType = uType;
                break;
            }else{
                usrType = uType;
            }
        }
        return usrType;
    }

    //Method to get Contact Details
    //NCP-6212 - add Language field to query
    public static Contact getContact( Id contactId ){
        Contact contactRec = [SELECT Id, FirstName, MD_CurrentRole__c, LastName, Email, MobilePrefix__c, Mobile__c, AccountId, Account.Country_Code__c, Account.Direct_Customer__c, Account.Global_Channel__c, D1_Setting__c, D1_User_Type__c,Preferred_Language__c FROM Contact WHERE Id = :contactId limit 1];
        return contactRec;
    }

    @AuraEnabled
    public static Map<String, D1_User_Types_Role__c> getUserRoleFromUser(string contactId ,Boolean isBackendRegistration){
        Map<String, D1_User_Types_Role__c> userRolesMap = new Map<String, D1_User_Types_Role__c>();
        if(isBackendRegistration){
            contact contactRec = getContact(contactId);
            D1_User_Type__c usrType = getUserType(contactRec.Account.Country_Code__c, (contactRec.Account.Direct_Customer__c? 'Direct Buyer':'Outlet/Retailers'), contactRec.Account.Global_Channel__c);
            userRolesMap = getUserRoleFromUserType(usrType.Id);
        }
        else{
            User usr = getUser();
            userRolesMap = getUserRoleFromUserType(usr.D1_User_Type_Id__c);
        }
        return userRolesMap;
    }

    //Method to Remove User's access from Account & Deactivate them NCP-2796
    @AuraEnabled
    public static ResponseWrapper deactivateUsers(List<Id> contacts) {
        //Response Wrapper
        ResponseWrapper responseWrapper = new ResponseWrapper();
        responseWrapper.isSuccess = true;
        responseWrapper.msgList = new List<String>();

        try{
            User usr = getUser();
            string loggedInUsercontactId = usr.ContactId;
            List<AccountContactRelation> accContactRelationList = getAccountContactRelation(loggedInUsercontactId, false);
            Set<Id> accIdSet = new Set<Id>();
            Map<Id, List<AccountContactRelation>> conACRMap = new Map<Id, List<AccountContactRelation>>();
            Map<Id, List<AccountContactRelation>> conRelationsByPrimaryContactId = new Map<Id, List<AccountContactRelation>>();
            Map<Id, Id> conAccPrimaryMap = new Map<Id, Id>();
            Map<Id, String> conIdMap = new Map<Id, String>();
            List<AccountContactRelation> acrList = new List<AccountContactRelation>();

            //Filter Account for which User Permission is Enabled
            if(!accContactRelationList.isEmpty()){
                for(AccountContactRelation accConRel : accContactRelationList){
                    if(accConRel.D1_Roles__c != null && accConRel.D1_Roles__c.contains('User Management')){
                        accIdSet.add(accConRel.AccountId);
                    }
                }
            }

            //Get Account Contact Relationship for selected contacts w/ respect to logged in user accounts where user has User Management Permission
            if(accIdSet.size()>0){
                for(AccountContactRelation acr : [SELECT Id, ContactId, Contact.Name,toLabel(Contact.MD_CurrentRole__c), AccountId, IsDirect, D1_Active__c, D1_Roles__c, D1_User_Role__c FROM AccountContactRelation 
                                                    WHERE ContactId IN :contacts AND D1_Active__c = true ORDER By ContactId, IsDirect DESC])
                {
                    //Checking whether Account & Contact Relation is Direct or not
                    if(acr.IsDirect){
                        conAccPrimaryMap.put(acr.ContactId, acr.AccountId);
                    }

                    // populating map for secoundary can not delete primary user
                    if(acr.D1_User_Role__c == 'Primary'){
                        List<AccountContactRelation> conACRS = conRelationsByPrimaryContactId.get(acr.contactId); 
                        if(conACRS == null){
                            conACRS = new List<AccountContactRelation>();
                            conRelationsByPrimaryContactId.put(acr.contactId,conACRS);
                        }
                        conACRS.add(acr);
                        if(!conIdMap.containsKey(acr.ContactId)){
                            conIdMap.put(acr.ContactId, acr.Contact.Name);
                        }
                    }else{
                        //Check if Account exist in logged in user's account id set
                        if(accIdSet.contains(acr.AccountId)){
                            if(conACRMap.containsKey(acr.ContactId)){
                                conACRMap.get(acr.ContactId).add(updateAccountContactRelation(acr));
                            }else{
                                conACRMap.put(acr.ContactId, new List<AccountContactRelation>());
                                conACRMap.get(acr.ContactId).add(updateAccountContactRelation(acr));
                            }
                        }else{
                            conIdMap.put(acr.ContactId, acr.Contact.Name);
                        }
                    }
                }

                //Cheking if secoundary going to delete primary user
                if(conRelationsByPrimaryContactId != null && conRelationsByPrimaryContactId.size() > 0){
                    for(Id conId : conRelationsByPrimaryContactId.keySet()){
                        responseWrapper.isSuccess = false;
                        responseWrapper.msgList.add(conIdMap.get(conId));
                    }
                }

                // get the ACRs of removed contact
                
                Set<Id> accountIds = new Set<Id>();
                List<AccountContactRelation> allRelationsOfContact = getAllARCsOfSelectedContact(accountIds, contacts);
                for(AccountContactRelation acr: allRelationsOfContact){
                    accountIds.add(acr.AccountId);
                }

                List<PNR_Partner_Function__c> partnerFunctions = [SELECT Id, Sales_Area__r.Sales_Area_ID__c, PNR_Distribution_Channel__c, PNR_Division__c, PNR_Sales_Org__c, PNR_Customer_No__c, 
                                                                    PNR_Customer_No__r.Name, PNR_Customer_No__r.phone, PNR_Customer_No__r.VAT_Number__c,PNR_Type__c, PNR_Customer_No__r.billingPostalCode,
                                                                    PNR_Customer_No__r.BillingAddress, PNR_Customer_No__r.BillingStreet, PNR_Customer_No__r.BillingCity, PNR_Customer_No__r.BillingState,
                                                                    PNR_Customer_No__r.BillingCountry, PNR_Customer_No__r.KUNNR__c,PNR_Sold_To__c FROM PNR_Partner_Function__c
                                                                    WHERE PNR_Sold_To__c  IN: accountIds AND (PNR_Type__c =: SOLDTO)];
                
                Set<Id> partnerAccountIds = new Set<Id>();
                for(PNR_Partner_Function__c pf: partnerFunctions){
                    partnerAccountIds.add(pf.PNR_Sold_To__c);
                }

                List<AccountContactRelation> allSoldToRelationsOfContact = getAllARCsOfSelectedContact(partnerAccountIds, contacts);
                
                Map<Id, List<AccountContactRelation>> acrsByContactId = new Map<Id, List<AccountContactRelation>>();
                for(AccountContactRelation acr: allSoldToRelationsOfContact){
                    List<AccountContactRelation> relatoins = acrsByContactId.get(acr.ContactId);
                    if(relatoins == null){
                        relatoins = new List<AccountContactRelation>();
                        acrsByContactId.put(acr.ContactId, relatoins);
                    }
                    relatoins.add(acr);
                }
                Map<Id, Contact> contactById = new Map<Id, Contact>([Select Id, AccountId from Contact where Id IN: contacts]);
                List<Contact> contactsToUpdate = new List<Contact>();

                for(Id conId : conACRMap.keySet()){
                    if(conIdMap.containsKey(conId) && conAccPrimaryMap.containsKey(conId) && accIdSet.contains(conAccPrimaryMap.get(conId))){        
                        List<AccountContactRelation> inactiveACRs = conACRMap.get(conId);
                        Set<Id> inactiveAcrIds = new Set<Id>();
                        for(AccountContactRelation acr: inactiveACRs){
                            inactiveAcrIds.add(acr.Id);
                        }
                        List<AccountContactRelation> acrs = acrsByContactId.get(conId);
                        for(AccountContactRelation acr: acrs){
                            
                            if(!inactiveAcrIds.contains(acr.Id)){
                                Contact contact = contactById.get(conId);
                                contact.AccountId = acr.AccountId;
                                contactsToUpdate.add(contact);
                                break;
                            }
                        }                                              
                        acrList.addAll(conACRMap.get(conId));
                    }else{
                        acrList.addAll(conACRMap.get(conId));
                    }
                }
                if(!contactsToUpdate.isEmpty()){
                    update contactsToUpdate;
                }
               
                if(acrList.size()>0){
                    //Update AccountContactRelation records
                    update acrList;

                    //Deactivate Users
                    Set<Id> deactivateContact = deactivateUserContact(conACRMap.keySet());
                    //List<Contact> updateContactList = new List<Contact>();
                    if(!deactivateContact.isEmpty()){
                        /*for(Contact conRec : [SELECT Id,D1_Login_Reminder_Status__c,D1_Login_Counter__c,MD_SubscriptionDate__c,D1_Invite_sent__c,
                                              D1_Contact_Last_Login_Date__c,Next_Action_Date__c,Registration_Source__c,MD_ContactSubscriptions__c,
                                              MD_SubscriptionSource__c,D1_NPS_Average_Score__c,D1_NPS_Survey_Date__c,D1_NPS_Survey_Name__c,
                                              D1_Generic_Login_Counter__c
                                              FROM Contact WHERE Id IN: deactivateContact ])
                        {
                            conRec.D1_Login_Reminder_Status__c = 'Deactivated';
                            conRec.D1_Login_Counter__c = 0;//NCP-6925
                            conRec.D1_Generic_Login_Counter__c = 0; //NCP-7458
                            conRec.MD_SubscriptionDate__c = null;
                            conRec.D1_Invite_sent__c = null;
                            conRec.D1_Contact_Last_Login_Date__c = null;
                            conRec.Next_Action_Date__c =null;
                            conRec.Registration_Source__c = '';
                            conRec.MD_ContactSubscriptions__c = '';
            				conRec.MD_SubscriptionSource__c = '';
                            conRec.D1_NPS_Average_Score__c = null;//NCP-7386
							conRec.D1_NPS_Survey_Date__c = null;//NCP-7386
							conRec.D1_NPS_Survey_Name__c = '';//NCP-7386
                            updateContactList.add(conRec);
                        }*/

                        //Update Contact fields
                        D1_RegistrationUtility.updateDeactivatedContact(deactivateContact); //148957
                    }

                    /*if(!updateContactList.isEmpty()){
                        update updateContactList;
                    }*/
                }
            }
            return responseWrapper;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Helper Method to update ACR NCP-2796
    public static AccountContactRelation updateAccountContactRelation(AccountContactRelation acr){
        acr.D1_Active__c = false;
        acr.D1_Roles__c = '';
        acr.D1_User_Role__c = '';

        return acr;
    }

    //NCP-6408
    public static Set<Id> deactivateUserContact(Set<Id> contactIdSet){
        if(contactIdSet.isEmpty()){
            return new Set<Id>();
        }

        Map<Id, Set<Id>> mapOfActiveACRAccounts = new Map<Id, Set<Id>>();
        for(Id contactId: contactIdSet){
            mapOfActiveACRAccounts.put(contactId, new Set<Id>());
            mapOfDeactiveACRAccounts.put(contactId, new Set<Id>());
        }

        for(AccountContactRelation acr: [SELECT Id,ContactId,toLabel(Contact.MD_CurrentRole__c),AccountId, D1_Active__c FROM AccountContactRelation WHERE ContactId IN:contactIdSet])
        {
            if(acr.D1_Active__c == true){
                mapOfActiveACRAccounts.get(acr.contactId).add(acr.AccountId);
            }else{
                mapOfDeactiveACRAccounts.get(acr.contactId).add(acr.AccountId);
            }
        }

        Set<Id> activeContactIds = new Set<Id>();
        Set<Id> deActiveContactIds = new Set<Id>();

        for(Id contactId: contactIdSet){
             if(mapOfActiveACRAccounts.get(contactId).size() == 0){
                deActiveContactIds.add(contactId);
            }else{
                activeContactIds.add(contactId);
            }
        }

        deactivateCommunityUsers(activeContactIds,deActiveContactIds);
        return deActiveContactIds;
    }

    //Method to Deactivate Users NCP-2796
    @future
    public static void deactivateCommunityUsers(Set<Id> activeContactIds,Set<Id> deActiveContactIds) {
        List<User> userList = new List<User>();
        if(!deActiveContactIds.isEmpty()){
            for(User user : [SELECT Id, IsActive, Effective_Account_Id__c 
                            FROM User 
                            WHERE ContactId =:deActiveContactIds]
            ){
                user.IsActive = false;
                user.Effective_Account_Id__c = '';
                userList.add(user);
            }
        }

        if(!activeContactIds.isEmpty()){
            for(User user : [SELECT Id, Effective_Account_Id__c, ContactId,AccountId 
                            FROM User 
                            WHERE ContactId =:activeContactIds]
            ){
                if(mapOfDeactiveACRAccounts.get(user.ContactId).contains(user.Effective_Account_Id__c)){
                    user.Effective_Account_Id__c = user.AccountId;
                    userList.add(user);
                }
            }
        }

        //Update User
        if(!userList.isEmpty()){
            update userList;
        }
    }

    /**
     * Method to get Current User Account Details
     */
    @AuraEnabled(cacheable = true)
    public static Account getEffectiveAccount() {
        Id currentUserId = UserInfo.getUserId();
        List<User> user = [SELECT Id, Available_Countries__c, Effective_Account_Id__c, AccountId FROM User WHERE Id =:currentUserId];
        Account account = [SELECT Id, Name FROM Account WHERE Id =:user[0].Effective_Account_Id__c LIMIT 1];
        
        return account;
    }

    //Method to get Account Contact Relationship
    public static List<AccountContactRelation> getAccountContactRelation(string contactId, Boolean isBackendRigistration){
        List<AccountContactRelation> accContactRelationList = new List<AccountContactRelation>();
        if(contactId != null){
            if( isBackendRigistration ){
                accContactRelationList = [SELECT Id, AccountId, ContactId, D1_Roles__c,Contact_Type__c, IsDirect FROM AccountContactRelation 
                                        WHERE ContactId =:contactId];
            }else{
                accContactRelationList = [SELECT Id, AccountId, ContactId, D1_Roles__c,Contact_Type__c, IsDirect FROM AccountContactRelation 
                                        WHERE ContactId =:contactId AND D1_Active__c = true];
            }
        }
        return accContactRelationList;
    }
   
    //Switch IsDirect Account on ACRs
    public static List<AccountContactRelation> getAllARCsOfSelectedContact(Set<Id> accountIds, List<Id> contactIds){
        String query = 'SELECT Id, D1_User_Role__c,Contact.Name, createdDate, Account.name, AccountId, contactId FROM AccountContactRelation WHERE ContactId IN: contactIds AND D1_Active__c = true ';
        if(accountIds.size() > 0){
            query += ' AND AccountId IN: accountIds ORDER BY contactId, createdDate, Account.Name DESC ';
        }else{
            query += ' AND isDirect = false ORDER BY contactId, createdDate, Account.Name DESC';
        }
        List<AccountContactRelation> allRelations = Database.query(query);
        return allRelations;
    }

	public static Boolean isHaveManageUserPermission(){
		final String permission = 'User Management';
        //NCP-2042 Change: added Effective_Account_Id__c instead of AccoutId in query for multiple sold to
			User currentUser = [SELECT id,ContactId,Contact.AccountId,Effective_Account_Id__c
			FROM User
			WHERE id =: UserInfo.getUserId()];

			List<AccountContactRelation> accountContactObjs = [SELECT id FROM AccountContactRelation
			WHERE contactId =:currentUser.ContactId
            //NCP-2042 Change: Commented code and added Effective_Account_Id__c instead of AccoutId in query for multiple sold to
			//AND AccountId =: currentUser.Contact.AccountId
            AND AccountId =: currentUser.Effective_Account_Id__c
			AND D1_Roles__c INCLUDES(:permission) LIMIT 1];

			if(!accountContactObjs.isEmpty()){
				return true;
			}
		return false;
	}

    @AuraEnabled(cacheable = true)
    public static Contact getLogInUserDetails() {
        id currentuserId = UserInfo.getUserId();
        User userdetails = [SELECT Id, ContactId FROM User WHERE Id =: currentuserId];
        Contact contactdetails = new Contact();
        if (userdetails.ContactId != null) {
            contactdetails = [SELECT Id, Name, AccountId, Account.Name,Email FROM Contact where Id =:userdetails.ContactId];
        }
        return contactdetails;
    }
  
    //Method to get User Role Details
    //NCP-3485
    @AuraEnabled
    public static Map<String, D1_User_Types_Role__c> getUserRoleFromUserType(string userTypeId){
        Map<String, D1_User_Types_Role__c> userRoleMap = new Map<String, D1_User_Types_Role__c>();
        if(userTypeId != null){
            for(D1_User_Types_Role__c utr: [SELECT Id, D1_User_Type__c, D1_User_Role__c, Name,D1_User_Role__r.Name,D1_User_Role__r.Access_Type__c,D1_User_Role__r.IsDefault__c,Description__c,Display_Name__c FROM D1_User_Types_Role__c WHERE D1_User_Type__c=:userTypeId ORDER By D1_User_Role__r.IsDefault__c DESC, Display_Name__c ASC]){
                userRoleMap.put(utr.D1_User_Role__r.Access_Type__c, utr);
            }
        }
        return userRoleMap;
    }
    
	/**
	Method : getUserPermissionSet
	Purpose : Return all permissions applicable for the current user
    //KB: OUTDATED
	**/
    //NCP-3485
    @AuraEnabled(cacheable=true)
	public static Object getUserPermissionSet(){
		List<UserRolePermissionWrapper> listOfPermissions = new List<UserRolePermissionWrapper>();
		List<User> users = [SELECT id,LanguageLocaleKey,Available_Countries__c,D1_User_Type__c FROM User WHERE id =: UserInfo.getUserId()];

		if(users.isEmpty()){
			throw new AuraHandledException('Access denied, You dont have access to User object');
		}

		User currentUser = users[0];
		List<String> availableCountries = currentUser.Available_Countries__c == NULL ? new LIst<String>() : currentUser.Available_Countries__c.split(';'); 
        for(D1_User_Types_Role__c utr: [SELECT Id, D1_User_Type__c, D1_User_Role__c, Name,D1_User_Role__r.Name,D1_User_Role__r.Access_Type__c,D1_User_Role__r.IsDefault__c,D1_User_Role__r.Id,Description__c,Display_Name__c FROM D1_User_Types_Role__c 
                                        WHERE D1_User_Type__r.User_Type__c =:currentUser.D1_User_Type__c
                                        AND D1_User_Type__r.D1_Setting__r.Language__c =:currentUser.LanguageLocaleKey
                                        AND D1_User_Type__r.D1_Setting__r.Market__r.Code__c  IN:availableCountries
                                        AND D1_User_Role__r.Autoassignment__c = false
                                        AND D1_User_Role__r.Autoassignment_for_Secondary_Contact__c = false]){ //NCP-7927 : Added Autoassignment_for_Secondary_Contact__c in Query
            listOfPermissions.add(new UserRolePermissionWrapper(utr));
        }
		return new Map<String, Object>{
			'userType' => currentUser.D1_User_Type__c,
			'listOfPermissions' =>listOfPermissions
		};
	}   

    //Wrapper Class
    public class UserRolePermissionWrapper{
		@AuraEnabled public String id{get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public Boolean isDefault {get;set;} 
        @AuraEnabled public String type {get;set;}

		public UserRolePermissionWrapper(D1_User_Types_Role__c permission){
			this.id = permission.D1_User_Role__r.Id;
            this.name = permission.Display_Name__c;
			this.description = permission.Description__c;
			this.isDefault = permission.D1_User_Role__r.IsDefault__c;
			this.type = permission.D1_User_Role__r.Access_Type__c;
		}
    }

    //Wrapper Class for Deactive User Response NCP-2796
    public class ResponseWrapper {
        @AuraEnabled public boolean isSuccess {get; set;}
        @AuraEnabled public List<String> msgList {get; set;}
    }

    //143282 - BE_Populate contacts under Registered and Non-Registered Tab on My users page
    /**
     * Method : getmynonregcontactdetails
	 * Purpose : Return list of non registered contacts
     * @return  `list <Contact>`
     * @exception 
     */
    @AuraEnabled
    public static List<Contact> getmynonregcontactdetails() {
        try {
            /*if(isHaveManageUserPermission()!=true){
                throw new AuraHandledException('Access Denied!');
            }*/

            Id currentuserId = UserInfo.getUserId();
            User userdetails = new User();
            if(Schema.sObjectType.User.isAccessible()){
                userdetails = [select id, Contactid,Effective_Account_Id__c from User where id =: currentuserId];
            }
		
            List < Contact > contactList = new list < Contact > ();

            if(Schema.sObjectType.Contact.isAccessible()){
                contactList = [SELECT Id,AccountId, Name, Contact_Type__c,phone,Email,FirstName,LastName,MobilePrefix__c,Mobile__c,toLabel(MD_CurrentRole__c)
                                from Contact Where D1_User__c = FALSE AND AccountId =:userdetails.Effective_Account_Id__c ORDER BY FirstName,LastName];
            }
            return contactList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}