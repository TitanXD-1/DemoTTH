public without sharing class MD_ManageUsersController {
    
    @AuraEnabled
    public static String getAccountContacts(){
        //Get all the Account Contacts related to the outlet and put the one related to my contact at the begining
        List<AccountContactRelation> orderListOfAccContacts = MD_AccountContactUtil.putAccContactForLoggedUserFirst(MD_UserSessionUtil.getAvailableContacts());
        System.debug(orderListOfAccContacts);
        TableConfigurationWrapper response = new TableConfigurationWrapper(orderListOfAccContacts, checkForRights());
        return JSON.serialize(response);
    }
    
    @AuraEnabled
    public static String saveChangesToSF(String tableConfigStr){
        TableConfigurationWrapper tableConfig = (TableConfigurationWrapper)JSON.deserialize(tableConfigStr, TableConfigurationWrapper.class);
        List<AccountContactRelation> accContacts = getAccountContactsFromTableConfig(tableConfig);
        
        //Add the existing Account Contacts that were active to the list of Account Contacts that will be updated
        List<AccountContactRelation> accConsToUpsert = MD_AccountContactUtil.getExistingAccContactsDisplayed(accContacts);
        
        //Get a map with the Account Contacts that were created in memory.
        //The ones that were created in memory can exist in Salesforce so we need to find out if they exist so that we update them and avoid creating another one
        map<String, AccountContactRelation> mapNewAccContacts = MD_AccountContactUtil.getMemoryCreatedAccContacts(accContacts);
        //We query to see if there are any records linked to the same account and contact and add the Id to the one we created in memory
        accConsToUpsert.addAll(MD_AccountContactUtil.addIdsOfExistingRecToNewAccContacts(mapNewAccContacts, 
                                                                                         [SELECT Id, MD_ContactAccountIds__c
                                                                                          FROM AccountContactRelation
                                                                                          WHERE MD_ContactAccountIds__c IN: mapNewAccContacts.keySet()]));
        
        try{
            upsert accConsToUpsert;
            return 'Success';
        }catch(Exception e){
            return e.getMessage();
        }
    }
    
    //This method will return if the logged user is owner of the contact he is watching and the Id of the logged contact.
    @TestVisible
    private static LoggedUserInfo checkForRights(){
        try{
            User u = MD_UserSessionUtil.getUser();
            Account acc = MD_UserSessionUtil.getOutlet();
            LoggedUserInfo loggedUser = new LoggedUserInfo();
            loggedUser.loggedContactId = u.ContactId;
            loggedUser.isOwnerOfAccount = false;
            for(AccountContactRelation accContact : u.Contact.AccountContactRelations){
                if(accContact.AccountId == acc.Id && accContact.MD_AssignedPermissions__c.contains('Manage Users')){
                    loggedUser.isOwnerOfAccount = true;
                }
            }
            return loggedUser;
        }catch(Exception e){
            system.debug(e.getStackTraceString());
            return null;
        }
    }
    
    private static List<AccountContactRelation> getAccountContactsFromTableConfig(TableConfigurationWrapper tableConfig){
        List<AccountContactRelation> accountContacts = new List<AccountContactRelation>();
        for(RowConfigurationWrapper rowConfig : tableConfig.rowConfigurations){
            accountContacts.add(rowConfig.accountContact);
        }
        return accountContacts;
    }

    
    @TestVisible 
    private class LoggedUserInfo{
        public Id loggedContactId;
        public Boolean isOwnerOfAccount;
    }
    
    public class TableConfigurationWrapper {
        public List<HeaderConfigurationWrapper> headerConfiguration;
        public List<RowConfigurationWrapper> rowConfigurations;
        public Id loggedContactId;
        public Boolean isOwnerOfAccount;

        public TableConfigurationWrapper(List<AccountContactRelation> accountContacts, LoggedUserInfo userInfo){
            Map<String, List<String>> permissionsByRegion = MD_MultiCountryUtils.getClusterPermissions(getDistinctRegions(accountContacts));

            List<RowConfigurationWrapper> rowsConfiguration = new List<RowConfigurationWrapper>();
            List<HeaderConfigurationWrapper> headerConfiguration = getDifferentColumnsToDisplay(accountContacts, permissionsByRegion);
            List<String> differentColumns = new List<String>();
            for(HeaderConfigurationWrapper header : headerConfiguration){
                differentColumns.add(header.headerName);
            }
            for(AccountContactRelation accCon : accountContacts){
                system.debug('## accCon: ' + accCon);
                List<ColumnWrapper> columns = new List<ColumnWrapper>();
                if(accCon.MD_AssignedPermissions__c == null)
                    accCon.MD_AssignedPermissions__c = '';
                if(differentColumns.contains(Label.MD_FrontendPermissionsAccess))
                    columns.add(new ColumnWrapper('Access', Label.MD_FrontendPermissionsAccess, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Access') ? true : false, accCon.MD_AssignedPermissions__c.contains('Access')));
                if(differentColumns.contains(Label.MD_FrontendPermissionsOrder))
                    columns.add(new ColumnWrapper('Order', Label.MD_FrontendPermissionsOrder, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Order') ? true : false, accCon.MD_AssignedPermissions__c.contains('Order')));
                if(differentColumns.contains(Label.MD_FrontendPermissionsAccountDocuments))
                    columns.add(new ColumnWrapper('Account Documents', Label.MD_FrontendPermissionsAccountDocuments, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Account Documents') ? true : false, accCon.MD_AssignedPermissions__c.contains('Account Documents')));
                if(differentColumns.contains(Label.MD_FrontendPermissionsManageUsers))
                    columns.add(new ColumnWrapper('Manage Users', Label.MD_FrontendPermissionsManageUsers, permissionsByRegion.get(accCon.Account.Country__r.Code__c).contains('Manage Users') ? true : false, accCon.MD_AssignedPermissions__c.contains('Manage Users')));
                RowConfigurationWrapper columnConfig = new RowConfigurationWrapper(columns, accCon);
                rowsConfiguration.add(columnConfig);
            }
            this.headerConfiguration = headerConfiguration;
            this.rowConfigurations = rowsConfiguration;
            if(userInfo != null){
                this.loggedContactId = userInfo.loggedContactId;
                this.isOwnerOfAccount = userInfo.isOwnerOfAccount;
            }
        }

		@TestVisible        
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
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsAccess
                                                                        , Label.MD_FrontendPermissionsAccessLabel
                                                                        , Label.MD_FrontendPermissionsAccessHelp
                                                                        , Label.MD_UsOuPerTabHelpIcon));
            }
            if(orderColumn){
                differentColumns.add(Label.MD_FrontendPermissionsOrder);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsOrder
                                                                        , Label.MD_FrontendPermissionsOrderLabel
                                                                        , Label.MD_FrontendPermissionsOrderHelp
                                                                        , Label.MD_UsOuPerTabHelpIcon));
            }
            if(accountDocumentsColumn){
                differentColumns.add(Label.MD_FrontendPermissionsAccountDocuments);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsAccountDocuments
                                                                        , Label.MD_FrontendPermissionsAccountDocumentsLabel
                                                                        , Label.MD_FrontendPermissionsAccountDocumentsHelp
                                                                        , Label.MD_UsOuPerTabHelpIcon));
            }
            if(manageUsersColumn){
                differentColumns.add(Label.MD_FrontendPermissionsManageUsers);
                headerConfiguration.add(new HeaderConfigurationWrapper(Label.MD_FrontendPermissionsManageUsers
                                                                        , Label.MD_FrontendPermissionsManageUsersLabel
                                                                        , Label.MD_FrontendPermissionsManageUsersHelp
                                                                        , Label.MD_UsOuPerTabHelpIcon));
            }
            return headerConfiguration;
        }
        
        private List<String> getDistinctRegions(List<AccountContactRelation> accountContacts){
            List<String> regions = new List<String>();
            for(AccountContactRelation accCon : accountContacts){
                if(!regions.contains(accCon.Account.Country__r.Code__c)){
                    regions.add(accCon.Account.Country__r.Code__c);
                }
            }
            return regions;
        }
    }
    
    public class HeaderConfigurationWrapper{
        public String headerName;
        public String headerLabel;
        public String headerHelpText;
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
    
    public class RowConfigurationWrapper{
        
        public List<ColumnWrapper> columns;
        public AccountContactRelation accountContact;
        
        public RowConfigurationWrapper(List<ColumnWrapper> columns, AccountContactRelation accountContact){
            this.columns = columns;
            this.accountContact = accountContact;
        }
    }
    
    public class ColumnWrapper{
        public String columnName;
        public String columnLabel;
        public Boolean displayCheckbox;
        public Boolean value;
        public Boolean isDisabled;
        
        public ColumnWrapper(String columnName, String columnLabel, Boolean displayCheckbox, Boolean value){
            this.columnName = columnName;
            this.columnLabel = columnLabel;
            this.displayCheckbox = displayCheckbox;
            this.value = value;
        }
    }
}