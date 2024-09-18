// used for Prospect Account record unlock
// added Without sharing by Vikas
public without sharing class EDGE_RecordUnlocker {
    @future
    public static void unlockProspectRecord(Set<Id> newItemsId){        
        List<Account> accList = new List<Account>();        
        List<Id> accIdList = new List<Id>();       
        //querying the accList to filter propect records
        if(Schema.sObjectType.Account.isAccessible()){
          accList = [SELECT Id,Status__c FROM Account WHERE ID IN : newItemsId AND Status__c = 'Approval In Progress'];  
        }
        
        
        for(Account acc : accList){            
            if(Approval.isLocked(acc.Id)){ 
                accIdList.add(acc.Id);    
            }       
        }
        
        Approval.UnlockResult[] urList = Approval.unlock(accIdList, false); //false mean if one record fails the rest will be excuted
        // Iterate through each returned result
        for(Approval.UnlockResult ur : urList) {
            if (ur.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully unlocked account with ID: ' + ur.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : ur.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
    } 
}