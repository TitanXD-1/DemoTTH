/**************************************************************************************
Apex Class Name  :  MD_ContactTriggerHandler 
Version          :  1.0
Created Date     :  29/04/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Schwarzbock         29/04/2019              Original Version
******************************************************************************/
public without sharing class MD_ContactTriggerHandler extends TriggersHandler{
     
    public MD_ContactTriggerHandler(List<SObject> p_triggerNew, List<SObject> p_triggerOld) {
    
        super(p_triggerNew, p_triggerOld);
        
        allow_masterLoop_BeforeInsert = true;
        allow_masterLoop_AfterInsert = true;
        allow_masterLoop_BeforeUpdate = true;
        allow_masterLoop_AfterUpdate = true;
        
        allow_dataPreparing = true;

        allow_finalLoop_BeforeInsert = true;
        allow_finalLoop_BeforeUpdate = true;
        
        allow_triggerFinish = true;
    }

    /*****************************************************************/
    /*********************** TRIGGER METHODS *************************/
    /*****************************************************************/
    
    //Master loops
    public override void masterLoop_BeforeInsert(SObject recNew) {
        syncronizeCurrentOutletFields((Contact) recNew, null, 'masterLoop');
    }    
    public override void masterLoop_AfterInsert(SObject recNew) {
        createUser((Contact) recNew, null, 'masterLoop');
    }
    public override void masterLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        syncronizeCurrentOutletFields((Contact) recNew, (Contact) recOld, 'masterLoop');
    }      
    public override void masterLoop_AfterUpdate(SObject recNew, SObject recOld) {
        setDefaultFieldsIfApproved((Contact) recNew, (Contact) recOld, 'masterLoop');
        createUser((Contact) recNew, (Contact) recOld, 'masterLoop');       
    }

    //Data Preparing
    public override void dataPreparing(){        
        syncronizeCurrentOutletFields(null, null, 'DataPreparing');
        setDefaultFieldsIfApproved(null, null, 'DataPreparing');
    }    

    //Final Loops
    public override void finalLoop_BeforeInsert(SObject recNew) {
        syncronizeCurrentOutletFields((Contact) recNew, null, 'FinalLoop');
    }
    public override void finalLoop_BeforeUpdate(SObject recNew, SObject recOld) {
        syncronizeCurrentOutletFields((Contact) recNew, (Contact) recOld, 'FinalLoop');
    }
    
    //Trigger Finish
    public override void triggerFinish() {
        setDefaultFieldsIfApproved(null, null, 'TriggerFinish');
        createUser(null, null, 'TriggerFinish');
    }
    
    /*****************************************************************/
    /********************** USE CASE METHODS *************************/
    /*****************************************************************/
    private Set<Id> approvedContacts = new set<Id>();
    private void createUser(Contact recNew, Contact recOld, String mode){        
        if(mode == 'masterLoop'){
            if((Trigger.isInsert && recNew.MD_Approvalstatus__c == 'Approved') || (Trigger.isUpdate && recNew.MD_Approvalstatus__c != recOld.MD_Approvalstatus__c)){
                approvedContacts.add(recNew.Id);
            }
        }
        if(mode == 'TriggerFinish'){
            if(!approvedContacts.isEmpty()){
                MD_RegistrationUtil.createUser(approvedContacts);
            }
        } 
    }

    private Set<Id> approvedContactIds = new set<Id>();
    private Set<Id> primaryContacts = new set<Id>();
    List<AccountContactRelation> accContactRelationships = new List<AccountContactRelation>();
    private void setDefaultFieldsIfApproved(Contact recNew, Contact recOld, String mode){        
        if(mode == 'masterLoop'){
            if(recNew.Contact_Type__c == 'Primary' && ((Trigger.isInsert && recNew.MD_Approvalstatus__c == 'Approved') || (Trigger.isUpdate && recNew.MD_Approvalstatus__c != recOld.MD_Approvalstatus__c))){
                approvedContactIds.add(recNew.Id);
                if(recNew.Contact_Type__c == 'Primary'){
                	primaryContacts.add(recNew.Id);
                }
            }
        }
        if(mode == 'dataPreparing'){
            if(!primaryContacts.isEmpty()){
                accContactRelationships = [SELECT Id, ContactId, MD_Role__c, MD_UserProfile__c, MD_AssignedPermissions__c, MD_Status__c, MD_MyDiageoEnabled__c, Contact_Type__c, Account.Country__r.Code__c FROM AccountContactRelation WHERE ContactId IN: primaryContacts OR ContactId IN: approvedContactIds];
                Set<String> countryCodes = new Set<String>();
                for(AccountContactRelation accContactRelationship: accContactRelationships){
                    if(accContactRelationship.Account.Country__r.Code__c != null){
                        countryCodes.add(accContactRelationship.Account.Country__r.Code__c);
                    }
                }
                Map<String,String> mapPermissionsByClusterCode = new Map<String,String>();
                for(DiageoCMS__Cluster__c cluster: [SELECT Id, DiageoCMS__ExternalId__c, MD_MyDiageoPermissions__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c IN: countryCodes]){
                    mapPermissionsByClusterCode.put(cluster.DiageoCMS__ExternalId__c, cluster.MD_MyDiageoPermissions__c);
                }
                for(AccountContactRelation accContactRelationship: accContactRelationships){
                    accContactRelationship.MD_Status__c = 'Active';
                    accContactRelationship.MD_MyDiageoEnabled__c = true;
                    if(primaryContacts.contains(accContactRelationship.ContactId)){
                        accContactRelationship.MD_Role__c = 'Owner';
                        accContactRelationship.MD_UserProfile__c = 'Primary User';
                        accContactRelationship.Contact_Type__c = 'Primary';
                    	accContactRelationship.MD_AssignedPermissions__c = mapPermissionsByClusterCode.containsKey(accContactRelationship.Account.Country__r.Code__c) ? mapPermissionsByClusterCode.get(accContactRelationship.Account.Country__r.Code__c) : null;                        
                    }                    
                }
            }
        }
        if(mode == 'TriggerFinish'){
            if(!accContactRelationships.isEmpty()){
                update accContactRelationships;
            }
        } 
    }    
    
    /* When the current outlet of a Contact changes, the Outlet Country, Role, User Profile and Assigned Permissions are retrieved from the Account Contact Relation to the Contact */
    private Set<Id> currentOutletIds = new set<Id>();
    private Set<Id> contactIds = new set<Id>();
    Private Map<Id,AccountContactRelation> mapContactRelationships = new Map<Id,AccountContactRelation>();
    private void syncronizeCurrentOutletFields(Contact recNew, Contact recOld, String mode){
        if(mode == 'masterLoop'){
            if((Trigger.isInsert && String.isNotBlank(recNew.MD_CurrentOutlet__c)) || (Trigger.isUpdate && recNew.MD_CurrentOutlet__c != recOld.MD_CurrentOutlet__c)){
                if(recNew.MD_CurrentOutlet__c != null){
                    currentOutletIds.add(recNew.MD_CurrentOutlet__c);
                }
                contactIds.add(recNew.Id);
            }
        }
        if(mode == 'dataPreparing'){
            if(!currentOutletIds.isEmpty() && !contactIds.isEmpty()){
                for(AccountContactRelation accContactRelationship: [SELECT Id, MD_Role__c, MD_UserProfile__c, MD_AssignedPermissions__c, Account.Country__r.Code__c, ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN: contactIds AND AccountId IN: currentOutletIds]){
                    mapContactRelationships.put(accContactRelationship.ContactId, accContactRelationship);
                }
            }
        }
        if(mode == 'finalLoop'){
            if(currentOutletIds.contains(recNew.MD_CurrentOutlet__c) && contactIds.contains(recNew.Id)){
                if(mapContactRelationships.containsKey(recNew.Id) && mapContactRelationships.get(recNew.Id).AccountId == recNew.MD_CurrentOutlet__c){
                    AccountContactRelation accContactRelationship = mapContactRelationships.get(recNew.Id);
                    recNew.MD_CurrentOutletCountry__c = accContactRelationship.Account.Country__r.Code__c;
                    recNew.MD_CurrentAssignedPermissions__c = accContactRelationship.MD_AssignedPermissions__c;
                    recNew.MD_CurrentRole__c = accContactRelationship.MD_Role__c;
                    recNew.MD_CurrentUserProfile__c = accContactRelationship.MD_UserProfile__c;
                }
            }
        }       
    }    
     
}