public class MD_AccountContactUtil { 
    //Looks at the records that contain an Id and returns them
    public static List<AccountContactRelation> getExistingAccContactsDisplayed(List<AccountContactRelation> accCons){
        List<AccountContactRelation> accConsToReturn = new List<AccountContactRelation>();
        for(AccountContactRelation accContact : accCons){
            //The record was created for display
            if(accContact.Id != null){
                accConsToReturn.add(accContact);
            }
        }
        return accConsToReturn;
    }
    
    //Returns a list with all the contacts that don't have an Id and were assigned for the contact to have permission.
    public static map<String, AccountContactRelation> getMemoryCreatedAccContacts(List<AccountContactRelation> accCons){
        map<String, AccountContactRelation> mapContactOutletToAccCon = new map<String, AccountContactRelation>();
        for(AccountContactRelation accContact : accCons){
            //The record was created for display
            if(accContact.Id == null && accContact.MD_Status__c == 'Active'){
                //Convert the Ids into 15 char
                mapContactOutletToAccCon.put(String.valueOf(accContact.Contact).substring(0, 15) + String.valueOf(accContact.Account).substring(0, 15), accContact);
            }
        }
        return mapContactOutletToAccCon;
    }
    
    //Adds Id to the records that were on database
    public static List<AccountContactRelation> addIdsOfExistingRecToNewAccContacts(map<String, AccountContactRelation> mapOfNewAccContacts, List<AccountContactRelation> listOfExistingCons){
        for(AccountContactRelation accContact : listOfExistingCons){
            //I put the Id of the existing record so that we don't create a new record and update the old one
            if(mapOfNewAccContacts.containsKey(accContact.MD_ContactAccountIds__c)){
                mapOfNewAccContacts.get(accContact.MD_ContactAccountIds__c).Id = accContact.Id;
            }
        }
        return mapOfNewAccContacts.values();
    }
    
    //From a list of account contacts it returns only the ones with an active status.
    public static List<AccountContactRelation> getActiveAccountContactsFrom(List<AccountContactRelation> accCons){
        List<AccountContactRelation> activeAccContacts = new List<AccountContactRelation>();
        for(AccountContactRelation accCon : accCons){
            if(accCon.MD_Status__c == 'Active'){
                activeAccContacts.add(accCon);
            }
        }
        return activeAccContacts;
    }
    
    //Creates an account contact with the information that needs to be displayed and no Permissions.
    public static AccountContactRelation createNewAccountContactFrom(AccountContactRelation accContact, Id contactId){
        return new AccountContactRelation(
            AccountId = accContact.AccountId,
            ContactId = contactId,
            MD_AssignedPermissions__c = ''
            
        );
    }
    
    //Returns the same list but the Account contact record for the logged user will be displayed first.
    public static List<AccountContactRelation> putAccContactForLoggedUserFirst(List<AccountContactRelation> accContacts){
        Id loggedContact = MD_UserSessionUtil.getUser().ContactId;
        for(Integer i = 0; i < accContacts.size(); i++){
            if(accContacts.get(i).ContactId == loggedContact){
                accContacts.add(0, accContacts.get(i));
                accContacts.remove(i+1);
                break;
            }
        }
        return accContacts;
    }
}