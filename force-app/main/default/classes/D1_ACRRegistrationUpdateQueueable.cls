/**
 * @name D1_ACRRegistrationUpdateQueueable
 * @description Queueable Class for D1 Registration
 * @history
 * VERSION          AUTHOR                      DATE            DETAIL
 * 1.0              Kapil Baliyan               09/10/2023
 */
public without sharing class D1_ACRRegistrationUpdateQueueable implements Queueable{

    //public String userId;
    public Id contactId;
    public Map<Id, String> accountPermissionMap;
    public Boolean isSecondaryRegistration;
    public D1_UserRegistrationDetailWrapper userRegWrapper;
    public Set<Id> selectedAccIdSet;

    
    public D1_ACRRegistrationUpdateQueueable(Id contactId,Map<Id, String> accountPermissionMap,Boolean isSecondaryRegistration,D1_UserRegistrationDetailWrapper userRegWrapper,Set<Id> selectedAccIdSet){
        
        this.contactId = contactId;
        this.accountPermissionMap = accountPermissionMap;
        this.isSecondaryRegistration = isSecondaryRegistration;
        this.userRegWrapper = userRegWrapper;
        this.selectedAccIdSet = selectedAccIdSet;
    }

    public void execute(QueueableContext context) {
        
        updateUserRelatedRecord();
    }
    public void updateUserRelatedRecord(){
        D1_AddUserPermissionsNewController.addUserRelatedRecordUpdate(contactId,accountPermissionMap,isSecondaryRegistration,userRegWrapper,selectedAccIdSet);
    }
}