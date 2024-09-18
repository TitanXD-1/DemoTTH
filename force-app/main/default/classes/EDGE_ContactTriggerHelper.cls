/**
* @Description: EDGE_ContactTriggerHelper

* @Purpose: The requirement is to help maintain  one primary contacts per Outlet - User Story : ES20-461

* @History                                                            
                                                            
* @VERSION   AUTHOR               DATE              DETAIL
*   1.0     Sandeep Sahoo       15/03/2019      Initial Development
*	2.0     Sagar Barman        18/03/2019      Added getOutletPrimaryContact 
*	3.0     Preyanka Ghosh      03/09/2019      Phone Number Validation 
*	4.0     Sai Kumar/Rupesh    15/01/2021      NCP-1789 - method ->populatePardotBUCode      
*	5.0     Sai Kumar           03/11/2021      NCP-5130 - method ->updateEmailPreference 
*	6.0     Ajay                07/12/2021      NCP-5558 - method - populatePardotBUCode, refactor and add synCode logic    
*	7.0     Rajarshi Lahiri		26/04/2022      ES20-12548 and ES20-12393 (commented out methods pertaining to Primary/Secondary Contacts validations)

*	8.0		Aparajita    		27/04/2022      ES20-12476(Method:updateOwnerChangedFlag)

*/

public with sharing class EDGE_ContactTriggerHelper {
    
    /**   
    Purpose: The below method checks if the associated Outlet has Primary 
             Contact while inserting Contact. 

    */ 

    /*Commented out for ES20-12548 and ES20-12393
    public static void checkprimarycontact(List<SObject> newItems){
        List<Id> accIdlistwithPrimaryCon = new List<Id>();
        Set<Id> accIdset = new Set<Id>();
        Map<Id, Boolean> outletPrimaryContactmap = new Map<Id,Boolean>(); 
        Map<Id, Boolean> outletContactmap = new Map<Id,Boolean>();
        List<Account> accountList = new List<Account>();
        Map<Id, Boolean> outletMarkPrimaryContactmap = new Map<Id,Boolean>();
        for(SObject obj :newItems){
            Contact newcon = (Contact)obj;
            outletMarkPrimaryContactmap.put(newcon.AccountId,false);
            if(newcon.AccountId!=null && newcon.Contact_Type__c=='Primary'){ 
                accIdlistwithPrimaryCon.add(newcon.AccountId); // list carrying accounts of all freshly inserted accounts with Contact type primary
            }
            if(newcon.AccountId!=null){
                accIdset.add(newcon.AccountId);    
            }
        }        
        //check if the contact is the first contact of the Account
        if(Schema.sObjectType.Contact.isAccessible() && Schema.sObjectType.Account.isAccessible() && accIdset.size() > 0) {
            accountList = [SELECT Id, (SELECT Id, Contact_Type__c FROM AccountContactRelations WHERE IsActive = true) 
                           FROM Account WHERE Id In :accIdset];  //WHERE IsActive=true ES20-8178
        }    
        for(Account ac : accountList){
            outletContactmap.put(ac.Id, ac.AccountContactRelations.size()>0 ? true : false);           
        }
        outletPrimaryContactmap =  getOutletPrimaryContact(accIdlistwithPrimaryCon);  
        for(SObject obj :newItems){
            Contact newcon = (Contact)obj;
            if(outletContactmap.get(newcon.AccountId) != null && outletContactmap.get(newcon.AccountId) == false){
                if(!outletMarkPrimaryContactmap.isEmpty() && outletMarkPrimaryContactmap.get(newcon.AccountId)){
           			newcon.Contact_Type__c = 'Secondary';// for the same Account if multiple contacts are inserted make the first one primary, others secondary     
                }else if(!outletMarkPrimaryContactmap.isEmpty() && outletMarkPrimaryContactmap.get(newcon.AccountId) == false){
                	newcon.Contact_Type__c = 'Primary';// make the contact by default primary
                    outletMarkPrimaryContactmap.put(newcon.AccountId,true);
                }
            }
            if(!outletPrimaryContactmap.isEmpty() && outletPrimaryContactmap.get(newcon.AccountId)){
                newcon.addError(Label.One_Primary_Contact);// throw error if acc has pre-existing primary contacts
            }
        }
    }
	*/

    /**
    Purpose: The below method checks if the associated Outlet has Primary 
             Contact while updating Contact. 
	*/

    /*Commented out for ES20-12548 and ES20-12393
    public static void checkprimarycontactupdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){        
        List<Id> accIdlist = new List<Id>();
        Map<Id, Boolean> outletPrimaryContactmap = new Map<Id,Boolean>(); 
        if(oldItems != null){
            for(SObject uc : newItems.values()){
                Contact newcon = (Contact)uc;
                Contact oldcon = (Contact)oldItems.get(newcon.id);
                if(newcon.Contact_Type__c != oldcon.Contact_Type__c && newcon.Contact_Type__c=='Primary'){
                    accIdlist.add(newcon.AccountId);
                }
            }
        } 
        if(accIdlist.size()>0){
            outletPrimaryContactmap =  getOutletPrimaryContact(accIdlist);
            for(SObject obj :newItems.values()){
                Contact newcon = (Contact)obj;
                if(outletPrimaryContactmap.get(newcon.AccountId)){
                    newcon.addError(Label.One_Primary_Contact); // throw error if acc has pre-existing primary contacts
                }
            }    
        }
    }
*/

    /**
    Purpose: The below method provides the MAP of oulet and boolean values
             depending on if the Outlet has promary contact or not.
    */

/*    Commented out for ES20-12548 and ES20-12393
    public static Map<Id, Boolean> getOutletPrimaryContact(List<Id> accIdlist){
        Map<Id, Boolean> outletPrimaryContactmap = new map<Id,Boolean>();
        List<Account> acclist = new List<Account>();
        if(Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Contact.isAccessible() && Schema.sObjectType.AccountContactRelation.isAccessible() 
           && accIdlist.size() > 0) {
            // All Accounts and corressponding contacts pre-existing in the system where ID is acclist
            //AND IsActive=true ES20-8178
            acclist = [SELECT Id, (SELECT Id, Contact_Type__c FROM AccountContactRelations WHERE Contact_Type__c = 'Primary' 
                       AND IsActive = true) FROM Account WHERE Id IN :accIdlist];
        }        
        for(Account ac : acclist){
            outletPrimaryContactmap.put(ac.Id, ac.AccountContactRelations.size()>0 ? true : false); //checking if the acc has pre-existing primary contacts
        }
        return outletPrimaryContactmap;        
    }*/

    /**
    Purpose: The below method updates the contact type of AccountContact.
    */ 

    /*Commented out for ES20-12548 and ES20-12393
    public static void updateAccountContact(Map<Id, SObject> newItems){
        List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();// ACR List with Accounts which has only One Contact
        List<AccountContactRelation> accConRelAllList = new List<AccountContactRelation>();
        List<Account> accList = new List<Account>();
        Map<Id, Boolean> outletPrimaryContactmap = new map<Id,Boolean>();
        LIst<Id> accIdSet = new List<Id>();
        Set<Id> accSetToUpdate = new Set<Id>();
        Set<Id> conIdSetToUpdate = new Set<Id>();
        Set<Id> conIdSet = new Set<Id>();
        for(SObject obj :newItems.values()){
            Contact newcon = (Contact)obj;
            if(newcon.AccountId!=null && newcon.Contact_Type__c!=null){ 
                accIdSet.add(newcon.AccountId);
                conIdSet.add(newcon.Id);                
            }
        }        
        if(Schema.sObjectType.Account.isAccessible() && Schema.sObjectType.Contact.isAccessible() && accIdSet.Size() > 0) {
            acclist = [SELECT Id, (SELECT Id, Contact_Type__c FROM AccountContactRelations WHERE IsActive = true) 
                       FROM Account WHERE Id In :accIdSet];//WHERE IsActive = true ES20-8178
        }        
        for(Account ac : acclist){
            outletPrimaryContactmap.put(ac.Id, ac.AccountContactRelations.size()==1 ? true : false); //checking if the acc has only one contact,for first contact type will primary by deafault
        } 
        for(SObject obj :newItems.values()){
            Contact newcon = (Contact)obj;
            if(!outletPrimaryContactmap.isEmpty() && outletPrimaryContactmap.get(newcon.AccountId)){
                accSetToUpdate.add(newcon.AccountId);   
                conIdSetToUpdate.add(newcon.Id);
            }            
        }
        if(Schema.sObjectType.AccountContactRelation.isAccessible() && accSetToUpdate.size()>0 && conIdSetToUpdate.size()>0){
            accConRelList = [SELECT ID,Contact_Type__c FROM AccountContactRelation 
                             WHERE AccountID IN : accSetToUpdate AND ContactID IN : conIdSetToUpdate];    
        }
        //for Accounts which has only one Contact, ACR contact type will be primary
        for(AccountContactRelation acr : accConRelList){
            acr.Contact_Type__c = 'Primary'  ; 
            acr.IsActive = true;
        }
        if(Schema.sObjectType.AccountContactRelation.isAccessible() && accIdSet.size()>0 && conIdSet.size()>0){
            //for Accounts which has more than Contact, ACR contact type will be same as Contact type 
            //AND IsActive=true ES20-8178
            accConRelAllList = [SELECT ID,Contact_Type__c,Contact.Contact_Type__c FROM AccountContactRelation 
                                WHERE AccountID IN : accIdSet AND ContactID IN : conIdSet 
                                AND AccountID NOT IN : accSetToUpdate AND ContactID NOT IN : conIdSetToUpdate 
                                AND IsActive=true];    
        }
        for(AccountContactRelation acr : accConRelAllList){
            acr.Contact_Type__c = acr.Contact.Contact_Type__c  ; 
            acr.IsActive = true;
        }
        if(accConRelList.size()>0 && accConRelAllList.size()>0 && Schema.sObjectType.AccountContactRelation.isAccessible() && Schema.sObjectType.AccountContactRelation.isUpdateable()){
            accConRelList.addAll(accConRelAllList); 
            update accConRelList;
        }
        if(accConRelList.size() >0 && accConRelAllList.size() == 0 && Schema.sObjectType.AccountContactRelation.isAccessible() && Schema.sObjectType.AccountContactRelation.isUpdateable()){
            update accConRelList;    
        }
        if(accConRelList.size() == 0 && accConRelAllList.size() > 0 && Schema.sObjectType.AccountContactRelation.isAccessible() && Schema.sObjectType.AccountContactRelation.isUpdateable()){
            update accConRelAllList;    
        }
    }  
*/
    
    /**
    Method  : validatePhoneNumber
    Purpose : Validate Phone number depending upon regex set on metadata
    */
    public static void validatePhoneNumber(List<sObject> newItems, Map<Id,SObject> oldItems){
        Map<Id,Contact> mapOldItems;
        List<SObject> lstNewData = new List<SObject>();
        Set<String> setPhonePrefix = new Set<String>();
        List<String> lstFieldName = new List<String>{'MobilePrefix__c','Mobile__c','PhonePrefix__c','Phone__c'};
        List<String> lstFieldToUpdate = new List<String>{'MobilePhone','Phone'};
        
        if(oldItems != null){
            mapOldItems = (Map<Id,Contact>) oldItems;
        }
        
        if(newItems != null && newItems.size()>0){ 
            for(sObject newObject : newItems){
                Contact newContact = (Contact)newObject;
                //Chnages Start -- 150663
                Boolean isBlankMobile = newContact.MobilePrefix__c != null && newContact.Mobile__c== null;
                Boolean isBlankPhone = newContact.PhonePrefix__c != null && newContact.Phone__c== null;
                Boolean isNotBlankMobile = newContact.MobilePrefix__c != null && newContact.Mobile__c!= null;
                Boolean isNotBlankPhone = newContact.PhonePrefix__c != null && newContact.Phone__c!= null;
                Boolean isNotBlankMobileWithNoPhoneValidation = isNotBlankMobile && (!isBlankPhone || newContact.PhonePrefix__c == null);
                Boolean isNotBlankPhoneWithNoPhoneValidation = isNotBlankPhone && (!isBlankMobile || newContact.MobilePrefix__c == null);

                if(isNotBlankMobileWithNoPhoneValidation || isNotBlankPhoneWithNoPhoneValidation){
                    if(isNotBlankMobile && !Pattern.matches('^[0-9]+$', newContact.Mobile__c)){
                        newContact.Mobile__c.addError(label.C360_Mobile_field_should_have_number);
                    }
                    if(isNotBlankPhone && !Pattern.matches('^[0-9]+$', newContact.Phone__c)){
                        newContact.Phone__c.addError(label.C360_Phone_field_should_have_number);
                    }
                    if(oldItems == null || (oldItems != null && mapOldItems.containsKey(newContact.Id) && 
                     (newContact.MobilePrefix__c != mapOldItems.get(newContact.Id).MobilePrefix__c || newContact.Mobile__c != mapOldItems.get(newContact.Id).Mobile__c || 
                      newContact.PhonePrefix__c != mapOldItems.get(newContact.Id).PhonePrefix__c || newContact.Phone__c != mapOldItems.get(newContact.Id).Phone__c)
                    )){
                    
                      lstNewData.add(newObject);
                      if(String.isNotBlank(newContact.MobilePrefix__c)){
                          setPhonePrefix.add(newContact.MobilePrefix__c);
                      }
                      
                      if(String.isNotBlank(newContact.PhonePrefix__c)){
                          setPhonePrefix.add(newContact.PhonePrefix__c);
                      }
                  }
                }
                //Chnages End -- 150663
                
                // if(((newContact.MobilePrefix__c != null && newContact.Mobile__c != null) || (newContact.PhonePrefix__c != null && newContact.Phone__c != null)) && 
                //    (oldItems == null || 
                //     (oldItems != null && mapOldItems.containsKey(newContact.Id) && 
                //      (newContact.MobilePrefix__c != mapOldItems.get(newContact.Id).MobilePrefix__c || newContact.Mobile__c != mapOldItems.get(newContact.Id).Mobile__c || 
                //       newContact.PhonePrefix__c != mapOldItems.get(newContact.Id).PhonePrefix__c || newContact.Phone__c != mapOldItems.get(newContact.Id).Phone__c)
                //     ))
                //   ){
                    
                //       lstNewData.add(newObject);
                //       if(String.isNotBlank(newContact.MobilePrefix__c)){
                //           setPhonePrefix.add(newContact.MobilePrefix__c);
                //       }
                      
                //       if(String.isNotBlank(newContact.PhonePrefix__c)){
                //           setPhonePrefix.add(newContact.PhonePrefix__c);
                //       }
                //   }
            }
            System.debug('lstNewData:::'+lstNewData);
            
            if(lstNewData != null && lstNewData.size()>0){
                EDGE_PhoneFormatting.validatePhoneNumber(lstNewData, setPhonePrefix, lstFieldName, lstFieldToUpdate);
                System.debug('lstNewData::::'+lstNewData);
            }
            
        }
    }

    /**
     * @description populatePardotBUCode populate pardot related sync codes
     * @param  newItems newItems list new items
     * @param  oldItems oldItems map old items
     */
    public static void populatePardotBUCode(List<sObject> newItems, Map<Id,SObject> oldItems){
        
        Map<Id,Contact> mapOldIdToContact = (Map<Id,Contact>) oldItems;
        LIst<Contact> listNewContact = (List<Contact>) newItems;
        Boolean isOldMap =  mapOldIdToContact != null;
        
        //Calculate records need update
        Set<Id> setRelatedAccountId = new Set<Id>();
        List<Contact> listContactToUpdate = new List<Contact>();
        for(Contact newContact: listNewContact){

            if( !isOldMap
                ||(isOldMap && mapOldIdToContact.get(newContact.Id).AccountId != newContact.AccountId)
            ){
                setRelatedAccountId.add(newContact.AccountId);
                listContactToUpdate.add(newContact);
            }
        }
        setRelatedAccountId.remove(null);

        //Fetch related Account records
        Map<Id, Account> mapIdToAccount = new Map<Id, Account>(); 
        Set<Id> setCountry = new Set<Id>();
        if(!setRelatedAccountId.isEmpty()){
            
            for(Account account: [
                SELECT Id, Hub__r.Code__c, Country__c
                FROM Account
                WHERE ID IN:setRelatedAccountId                
            ]){
                mapIdToAccount.put(account.Id, account);
                setCountry.add(account.Country__c);
            }
        }
        setCountry.remove(null);

        //Fetch related D1 Settings records required
        Map<Id, String> mapCountryIdToPardotSyncCode = new Map<Id, String>();
        if(!setCountry.isEmpty()){

            for(D1_Setting__c d1Setting: [
                SELECT Id, Pardot_Sync_code__c, Market__c
                FROM D1_Setting__c
                WHERE Market__c IN:setCountry
            ]){
                mapCountryIdToPardotSyncCode.put( d1Setting.Market__c, d1Setting.Pardot_Sync_code__c);
            }
        }
        
        //Update contacts
        for(Contact contact: listContactToUpdate){
            Account relatedAccount = mapIdToAccount.get(contact.AccountId);

            if(relatedAccount !=null){
                contact.Pardot_BU_Code_Sync__c = relatedAccount.Hub__r.Code__c;
                contact.Pardot_Sync_code__c = mapCountryIdToPardotSyncCode.get(relatedAccount.Country__c);
            }else{
                contact.Pardot_BU_Code_Sync__c = null;
                contact.Pardot_Sync_code__c = null;
            }
        }
    }
    
    
    /*
* @description: updateOwnerChangedFlag -> ES20-12476
* @purpose: Updating Owner_Changed__c flag to true when contact owner changes
* @parameters: List<SObject> newItems, Map<Id, SObject> oldItems
*/
    public static void updateOwnerChangedFlag(List<SObject> newItems, Map<Id, SObject> oldItems){
        
        //Assignment  
        Set<Id> conIdSet = new Set<Id>();
        Set<Contact> conUpdateSet = new Set<Contact>();
        List<Contact> conUpdateList = new List<Contact>();
        List<Contact> newConList = (List<Contact>)newItems;
        Map<Id,Contact> oldConMap = (Map<Id,Contact>)oldItems;
        
        //Updating Owner_Changed__c flag to true when contact owner changes
        if(newConList!=null && newConList.size()>0){
            for(Contact newCon : newConList){
                Contact oldCon = oldConMap.get(newCon.Id);
                if(newCon.OwnerId != oldCon.OwnerId && oldCon.Owner_Changed__c == FALSE){
                    newCon.Owner_Changed__c = TRUE;
                }
            }
        }
    }
}