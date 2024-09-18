/**************************************************************************************
Apex Class Name  :  MD_AccountDetailsController 
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
public without sharing class MD_AccountDetailsController {  
    
    @TestVisible
    private class accDetailWrapper{
        public String currencySymbol;
        public String accountNumber;
        public Account parent;
        public Account outlet;
        
        public Contact contactDetails;
        public List<fieldValueLabel> contactFields;
        
        public accordionSetting accordion;
        
        List<Map<String, Object>> subscriptionsValues;
        public String subscriptionSubHeadingText;
        
        public accDetailWrapper() {

        }

        public accDetailWrapper(Account outlet, Contact contactDetails, List<Map<String, Object>> subscriptionsValues, List<fieldValueLabel> contactFields, accordionSetting accordion, String subscriptionSubHeadingText, String accountNumber){
            this.currencySymbol = MD_UserSessionUtil.getCurrencySimbol();
            this.parent = outlet.parent;
            outlet.parent = null;
            this.outlet = outlet;
            
            this.contactDetails = contactDetails;
            this.contactFields = contactFields;
            
            this.accordion = accordion;
            
            this.subscriptionsValues = subscriptionsValues;
            this.subscriptionSubHeadingText = subscriptionSubHeadingText;
            this.accountNumber = accountNumber;
        }    
    }
    
    private class fieldValueLabel{
        public Object value;
        public String label;
        
        public fieldValueLabel( String label, Object value){
            this.value = value;
            this.label = label;
        }
    }
    
    @TestVisible
    private class accordionSetting{
        public boolean showCommPref;
        public boolean showOutlet;
        
        public accordionSetting(boolean showCommPref, boolean showOutlet){
            this.showCommPref = showCommPref;
            this.showOutlet = showOutlet;
        }
    }
    
    @AuraEnabled
    public static Object getWrapper(){ 
        MD_AccountDetailsController.accDetailWrapper returnWrapper = new MD_AccountDetailsController.accDetailWrapper();

        DiageoCMS__Cluster__c cluster = MD_ClusterUtil.getCountryClusterForUser(new Set<String>{'DiageoCMS__ExternalId__c'
                                                                                                , 'MD_MembershipContactFields__c'
                                                                                                , 'MD_AccountSections__c'
                                                                                                , 'MD_AccountNumberAPIName__c'});

        System.debug('CG - in MD_AccountDetailsController.getWrapper() method. cluster: ' + cluster);
        if (cluster != null) {
            //get contact detail
            String accountNumberAPIName;

            if(String.isNotEmpty(cluster.MD_AccountNumberAPIName__c)) {
                accountNumberAPIName = cluster.MD_AccountNumberAPIName__c;
            }else {
                accountNumberAPIName = 'AccountNumber';
            }

            System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPIName: ' + accountNumberAPIName);

            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getmap();
            Set<String> setSelectedContactField = getSelectedFields('Email;MobilePhone', fieldMap);
            Contact contact = getContactRecord(setSelectedContactField);

            List<fieldValueLabel> contactFields = getContactFields(contact, fieldMap, setSelectedContactField);

            List<Map<String, Object>> subscriptionsValues = getContactSubscription(contact);
            
            // get outlet Detail
            Account outlet = getOutlet(accountNumberAPIName);

            System.debug('CG - in MD_AccountDetailsController.getWrapper() method. outlet: ' + outlet);

            //String accountNumber = (String)outlet.get(accountNumberAPIName);
            String accountNumber;

            /* ECOM - 3843 - BEGIN 
             * The outlet.IsIndependent__c || outlet.Independent_of_Operator__c condition was added, for using the Outlet's VAT_Number__c field.
             * A validation over accountNumberAPINameArgs[0] was added to validate if the lookup is actually filled.
             */
            if(outlet.IsIndependent__c || outlet.Independent_of_Operator__c) {
                accountNumber = outlet.VAT_Number__c;
            }else {

                if(accountNumberAPIName.contains('__r')) {
                    String[] accountNumberAPINameArgs = accountNumberAPIName.split('\\.');
                    System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPINameArgs: ' + accountNumberAPINameArgs);

                    if(outlet.getSObject(accountNumberAPINameArgs[0]) != null) {
                        System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPINameArgs[0]: ' + accountNumberAPINameArgs[0] + ' - accountNumberAPINameArgs[1]: ' + accountNumberAPINameArgs[1]);
                        accountNumber = (String)outlet.getSObject(accountNumberAPINameArgs[0]).get(accountNumberAPINameArgs[1]);
                    }else {
                        System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accountNumberAPINameArgs[0] ' + accountNumberAPINameArgs[0] + ' is an empty relation.');
                        accountNumber = outlet.VAT_Number__c;
                    }
                }else {
                    System.debug('CG - in MD_AccountDetailsController.getWrapper() method. doesnt contains __r - accountNumberAPIName: ' + accountNumberAPIName);
                    accountNumber = (String)outlet.get(accountNumberAPIName);
                }
            }

            // get accordion sections
            accordionSetting accordion = new accordionSetting(true, true);

            // get DynamicLabel
            String location = cluster.DiageoCMS__ExternalId__c;
            String dynamicLabel = String.format(label.MD_AccountDetailSubscriptionsSubHeading, new List<String>{location});
            
            returnWrapper = new accDetailWrapper(outlet, contact, subscriptionsValues, contactFields, accordion, dynamicLabel, accountNumber);
            System.debug('CG - in MD_AccountDetailsController.getWrapper() method. accDetailWrapper: ' + returnWrapper);
        }

        return JSON.serialize(returnWrapper);
    }
    
    @AuraEnabled
    public static String updateContactWithSubscriptions(String subscriptionValues, String contactId){
        System.debug('CG - in MD_AccountDetailsController.updateContactWithSubscriptions() method. subscriptionValues: ' + subscriptionValues);
        
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getmap();
        List<Schema.Picklistentry> subscriptions = fieldMap.get('MD_ContactSubscriptions__c').getDescribe().getpicklistValues();
        
        Map<String,String> subscriptionsMap = new Map<String,String>();
        for (Schema.PicklistEntry subscription : subscriptions) {
            subscriptionsMap.put(subscription.getValue(), subscription.getValue());
        }
        
        List<String> subscriptionsList = subscriptionValues.split(';');
        List<String> subscriptionsValidatedList = new List<String>();
        
        for (Integer i = 0; i < subscriptionsList.size(); i++) {
            if(subscriptionsMap.containskey(subscriptionsList.get(i))){
                subscriptionsValidatedList.add(subscriptionsList.get(i));
            }
        }
        
        String subscriptionsValidateValues = '';
        for (Integer j = 0; j < subscriptionsValidatedList.size(); j++) {
            if(j == subscriptionsValidatedList.size()-1){
                subscriptionsValidateValues += subscriptionsValidatedList.get(j);
            }else{
                subscriptionsValidateValues += subscriptionsValidatedList.get(j) + ';';
            }
        }
        MD_JSONResponse result = new MD_JSONResponse();
        try{
            system.debug('contactId ' + contactId +' subscriptionsValidateValues ' + subscriptionsValidateValues );
            update new Contact(Id = contactId, MD_ContactSubscriptions__c = subscriptionsValidateValues);
            result.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            result.title = '';
            result.message = label.MD_YourSubscriptionPreferencesHaveBeenUpdated;
            return Json.serialize(result);
        }catch(DMLException e){
            result.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            result.title = label.MD_ToastTitleError;
            result.message = e.getDMLMessage(0);
            return Json.serialize(result);
        }catch(Exception e){
            result.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            result.title = label.MD_ToastTitleError;
            result.message = e.getMessage();
            return Json.serialize(result);
        }
    }
    
    @AuraEnabled
    public static String doUpdateUserPassword(String newPassword){
        System.debug('CG - in MD_AccountDetailsController.doUpdateUserPassword() method. UserInfo.getUserId(): ' + UserInfo.getUserId());
        MD_JSONResponse result = new MD_JSONResponse();
        
        try{
            System.setPassword(UserInfo.getUserId(), newPassword);
            result.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            result.title = label.MD_PasswordChanged;
            result.message = label.MD_YourPasswordHasBeenChanged;
            return Json.serialize(result);
        }catch(Exception e){
            result.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            result.title = label.MD_ToastTitleError;
            result.message =  Label.MD_InvalidPassword;
            return Json.serialize(result);
        }
    } 
    
    private static SObject getRecord(Set<String> fieldset, String recordId, String objectApiName ){
        String fields = '';
        
        if(!fieldset.isEmpty()){
            fields = String.join(new List<String>(fieldset),',');
        }else{
            fields = 'Id, Name';
        }
        List<SObject> objectRecord = Database.query('SELECT ' + fields + ' FROM ' + objectApiName + ' WHERE Id =: recordId LIMIT 1');
        if(!objectRecord.isEmpty()){
            return objectRecord.isEmpty() ? null : objectRecord[0];
        }
        
        return null;
    }
    
    private static Set<String> getSelectedFields(String fields, Map<String, Schema.SObjectField> fieldMap){
        Set<String> setSelectedField = new Set<String>();
        
        if(fields != null){
            for(String field : fields.deleteWhitespace().split(';')){
                if(fieldMap.containsKey(field)){
                    setSelectedField.add(field);    
                }
            }
        }
        
        return setSelectedField; 
    }

    private static Contact getContactRecord(Set<String> setSelectedContactField){
        Set<String> setContactField = new Set<String>(setSelectedContactField);
        setContactField.add('Id');
        setContactField.add('Name');
        setContactField.add('MD_ContactSubscriptions__c');
        
        String contactId = MD_UserSessionUtil.getUser().contactId;
        System.debug('CG - in CP_AccountDetailsController.getContactRecord() method. contactId: ' + contactId);
         
        Contact contact = (Contact)getRecord(setContactField, contactId, 'Contact');
        return contact;
    }
    
    private static List<fieldValueLabel> getContactFields (Contact contact, Map<String, Schema.SObjectField> fieldMap, Set<String> setSelectedContactField){
        List<fieldValueLabel> contactFields = new List<fieldValueLabel>();
        if(setSelectedContactField != null){
            for (String field : setSelectedContactField){
                contactFields.add(new fieldValueLabel(fieldMap.get(field).getDescribe().getLabel(), contact.get(field)));
            }
        }
        return contactFields;
    }
    
    private static list<Map<String, Object>> getContactSubscription(Contact contact){

        Set<String> contactSubscriptionValues = new Set<String>();

        if (contact.MD_ContactSubscriptions__c != null) {
            contactSubscriptionValues.addAll(contact.MD_ContactSubscriptions__c.split(';'));
        }

        List<Map<String, Object>> subscriptionsValues = new List<Map<String, Object>>();
        
        SObjectField contactSubscriptionField = MD_SchemaUtil.getObjectField('Contact', 'MD_ContactSubscriptions__c');
        DescribeFieldResult contactSubscriptionFieldDescribe = contactSubscriptionField.getDescribe(); 

        Map<String, Object> value = new Map<String, Object>();
        for (PicklistEntry subscriptionValue : contactSubscriptionFieldDescribe.getPicklistValues()) {
                value = new Map<String, Object>();
                value.put('label', subscriptionValue.label);
                value.put('value', subscriptionValue.value);
                value.put('selected', contactSubscriptionValues.contains(subscriptionValue.value));
                subscriptionsValues.add(value);
        }
           
        return subscriptionsValues;
    }
    
    private static Account getOutlet(String accountNumberApiName){
        Id outletId = MD_UserSessionUtil.getOutlet().Id;
        System.debug('CG - in MD_AccountDetailsController.getOutlet() method. outletId: ' + outletId);

        /* ECOM - 3843 - BEGIN 
         * The IsIndependent__c, Independent_of_Operator__c & VAT_Number__c fields were added to the Query
         */
        String query = 'SELECT Id, Name, IsIndependent__c, Independent_of_Operator__c, VAT_Number__c, BillingCountry, Parent.Name ' + (accountNumberApiName != null ? ', ' + accountNumberApiName : '') + ' FROM Account WHERE Id = :outletId';
        System.debug('CG - in MD_AccountDetailsController.getOutlet() method. query: ' + query);

        List<Account> outlets  = Database.query(query);
        Account outlet;
        
        if(outlets.size() > 0) {
            outlet = outlets.get(0);
        }

        System.debug('CG - in MD_AccountDetailsController.getOutlet() method. outlet: ' + outlet);
        
        return outlet;
    }
    
    @TestVisible
    private static accordionSetting getAccordionSetting(String accountSections){
        boolean showCommPref = false; 
        boolean showOutlet = false ;
        if(accountSections != null){
            for(String fieldValue : accountSections.deleteWhitespace().split(';')){
                if (fieldValue == 'CommunicationsPreferences') showCommPref = true;
                if (fieldValue == 'Outlets') showOutlet = true;
            }
        }
        return new accordionSetting(showCommPref, showOutlet);
    }
}