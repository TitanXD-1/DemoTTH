/**********************************************************************
Name: EDGE_ContactShareServiceHelper
=======================================================================
Purpose: This class is needed to share a contact with the respective
user(sales rep) sent via Contact Share Service & return the request back 
with status of the processing
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandip Ghosh      05/11/2020        ES20-7921

***********************************************************************/
public class EDGE_ContactShareServiceHelper {
    
    public static EDGE_ContactShareServiceWrapper shareContacts(List<Map<String, Object>> deserializedMapList){
        
        EDGE_ContactShareServiceWrapper contactShareWrapper = new EDGE_ContactShareServiceWrapper();
        contactShareWrapper.isSuccess = true;
        Set<Id> contactIds = new Set<Id>();
        Set<Id> userOrGroupIds = new Set<Id>();
        List<ContactShare> contactShareList = new List<ContactShare>();       
        List<ContactShare> finalContactShareList = new List<ContactShare>();
        
        if(deserializedMapList != null && deserializedMapList.size() > 0){
            for(Map<String, Object> deserializedMap : deserializedMapList){

                ContactShare record = new ContactShare();
                
                for(String field : deserializedMap.keySet()){
                    Object fieldValue = deserializedMap.get(field);
                    record.put(field, fieldValue);
                    
                    if(field == 'ContactId' && fieldValue != null){                       
                        contactIds.add((Id)fieldValue);
                    }
                    if(field == 'UserOrGroupId' && fieldValue != null){                       
                        userOrGroupIds.add((Id)fieldValue);
                    }                
                }
                record.ContactAccessLevel = 'Read';
                
                contactShareList.add(record);
            }
            
            if(contactShareList != null && contactShareList.size() > 0){
				
                Map<String, Boolean> contactShareMap = checkForExistingRecShare(contactIds, userOrGroupIds);
                
                for(ContactShare conShare : contactShareList){
                    if(contactShareMap != null){
                        if(!contactShareMap.containsKey(conShare.ContactId + '_' + conShare.UserOrGroupId)){//false means sharing doesn't exist
                            finalContactShareList.add(conShare);  
                        } 
                    }
                }
                
                if(finalContactShareList != null && finalContactShareList.size() > 0){
                    
                    List<Database.SaveResult> saveResultList = Database.insert(finalContactShareList , false);
                    
                    if(saveResultList != null && saveResultList.size() > 0){
                        for(Integer i = 0 ; i < saveResultList.size() ; i++){
                            Database.SaveResult saveResult = saveResultList[i];                  
                            
                            if(!saveResult.isSuccess()){//Failure
                                contactShareWrapper.isSuccess = false;
                                contactShareWrapper.errorMessage = '';
                                for (Database.Error error : saveResult.getErrors()) {           
                                    System.debug('error = '+ error);
                                    if(error.getMessage() != null){
                                        contactShareWrapper.errorMessage += error.getMessage() + '\t';
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        System.debug('contactShareList = '+ contactShareList);
        return contactShareWrapper;
    }
    
    //Method to check if sharing exist for the passed contact and user ids
    private static Map<String, Boolean> checkForExistingRecShare(Set<Id> contactIds, Set<Id> userOrGroupIds){
        
        Map<String, Boolean> contactShareMap = new Map<String, Boolean>();
        
        if(contactIds != null && userOrGroupIds != null){
            for(ContactShare conShare : [Select ContactId,UserOrGroupId from ContactShare where ContactId in :contactIds and UserOrGroupId in :userOrGroupIds]){
           		contactShareMap.put(conShare.ContactId + '_' + conShare.UserOrGroupId, true);                         
            }
        }
        
        return contactShareMap;
    }
}