/**************************************************************************************
Apex Class Name  :  MD_AccountContactRelationTriggerHandler
Version          :  1.0
Created Date     :  10/05/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         10/05/2019              Original Version
******************************************************************************/
public class MD_AccountContactRelationTriggerHandler extends TriggersHandler{
    
    public MD_AccountContactRelationTriggerHandler(List<SObject> p_triggerNew, List<SObject> p_triggerOld) {
        
        super(p_triggerNew, p_triggerOld);
        
        allow_masterLoop_AfterUpdate = true;
        
        allow_finalLoop_AfterUpdate = true;
        
        allow_dataPreparing = true;
        allow_triggerFinish = true;
    }
    
    /*****************************************************************/
    /*********************** TRIGGER METHODS *************************/
    /*****************************************************************/
    
    //Master loops
    public override void masterLoop_AfterUpdate(SObject recNew, SObject recOld) {
        syncronizeCurrentOutletFields((AccountContactRelation) recNew, (AccountContactRelation) recOld, 'MasterLoop');
        addPermissionIfGrantedAccess((AccountContactRelation) recNew, (AccountContactRelation) recOld, 'MasterLoop');
    }
    
    //Data Preparing
    public override void dataPreparing(){        
        syncronizeCurrentOutletFields(null, null, 'DataPreparing');
        addPermissionIfGrantedAccess(null, null, 'DataPreparing');
    }    
    
    //Final Loops
    public override void finalLoop_AfterUpdate(SObject recNew, SObject recOld) {
        syncronizeCurrentOutletFields((AccountContactRelation) recNew, (AccountContactRelation) recOld, 'FinalLoop');
    }
    
    //Trigger Finish
    public override void triggerFinish() {
        syncronizeCurrentOutletFields(null, null, 'TriggerFinish');
        addPermissionIfGrantedAccess(null, null, 'TriggerFinish');
    }    
    
    /*****************************************************************/
    /********************** USE CASE METHODS *************************/
    /*****************************************************************/
    
    /* If the updated Account Contact Relation is the currect outlet for the contact, the fields Role, User Profile and Assigned Permissions are updated on the contact*/
    private Set<Id> accountIds = new set<Id>();
    private Set<Id> contactIds = new set<Id>();
    private Map<Id,Contact>  mapContacts = new Map<Id,Contact>();
    private List<Contact>  contactsToUpdate = new List<Contact>();
    private Set<Id>  contactsToRemovePermission = new Set<Id>();
    private Set<Id>  contactsToAddPermission = new Set<Id>();
    
    
    private void syncronizeCurrentOutletFields(AccountContactRelation recNew, AccountContactRelation recOld, String mode){
        if(mode == 'masterLoop'){
            Set<String> fieldsToSync = new Set<String>{'MD_Role__c','MD_UserProfile__c','MD_AssignedPermissions__c'};
                for(String fieldToSync: fieldsToSync){
                    if((String) recNew.get(fieldToSync) != (String) recOld.get(fieldToSync)){
                        accountIds.add(recNew.AccountId);
                        contactIds.add(recNew.ContactId);
                    }
                }
        }
        if(mode == 'dataPreparing'){
            if(!accountIds.isEmpty() && !contactIds.isEmpty()){
                mapContacts = new Map<Id,Contact>([SELECT Id, MD_CurrentRole__c, MD_CurrentUserProfile__c, MD_CurrentAssignedPermissions__c, MD_CurrentOutlet__c, 
                                                   (SELECT id, AccountId, MD_Role__c, MD_UserProfile__c, MD_AssignedPermissions__c, MD_MyDiageoEnabled__c FROM AccountContactRelations) 
                                                   FROM Contact 
                                                   WHERE Id IN: contactIds 
                                                   AND MD_CurrentOutlet__c IN: accountIds]);
                
            }
        }
        if(mode == 'finalLoop'){
            if(accountIds.contains(recNew.AccountId) && contactIds.contains(recNew.ContactId)){
                if(mapContacts.containsKey(recNew.ContactId) && mapContacts.get(recNew.ContactId).MD_CurrentOutlet__c == recNew.AccountId){
                    AccountContactRelation accountContactToAssign = recNew;
                    List<String> assignedPermissions = new List<String>();
                    if(recNew.MD_AssignedPermissions__c != null){
                        assignedPermissions = recNew.MD_AssignedPermissions__c.split(';');
                    }
                    if(!assignedPermissions.contains('Access')){
                        if(mapContacts.get(recNew.ContactId).AccountContactRelations.size() > 1){
                            for(AccountContactRelation accCon : mapContacts.get(recNew.ContactId).AccountContactRelations){
                                if(accCon.id != recNew.id){
                                    List<String> assignedPermissionsAux = new List<String>();
                                    if(accCon.MD_AssignedPermissions__c != null)
                                        assignedPermissionsAux = accCon.MD_AssignedPermissions__c.split(';');
                                    if(assignedPermissionsAux.contains('Access')){
                                        accountContactToAssign = accCon;
                                        break;
                                    }
                                    accountContactToAssign = null;
                                }
                            }
                        }else{
                            contactsToRemovePermission.add(mapContacts.get(recNew.ContactId).Id);
                        }
                        
                    }
                    if(accountContactToAssign != null){
                        Contact con = mapContacts.get(recNew.ContactId);
                        con.MD_CurrentRole__c = accountContactToAssign.MD_Role__c;
                        con.MD_CurrentUserProfile__c = accountContactToAssign.MD_UserProfile__c;
                        con.MD_CurrentAssignedPermissions__c = accountContactToAssign.MD_AssignedPermissions__c;
                        con.MD_CurrentOutlet__c = accountContactToAssign.AccountId;
                        contactsToUpdate.add(con);                       
                    }else{
                        Contact con = mapContacts.get(recNew.ContactId);
                        con.MD_CurrentRole__c = '';
                        con.MD_CurrentUserProfile__c = '';
                        con.MD_CurrentAssignedPermissions__c = '';
                        con.MD_CurrentOutlet__c = null;
                        contactsToUpdate.add(con);
                        contactsToRemovePermission.add(con.Id);
                    }
                }
            }
        }
        if(mode == 'TriggerFinish'){
            if(!contactsToUpdate.isEmpty()){
                update contactsToUpdate;
            }
            if(!contactsToRemovePermission.isEmpty()){
                MD_RegistrationUtil.removePermissions(contactsToRemovePermission, 'MD_MyDiageoUser') ;
            }
        }
    }
    
    
    private Set<Id> contactIdsToAddPermission = new set<Id>();
    private Set<Id> allContactIds = new set<Id>();
    private Set<Id> userIds = new Set<Id>();
    private Id permissionSetId;
    private void addPermissionIfGrantedAccess(AccountContactRelation recNew, AccountContactRelation recOld, String mode){
        
        if(mode == 'masterLoop'){
            List<String> newAssignedPermissions = new List<String>();
            if(recNew.MD_AssignedPermissions__c != null)
                newAssignedPermissions = recNew.MD_AssignedPermissions__c.split(';');
            List<String> oldAssignedPermissions = new List<String>();
            if(recOld.MD_AssignedPermissions__c != null)
                oldAssignedPermissions = recOld.MD_AssignedPermissions__c.split(';');
            if(newAssignedPermissions.contains('Access') && !oldAssignedPermissions.contains('Access')){
                allContactIds.add(recNew.contactId);
                contactIdsToAddPermission.add(recNew.contactId);
            }
            	    
        }
        if(mode == 'dataPreparing'){
            if(!allContactIds.isEmpty()){
                List<PermissionSetAssignment> permissionAssignments = [SELECT id, assigneeId, assignee.contactId 
                                                                 FROM PermissionSetAssignment 
                                                                 WHERE assignee.contactId 
                                                                 IN :contactIdsToAddPermission
                                                                 AND PermissionSet.name = 'MD_MyDiageoUser'];
                for(PermissionSetAssignment permission : permissionAssignments){
                    for(Id contactId : contactIdsToAddPermission){
                        if(permission.assignee.contactId == contactId){
                            contactIdsToAddPermission.remove(contactId);
                        }
                    }
                }
                Map<Id,User> mapUsers = new Map<Id,User>([SELECT id FROM User WHERE contactId IN :contactIdsToAddPermission]);
                permissionSetId = [SELECT id FROM PermissionSet WHERE name = 'MD_MyDiageoUser'].id;
               	userIds =  mapUsers.keySet();
            }
        }
        if(mode == 'TriggerFinish'){
            if(!userIds.isEmpty()){
                MD_RegistrationUtil.assignPermissions(userIds, permissionSetId);
            }
        }
    }
    
}