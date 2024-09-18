/**
*  @Name: UserTriggerHandler
*  @Purpose: Trigger Handler Class for UserBusinessRoleTrigger

*   @History                                                            
                                                                
*    @VERSION    AUTHOR            DATE              DETAIL
*     1.0       Sandeep Sahoo     25/02/2019        Initial Development
*	  2.0 	    Pradeep Kumar	  07/12/2020		User Story ECM-3432 - Validation for Update Functionality
*     3.0       Supriya           07/04/2022        ES20-12426 - assignUserToTerritories
**/
public with sharing class UserBusinessRoleTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'UserBusinessRoleTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UserBusinessRoleTriggerHelper.checkBusinessRoleInsert(newItems);
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_UserBusinessRoleTriggerHelper.checkBusinessRoleUpdate(newItems, oldItems);
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
         EDGE_UserBusinessRoleTriggerHelper.assignBusinessRole(newItems, null); 
        EDGE_UserBusinessRoleTriggerHelper.assignUserToTerritories(newItems,null); 
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         EDGE_UserBusinessRoleTriggerHelper.assignBusinessRole(newItems, oldItems);
        EDGE_UserBusinessRoleTriggerHelper.assignUserToTerritories(newItems,oldItems);
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
        
    }
}