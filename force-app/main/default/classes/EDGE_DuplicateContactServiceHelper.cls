/*
* Name: EDGE_DuplicateContactServiceHelper
* Purpose: This class is needed to find duplicates with the contact
*			details provided in the Contact service & return the request back with
*			possible duplicates and error message(if any)
* History                                                            

VERSION			AUTHOR					DATE				DETAIL
1.0       Sandip Ghosh      12/11/2019        ES20-6244
2.0		  Swagata Mondal     08/21/2023        144596
*/
public without sharing class EDGE_DuplicateContactServiceHelper {
    
    //static Integer MAX_NO_OF_DUPLICATE_CONTACTS = Integer.valueOf(Label.EDGE_Max_Duplicate_Contacts_Returned);
    
    public static EDGE_DuplicateContactServiceWrapper validateContacts(List<Map<String, Object>> deserializedMapList){
        
        EDGE_DuplicateContactServiceWrapper outerWrapper = new EDGE_DuplicateContactServiceWrapper();
        List<Contact> contactList = new List<Contact>();
        Set<Id> duplicateConIds = new Set<Id>();
        Map<Id, Contact> dupConIdtoRecMap = new Map<Id, Contact>();
        Savepoint savePoint = Database.setSavepoint();
        
        outerWrapper.hasAnySuggestion = false;
        outerWrapper.hasOtherErrors = false;
        
        if(deserializedMapList != null && deserializedMapList.size() > 0){
            for(Map<String, Object> deserializedMap : deserializedMapList){
                Contact record = new Contact();
                for(String field : deserializedMap.keySet()){
                    Object fieldValue = deserializedMap.get(field);
                    record.put(field, fieldValue);
                }
                contactList.add(record);
            }
            
            //Insert Contact
            List<Database.SaveResult> saveResultList = database.insert(contactList, false);
            
            if(saveResultList != null && saveResultList.size() > 0){
                outerWrapper.suggestionList = new List<EDGE_DuplicateContactServiceWrapper.EDGE_ContactDupChkResultWrapper>();
                
                for(Integer i = 0 ; i < saveResultList.size() ; i++){
                    Database.SaveResult saveResult = saveResultList[i];                    
                    if(!saveResult.isSuccess()){//only look at failures, not Successes
                        
                        System.debug(i +'-th contact errors = ' + saveResultList[i].getErrors());
                        EDGE_DuplicateContactServiceWrapper.EDGE_ContactDupChkResultWrapper outerL1Wrapper = new EDGE_DuplicateContactServiceWrapper.EDGE_ContactDupChkResultWrapper();
                        List<EDGE_DuplicateContactServiceWrapper.EDGE_ContactWrapper> contacts = new List<EDGE_DuplicateContactServiceWrapper.EDGE_ContactWrapper>();
                        
                        for (Database.Error error : saveResult.getErrors()) {           
                            System.debug('error = '+ error);
                            System.debug('saveResult = '+ saveResult);
                            Contact reqBodyContact = contactList[i];
                            
                            if (error instanceof Database.DuplicateError) {
                                outerWrapper.hasAnySuggestion = true;
                                Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                                Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                                Contact dupContact;
                                
                                Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                                if(matchResults != null && matchResults.size() > 0){
                                    for(Datacloud.MatchResult matchResult : matchResults){
                                        if(matchResult != null){
                                            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                                            for (Datacloud.MatchRecord matchRecord : matchRecords) {
                                                if(matchRecord != null){
                                                    dupContact = (Contact)matchRecord.getRecord();
                                                    duplicateConIds.add(dupContact.Id);
                                                    System.debug(i +'-th contact duplicate contact details = '+ dupContact);
                                                    EDGE_DuplicateContactServiceWrapper.EDGE_ContactWrapper conWrapper = new EDGE_DuplicateContactServiceWrapper.EDGE_ContactWrapper();
                                                    
                                                    if(dupContact != null){
                                                        conWrapper.existingContactId = dupContact.Id;
                                                        conWrapper.existingContactEmail = dupContact.Email;
                                                        conWrapper.existingContactPhone = dupContact.Phone;
                                                    } 
                                                    
                                                    
                                                       contacts.add(conWrapper); 
                                                 
                                                    
                                                }
                                            }
                                        }   
                                    }
                                }
                                outerL1Wrapper.errorCode = 'DUPLICATES_DETECTED';
                            }else{// end of Duplicate error check if block
                                outerWrapper.hasOtherErrors = true;
                                if(error.getStatusCode() != null && error.getStatusCode().name() != null){
                                    outerL1Wrapper.errorCode = error.getStatusCode().name();
                                }
                            }                            
                            outerL1Wrapper.GUID = reqBodyContact.GUID__c;
                            outerL1Wrapper.Status = false;
                            outerL1Wrapper.contacts = contacts;
                            outerWrapper.suggestionList.add(outerL1Wrapper);
                        }// end of saveResult.getErrors for loop
                    }// checking error for an individual contact
                }// end of iterating through all the possible Save Result errors against a contact
            }// end of check if any errors occurred at all
            
            Database.rollback(savePoint);
        }
        
        //Get Contact Other Details
        ////144596-Added MD_CurrentRole__c in SOQL query.
        for(Contact conRec : [Select Id, FirstName, LastName, MobilePhone,Phone__c,PhonePrefix__c,Title,Salutation,MD_CurrentRole__c  from Contact where Id in :duplicateConIds]){
            dupConIdtoRecMap.put(conRec.Id, conRec);
        }
        
        if(outerWrapper.suggestionList != null && outerWrapper.suggestionList.size() > 0){
            for(EDGE_DuplicateContactServiceWrapper.EDGE_ContactDupChkResultWrapper outerL1Wrapper : outerWrapper.suggestionList){
                List<EDGE_DuplicateContactServiceWrapper.EDGE_ContactWrapper> contacts = outerL1Wrapper.contacts;
                if(contacts != null && contacts.size()>0){
                    for(EDGE_DuplicateContactServiceWrapper.EDGE_ContactWrapper conWrapper : contacts){
                        Id existingConId = conWrapper.existingContactId;
                        if(existingConId != null && dupConIdtoRecMap.containsKey(existingConId)){
                            Contact dupContact = dupConIdtoRecMap.get(existingConId);
                            conWrapper.existingContactFirstName = dupContact.FirstName;
                            conWrapper.existingContactLastName = dupContact.LastName;
                            conWrapper.existingContactMobilePhone = dupContact.MobilePhone;
                            conWrapper.existingContactPhonePrefix = dupContact.PhonePrefix__c;
                            conWrapper.existingContactPhoneNumber = dupContact.Phone__c;
                            conWrapper.existingContactTitle = dupContact.Title;
                            conWrapper.existingContactSalutation = dupContact.Salutation;
                            conWrapper.existingContactOutletRole = dupContact.MD_CurrentRole__c;//144596
                        }
                    }  
                }
            } 
        }
        return outerWrapper;
    }
    
}