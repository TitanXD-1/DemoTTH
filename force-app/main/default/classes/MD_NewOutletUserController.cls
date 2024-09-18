/******************************************************************************
Apex Class Name     :   MD_NewOutletUserController.cls 
Version             :   1.0
Created Date        :   09/05/2018
Release             :   R1
Function            :   
Modification Log    :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Ramiro Ichazo               09/05/2018              Original Version
* Agustin Sanchez             13/09/2018              ECOM 754 - Add/rename fields and make them accessible in reports/objects layout - Contact object
* Agustin Sanchez             13/09/2018              ECOM 763 - Add/rename fields and make them accessible in reports/objects layout - Outlet Contact object
* Hernan Arakaki              19/09/2018              ECOM 1043 - Contact - Users created on frontend with create an user option appear as Customer Portal User on backend
******************************************************************************/
public without sharing class MD_NewOutletUserController {
    @AuraEnabled
    public static TableConfigurationWrapper getLoggedUserInformation(String formExternalId){
        Set<Id> clustersId = new Set<Id>();
        
        Contact userContact = MD_UserSessionUtil.getUser().Contact;
        
        System.debug('CG - in MD_NewOutletUserController.getLoggedUserInformation() method. userContact: ' + userContact);
        
        List<String> regions = new List<String>();
        
        for(AccountContactRelation accCon : userContact.AccountContactRelations){
            if(!regions.contains(accCon.Account.Country__r.Code__c)){
                regions.add(accCon.Account.Country__r.Code__c);
            }
        }
        
        System.debug('CG - in MD_NewOutletUserController.getLoggedUserInformation() method. regions: ' + regions);
        
        for(DiageoCMS__Cluster__c cluster : [SELECT Id FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c IN :regions]) {
            clustersId.add(cluster.Id);
        }
        
        System.debug('CG - in MD_NewOutletUserController.getLoggedUserInformation() method. clustersId: ' + clustersId);
        
        TableConfigurationWrapper response = new TableConfigurationWrapper(userContact, MD_MultiCountryUtils.getClusterPermissions(regions), formExternalId, clustersId);
        
        System.debug('CG - in MD_NewOutletUserController.getLoggedUserInformation() method. response: ' + response);
        
        return response; //JSON.serialize(response);
    }
    
    @AuraEnabled
    public static String checkForDuplicates(String newContactStr){
        CheckForDuplicatesResponse checkForDuplicatesResponse = new CheckForDuplicatesResponse();
        Contact newContact = (Contact)JSON.deserialize(newContactStr, Contact.class);
        //We check if there is a user with the same username
        List<User> repeatedUsers = [SELECT FirstName, LastName, Username, ContactId, Profile.Name, IsActive FROM User WHERE UserName =: newContact.Email];
        //There is another user with the same username
        if(!repeatedUsers.isEmpty()){
            if(repeatedUsers.get(0).Profile.Name != 'Collaborate Full Contact Community Plus Login' || !repeatedUsers.get(0).IsActive){
                checkForDuplicatesResponse.duplicateResult = 'Error';
            }else{
                checkForDuplicatesResponse.duplicateResult = 'Duplicate';
                checkForDuplicatesResponse.user = repeatedUsers.get(0);
            }
            return JSON.serialize(checkForDuplicatesResponse);
        }
        checkForDuplicatesResponse.duplicateResult = 'Confirm';
        return JSON.serialize(checkForDuplicatesResponse);
    }
    
    
    //Called if a user was found with the same email address and the user wants to add permissions.
    @AuraEnabled
    public static String addPermissionsToContact(String contactId, String rowConfigurations) {
        
        List<RowConfigurationWrapper> rowConfig = (List<RowConfigurationWrapper>)JSON.deserialize(rowConfigurations, List<RowConfigurationWrapper>.class);
        
        List<AccountContactRelation> listOfAccountUsers = getAccountContactsFromTableConfig(rowConfig);
        List<AccountContactRelation> listSelectedAccContacts = new List<AccountContactRelation>();
        
        Map<Id, AccountContactRelation> mapAccountIdToAccContact = new map<Id, AccountContactRelation>();
        for(AccountContactRelation accCon : [SELECT Id, AccountId FROM AccountContactRelation WHERE ContactId = :contactId]){
            mapAccountIdToAccContact.put(accCon.AccountId, accCon);
        }
        for(AccountContactRelation accContact : listOfAccountUsers){
            if(accContact.MD_Status__c == 'Active'){
                if(mapAccountIdToAccContact.containsKey(accContact.AccountId)){
                    accContact.Id = mapAccountIdToAccContact.get(accContact.AccountId).Id;
                }
                if (accContact.ContactId == null) {
                    accContact.ContactId = contactId;
                }
                listSelectedAccContacts.add(accContact);
            }
        }
        System.debug('MD_NewOutletUserController.addPermissionsToContact listSelectedAccContacts=' + listSelectedAccContacts);
        try{
            upsert listSelectedAccContacts;
            return 'Success';
        }catch(Exception e){
            return 'Error';
        }
    }
    
    @AuraEnabled
    public static String saveContact(String formSettings, String contactData, String rowConfigurations){
        
        Map<String, SObject> formData = new Map<String, SObject>();
        Contact con = (Contact)JSON.deserialize(contactData, Contact.class);
        formData.put('Contact', con);
        
        System.debug('CG - in MD_NewOutletUserController.saveContact() method. formSettings: ' + formSettings + ' - rowConfigurations: ' + rowConfigurations);
        MD_JSONResponse response = new MD_JSONResponse();
        
        List<RowConfigurationWrapper> rowConfig = (List<RowConfigurationWrapper>)JSON.deserialize(rowConfigurations, List<RowConfigurationWrapper>.class);
        
        
        List<AccountContactRelation> listOfAccountUsers = getAccountContactsFromTableConfig(rowConfig);
        
        for(Integer i = 0 ; i < listOfAccountUsers.size() ; i++){
            if(listOfAccountUsers[i].MD_AssignedPermissions__c != '') {
                formData.put('AccountContactRelation' + i, listOfAccountUsers[i]);
            }
        }
        
        System.debug('CG - in MD_NewOutletUserController.saveContact() method. formData: ' + formData);
        DiageoCMS.FormResponseWrapper saveFormResponse = DiageoCMS.GeneralForm.saveForm(formSettings, formData);
        System.debug('CG - in MD_NewOutletUserController.saveContact() method. saveFormResponse: ' + saveFormResponse);
        
        if(Test.isRunningTest()) {
            response.message = 'TestMessage';
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
        }else {
            response.message = saveFormResponse.message;
            
            if(saveFormResponse.status == 'Success') {
                response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            }else {
                 if (response.message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')){
                    String text1='FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
                    Integer i = response.message.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION, ');
                    response.message = response.message.substring(i + text1.length());
                }
                response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            }
        }
        
        return JSON.serialize(response);
    }
    
    @AuraEnabled
    public static String saveUser(String contactStr, String listToRevertInCaseOfFailure, String contactData, String formSettings){
        Contact contact = (Contact) JSON.deserialize(contactStr, Contact.class);
        MD_JSONResponse response = new MD_JSONResponse();
        List<SObject> listToRevert = (List<SObject>) JSON.deserialize(listToRevertInCaseOfFailure, List<SObject>.class);
        
        Map<String, SObject> formData = new Map<String, SObject>();
        Contact con = (Contact)JSON.deserialize(contactData, Contact.class);
        formData.put('Contact', con);
        
        System.debug(contact);
        
        String countryCode = MD_UserSessionUtil.getclusterLocationCode(contact.MailingCountry);
        
        for(Integer i = 0 ; i < listToRevert.size() ; i++){
            formData.put('sObjectToRevert_' + i, listToRevert[i]);
        }
        
        
        //return JSON.serialize(DiageoCMS.GeneralForm.saveForm(formSettings, tableConfiguration.form.formData));
        
        DiageoCMS.FormResponseWrapper saveFormResponse = DiageoCMS.GeneralForm.saveForm(formSettings, formData);
        System.debug('CG - in MD_NewOutletUserController.saveUser() method. saveFormResponse: ' + saveFormResponse);
        
        if(Test.isRunningTest()) {
            response.message = 'TestMessage';
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
        }else {
            response.message = saveFormResponse.message;
            
            if(saveFormResponse.status == 'Success') {
                response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            }else {
                if (response.message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, ')){
                    String text1='FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
                    Integer i = response.message.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION, ');
                    response.message = response.message.substring(i + text1.length());
                }
                response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            }
        }
        return JSON.serialize(response);        
        
    }
    
    /* MIGRATION - Commented */
    @TestVisible
    private static List<AccountContactRelation> getAccountContactsFromTableConfig(List<RowConfigurationWrapper> rowConfigs){
        List<AccountContactRelation> accountContacts = new List<AccountContactRelation>();
        for(RowConfigurationWrapper rowConfig : rowConfigs){//tableConfig.rowConfigurations){
            accountContacts.add(rowConfig.accountContact);
        }
        return accountContacts;
    }
    
    @TestVisible
    private class CheckForDuplicatesResponse{
        public String duplicateResult;
        public User user;
    }
    
    public class FormWrapper {
        @AuraEnabled
        public MD_GeneralFormWrapper.FormSettings formSettings;
        
        @AuraEnabled
        public Map<String, SObject> formData{get;set;}
        
        public FormWrapper() {
            
        }
        
        public FormWrapper(DiageoCMS.GeneralForm form) {
            this.formData = form.formData;
            this.formSettings = new MD_GeneralFormWrapper.FormSettings(form.formSettings);
        }
    }
    
    
    public class TableConfigurationWrapper {
        @AuraEnabled
        public DiageoCMS.GeneralForm form;
        
        @AuraEnabled
        public List<HeaderConfigurationWrapper> headerConfiguration;
        
        @AuraEnabled
        public List<RowConfigurationWrapper> rowConfigurations;
        
        @AuraEnabled
        public Contact userContact;
        
        /* MIGRATION - Commented */
        public TableConfigurationWrapper(Contact con, Map<String, List<String>> permissionsByRegion, String formExternalId, Set<Id> clustersId){
            
            System.debug('CG - in MD_NewOutletUserController.TableConfigurationWrapper() - con: ' + con + ' - permissionsByRegion: ' + permissionsByRegion + ' - formExternalId: ' + formExternalId + ' - clustersId: ' + clustersId);
            DiageoCMS.GeneralForm cmsForm = new DiageoCMS.GeneralForm(formExternalId, clustersId);
            this.form = cmsForm;//new FormWrapper(cmsForm);
            
            List<RowConfigurationWrapper> rowsConfiguration = new List<RowConfigurationWrapper>();
            List<HeaderConfigurationWrapper> headerConfiguration = getDifferentColumnsToDisplay(con.AccountContactRelations, permissionsByRegion);
            
            System.debug('CG - in MD_NewOutletUserController.TableConfigurationWrapper() - headerConfiguration: ' + headerConfiguration);
            
            List<String> differentColumns = new List<String>();
            for(HeaderConfigurationWrapper header : headerConfiguration){
                differentColumns.add(header.headerName);
            }
            
            System.debug('CG - in MD_NewOutletUserController.TableConfigurationWrapper() - differentColumns: ' + differentColumns);
            
            for(AccountContactRelation accCon : con.AccountContactRelations){
                List<ColumnWrapper> columns = new List<ColumnWrapper>();
                if(differentColumns.contains(Label.MD_FrontendPermissionsAccess)) {
                    columns.add(new ColumnWrapper('Access', Label.MD_FrontendPermissionsAccess, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Access') ? true : false));
                }
                if(differentColumns.contains(Label.MD_FrontendPermissionsOrder)) {
                    columns.add(new ColumnWrapper('Order', Label.MD_FrontendPermissionsOrder, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Order') ? true : false));
                }
                if(differentColumns.contains(Label.MD_FrontendPermissionsAccountDocuments)) {
                    columns.add(new ColumnWrapper('Account Documents', Label.MD_FrontendPermissionsAccountDocuments, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Account Documents') ? true : false));
                }
                if(differentColumns.contains(Label.MD_FrontendPermissionsManageUsers)) {
                    columns.add(new ColumnWrapper('Manage Users', Label.MD_FrontendPermissionsManageUsers, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Manage Users') ? true : false));
                }
                RowConfigurationWrapper columnConfig = new RowConfigurationWrapper(columns, accCon);
                rowsConfiguration.add(columnConfig);
            }
            
            System.debug('CG - in MD_NewOutletUserController.TableConfigurationWrapper() - rowsConfiguration: ' + rowsConfiguration);
            this.headerConfiguration = headerConfiguration;
            this.rowConfigurations = rowsConfiguration;
            this.userContact = con;
        }
        
        private List<HeaderConfigurationWrapper> getDifferentColumnsToDisplay(List<AccountContactRelation> accountContacts, Map<String, List<String>> permissionsByRegion){
            List<HeaderConfigurationWrapper> headerConfiguration = new List<HeaderConfigurationWrapper>();
            List<String> differentColumns = new List<String>();
            Boolean accessColumn = false;
            Boolean orderColumn = false;
            Boolean accountDocumentsColumn = false;
            Boolean manageUsersColumn = false;
            for(AccountContactRelation accCon : accountContacts){
                if(permissionsByRegion.get(accCon.Account.Country__r.Code__c) != null){
                    if(permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Access'))
                        accessColumn = true;
                    if(permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Order') && !differentColumns.contains('Order'))
                        orderColumn = true;
                    if(permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Account Documents') && !differentColumns.contains('Account Documents'))
                        accountDocumentsColumn = true;
                    if(permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Manage Users') && !differentColumns.contains('Manage Users'))
                        manageUsersColumn = true;
                }
            }
            if(accessColumn){
                differentColumns.add(Label.MD_FrontendPermissionsAccess);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsAccess, Label.MD_FrontendPermissionsAccessLabel, Label.MD_FrontendPermissionsAccessHelp, Label.MD_UsOuPerTabHelpIcon));
            }
            if(orderColumn){
                differentColumns.add(Label.MD_FrontendPermissionsOrder);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsOrder, Label.MD_FrontendPermissionsOrderLabel, Label.MD_FrontendPermissionsOrderHelp, Label.MD_UsOuPerTabHelpIcon));
            }
            if(accountDocumentsColumn){
                differentColumns.add(Label.MD_FrontendPermissionsAccountDocuments);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsAccountDocuments, Label.MD_FrontendPermissionsAccountDocumentsLabel, Label.MD_FrontendPermissionsAccountDocumentsHelp, Label.MD_UsOuPerTabHelpIcon));
            }
            if(manageUsersColumn){
                differentColumns.add(Label.MD_FrontendPermissionsManageUsers);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsManageUsers, Label.MD_FrontendPermissionsManageUsersLabel, Label.MD_FrontendPermissionsManageUsersHelp, Label.MD_UsOuPerTabHelpIcon));
            }
            
            return headerConfiguration;
        }
    }
    
    public class HeaderConfigurationWrapper{
        @AuraEnabled
        public String headerName;
        @AuraEnabled
        public String headerLabel;
        @AuraEnabled
        public String headerHelpText;
        @AuraEnabled
        public String headerHelpIcon;
        
        public HeaderConfigurationWrapper(String headerName, String headerHelpText, String headerHelpIcon){
            this.headerName = headerName;
            this.headerHelpText = headerHelpText;
            this.headerHelpIcon = headerHelpIcon;
        }
        
        public HeaderConfigurationWrapper(String headerName, String headerLabel, String headerHelpText, String headerHelpIcon){
            this.headerName = headerName;
            this.headerLabel = headerLabel;
            this.headerHelpText = headerHelpText;
            this.headerHelpIcon = headerHelpIcon;
        }
    }
    
    public class RowConfigurationWrapper {
        @AuraEnabled
        public List<ColumnWrapper> columns {get;set;}
        @AuraEnabled
        public AccountContactRelation accountContact {get;set;}
        
        public RowConfigurationWrapper(List<ColumnWrapper> columns, AccountContactRelation accountContact){
            this.columns = columns;
            this.accountContact = accountContact;
        }
    }
    
    public class ColumnWrapper{
        @AuraEnabled
        public String columnName;
        @AuraEnabled
        public String columnLabel;
        @AuraEnabled
        public Boolean displayCheckbox;
        @AuraEnabled
        public Boolean value;
        @AuraEnabled
        public Boolean isDisabled;
        
        public ColumnWrapper(String columnName, String columnLabel, Boolean displayCheckbox){
            this.columnName = columnName;
            this.columnLabel = columnLabel;
            this.displayCheckbox = displayCheckbox;
            this.value = false;
        }
    }
    
    
}