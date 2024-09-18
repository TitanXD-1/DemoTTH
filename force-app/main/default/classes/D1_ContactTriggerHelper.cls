/**
* @name: D1_ContactTriggerHelper
* @description: Trigger Handler Class for ContactTrigger
* @history
* VERSION      AUTHOR              DATE            DETAIL
* 1.0          Sai Kumar           03/11/2021      NCP-5159 (updateEmailPreference)
* 2.0          Rakesh Kumar        09/12/2021      NCP-3358 (updateLoginNextAction)
* 3.0          Gaurav              28/03/2022      NCP-6349 (validatePreferredLanguage)
* 4.0          Rubeena Naaz        28/03/2022      NCP-6408 (updateAccountData)
* 5.0          Kapil Baliyan       04/04/2022      NCP-6511 (Update Class from with sharing to without sharing)
* 6.0		   Rubeena Naaz		   10/06/2022	   NCP-6837(updatePOSOrderDate,updatePOSOrderDateOnACR)
* 8.0          Suvendu             25/07/2023      143004 Allow users to create/edit contact based on Business Role_SFDC
**/

public without sharing class D1_ContactTriggerHelper {
    /**
    * @method : updateEmailPreference
    * @purpose : update Email Opt-out with respect to MD_ContactSubscriptions__c
    */ 
    public static void updateEmailPreference(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Contact> mapOldItems;
        List<Contact> listNewData;
        if(oldItems != null){
            mapOldItems = (Map<Id,Contact>) oldItems;
        }
        if(newItems != null){
            listNewData = (List<Contact>) newItems;
        }
        if(listNewData.size()>0){
            if(oldItems !=null && mapOldItems.size()>0 ){
                for(Contact con: listNewData){
                    if(mapOldItems.containsKey(con.Id) ){ 
                        if( con.MD_ContactSubscriptions__c!= mapOldItems.get(con.Id).MD_ContactSubscriptions__c){
                            if(con.MD_ContactSubscriptions__c != null && con.MD_ContactSubscriptions__c.contains('Email') && con.HasOptedOutOfEmail ){
                                con.HasOptedOutOfEmail=false;
                            }  
                            if((con.MD_ContactSubscriptions__c == Null || !con.MD_ContactSubscriptions__c.contains('Email')) && !con.HasOptedOutOfEmail ){
                                con.HasOptedOutOfEmail=true;
                            }
                        }
                        else if(con.HasOptedOutOfEmail != mapOldItems.get(con.Id).HasOptedOutOfEmail ){
                            if(con.MD_ContactSubscriptions__c != null){
                                string contactSubscriptionsValue = con.MD_ContactSubscriptions__c;
                                List<string> contactSubscriptions = contactSubscriptionsValue.split(';');
                                string emailValue ='Email';
                                if(!con.HasOptedOutOfEmail && !contactSubscriptions.contains(emailValue) ){
                                    contactSubscriptions.add(emailValue); 
                                    con.MD_ContactSubscriptions__c=String.join(contactSubscriptions,';');
                                }
                                if(con.HasOptedOutOfEmail && contactSubscriptions.contains(emailValue) ){
                                    contactSubscriptions.remove(contactSubscriptions.indexOf(emailValue)); 
                                    con.MD_ContactSubscriptions__c=String.join(contactSubscriptions,';');
                                }
                            }else if(!con.HasOptedOutOfEmail){
                                con.MD_ContactSubscriptions__c='Email';
                            }
                        }
                    }
                }
            }else{
                for(Contact con: listNewData){
                    if(con.MD_ContactSubscriptions__c !=null && con.MD_ContactSubscriptions__c.contains('Email') ){
                        con.HasOptedOutOfEmail=false;
                    }  
                    if(con.MD_ContactSubscriptions__c == null || !con.MD_ContactSubscriptions__c.contains('Email') ){
                        con.HasOptedOutOfEmail=true;
                    }
                }
            }
        }
    }
    
    /**
    * @method : updateLoginNextAction
    * @purpose : update Login Reminder Status
    */
    public static void updateLoginNextAction(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Contact> mapOldItems;
        List<Contact> listNewData;
        if(oldItems != null){
            mapOldItems = (Map<Id,Contact>) oldItems;
        }
        if(newItems != null){
            listNewData = (List<Contact>) newItems;
        }        
        Diageo_One_Security_Settings__c diageoOneSecuritySettings = Diageo_One_Security_Settings__c.getInstance();
        
        for(Contact con : listNewData){            
            Date contactLastLoginDate = con.D1_Contact_Last_Login_Date__c != null ?con.D1_Contact_Last_Login_Date__c.date() :null;            
            //Compliant status check
            if(con.D1_Contact_Last_Login_Date__c != mapOldItems.get(con.Id).D1_Contact_Last_Login_Date__c && con.D1_Contact_Last_Login_Date__c!=null){
                con.D1_Login_Reminder_Status__c = 'Compliant';
                con.Next_Action_Date__c = contactLastLoginDate.addDays(Integer.valueOf(diageoOneSecuritySettings.First_Reminder_Days__c));
            }
            else if(con.D1_Contact_Last_Login_Date__c != null && con.D1_Login_Reminder_Status__c !=mapOldItems.get(con.Id).D1_Login_Reminder_Status__c ){             
                if (con.D1_Login_Reminder_Status__c == 'First Reminder' && diageoOneSecuritySettings.Second_Reminder_Days__c!= null){
                    con.Next_Action_Date__c = contactLastLoginDate.addDays(Integer.valueOf(diageoOneSecuritySettings.Second_Reminder_Days__c));
                }                
                if (con.D1_Login_Reminder_Status__c == 'Second Reminder' && diageoOneSecuritySettings.Deactivate_Reminder_Days__c!=null){
                    con.Next_Action_Date__c = contactLastLoginDate.addDays(Integer.valueOf(diageoOneSecuritySettings.Deactivate_Reminder_Days__c));
                }
            }
        }        
    }

    /**
    * @method : validatePreferredLanguage
    * @purpose : validate preferred language on contact NCP-6349
    */
    public static void validatePreferredLanguage(List<sObject> newItems){
        List<Contact> listNewData;
        if(newItems != null){
            listNewData = (List<Contact>) newItems;
        }


        List<Id> accountIds = new List<Id>();
        for(Contact con : listNewData){
            accountIds.add(con.AccountId);
        }

        Map<Id,Account> accountMap;
        if(accountIds!=null && accountIds.size()>0){
        	accountMap = new Map<Id,Account>([Select Id,Country__c from Account where Id IN:accountIds]);
        }

        List<Id> countryIds = new List<Id>();
        for(Account acc : accountMap.values()){
            countryIds.add(acc.Country__c);
        }
		
        Map<String,String> languageCodeNameMap = new Map<String,String>();
		for(Schema.PicklistEntry pickListVal : D1_Setting__c.Language__c.getDescribe().getPicklistValues() ){
			languageCodeNameMap.put(pickListVal.getValue(), pickListVal.getLabel());
		}     
		

        Map<Id,Set<String>> countryLanguagesSet = new Map<Id,Set<String>>();
        for( D1_Setting__c d1s : [Select id,Market__c,Language__c from D1_Setting__c where Market__c IN :countryIds ]){
            if(!countryLanguagesSet.containsKey(d1s.Market__c)){
                countryLanguagesSet.put(d1s.Market__c, new Set<String>{d1s.Language__c});
            }else{
                countryLanguagesSet.get(d1s.Market__c).add(d1s.Language__c);
            }
        }

        for(Contact con : listNewData){            

            if(con.AccountId != NULL && con.Preferred_Language__c != NULL && accountMap.size()>0 && (!accountMap.containsKey(con.AccountId) || !countryLanguagesSet.containsKey(accountMap.get(con.AccountId).Country__c) || !countryLanguagesSet.get(accountMap.get(con.AccountId).Country__c).contains(con.Preferred_Language__c)) ){

                String languages = '';
                for( String  lang : countryLanguagesSet.get(accountMap.get(con.AccountId).Country__c) ){
                    languages += languageCodeNameMap.get(lang)+', ';
                }
                languages = languages.removeEnd(', ');
                
                String errorMsg = System.Label.D1_SelectRelevantLanguage;
                errorMsg = errorMsg.replace('{0}', languages);
                
                con.addError(errorMsg);
            }
        }        
    }
    
    /**
     * @method : updateAccountData NCP-6408
     * @param newItems 
     * @param oldItems 
     */
    public static void updateAccountData(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){

        Map<Id,Contact> newContact = (Map<Id,Contact>) newItems;

        Map<Id,Contact> oldContact;
     
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> relatedAccounts = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        List<Account> accountToUpdate = new List<Account>();
        
        Set<Id> activeAccountSet = new Set<Id>();

        if(oldItems != null){
            oldContact = (Map<Id,Contact>) oldItems;
        }
        
        for(Contact con : newContact.values()){
            Contact oldContactItem = oldContact.get(con.Id);

            if(oldContactItem != null && con.D1_Login_Reminder_Status__c != oldContactItem.D1_Login_Reminder_Status__c && con.D1_Login_Reminder_Status__c == 'Deactivated'){
				contactIdSet.add(con.Id);
            }
        }

        if(!contactIdSet.isEmpty()){
            for(AccountContactRelation acr : [Select Id,AccountId,ContactId,D1_Active__c FROM AccountContactRelation WHERE ContactId IN: contactIdSet]){
                relatedAccounts.add(acr.AccountId);
            }
        }
        
        
        if(!relatedAccounts.isEmpty()){
            for(AccountContactRelation acr : [Select Id,AccountId,ContactId,D1_Active__c FROM AccountContactRelation WHERE AccountId IN: relatedAccounts]){
                
                if(acr.D1_Active__c == true){
                    activeAccountSet.add(acr.AccountId);
                }
                
            }
            for(Id accId : relatedAccounts){
                if(!activeAccountSet.contains(accId)){
                    accountIdSet.add(accId);
                }
            }
            
        }
         
        if(!accountIdSet.isEmpty()){
            for(Account acc : [SELECT Id,D1_Registration_Status__c,D1_Account_Last_Login_Date__c,D1_Partner_Reminder_Display_Login_Count__c,
                               Partner_Plus_Enabled__c,Partner_Plus_Joining_Date__c
                               FROM Account WHERE ID IN:accountIdSet ]){
                acc.D1_Registration_Status__c = '';
                acc.D1_Account_Last_Login_Date__c = null;
                /*NCP-7458*/
                acc.D1_Partner_Reminder_Display_Login_Count__c = null;
                acc.Partner_Plus_Enabled__c = false;
                acc.Partner_Plus_Joining_Date__c = null;
                accountToUpdate.add(acc); 
            }
        }
        
        if(!accountToUpdate.isEmpty()){
            update accountToUpdate;

        }

    }
     /**
    * @userStory : NCP-6837
    * @method : updatePOSOrderDate
    * @purpose : update New Account Name and Last POS order date on Contact to trigger pardot mails accordingly
    */ 
    
    public static void updatePOSOrderDate(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Contact> mapNewItems;
        Map<Id,Contact> mapOldItems;
        Set<Id> contactIdSet = new Set<id>();
        Map<Id,AccountContactRelation> contactACRMap = new Map<Id,AccountContactRelation>();
        
        if(oldItems != null){
            mapOldItems = (Map<Id,Contact>) oldItems;
        }
        if(newItems != null){
            mapNewItems = (Map<Id,Contact>) newItems;
        }

        if(!mapOldItems.isEmpty() && !mapNewItems.isEmpty()){
            for(Contact newcon : mapNewItems.values()){
                Contact oldCon = mapOldItems.get(newcon.Id);
                if(newcon.POS_Order_Email_Sent__c != null && (newcon.POS_Order_Email_Sent__c != oldCon.POS_Order_Email_Sent__c)){
                    contactIdSet.add(newCon.Id);
                }
            }
        }

        if(!contactIdSet.isEmpty()){
            for(AccountContactRelation acr : [SELECT Id,ContactId,Last_POS_Order_Date__c,AccountId,Account.name,Account.Last_POS_Order_Date__c 
                                              FROM AccountContactRelation 
                                              WHERE ContactId IN:contactIdSet 
                                              AND D1_Roles__c INCLUDES('POS & Equipment Ordering') AND D1_Active__c = True
                                              ORDER BY ContactId,Account.Last_POS_Order_Date__c]){
                //Get the next minimun Order date from ACR compared to what exists on contact, to populate the same on con POS Order Date                                  
                if(!contactACRMap.containsKey(acr.ContactId)){
                    if(mapNewItems.get(acr.ContactId).POS_Order_Date__c < acr.Account.Last_POS_Order_Date__c){
                        contactACRMap.put(acr.ContactId,acr);
                    }
                }
            }
        }

        if(!contactACRMap.isEmpty()){
            for(Contact con : mapNewItems.values()){
                if(contactACRMap.containsKey(con.Id)){
                    con.POS_Order_Date__c = contactACRMap.get(con.Id).Account.Last_POS_Order_Date__c;
                    con.POS_Order_Account_Name__c = contactACRMap.get(con.Id).Account.Name;
                    con.POS_Order_Account_Id__c = contactACRMap.get(con.Id).AccountId;
                }
            }
        }
    }
    /**
    * @userStory : NCP-6837
    * @method : updatePOSOrderDateOnACR
    * @purpose : update ACR of previous account with new Email sent date on Contact
    */ 
    
    public static void updatePOSOrderDateOnACR(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Contact> mapNewItems = (Map<Id,Contact>) newItems;
        Map<Id,Contact> mapOldItems = new Map<Id,Contact>();
        Map<Id,Id> contactAccountMap = new Map<id,Id>();
        
        List<AccountContactRelation> toUpdateACR = new List<AccountContactRelation>();

        if(oldItems != null){
            mapOldItems = (Map<Id,Contact>) oldItems;
        }
        
        for(Contact newcon : mapNewItems.values()){
            Contact oldCon = mapOldItems.get(newcon.Id);
            if(newcon.POS_Order_Email_Sent__c != null && (newcon.POS_Order_Email_Sent__c != oldCon.POS_Order_Email_Sent__c)){
                contactAccountMap.put(oldCon.Id,oldCon.POS_Order_Account_Id__c); //getting previous Account id to fetch related ACR later
            }
        }
        
        
        if(!contactAccountMap.isEmpty()){
            for(AccountContactRelation acr : [SELECT Id,ContactId,Last_POS_Order_Date__c,AccountId,Account.name,Contact.POS_Order_Account_Id__c 
                                              FROM AccountContactRelation 
                                              WHERE ContactId IN:contactAccountMap.keySet() AND AccountId IN : contactAccountMap.values()]){
                //Update POS email send date on corresponding ACR so that cycle could be maintained.
                if(acr.AccountId == contactAccountMap.get(acr.ContactId)){
						acr.Last_POS_Order_Date__c =  mapNewItems.get(acr.ContactId).POS_Order_Email_Sent__c;
                    	toUpdateACR.add(acr);
                }
            }
        }
        
        if(!toUpdateACR.isEmpty()){
            update toUpdateACR;
        }
    }
    
    /**
    * @userStory : 143004
    * @method : validateUserBusinessRole
    * @purpose : Allow users to create/edit contact based on Business Role_SFDC
    */
    public static void validateUserBusinessRole(List<SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Contact> oldItemsMap = (Map<Id, Contact>)oldItems;
        List<User_Business_Role__c>  userBusinessRoleList = [SELECT Id,Business_Role__r.Eligible_Outlet_Role__c FROM User_Business_Role__c WHERE User__c =: UserInfo.getUserId()];
        
        if(userBusinessRoleList.Size()==1 && userBusinessRoleList.get(0).Business_Role__r.Eligible_Outlet_Role__c != null){
            String userRoles = userBusinessRoleList.get(0).Business_Role__r.Eligible_Outlet_Role__c;
            for(Contact conItem : (List<Contact>)newItems){
                String currentRole = conItem.MD_CurrentRole__c!= null ? conItem.MD_CurrentRole__c:'';
                if(oldItemsMap!=null){
                    String oldCurrentRole = oldItemsMap.get(conItem.Id).MD_CurrentRole__c!= null ?oldItemsMap.get(conItem.Id).MD_CurrentRole__c:'';
                    if(currentRole != oldCurrentRole && (!userRoles.contains(currentRole) || !userRoles.contains(oldCurrentRole))){
                        conItem.MD_CurrentRole__c.addError(System.Label.C360_UserBusinessRole_Error1+' '+userRoles.replace(';', ', ')+System.Label.C360_UserBusinessRole_Error2);
                        continue;
                    }
                }
                if(!userRoles.contains(currentRole)){
                    conItem.addError(System.Label.C360_UserBusinessRole_Error1+' '+userRoles.replace(';', ', ')+System.Label.C360_UserBusinessRole_Error2);
                }
            }
        }
        
    }
}