/*
Name : EDGE_UpdateContactCtrl 
Description: This is the server side controller class for <UpdateUserRecord> lightning component.
Server side update, fetch record will be perform here.

History                                                            

VERSION   AUTHOR            DATE              DETAIL
1.0       Sandip Ghosh      01/09/2020        ES20-8427
*/
public without sharing class EDGE_UpdateContactCtrl{
    
    /*
Method Name : checkContactStatus
Description : Check if the contact is associated with any Community user
and if related to one or more open accounts
*/
    @AuraEnabled
    public static String checkContactStatus(String contactRecordId){
        
        String statusMessage = 'none';
        Map<Id,Id> contactWithActiveComm = new Map<Id,Id>();
        set<Id> contactIdWithOtherRelSet = new set<Id>();
        //System.debug('contactRecordId = '+ contactRecordId);
        
        //If a community user found linked to the contact then set the status to commUserExists
        // Sample query : SELECT Id,ContactId,Contact.AccountId FROM User WHERE ContactId = :contactRecordId 
        // AND IsActive = TRUE AND UserType != 'Standard'
        contactWithActiveComm = EDGE_AccountTriggerDataHelper.checkForCommUser(new Set<Id>{contactRecordId});
        if(contactWithActiveComm.containsKey(contactRecordId) && contactWithActiveComm.get(contactRecordId)!=null){
            statusMessage = 'commUserExists';
        }
        
        //If a community user found linked to the contact and the contact also assoicated with one or more
        // open accounts then set the status to commUserAndAccRelExists
        
        if(Schema.sObjectType.AccountContactRelation.isAccessible() ){
            for(AccountContactRelation accConRel : [SELECT Id,ContactId,AccountId,
                                                    Contact_Type__c FROM AccountContactRelation 
                                                    WHERE ContactId = :contactRecordId  AND Account.Status__c != 'Closed'])
            {
                contactIdWithOtherRelSet.add(accConRel.ContactId);
            }
        }
        
        System.debug(LoggingLevel.Debug,'contactWithActiveComm:' + contactWithActiveComm);
        System.debug(LoggingLevel.Debug,'contactIdWithOtherRelSet:' + contactIdWithOtherRelSet);
        
        if(contactIdWithOtherRelSet != null && contactIdWithOtherRelSet.size()>0){
            
            if(contactWithActiveComm.containsKey(contactRecordId)){
                statusMessage = 'commUserAndAccRelExists';
            }else{
                statusMessage = 'accRelExists';
            }
        }
        
        if(statusMessage == 'none'){
            deleteContact(contactRecordId);
        }
        
        return statusMessage;
    }
    
    /*
Method Name : deleteContact
Description : Delete the Contact Record
*/
    @AuraEnabled
    public static Boolean deleteContact(String contactRecordId){
        
        Boolean isDeleted = false;
        profile currentProfile;
        Map<Id,Id> contactWithActiveComm = new Map<Id,Id>();
        
        System.debug(LoggingLevel.Debug,'getCurrentUserProfileId ='+ EDGE_UtilityClass.getCurrentUserProfileId());
        currentProfile = EDGE_UtilityClass.getCurrentUserProfileId();
        if(currentProfile.Name == 'Master Data Manager'){
            contactWithActiveComm = EDGE_AccountTriggerDataHelper.checkForCommUser(new Set<Id>{contactRecordId});
            System.debug(LoggingLevel.Debug,'contactWithActiveComm = '+ contactWithActiveComm);
            if(contactWithActiveComm.containsKey(contactRecordId) && contactWithActiveComm.get(contactRecordId)!=null){
                Id userId = contactWithActiveComm.get(contactRecordId);
                deactivateCommUser(userId);
                ID contactJobID = System.enqueueJob(new EDGE_AsyncContactRemover(contactRecordId));
                //ID userJobID = System.enqueueJob(new EDGE_AsyncUserDeactivator(userId,contactRecordId));
            }else{//Only contact deletion required, no community user exists for the contact
                deleteContactDetails(contactRecordId);
            }
            
            isDeleted = true;
        }
        return isDeleted;
    }
    
    /*
Method Name: deactivateCommUser      
Description: De-activates the associated community user
*/
    private static void deactivateCommUser(Id userId){
        if(Schema.sObjectType.User.isAccessible() && Schema.sObjectType.User.isUpdateable()){
            List<User> userList = [Select Id,IsActive from User where Id = :userId LIMIT 1];
            User userToBeDeactivated;
            if(userList != null && userList.size() > 0){
                userToBeDeactivated = userList[0];
                System.debug(LoggingLevel.Debug,'userToBeDeactivated = '+ userToBeDeactivated);
                userToBeDeactivated.IsActive = false;
                userToBeDeactivated.IsPortalEnabled = false;
                //userToBeDeactivated.ContactId = null;              
                Database.update(userToBeDeactivated);

            }
        }
        
    }
    
    /*
Method Name: deleteContactDetails      
Description: Hard delets the contacts
*/
    private static void deleteContactDetails(Id contactRecordId){
        Contact contactRec;
        if(Schema.sObjectType.Contact.isAccessible() && Schema.sObjectType.Contact.isDeletable()){
            List<Contact> conList = [Select Id,Name from Contact where Id = :contactRecordId];
            
            System.debug(LoggingLevel.Debug,'conList = '+ conList);
            if(conList != null && conList.size() > 0){
                contactRec = conList[0];
                System.debug(LoggingLevel.Debug,'contactRec = '+ contactRec);
                Database.delete(contactRec);
            }
        }
    }    
    /*
Method Name: getListViews      
Description: To get all listview associated with contact
*/
    @AuraEnabled
    public static List<ListView> getListViews() {
        List<ListView> listviews = new List<ListView>();
        if(Schema.sObjectType.ListView.isAccessible()){
            listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'Contact'and Name = :System.Label.EDGE_Contact_List_View];  
        }
        return listviews;
    }
    
}