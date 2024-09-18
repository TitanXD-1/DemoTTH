/**************************************************************************************
Apex Class Name  :  MD_UserSessionUtil 
Version          :  1.0
Created Date     :  28/08/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Hernan Arakaki           28/08/2019             Original Version
* Hernan Arakaki           11/10/2019             ECOM-3843 - Blank Page After password
**************************************************************************************/ 

public without sharing class MD_UserSessionUtil {
    
    public static Map<Id, AccountContactRelation> availableOutlets;
    private static MD_SessionSettings__c sessionSettings;
    private static User loggedUser;
    private static AccountContactRelation loggedOutletContact;
    private static Account loggedOutlet;
    private static String currencySimbol;
    private static Map<String,List<String>> clustersByCountry;
    private static Boolean isLoggedUser;
    public static Id userIdlogin;

    public static AccountContactRelation getOutletContact(){
        if (loggedOutletContact == null){

            if(isCommunityUser()) {
                Id accContId = getSessionSettings().NavigateAsOutlet__c;
                loggedOutletContact = availableOutlets.get(accContId);
            }else {
                // ECOM-762: Backend visualforce page adjustments
                AccountContactRelation outletContact = [SELECT Id, AccountId, Account.Name, MD_Role__c
                                                                    , Account.BillingCountry, MD_AssignedPermissions__c
                                                                    , Account.Country__r.Code__c
                                                            FROM AccountContactRelation LIMIT 1];
                // ECOM-762: Backend visualforce page adjustments

                loggedOutletContact = outletContact;
            }
        }
        return loggedOutletContact;
    }

    public static AccountContactRelation getOutletContact(String accContId){
        if (loggedOutletContact == null){

            if(isCommunityUser()) {
                loggedOutletContact = availableOutlets.get(accContId);
            }else {
                // ECOM-762: Backend visualforce page adjustments
                AccountContactRelation outletContact = [SELECT Id, AccountId, Account.Name, MD_Role__c
                                                                    , Account.BillingCountry, MD_AssignedPermissions__c
                                                                    , Account.Country__r.Code__c
                                                            FROM AccountContactRelation LIMIT 1];
                // ECOM-762: Backend visualforce page adjustments

                loggedOutletContact = outletContact;
            }
        }
        return loggedOutletContact;
    }

    public static Account getOutlet() {

        System.debug('MD - in MD_UserSessionUtil.getOutlet() method.');

        Id accContId = getSessionSettings().NavigateAsOutlet__c;

        System.debug('MD - in MD_UserSessionUtil.getOutlet() method.');

        if(loggedOutlet == null) {
            System.debug('MD - in MD_UserSessionUtil.getOutlet() method. loggedOutlet is null');

            if(availableOutlets != null && String.isNotEmpty(accContId)) {

                Id accId = availableOutlets.get(accContId).AccountId;

                System.debug('MD - in MD_UserSessionUtil.getOutlet() method. accId: ' + accId);

                loggedOutlet = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, Parent.Id, Parent.BillingStreet
                                            , Parent.BillingPostalCode, Parent.BillingCity, Parent.Name, Country__c, Country__r.Code__c
                                    FROM Account
                                    WHERE Id =: accId];

                System.debug('MD - in MD_UserSessionUtil.getOutlet() method. loggedOutlet: ' + loggedOutlet);
            }
        }

        return loggedOutlet;
    }

    public static User getUser() {

        if(loggedUser == null) {
            System.debug('CG - MD_UserSessionUtil.getUser() - loggedUser == null');

            Id userId = userIdlogin != null ? userIdlogin : UserInfo.getUserId();

            System.debug('CG - in MD_UserSessionUtil.getUser() method. userId: ' + userId);

            User currentUser = [SELECT Id, Name, Username, ContactId, Profile.UserLicense.Name, LanguageLocaleKey
                                        , MobilePhone, FirstName, LastName, Email
                                        , (SELECT Id, DiageoCMS__Cluster__c FROM DiageoCMS__ClusterUsers__r)
                                        , (SELECT Id, DiageoCMS__Cluster__c, DiageoCMS__Cluster__r.MD_AccountNumberAPIName__c 
                                            FROM DiageoCMS__CMSUsersSettings__r)
                                    FROM User WHERE Id = :userId];
            
            System.debug('CG - in MD_UserSessionUtil.getUser() method. currentUser: ' + currentUser);
            System.debug('CG - in MD_UserSessionUtil.getUser() method. currentUser.ContactId: ' + currentUser.ContactId);
            
            try {
                currentUser.Contact = getContactInformation(currentUser.ContactId);

                completeAccountRelationsAccountNumber(currentUser);

                availableOutlets = new Map<Id, AccountContactRelation>(currentUser.Contact.AccountContactRelations);
                
            }catch(Exception e) {
                currentUser.Contact = new Contact();
                System.debug('e message' + e.getMessage());
                System.debug('e message' + e.getLineNumber());
            }
            loggedUser = currentUser;
        }else {
            System.debug('CG - MD_UserSessionUtil.getUser() - loggedUser != null');
        }

        return loggedUser;
    }

    @TestVisible
    private static void completeAccountRelationsAccountNumber(User currentUser) {
        Set<Id> accountsId = new Set<Id>();
        
        System.debug('CG - in MD_UserSessiontUtil.completeAccountRelationsAccountNumber() method. currentUser: ' + currentUser);
        
        DiageoCMS__CMSUserSettings__c cmsSettings;
        
        if(currentUser.DiageoCMS__CMSUsersSettings__r.size() > 0) {
            cmsSettings = currentUser.DiageoCMS__CMSUsersSettings__r.get(0);
        }

        for(AccountContactRelation acr : currentUser.Contact.AccountContactRelations) {
            accountsId.add(acr.AccountId);
        }

        System.debug('CG - in MD_UserSessiontUtil.completeAccountRelationsAccountNumber() method. accountsId: ' + accountsId);

        Map<String, String> accountOwnersMap = new Map<String, String>();
        
        String accountNumberField;
        
        if(cmsSettings != null && cmsSettings.DiageoCMS__Cluster__r.MD_AccountNumberAPIName__c != null) {
            accountNumberField = cmsSettings.DiageoCMS__Cluster__r.MD_AccountNumberAPIName__c;
        }else {
            accountNumberField = 'AccountNumber';
        }

        System.debug('CG - in MD_UserSessiontUtil.completeAccountRelationsAccountNumber() method. accountNumberField: ' + accountNumberField);

        String query = 'SELECT Id, ' + accountNumberField + ', Independent_of_Operator__c, IsIndependent__c, VAT_Number__c FROM Account WHERE Id IN :accountsId';

        System.debug('CG - in MD_UserSessiontUtil.completeAccountRelationsAccountNumber() method. query: ' + query);

        List<Account> outlets = Database.query(query);

        for(Account outlet : outlets) {
            
            /* ECOM - 3843 - BEGIN 
             * The outlet.IsIndependent__c || outlet.Independent_of_Operator__c condition was added, for using the Outlet's VAT_Number__c field.
             * A validation over accountNumberAPINameArgs[0] was added to validate if the lookup is actually filled.
             */
            if(outlet.IsIndependent__c || outlet.Independent_of_Operator__c) {
                accountOwnersMap.put(outlet.Id, outlet.VAT_Number__c);
            }else {
                if(accountNumberField.contains('__r')) {
                    String[] accountNumberAPINameArgs = accountNumberField.split('\\.');
                    System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPINameArgs: ' + accountNumberAPINameArgs);

                    if(outlet.getSObject(accountNumberAPINameArgs[0]) != null) {
                        System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPINameArgs[0]: ' + accountNumberAPINameArgs[0] + ' - accountNumberAPINameArgs[1]: ' + accountNumberAPINameArgs[1]);
                        accountOwnersMap.put(outlet.Id, (String)outlet.getSObject(accountNumberAPINameArgs[0]).get(accountNumberAPINameArgs[1]));
                    }else {
                        System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPINameArgs[0] ' + accountNumberAPINameArgs[0] + ' is an empty relation.');
                        accountOwnersMap.put(outlet.Id, outlet.VAT_Number__c);
                    }

                }else {
                    System.debug('CG - in MD_AccountDetailsController.getWrapper() method. doesnt contains __r - accountNumberField: ' + accountNumberField);
                    accountOwnersMap.put(outlet.Id, (String)outlet.get(accountNumberField));
                }
            }
        }

        System.debug('CG - in MD_UserSessiontUtil.completeAccountRelationsAccountNumber() method. accountOwnersMap: ' + accountOwnersMap);

        for(AccountContactRelation acr : currentUser.Contact.AccountContactRelations) {
            acr.Account.AccountNumber = accountOwnersMap.get(acr.AccountId);
        }

        System.debug('CG - in MD_UserSessiontUtil.completeAccountRelationsAccountNumber() method. currentUser.Contact.AccountContactRelations: ' + currentUser.Contact.AccountContactRelations);
    }

    public static User getUser(Id userId) {

        User currentUser = [SELECT Id, Name,FirstName, LastName, Email, MobilePhone, Username, ContactId, Profile.UserLicense.Name FROM User WHERE Id =: userId];

        try {
            currentUser.Contact = getContactInformation(currentUser.ContactId);
            availableOutlets = new Map<Id, AccountContactRelation>(currentUser.Contact.AccountContactRelations);
        }catch(Exception e) {
            System.debug('e message' + e.getMessage());
            System.debug('e message' + e.getLineNumber());
        }

        return currentUser;
    }

    public static User getUserFromContactId(Id contactId) {

        User currentUser = [SELECT Id, Name, Username, ContactId, Profile.UserLicense.Name FROM User WHERE Contact.Id =: contactId];

        try {
            currentUser.Contact = getContactInformation(currentUser.ContactId);
            availableOutlets = new Map<Id, AccountContactRelation>(currentUser.Contact.AccountContactRelations);
        }catch(Exception e) {
            System.debug('e message' + e.getMessage());
            System.debug('e message' + e.getLineNumber());
        }

        return currentUser;
    }
    
    public static Contact getContactInformation(String contactId) {
        System.debug('CG - in MD_UserSessionUtil.getContactInformation() method. contactId: ' + contactId);
        
        Contact result = [SELECT Id, Name, MD_TermsAndConditionsLookup__c, MD_PrivacyPolicyLookup__c, Account.BillingCountry
                                    , MD_LastConnectionDate__c, MD_SelectedOutlet__c, Account.Country__r.Code__c
                                    , MD_CurrentOutlet__c, MD_CurrentOutlet__r.Country__r.Code__c, MD_Subscribed__c, MD_SubscriptionDate__c
                                    , (SELECT Id, ContactId
                                                , AccountId, Account.Name, Account.BillingCity, Account.BillingCountry, Account.AccountNumber
                                                , Account.BillingPostalCode, Account.BillingStreet, Account.Country__c
                                                , Account.Country__r.Code__c, Account.Operator__c, Account.Operator__r.VAT_Number__c
                                                /* ECOM-3843 - BEGIN */
                                                , Account.IsIndependent__c, Account.Independent_of_Operator__c
                                                /* ECOM-3843 - END   */
                                                , MD_OutletAddress__c, MD_Role__c, MD_Status__c, MD_AssignedPermissions__c, MD_UserProfile__c 
                                            FROM AccountContactRelations 
                                            WHERE MD_Status__c = 'Active')
                          FROM Contact
                          WHERE Id = :contactId];

        return result;
    }
    
    public static MD_SessionSettings__c getSessionSettings() {
        System.debug('CG - in MD_UserSessionUtil.getSessionSettings() method.');
        MD_SessionSettings__c sets;

        if (sessionSettings == null) {
            System.debug('CG - MD_UserSessionUtil.getSessionSettings() - MD_SessionSettings__c == null');
            User currentUser;
            
            if(loggedUser == null) {
                currentUser = getUser();
            }else {
                currentUser = loggedUser;
            }

            System.debug('CG - in MD_UserSessionUtil.getSessionSettings() method. currentUser: ' + currentUser);

            try {
                sets = [SELECT NavigateAsOutlet__c, Segments__c, Clusters__c FROM MD_SessionSettings__c WHERE SetupOwnerId = :currentUser.Id LIMIT 1];
            }catch(Exception ignored){
                sets = null;
            }

            System.debug('CG - MD_UserSessionUtil.getSessionSettings() - sets: ' + sets + ' - getUser().Id: ' + getUser().Id);

            if (sets == null) {
                System.debug('CG - MD_UserSessionUtil.getSessionSettings() - MD_SessionSettings__c should be created.');
                sets = new MD_SessionSettings__c();
                sets.SetupOwnerId = getUser().Id;
                if(!MD_UserSessionUtil.isCommunityUser()){
                    MD_SessionSettings__c defaultSessionSettings = MD_SessionSettings__c.getOrgDefaults();
                    sets.Clusters__c = defaultSessionSettings.Clusters__c;
                }else{
                    AccountContactRelation theOne = currentUser.Contact.AccountContactRelations.get(0);
                    sets.NavigateAsOutlet__c = theOne.Id;
                }
                insert sets;
            }

            sessionSettings = sets;

        } else {
            System.debug('CG - MD_UserSessionUtil.getSessionSettings() - MD_SessionSettings__c != null');
        }

        return sessionSettings;
    }

   
    public static void updateUserSessionSettings() {
        update sessionSettings;
    }

    /**
    *  @Author         :   Elena Schwarzböck
    *  @description    :   used to update fields Segments and Clusters of the session settings record
    *  @returns         :   void
    **/
    public static void setSessionSettingsFields(Id userId) {
        userIdlogin = userId;
        String segmentsString = '';
        
        sessionSettings = getSessionSettings();

        /* MIGRATION - Commented HERNAN
        Set<Id> userSegmentsSet = CP_SegmentUtil.getCurrentUserSegments(getUser());

        System.debug('CG - in MD_UserSessionUtil.setUserSegments() method - userSegmentsSet.size(): ' + userSegmentsSet.size());

        if(userSegmentsSet.size() > 0) {
            List<Id> userSegments = new List<Id>(userSegmentsSet);
            segmentsString = String.join(userSegments, ',');
        }
          MIGRATION - Commented */
        sessionSettings.Segments__c = segmentsString;

        System.debug('CG - MD_UserSessionUtil.setUserSegments() method - segmentsString: ' + segmentsString);

        //ECOM-1243: Adds Clusters to session settings
        if(getOutlet() != null && String.IsNotBlank(getOutlet().Country__c)){
            sessionSettings.Clusters__c = String.join(getClusters(getOutlet().Country__c),',');
        }else{
            sessionSettings.Clusters__c = '';
        }
        //END OF ECOM-1243

        System.debug('CG - MD_UserSessionUtil.setUserSegments() method - clustersString: ' + sessionSettings.Clusters__c);
    }

    public static MD_UserSessionUtil.MD_CheckOutletInformationResponse checkForOutletsInfo() {
        MD_UserSessionUtil.MD_CheckOutletInformationResponse response = new MD_CheckOutletInformationResponse();
        Boolean updateUserSessionSettings = false;

        System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method.');

        User currentUser = getUser();

        System.debug('CG - getSessionSettings().NavigateAsOutlet__c: ' + getSessionSettings().NavigateAsOutlet__c);

        if(getSessionSettings().NavigateAsOutlet__c != null  && getSessionSettings().NavigateAsOutlet__c != '') {

            if(String.isEmpty(getSessionSettings().Clusters__c)) {
                MD_UserSessionUtil.setSessionSettingsFields(currentUser.Id);
                updateUserSessionSettings = true;
            }

            System.debug('CG - MD_UserSessionUtil.checkForOutletsInfo() method. user has already selected an AccountContact. MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c: ' + getSessionSettings().NavigateAsOutlet__c);
            response.type = MD_CheckOutletInformationResponseType.HAS_OUTLET_SELECT;
            response.result = true;
        }else {
            System.debug('CG - MD_UserSessionUtil.checkForOutletsInfo() method. MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c empty');

            
            List<AccountContactRelation> outlets = currentUser.Contact.AccountContactRelations;
            
            System.debug('CG - MD_UserSessionUtil.checkForOutletsInfo() method. outlets: ' + outlets);
            System.debug('outlets.size() ' + outlets.size());

            setSessionSettingsFields(getUser().Id);
            updateUserSessionSettings = true;

            if(outlets.size() == 1) {
                System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method. user has only one AccountContact to choose.');

                AccountContactRelation theOne = currentUser.Contact.AccountContactRelations.get(0);

                response.countryCode = theOne.Account.Country__r.Code__c;
                response.type = MD_CheckOutletInformationResponseType.HAS_ONLY_ONE_OUTLET;
                response.result = true;

                update new Contact(Id = theOne.ContactId, MD_SelectedOutlet__c = theOne.Id);

                getSessionSettings().NavigateAsOutlet__c = theOne.Id;
                updateUserSessionSettings = true;
            }else {
                System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method. user has ' + outlets.size() +'  AccountContacts to choose.');

                response.type = MD_CheckOutletInformationResponseType.HAS_MULTIPLE_OUTLETS; response.result = false;
            }
            
        }

        if(updateUserSessionSettings){
            updateUserSessionSettings();
        }
        
            
        return response;
    }

    public static String getDefaultCookieValue(Id userId) {

        String response = '';
        loggedUser = getUser(userId);

        System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method. loggedUser: ' + loggedUser);
        System.debug('CG - getSessionSettings().NavigateAsOutlet__c: ' + getSessionSettings().NavigateAsOutlet__c);

        Id outletContactId;
        
        if(loggedUser.Contact.MD_CurrentOutlet__c != null) {
            response = loggedUser.Contact.MD_CurrentOutlet__r.Country__r.Code__c;
        }else {
            AccountContactRelation theOne;

            if(getSessionSettings().NavigateAsOutlet__c != null  && getSessionSettings().NavigateAsOutlet__c != '') {
                System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method. getSessionSettings().NavigateAsOutlet__c != null');
                outletContactId = getSessionSettings().NavigateAsOutlet__c;
            }
            else {
                System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method. getSessionSettings().NavigateAsOutlet__c == null');
                outletContactId = loggedUser.Contact.AccountContactRelations.get(0).Id;
            }
            
            System.debug('CG - in MD_UserSessionUtil.checkForOutletsInfo() method. loggedUser.Contact.AccountContactRelations.size(): ' + loggedUser.Contact.AccountContactRelations.size());
            for(AccountContactRelation availableOutlet : loggedUser.Contact.AccountContactRelations) {
                if(availableOutlet.Id == outletContactId) {
                    theOne = availableOutlet;
                    break;
                }
            }
            
            if(theOne != null) {
                System.debug('CG - in MD_UserSessionUtil.getDefaultCookieValue() method. theOne: ' + theOne);
                response = theOne.Account.Country__r.Code__c;
            }
        }
        
        return response;
    }
    /**
     *  @Author         :   Hernan Arakaki
     *  @description    :   used for a lightning component that needs to display CP_Component__c records information. Class to the generic getController method
     *  @returns        :   instance of the componentController to the CP_BaseComponent.cmp as a JSON Object
     **/
     
    public static List<AccountContactRelation> getAvailableOutlets() {
        return getUser().Contact.AccountContactRelations;
    }

    public static List<AccountContactRelation> getAvailableOutletsForContact(Id contactId){
        return getUserFromContactId(contactId).Contact.AccountContactRelations;
    }
    
    /**
     *  @Author         :   Ramiro Ichazo
     *  @description    :   Used for a lightning component that needs to Display the Outlets a Contact has access to.
     *  @returns         :  List of AccountContactRelation of all the users the account has
     **/
    
    public static List<AccountContactRelation> getAvailableContacts(){
        Id accContId = getSessionSettings().NavigateAsOutlet__c;
        Id accId = availableOutlets.get(accContId).AccountId;

        return [SELECT Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.MD_CurrentOutlet__c
                        , Account.Name, Account.Country__r.Code__c
                        , Account.BillingStreet, Account.BillingCity, Account.BillingPostalCode, Account.BillingCountry
                        , MD_Role__c, MD_Status__c, MD_AssignedPermissions__c
                    FROM AccountContactRelation
                    WHERE AccountId =: accId 
                        AND Contact.Id != null
                        AND MD_Status__c = 'Active' 
                    ORDER BY CreatedDate DESC];
    }
    

    /**
     *  @Author         :   Hernan Arakaki
     *  @description    :   used for a lightning component that needs to display CP_Component__c records information. Class to the generic getController method
     *  @returns         :   instance of the componentController to the CP_BaseComponent.cmp as a JSON Object
     **/
    public static void navigateAsOutlet(Id outletId){
        getSessionSettings().NavigateAsOutlet__c = outletId;

        updateUserSessionSettings();

        //when a user selects a new outlet the "Selected Outlet" on contact has to be updated
        setContactFields(false);
    }

    public static Boolean isCommunityUser() {
        Boolean result = false;

        if(getUser().Profile.UserLicense.Name.contains('Community')){
            result = true;
        }else{
            result = false;
        }

        return result;
    }

    public static Boolean isLoggedUser(){
        User currentUser = getUser();
        Boolean isLoggedUser = false;

        System.debug('CG - in MD_UserSessionUtil.isLoggedUser() method. currentUser.Profile.UserLicense.Name: ' + currentUser.Profile.UserLicense.Name);
        System.debug('CG - in MD_UserSessionUtil.isLoggedUser() method. Label.MD_GuestUserLicense: ' + Label.MD_GuestUserLicense);
        
        if(currentUser.Profile.UserLicense.Name == Label.MD_GuestUserLicense){
            isLoggedUser = false;
        }else{
            isLoggedUser = true;
        }
        
        System.debug('CG - in MD_UserSessionUtil.isLoggedUser() method. isLoggedUser: ' + isLoggedUser);
        return isLoggedUser;
    }

    public static String getCurrencySimbol(){
        if(currencySimbol == null){
            /* MIGRATION - Commented 
            List<Outlet_SAP_Sales_Area__c> outletSapArea = [SELECT Currency_Code__c FROM Outlet_SAP_Sales_Area__c WHERE Outlet__c = :getOutletContact().Account__c];
            System.debug(getSessionSettings().NavigateAsOutlet__c+ 'getSessionSettings().NavigateAsOutlet__crrrrrrrr' + outletSapArea);
            if(!outletSapArea.isEmpty()){
                currencySimbol = outletSapArea.get(0).Currency_Code__c == 'EUR' ? '€' : '£';
            }else{
                currencySimbol = '';
            }
            MIGRATION - Commented */
        }

        System.debug('CG - MD_UserSessionUtil.getCurrencySimbol: ' + currencySimbol);

        return currencySimbol;
    }

    /*
     *  @Author     :   Elena Schwarzbock
     *  @description:   sets contact fields: "Selected Outlet" and "Last Connection Date"
     */
    public static void setContactFields(Boolean setLastConection){

        User currentUser = getUser();

        Contact currentContact = currentUser.contact;

        System.debug('CG - in MD_UserSessionUtil.updateContact() method. currentContact: ' + currentContact);
      
        if(setLastConection){
            if(currentContact.MD_LastConnectionDate__c == null){
                currentContact.FirstName = currentUser.FirstName; 
                currentContact.LastName = currentUser.LastName; 
                currentContact.Email = currentUser.Email;
                currentContact.MobilePhone = currentUser.MobilePhone;
            }
            currentContact.MD_LastConnectionDate__c = datetime.now();
            System.debug('CG - in MD_UserSessionUtil.updateContact() method. updates CP_LastConnectionDate__c: ' + currentContact.MD_LastConnectionDate__c);
        }

        String countryCode;
        for (AccountContactRelation r : currentContact.AccountContactRelations){
            if (r.Id == getSessionSettings().NavigateAsOutlet__c){
                currentContact.MD_CurrentOutlet__c =  r.AccountId;
                currentContact.MD_CurrentRole__c = r.MD_Role__c;
                currentContact.MD_CurrentUserProfile__c = r.MD_UserProfile__c;
                currentContact.MD_CurrentAssignedPermissions__c = r.MD_AssignedPermissions__c;
                countryCode = r.Account.Country__r.Code__c;
                break;
            }
        }
        
        System.debug('CG - in MD_UserSessionUtil.setContactFields() method. update currentContact');
        update currentContact;

        updateUserSettings(countryCode);
    }

    /**
     *  @Author         :   Elena Schwarzböck
     *  @description    :   Updates/Create a CMS User Setting for the new Outlet's cluster
     *  @returns        :   void
     **/
    public static void updateUserSettings(String countryCode){
        if(countryCode != null){
            System.debug('CG - in MD_UserSessionUtil.updateUserSettings() method. countryCode: ' + countryCode);
            
            List<DiageoCMS__Cluster__c> clusters = [SELECT Id FROM DiageoCMS__Cluster__c 
                                                        WHERE DiageoCMS__ExternalId__c =: countryCode 
                                                            AND RecordType.DeveloperName = 'ClusterLeaf'
                                                        LIMIT 1];
            if(!clusters.isEmpty()){
                System.debug('CG - in MD_UserSessionUtil.updateUserSettings() method. clusters: ' + clusters);
                
                User loggedUser = getUser();
                System.debug('CG - in MD_UserSessionUtil.updateUserSettings() method. userId: ' + user.Id + ' - clusters[0].Id: ' + clusters[0].Id);
                
                DiageoCMS.CMSUserSettingsUtils.updateUserSettings(loggedUser.Id, clusters[0].Id, loggedUser.Contact.MD_CurrentOutlet__c, loggedUser.ContactId, loggedUser.Id);
            }
        }
    }

    /**
     *  @Author         :   Elena Schwarzböck
     *  @description    :   gets all the clusters for a country code
     *  @returns        :   a list of strings
     **/
    public static List<String> getClusters(String countryCode){

        if(String.isBlank(countryCode)){
            return new List<String>();
        }
        
        /* TODO: CMS Implementation
        if(clustersByCountry == null || !clustersByCountry.containsKey(countryCode)){
            List<String> clusters = new List<String>();
            Id recordTypeId = Schema.SObjectType.CP_cluster__c.getRecordTypeInfosByDeveloperName().get('Leaf').getRecordTypeId();
            for(CP_Cluster__c cluster: [SELECT Id, ParentCluster__c, ParentCluster__r.ParentCluster__c, ParentCluster__r.ParentCluster__r.ParentCluster__c, ParentCluster__r.ParentCluster__r.ParentCluster__r.ParentCluster__c FROM CP_Cluster__c WHERE RecordTypeId =: recordTypeId AND LocationCode__c =: countryCode]){
                //adds cluster and 4 levels up in the clusters tree if they are parents clusters
                clusters.add(cluster.Id);
                if(cluster.ParentCluster__c != null){
                    clusters.add(cluster.ParentCluster__c);
                    if(cluster.ParentCluster__r.ParentCluster__c != null){
                        clusters.add(cluster.ParentCluster__r.ParentCluster__c);
                        if(cluster.ParentCluster__r.ParentCluster__r.ParentCluster__c != null){
                            clusters.add(cluster.ParentCluster__r.ParentCluster__r.ParentCluster__c);
                            if(cluster.ParentCluster__r.ParentCluster__r.ParentCluster__r.ParentCluster__c != null){
                                clusters.add(cluster.ParentCluster__r.ParentCluster__r.ParentCluster__r.ParentCluster__c);
                            }
                        }
                    }
                }
            }
            if(clustersByCountry == null){
                clustersByCountry = new Map<String,List<String>>{countryCode => clusters};
            }else{
                clustersByCountry.put(countryCode,clusters);
            }
        }
        return clustersByCountry.get(countryCode);
        TODO: CMS Implementation */
        return new List<String>();
    }

    /**
     *  @Author         :   Elena Schwarzböck
     *  @description    :   gets a list of all clusters stored in the session settings custom setting
     *  @returns        :   list of strings
     **/
    public static List<String> getClusters(){
        if(getSessionSettings().Clusters__c != null){
            return getSessionSettings().Clusters__c.split(',');
        }else{
            return new List<String>();
        }
    }
    
    public static String getClusterLocationCode(String regionName){
        /**
        * TODO: CMS Implementation
        List<CP_Cluster__c> cluster = [SELECT locationCode__c FROM CP_Cluster__c WHERE name = :regionName];
        if(cluster.size() > 0){
            return cluster.get(0).locationCode__c;
        }
        */
        return null;
    }


    public class MD_CheckOutletInformationResponse {
        public Boolean result {get;set;}
        public String countryCode {get;set;}
        public MD_CheckOutletInformationResponseType type {get;set;}

        public MD_CheckOutletInformationResponse() {
            result = false;
            countryCode = '';
        }
    }

    public enum MD_CheckOutletInformationResponseType { HAS_OUTLET_SELECT, HAS_ONLY_ONE_OUTLET, HAS_MULTIPLE_OUTLETS }

    public class OutletInfo {
        public String outletName{get;set;}
        public String outletId{get;set;}

        public OutletInfo() {
            this.outletId = '';
            this.outletName = '';
        }

        public OutletInfo(String outletName, String outletId) {
            this.outletName = outletName;
            this.outletId = outletId;
        }
    }
}