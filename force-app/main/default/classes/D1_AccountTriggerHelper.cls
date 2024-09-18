/**
* @Name: D1_AccountTriggerHelper
* 
* Purpose: Trigger Helper Class for Account
* 
* History                                                            
* -                                                           
* VERSION     AUTHOR            DATE              DETAIL
* 1.0			Saurav Paul       14/01/2021        NCP-1582
* 2.0			Abhishek Jethi	  15/02/2021		NCP-1584 (preventAccountDelete)
* 3.0         Praveen           21/04/2021          NCP-3024 (setDirectCustomer)
* 4.0         Gaurav            15/06/2021          NCP-3074 (deactivateContactOnCustomerDelete)
* 5.0         Gaurav            26/07/2021          NCP-3897 (updateContactPointAddresses)
* 6.0         Gaurav            30/08/2021          NCP-3076 (removeOrdersForDeletedFromSAP)
* 7.0		  Shivam			21/07/2022			NCP-6798 (updateSapAddressOnCpa)
**/
public without sharing class D1_AccountTriggerHelper {
    final static String OUTLET_RECORD_TYPE_ID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    final static String DIRECT_CUST_REC_TYPE_ID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
    
    public final static String ACCOUNT_CENTRAL_ORDER_BLOCK_BLOCKED = 'Blocked';
    public final static String CONTACT_POINT_ADDRESS_STATUS_ACTIVE = 'Active';
    public final static String CONTACT_POINT_ADDRESS_STATUS_BLOCKED = 'Blocked';
    public final static String CONTACT_POINT_ADDRESS_STATUS_CLOSED = 'Closed';
    
    /**
* @description Method to populate Conversion Date while  and changing recordtype from "Direct Customer" to "Outlet" by MDM
* @param newItems 
* @param oldItems 
*/    
    public static void populateConvDate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Id profileId = UserInfo.getProfileId();
        String profileName = [SELECT Id,Name FROM Profile where Id=:profileId].Name;
        if(profileName.equalsIgnoreCase(Label.D1_MDM_Profile) || Test.IsRunningTest()){
            for(Id accIdVal : newItems.keySet()){
                Account accNewObj = (Account)newItems.get(accIdVal);
                if(oldItems!= null && oldItems.containsKey(accIdVal)){
                    Account accOldObj = (Account)oldItems.get(accIdVal); 
                    if(accNewObj.recordTypeId == OUTLET_RECORD_TYPE_ID && accOldObj.recordTypeId == DIRECT_CUST_REC_TYPE_ID){
                        accNewObj.Conversion_Date__c = Date.today();  
                    }
                }
            }
        }
    }
    /**
* @description 
* @param oldItems 
*/    
    public static void preventAccountDelete(Map<Id,SObject> oldItems){
        
        list<Account> accountlist = [SELECT Id, RecordTypeId, recordtype.developername from account where Id in :oldItems.keyset()];
        boolean isD1mdms = featuremanagement.checkpermission('D1_Account_Delete_Permission');
        
        for(Account acc : accountlist){
            if (isD1mdms && acc.recordtype.developername != 'PNR_Direct_Customer'){
                Trigger.oldMap.get(acc.id).addError('Not Authorised to delete');
                
            }
        }
    }
    
    /**
* @description Method to Update Direct Customer Flag based on Customer Account Group. This triggers from Before Update
* @param newItems 
* @param oldItems 
*/    
    public static void setDirectCustomer(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id,PNR_Partner_Function__c> mapIdPFObj = new Map<Id, PNR_Partner_Function__c>();
        
        for(PNR_Partner_Function__c pf : [SELECT Id, PNR_Sold_To__c, PNR_Type__c FROM PNR_Partner_Function__c WHERE PNR_Type__c='Ship-To' AND PNR_Sold_To__c =:newItems.keyset()]){
            mapIdPFObj.put(pf.PNR_Sold_To__c, pf);
        }
        
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);                
            String cagStrNew = accNewObj.Customer_Account_Group__c;
            Account accOldObj = (Account)oldItems.get(accIdVal);                
            String cagStrOld = accOldObj.Customer_Account_Group__c;
            //check if Customer_Account_Group__c changes
            if(cagStrNew!=cagStrOld){
                if(string.IsBlank(cagStrNew) || cagStrNew.contains('YIND') || (cagStrNew.contains('Y008') && mapIdPFObj.get(accNewObj.Id) == null)){
                    accNewObj.Direct_Customer__c = False;
                }else{
                    accNewObj.Direct_Customer__c = True;
                }   
            }
        }
    }
    /**
* @description 
* @param newItems 
*/    
    public static void setDirectCustomer(List<SObject> newItems){
        for(sObject accNewObj : newItems){
            Account ac = (Account)accNewObj;
            String cagStr = ac.Customer_Account_Group__c;
            if(string.IsBlank(cagStr) || cagStr.contains('YIND') || cagStr.contains('Y008')){
                ac.Direct_Customer__c = False;
            }
            else{
                ac.Direct_Customer__c = True;
            }
        }
    }
    /**
	* @userstory NCP-3074
	* @description Method to Deactivate Contact/User when Customer is marked deleted. This is triggers from After Update.
	* @param newItems 
	* @param oldItems 
	*/    
    public static void deactivateContactOnCustomerDelete(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //Filter Accounts for which deletion flag is checked.
        Set<Id> deactivatedCustomerIds = new Set<Id>();
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);
            Account accOldObj = (Account)oldItems.get(accIdVal);
            if( accNewObj.Deletion_Flag_from_SAP__c && !accOldObj.Deletion_Flag_from_SAP__c ){
                deactivatedCustomerIds.add(accIdVal);
            }
        }
        
        if( !deactivatedCustomerIds.isEmpty() ){
            //Get ACR for Accounts where deletion flag is checked, and collect ContactIds from ACRs
            Set<Id> contactIdsForDeactiveAccs = new Set<Id>();
            for( AccountContactRelation acr : [Select id, ContactId, AccountId from AccountContactRelation 
                                               where AccountId IN :deactivatedCustomerIds] ){
                                                   contactIdsForDeactiveAccs.add( acr.ContactId );
                                               }
            
            //Get ACR for ContactIds collected from deactivated Accounts.
            Map<Id,List<AccountContactRelation>> contactIdACRListMap = new Map<Id,List<AccountContactRelation>>();
            Set<Id> accountIdsAllACRForDeactiveContacts = new Set<Id>();
            for( AccountContactRelation acr : [Select id, ContactId, AccountId, IsDirect from AccountContactRelation 
                                               where D1_Active__c = True 
                                               and ContactId IN :contactIdsForDeactiveAccs order by CreatedDate,Account.Name] ){
                                                   accountIdsAllACRForDeactiveContacts.add(acr.AccountId);
                                                   
                                                   if( contactIdACRListMap.containsKey(acr.ContactId) ){
                                                       contactIdACRListMap.get(acr.ContactId).add(acr);
                                                   }else{
                                                       contactIdACRListMap.put(acr.ContactId, new List<AccountContactRelation>{acr});
                                                   }
                                               }
            
            //Get PF counts for All AccountIds for All Contacts below deactivated Accounts.
            Map<Id,Integer> soldToIdPFCount = new Map<Id,Integer>();
            for(AggregateResult ar : [SELECT Count(Id), PNR_Customer_No__c FROM PNR_Partner_Function__c 
                                      WHERE PNR_Customer_No__c IN :accountIdsAllACRForDeactiveContacts 
                                      and PNR_Type__c IN ('Sold-To','Ship-To') 
                                      and PNR_Customer_No__r.Deletion_Flag_from_SAP__c = False GROUP By PNR_Customer_No__c]){
                                          soldToIdPFCount.put(String.valueOf(ar.get('PNR_Customer_No__c')), Integer.valueOf(ar.get('expr0')));
                                      }
            
            //Create ContactId -> User Map for All Contacts for Deactivated Accounts.
            Map<Id,User> contactIdUserMap = new Map<Id,User>();
            for(User usr : [SELECT Id, IsActive, AccountId, Effective_Account_Id__c, ContactId FROM User 
                            WHERE ContactId IN:contactIdACRListMap.keySet()]){
                                contactIdUserMap.put( usr.ContactId, usr);
                            }
            
            //Create List of ACR to deactivate
            //Create List of Contact to update Primary Account
            //set of contact id for which related user will be deactivated
            //set of contact id for which affective account id on related user will be updated
            List<AccountContactRelation> deactivateACRs = new List<AccountContactRelation>();
            List<Contact> updateContactPrimaryAcc = new List<Contact>();
            Set<Id> userContactIdToDeactivate = new Set<Id>();
            Set<Id> userContactIdToUpdateEffectiveAcc = new Set<Id>();
            for( Id contactId : contactIdACRListMap.keySet() ){
                User usr = contactIdUserMap.get(contactId);
                List<AccountContactRelation> contactACRList = contactIdACRListMap.get(contactId);
                
                AccountContactRelation activeDirectACR;
                Boolean updateUserEffectiveAcc = false;
                for( AccountContactRelation contactACR : contactACRList ){
                    Boolean remainActive = false;
                    if( soldToIdPFCount.containsKey(contactACR.AccountId) && soldToIdPFCount.get(contactACR.AccountId) > 0 ){
                        remainActive = true;
                    }
                    if( !remainActive ){
                        deactivateACRs.add( deactivateAccountContactRelation(contactACR) );
                        
                        //If effectve Account Id ACR is deactivated.
                        if( usr != NULL && usr.Effective_Account_Id__c ==  contactACR.AccountId ){
                            updateUserEffectiveAcc = true;
                        }
                    }else if( remainActive && (activeDirectACR == NULL || contactACR.IsDirect) ){ //Check if older direct is still active 
                        activeDirectACR = contactACR;
                    }
                }
                
                if( activeDirectACR != NULL ){
                    if( !activeDirectACR.IsDirect ){
                        updateContactPrimaryAcc.add( updateContactPrimaryAccount(activeDirectACR) );
                    }
                    
                    if( updateUserEffectiveAcc ){
                        userContactIdToUpdateEffectiveAcc.add(contactId);
                    }
                }else{
                    userContactIdToDeactivate.add(contactId);
                }
            }
            
            if( !deactivateACRs.isEmpty() ){
                update deactivateACRs;
            }
            
            if( !updateContactPrimaryAcc.isEmpty() ){
                update updateContactPrimaryAcc;
            }
            
            //Enqueue Queueable apex to deactivate user. 
            //Queueable apex is used since User trigger internally makes future calls, and futue call cannot happen from future call.
            if( !userContactIdToUpdateEffectiveAcc.isEmpty() || !userContactIdToDeactivate.isEmpty() ){
                System.enqueueJob(new DeactivateUserAsyncExecution(userContactIdToUpdateEffectiveAcc, userContactIdToDeactivate));
            }
        }
    }
    /**
* @description 
* @param acr 
* @return  `AccountContactRelation`
*/    
    public static AccountContactRelation deactivateAccountContactRelation(AccountContactRelation acr){
        acr.D1_Active__c = false;
        acr.D1_Roles__c = '';
        acr.D1_User_Role__c = '';
        return acr;
    }
    /**
* @description 
* @param acr 
* @return  `Contact`
*/    
    public static Contact updateContactPrimaryAccount(AccountContactRelation acr){
        Contact con = new Contact(Id=acr.ContactId);
        con.AccountId = acr.AccountId;
        return con;
    }
    
    /**
* @description Method to Deactivate User or Update Effective Account Id on user when Customer is marked deleted. 
* @param contactIdUpdateEffectiveAcc 
* @param contactIdSetDeactivate 
*/    
    public static void deactivateCommunityUsers( Set<Id> contactIdUpdateEffectiveAcc, Set<Id> contactIdSetDeactivate ) {
        Set<Id> allContactIds = new Set<Id>();                                       
        Set<Id> deActivatedUserId = new Set<Id>();                                          // NCP - 4205 
        Set<Id> deActivatedContactId = new Set<Id>();                                       // NCP - 4205 
        allContactIds.addAll(contactIdUpdateEffectiveAcc);
        allContactIds.addAll(contactIdSetDeactivate);
        
        List<AccountContactRelation> acrList = [Select id, ContactId, AccountId, IsDirect from AccountContactRelation 
                                                where D1_Active__c = True and ContactId IN :contactIdUpdateEffectiveAcc 
                                                order by CreatedDate,Account.Name];
        Map<Id,Id> contactIdAccountId = new Map<Id,Id>();
        for( AccountContactRelation acr : acrList ){
            if( !contactIdAccountId.containsKey(acr.ContactId) ){
                contactIdAccountId.put(acr.ContactId, acr.AccountId);
            }
        }
        
        if(!allContactIds.isEmpty()){
            List<User> userList = [SELECT Id, IsActive, AccountId, Effective_Account_Id__c, ContactId FROM User 
                                   WHERE ContactId IN:allContactIds];
            for(User usr : userList ){
                if( contactIdUpdateEffectiveAcc.contains(usr.ContactId) ){
                    usr.Effective_Account_Id__c = contactIdAccountId.get(usr.ContactId);
                }else{
                    usr.IsActive = false;
                    usr.Effective_Account_Id__c = '';
                    deActivatedUserId.add(usr.Id);                                              // NCP - 4205 
                    deActivatedContactId.add(usr.ContactId);                                    // NCP - 4205 
                }
            }
            update userList;
            anonymizeContacts(deActivatedUserId,deActivatedContactId);
        }
    }
    
    /* @userstory NCP-3074
* DeactivateUserAsyncExecution : Queueable apex to create Async transaction to update update user.
*/
    public class DeactivateUserAsyncExecution implements Queueable {
        public Set<Id> contactIdUpdateEffectiveAcc;
        public Set<Id> contactIdSetDeactivate;
        public DeactivateUserAsyncExecution(Set<Id> contactIdUpdateEffectiveAcc, Set<Id> contactIdSetDeactivate){
            this.contactIdUpdateEffectiveAcc = contactIdUpdateEffectiveAcc;
            this.contactIdSetDeactivate = contactIdSetDeactivate;
        }
        public void execute(QueueableContext context) {
            D1_AccountTriggerHelper.deactivateCommunityUsers( contactIdUpdateEffectiveAcc, contactIdSetDeactivate );
        }
    }
    /**
	* @description Method to update CPAs for Accounts where deletion flag is changed or Central Order Block is changed
	* @param newItems 
	* @param oldItems 
	*/    
    public static void updateContactPointAddresses( Map<Id, SObject> newItems, Map<Id, SObject> oldItems ) {
        //Get Customer SAP Codes where deletion flag is changed or Central Order Block is changed
        Map<String,Account> customerNumberAccMap = new Map<String,Account>();
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);
            Account accOldObj = (Account)oldItems.get(accIdVal);
            if( accNewObj.Deletion_Flag_from_SAP__c != accOldObj.Deletion_Flag_from_SAP__c || accNewObj.Central_Order_Block__c != accOldObj.Central_Order_Block__c ){
                customerNumberAccMap.put(accNewObj.KUNNR__c, accNewObj);
            }
        }
        
        if( !customerNumberAccMap.isEmpty() ){
            //Get CPA for Accounts where deletion flag is changed or Central Order Block is changed
            List<ContactPointAddress> cpasToUpdate = [Select id, Account_Number__c, Status__c from ContactPointAddress where Account_Number__c IN :customerNumberAccMap.keySet()];
            for( ContactPointAddress cpa : cpasToUpdate ){
                Account accNewObj = customerNumberAccMap.get(cpa.Account_Number__c);
                if( accNewObj.Deletion_Flag_from_SAP__c ){
                    cpa.Status__c = CONTACT_POINT_ADDRESS_STATUS_CLOSED;
                }else if( accNewObj.Central_Order_Block__c == CONTACT_POINT_ADDRESS_STATUS_BLOCKED ){
                    cpa.Status__c = CONTACT_POINT_ADDRESS_STATUS_BLOCKED;
                }else{
                    cpa.Status__c = CONTACT_POINT_ADDRESS_STATUS_ACTIVE;
                }
            }
            
            update cpasToUpdate;
        }
    }
    
    public static void updateSapAddressOnCpa( Map<Id, SObject> newItems, Map<Id, SObject> oldItems ) {
        Map<String,Account> customerNumberAccMap = new Map<String,Account>();
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);
            Account accOldObj = (Account)oldItems.get(accIdVal);
            if(accNewObj.KUNNR__c != null && (accNewObj.BillingCity != accOldObj.BillingCity || accNewObj.BillingCountry != accOldObj.BillingCountry || accNewObj.BillingCountryCode != accOldObj.BillingCountryCode || 
            accNewObj.BillingGeocodeAccuracy != accOldObj.BillingGeocodeAccuracy || accNewObj.BillingLatitude != accOldObj.BillingLatitude || accNewObj.BillingLongitude != accOldObj.BillingLongitude || 
            accNewObj.BillingPostalCode != accOldObj.BillingPostalCode || accNewObj.BillingState != accOldObj.BillingState || accNewObj.BillingStateCode != accOldObj.BillingStateCode || 
            accNewObj.BillingStreet != accOldObj.BillingStreet)){
                customerNumberAccMap.put(accNewObj.KUNNR__c, accNewObj);
            }
        }
        
        if(!customerNumberAccMap.isEmpty() ){
            List<ContactPointAddress> cpasToUpdate = [Select id, Account_Number__c, Status__c,city,Country,CountryCode,GeocodeAccuracy,Latitude,Longitude,PostalCode,State,StateCode,Street
                                                      from ContactPointAddress 
                                                      where Account_Number__c IN :customerNumberAccMap.keySet()];
            for(ContactPointAddress cpa : cpasToUpdate){
                Account accNewObj = customerNumberAccMap.get(cpa.Account_Number__c);
                cpa.city = accNewObj.BillingCity;
                cpa.Country = accNewObj.BillingCountry;
                cpa.CountryCode = accNewObj.BillingCountryCode;
                cpa.GeocodeAccuracy = accNewObj.BillingGeocodeAccuracy;
                cpa.Latitude = accNewObj.BillingLatitude;
                cpa.Longitude = accNewObj.BillingLongitude;
                cpa.PostalCode = accNewObj.BillingPostalCode;
                cpa.State = accNewObj.BillingState;
                cpa.StateCode = accNewObj.BillingStateCode;
                cpa.Street = accNewObj.BillingStreet;
            }
            if(cpasToUpdate != null && cpasToUpdate.size()>0) {
                update cpasToUpdate;
            }
        }
    }
    
    /**
	* @description Method to anonymize user and contact records
	* @param userIds  
    * @param userIds 
    * NCP - 4205 
	*/    
    public static void anonymizeContacts(Set<Id> userIds, set<Id> contactIds){
        
        for(Id uId : userIds){
            if(!Test.isRunningTest()){
             System.UserManagement.obfuscateUser(uId);    
            }           
        }
        /*
        for(contact con : Contacts){
            con.FirstName = '*****';
            con.LastName = '*****';
            con.Email = ''; 
            con.Phone__c = '*****';
            con.Mobile__c = '*****';
            con.MailingStreet = '*****';
            con.MailingCity = '*****';
            con.MailingState = '';
            con.MailingPostalCode = '*****';
            con.MailingCountry = '';
            con.OtherStreet = '*****';
            con.OtherCity = '*****';
            con.OtherState = '';
            con.OtherPostalCode = '*****';
            con.OtherCountry = '';
            contactList.add(con);
        }
        update contactList;*/
    }
    
    
    /**
	* @description Method to update SAP Deletion Date.
	* @param newItems 
	* @param oldItems
    * NCP - 4205 
	*/
    public static void updateSAPDeletionDate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);
            Account accOldObj = (Account)oldItems.get(accIdVal);
            if( accNewObj.Deletion_Flag_from_SAP__c != accOldObj.Deletion_Flag_from_SAP__c){
                if(accNewObj.Deletion_Flag_from_SAP__c == true){
                    accNewObj.SAP_Deletion_Date__c = Date.today();
                }else{
                    accNewObj.SAP_Deletion_Date__c = null;
                }
            }
        }   
    }

    /**
	* @description Method to Deleted related Order, Order Summary, Sales Orders if Account is Deactivated
	* @param newItems 
	* @param oldItems 
	*/    
    public static void removeOrdersForDeletedFromSAP( Map<Id, SObject> newItems, Map<Id, SObject> oldItems ) {
        //Get Account deletion flag is changed
        List<Account> accList = new List<Account>();
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);
            Account accOldObj = (Account)oldItems.get(accIdVal);
            if( accNewObj.Deletion_Flag_from_SAP__c && !accOldObj.Deletion_Flag_from_SAP__c ){
                accList.add(accNewObj);
            }
        }
        
        if( !accList.isEmpty() ){
            //deactivate orders
            List<Order> ordersToDelete = [Select id,OrderNumber from Order where AccountId IN :accList];
            for(Order orderRec : ordersToDelete ){
                orderRec.Status = 'Draft';
            }
            update ordersToDelete;

            //Delete OrderSummary (Deletes OrderSummaryItems and Sales Orders also)
            delete [Select id,OriginalOrder.OrderNumber from OrderSummary where AccountId IN :accList];
            //Delete Order (Deletes OrderItems also)
            delete ordersToDelete;
        }
    }

    /**
	* @description Method to Deleted related Order, Order Summary, Sales Orders if Account is Deactivated
	* @param newItems 
	* @param oldItems 
	*/    
    public static void anonymizeContactsForDeletedAccounts( Map<Id, SObject> newItems, Map<Id, SObject> oldItems ) {
        //Get Account deletion flag is changed
        List<Account> accList = new List<Account>();
        for(Id accIdVal : newItems.keySet()){
            Account accNewObj = (Account)newItems.get(accIdVal);
            Account accOldObj = (Account)oldItems.get(accIdVal);
            if( accNewObj.Deletion_Flag_from_SAP__c && !accOldObj.Deletion_Flag_from_SAP__c ){
                accList.add(accNewObj);
            }
        }
        
        if( !accList.isEmpty() ){
            List<Contact> contacts = [Select Id,FirstName,LastName,Email,MailingStreet,MailingCity, MailingState,MailingPostalCode,MailingCountry,

                                        OtherStreet,OtherCity,OtherState,OtherPostalCode,OtherCountry,Mobile__c,MobilePhone,Phone,Phone__c,Contact_Type__c

                                        From Contact where AccountId IN :accList];
            for(contact con : contacts){
                con.FirstName = '*****';
                con.LastName = '*****';

                con.Email = '*****@invalid.com'; 
                con.Phone__c = '';
                con.Mobile__c = '';
                con.MobilePhone ='';
                con.Phone = '';

                con.MailingStreet = '*****';
                con.MailingCity = '*****';
                con.MailingState = '';
                con.MailingPostalCode = '*****';
                con.MailingCountry = '';
                con.OtherStreet = '*****';
                con.OtherCity = '*****';
                con.OtherState = '';
                con.OtherPostalCode = '*****';
                con.OtherCountry = '';
                con.Contact_Type__c = 'Secondary';//Added NCP-6114
            }
            update contacts;
        }
    }
}