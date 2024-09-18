/**
 * @name : EDGE_ContactTriggerExtendedHelper
 * @description : Trigger Helper for Contact
 * @history
 * VERSION          AUTHOR                  DATE                DETAIL
 * 1.0              Shahbaz Khan            07/12/2020          ES20-8738
 * 2.0              Kapil Baliyan           11/03/2024          151317
 */
public without sharing class EDGE_ContactTriggerExtendedHelper {
    /**
     * @name : updateUserFields
     * @description : Update the FirstName,LastName,MobilePhone on user when its related contact fields(FirstName,LastName,MobilePhone) get updated
     * @param newItems 
     * @param oldItems 
     */
    public static void updateUserFields(List<Contact> newItems, Map<Id, SObject> oldItems){
        profile currentProfile;
        Set<Id> contactIdSet = new Set<Id>();
        Map<Id,User> contactUserMap = new Map<Id,User>();
        List<User> upadteUserList = new List<User>();
        Map<Id,Contact> oldItemMap = (Map<Id,Contact>)oldItems;
        
       /* for(Contact conRec : newItems){
            System.debug('getCurrentUserProfileId ='+ EDGE_UtilityClass.getCurrentUserProfileId());
            currentProfile = EDGE_UtilityClass.getCurrentUserProfileId();
        }*/
        
        currentProfile = EDGE_UtilityClass.getCurrentUserProfileId(); 
        
        
        String profiles = System.label.EDGE_User_Sync_Profile_Check; 
        List<String> listOfProfiles = profiles.split(';');
        
        if(currentProfile != null && listOfProfiles.contains(currentProfile.Name)){
            for(Contact conRec : newItems){
                if(oldItemMap!=null && (conRec.Mobile__c != oldItemMap.get(conRec.Id).Mobile__c || conRec.MobilePrefix__c != oldItemMap.get(conRec.Id).MobilePrefix__c || conRec.FirstName != oldItemMap.get(conRec.Id).FirstName || conRec.LastName != oldItemMap.get(conRec.Id).LastName))
                {   
                    contactIdSet.add(conRec.Id);
                        
                }
            }
            if(contactIdSet != null && contactIdSet.size()>0 && Schema.sObjectType.User.isAccessible()){
                for(User user : [SELECT Id,FirstName,LastName,MobilePhone,ContactId,Contact.AccountId,Mobile_Number__c,Mobile_Prefix__c FROM User WHERE ContactId IN :contactIdSet AND IsActive = TRUE AND UserType != 'Standard'])
                {
                    contactUserMap.put(user.ContactId,user);
                    
                }
                
            } 
            for(Contact contactRec : newItems){
                Id contactId = contactRec.Id;
                if(contactUserMap != null && contactUserMap.get(contactId) != null){
                    User userObj= new User(id=contactUserMap.get(contactId).Id);
                    userObj.FirstName = contactRec.FirstName;
                    userObj.LastName = contactRec.LastName;
                    userObj.MobilePhone = contactRec.MobilePhone;
                    userObj.Mobile_Prefix__c = contactRec.MobilePrefix__c;
                    userObj.Mobile_Number__c = contactRec.Mobile__c;
                    upadteUserList.add(userObj);
                }
            }
            if(!upadteUserList.isEmpty() && upadteUserList.size()>0 && Schema.sObjectType.User.isUpdateable()){
                database.update(upadteUserList);
            }
        }
    }
}