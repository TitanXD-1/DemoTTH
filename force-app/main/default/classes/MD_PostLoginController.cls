/***********************************************************************************
Apex Class Name  :  MD_PostLoginController 
Version          :  1.0
Created Date     :  21/05/2018
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Julio Enrique             17/04/2018              Original Version
* Hernan Arakaki            09/10/2018              ECOM-1479: On new Users first login, the Basket Cart shows no quantity
* Elena Shwarzböck          09/11/2018              ECOM-1333: Dynamic Navigations Component
* Cristian Canepa         	12/04/2019              ECOM-2769: Registration - Terms & Conditions and Privacy Policies public pages
* Hernan Arakaki			08/08/2019				ECOM 3408: EDGE - Agreements versioning
******************************************************************************/
public without sharing class MD_PostLoginController {

    public static String portalName = 'MyDiageo';
    public Boolean doPostLogin{get;set;}
    public String component{get;set;}
    public List<AccountContactRelation> availableOutlets {get;set;}
    public String countryCode {get;set;}
    public MD_UserSessionUtil.OutletInfo currentOutlet {get;set;}
    
    public MD_PostLoginController(Boolean setOutlet){
        doPostLogin = false;
        
        System.debug('CG - MD_PostLoginController.constructor() method. ' + UserInfo.getUserId());
        
        if(MD_UserSessionUtil.isCommunityUser()) {
            
            if(CP_AgreementUtil.userHasUnacceptedAgreements(MD_UserSessionUtil.getUser(), portalName)) {
                System.debug('CG - MD_PostLoginController.constructor() method. User has not accepted the latest Agreements for  Policies.');
                doPostLogin = true;
            }

            // Checks for User selected outlet. If not, redirects to Outlet Selection Page 
            if(!doPostLogin) {
                System.debug('CG - in MD_PostLoginController.constructor() method. Checking Account Outlets information.');

                // ECOM-1479
                MD_UserSessionUtil.MD_CheckOutletInformationResponse checkedOutletInformation = MD_UserSessionUtil.checkForOutletsInfo();

                // if checkForOutletsInfo.response FALSE, means that the User has no NavigateAsOutlet session value selected 
                if(! checkedOutletInformation.result) {
                    System.debug('CG - in CP_PostLoginController.constructor() method. User has no NavigateAsOutlet session value selected.');

                    if(checkedOutletInformation.type == MD_UserSessionUtil.MD_CheckOutletInformationResponseType.HAS_MULTIPLE_OUTLETS) {
                        System.debug('CG - MD_PostLoginController.constructor() method. User does not has a selected Outlet.');
                        doPostLogin = true;
                        component = 'outlet';
                    }else if(checkedOutletInformation.type == MD_UserSessionUtil.MD_CheckOutletInformationResponseType.HAS_ONLY_ONE_OUTLET) {
                        System.debug('CG - MD_PostLoginController.constructor() method. User has only one Outlet.');
                        countryCode = checkedOutletInformation.countryCode;
                    }
                }
                // ECOM-1479 
            }

            if(setOutlet){

                availableOutlets = MD_UserSessionUtil.getAvailableOutlets();
                // ECOM-1333 
                currentOutlet = new MD_UserSessionUtil.OutletInfo();

                if(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c != null &&  MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c != '') {
                    AccountContactRelation sessionOutlet = MD_UserSessionUtil.availableOutlets.get(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c);

                    currentOutlet = new MD_UserSessionUtil.OutletInfo(sessionOutlet.Account.Name, sessionOutlet!= null ? String.valueOf(sessionOutlet.Id) : null);
                }
                // ECOM-1333  
            }
        }

    }

    @AuraEnabled
    public static String evaluatePostLoginConditions() {
        PostLoginControllerResponse response = new MD_PostLoginController.PostLoginControllerResponse();
        response.agreementsToAccept = new List<CP_AgreementUtil.AgreementWrapper>();
        response.doPostLogin = false;

        List<CP_Agreement__c> toAcceptAgreements = CP_AgreementUtil.getAgreementsToAccept(MD_UserSessionUtil.getUser(), portalName);

        response.availableOutlets = MD_UserSessionUtil.getAvailableOutlets();

        if(toAcceptAgreements.size() > 0) {
            for(CP_Agreement__c toAcceptAgreement : toAcceptAgreements) {
                CP_AgreementUtil.AgreementWrapper ag = new CP_AgreementUtil.AgreementWrapper();
                ag.agreementId = toAcceptAgreement.Id;
                ag.type = toAcceptAgreement.Type__c;
                ag.version = toAcceptAgreement.Version__c;
                response.agreementsToAccept.add(ag);
            }

            response.doPostLogin = true;
        }
        
        /*
        if(!doPostLogin) {
            System.debug('CG - in MD_PostLoginController.constructor() method. Checking Account Outlets information.');

            // ECOM-1479
            MD_UserSessionUtil.MD_CheckOutletInformationResponse checkedOutletInformation = MD_UserSessionUtil.checkForOutletsInfo();

            // if checkForOutletsInfo.response FALSE, means that the User has no NavigateAsOutlet session value selected 
            if(! checkedOutletInformation.result) {
                System.debug('CG - in CP_PostLoginController.constructor() method. User has no NavigateAsOutlet session value selected.');

                if(checkedOutletInformation.type == MD_UserSessionUtil.MD_CheckOutletInformationResponseType.HAS_MULTIPLE_OUTLETS) {
                    System.debug('CG - MD_PostLoginController.constructor() method. User does not has a selected Outlet.');
                    doPostLogin = true;
                    component = 'outlet';
                }else if(checkedOutletInformation.type == MD_UserSessionUtil.MD_CheckOutletInformationResponseType.HAS_ONLY_ONE_OUTLET) {
                    System.debug('CG - MD_PostLoginController.constructor() method. User has only one Outlet.');
                    countryCode = checkedOutletInformation.countryCode;
                }
            }
            // ECOM-1479 
        }

        if(setOutlet){

            availableOutlets = MD_UserSessionUtil.getAvailableOutlets();
            // ECOM-1333 
            currentOutlet = new MD_UserSessionUtil.OutletInfo();

            if(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c != null &&  MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c != '') {
                AccountContactRelation sessionOutlet = MD_UserSessionUtil.availableOutlets.get(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c);

                currentOutlet = new MD_UserSessionUtil.OutletInfo(sessionOutlet.Account.Name, sessionOutlet!= null ? String.valueOf(sessionOutlet.Id) : null);
            }
            // ECOM-1333  
        }
        */

        return JSON.serialize(response);

    }

    @AuraEnabled
    public static String initPostLogin() {
        MD_PostLoginController controller = new MD_PostLoginController(true);

        return JSON.serialize(controller);
    }


    /**** TERMS AND AGREEMENTS - BEGIN ******/
    @AuraEnabled
    public static Object getActualTermsAndAgreement(String agreementId, String countryCode) {

        List<CP_Agreement__c> terms = new List<CP_Agreement__c>();
        User currentUser = MD_UserSessionUtil.getUser();
        
        if(String.isNotEmpty(agreementId)) {
            terms = getActiveAgreementFromId(agreementId);
        }else {
            String country;
            if(countryCode == null){
                country = currentUser.Contact.Account.Country__r.Code__c;
            } else {
                country = countryCode;
            }
            terms = getAgreementFromCountryCode(country, 'Terms & Conditions');
        }

        if(terms.size() > 0) {
            return JSON.serialize(terms.get(0));
        }else {
            return JSON.serialize(new MD_Agreement__c());
        }
    }

    @TestVisible
    private static List<CP_Agreement__c> getActiveAgreementFromId (String agreementId) {
        Id activeRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();

        DiageoCMS__CMSUserSettings__c cmsSettings = DiageoCMS.CMSUserSettingsUtils.getUserSettings(UserInfo.getUserId());
        String clusterId = cmsSettings.DiageoCMS__Cluster__c;

        List<CP_Agreement__c> agreement = [SELECT Id, AgreementBody__c FROM CP_Agreement__c 
                                            WHERE Id = :agreementId 
                                                AND RecordTypeId = :activeRtId 
                                                AND Portal__c = 'MyDiageo' 
                                                AND Cluster__c = :clusterId];

        return agreement;
    }

    @TestVisible
    private static List<CP_Agreement__c> getAgreementFromCountryCode (String countryCode, String type) {
        String clusterId = '';
        Id activeRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();
        List<DiageoCMS__Cluster__c> clusterList = [SELECT Id FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = :countryCode];

        if(clusterList.size() > 0) {
            clusterId = clusterList.get(0).Id;
        }

        List<CP_Agreement__c> agreement = [SELECT Id, AgreementBody__c FROM CP_Agreement__c 
                                            WHERE RecordTypeId = :activeRtId 
                                                AND Portal__c = 'MyDiageo' 
                                                AND Cluster__c = :clusterId
                                                AND Type__c = :type
                                            ORDER BY LastModifiedDate DESC];

        return agreement;
    }

    @AuraEnabled
    public static void confirmTerms(Id agreementsId) {
        System.debug('CG - MD_UserSessionUtil.confirmTerms() method. agreementsId: ' + agreementsId);

        CP_Agreement__c agreement = [SELECT Id, Type__c FROM CP_Agreement__c WHERE Id = :agreementsId];

        List<CP_ContactAgreement__c> contactAgreements = [SELECT Id FROM CP_ContactAgreement__c 
                                                            WHERE Contact__c = : MD_UserSessionUtil.getUser().ContactId
                                                                AND Type__c = :agreement.Type__c];


        if(contactAgreements.size() > 0) {
            CP_ContactAgreement__c forUpdateContactAgreement = new CP_ContactAgreement__c(Id = contactAgreements.get(0).Id);

            forUpdateContactAgreement.CurrentAgreement__c = agreement.Id;
            forUpdateContactAgreement.Acceptance__c = DateTime.now();
			
            System.debug('MD - in MD_PostLoginController.confirmTerms() method. forUpdateContactAgreement: ' + forUpdateContactAgreement);
            
            update forUpdateContactAgreement;
        }else {
            CP_ContactAgreement__c newContactAgreement = new CP_ContactAgreement__c();
            newContactAgreement.CurrentAgreement__c = agreement.Id;
            newContactAgreement.Contact__c = MD_UserSessionUtil.getUser().ContactId;
            newContactAgreement.Acceptance__c = DateTime.now();
            newContactAgreement.Type__c = agreement.Type__c;

            insert newContactAgreement;
        }

    }

    /**** TERMS AND CONDITIONS - END */

    @AuraEnabled
    public static String getAvailableOutlets(){
        if(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c != null &&  MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c != '') {
            AccountContactRelation sessionOutlet = MD_UserSessionUtil.availableOutlets.get(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c);
            return JSON.serialize(new MD_UserSessionUtil.OutletInfo(sessionOutlet.Account.Name, String.valueOf(sessionOutlet.Id)));

        }
        return JSON.serialize(new MD_UserSessionUtil.OutletInfo());
    }

    @AuraEnabled
    public static Object getPrivacyPoliciesData(String countryCode, String agreementId) {
        Map<String, Object> privacyData = new Map<String, Object>();

        List<CP_Agreement__c> terms = new List<CP_Agreement__c>();
        User currentUser = MD_UserSessionUtil.getUser();
        
        if(String.isNotEmpty(agreementId)) {
            terms = getActiveAgreementFromId(agreementId);
        }else {
            String country;
            if(countryCode == null){
                country = currentUser.Contact.Account.Country__r.Code__c;
            } else {
                country = countryCode;
            }
            terms = getAgreementFromCountryCode(country, 'Privacy Policies');
        }

        if(terms.size() > 0) {
            // Create the response data for the lightning component
            privacyData.put('actualPolicies', terms.get(0));
            
            if(MD_UserSessionUtil.isLoggedUser()) {
                // Get the contact subscriptions
                System.debug('CG - in MD_PostLoginController.getPrivacyPoliciesData() method. LoggedUser currentUser: ' + currentUser);
        
                Contact contact = [SELECT Id, MD_PrivacyPolicyLookup__c, MD_ContactSubscriptions__c 
                                    FROM Contact 
                                    WHERE Id =: currentUser.ContactId];

                privacyData.put('contactPolicies', contact.MD_PrivacyPolicyLookup__c);
                
                Set<String> contactSubscriptionValues = new Set<String>();

                if (contact.MD_ContactSubscriptions__c != null) {
                    contactSubscriptionValues.addAll(contact.MD_ContactSubscriptions__c.split(';'));
                }

                List<Map<String, Object>> subscriptionsValues = new List<Map<String, Object>>();
                SObjectField contactSubscriptionField = MD_SchemaUtil.getObjectField('Contact', 'MD_ContactSubscriptions__c');
                DescribeFieldResult contactSubscriptionFieldDescribe = contactSubscriptionField.getDescribe();

                Map<String, Object> value = new Map<String, Object>();
                for (PicklistEntry subscriptionValue : contactSubscriptionFieldDescribe.getPicklistValues()) {
                    //ECOM-1391 Add SMS, Post, Telephone in Marketing preferences channel
                    value = new Map<String, Object>();
                    value.put('label', subscriptionValue.label);
                    value.put('value', subscriptionValue.value);
                    value.put('selected', contactSubscriptionValues.contains(subscriptionValue.value));
                    subscriptionsValues.add(value);
                }
                
                privacyData.put('contactSubscriptions', subscriptionsValues);
            }
        }

        return JSON.serialize(privacyData);
    }

    @AuraEnabled
    public static void confirmPrivacyPolicies(Id policiesId, String contactSubscriptions) {
        System.debug('CG - MD_UserSessionUtil.confirmPrivacyPolicies() method. policiesId: ' + policiesId + ' contactSubscriptions: ' + contactSubscriptions);

        try {

            Contact contact = MD_UserSessionUtil.getUser().Contact;
            Set<Id> contactIds = new Set<Id>{contact.Id};

            confirmTerms(policiesId);
            
            if(contact.MD_SubscriptionDate__c == null) {
                contact.MD_SubscriptionDate__c = DateTime.now();
            }

            contact.MD_ContactSubscriptions__c = contactSubscriptions;
            contact.MD_Subscribed__c = true;

            setMyDiageoSuscribed(contactIds);

            System.debug('CG - MD_UserSessionUtil.confirmPrivacyPolicies() method. forUpdateContact: ' + contact);
            update contact;

        }catch(DmlException e){
            System.debug('Error on MD_PostLoginController - confirmPrivacyPolicies: ' + e.getMessage());
        }
    }

    @TestVisible
    private static void setMyDiageoSuscribed(Set<Id> contactIds){
        List<Account> accounts = new List<Account>();
        
        for (AccountContactRelation acr: [SELECT Id, AccountId, Account.MD_MyDiageoSuscribed__c FROM AccountContactRelation WHERE ContactId in: contactIds AND MD_MyDiageoEnabled__c = true]){
            if(!acr.Account.MD_MyDiageoSuscribed__c){
                accounts.add(new Account(Id = acr.AccountId, MD_MyDiageoSuscribed__c = true));
            }
        }
        if (accounts.size()>0){
            update accounts;
        }
    } 
    
    public class PostLoginControllerResponse {
        public Boolean doPostLogin {get;set;}
        public List<CP_AgreementUtil.AgreementWrapper> agreementsToAccept {get;set;}
        public List<AccountContactRelation> availableOutlets {get;set;}
    }
}