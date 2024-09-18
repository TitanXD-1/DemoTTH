/**
* @description FieldPermissionTriggerHandler
* @history
* @Purpose: Trigger Handler Class for Field Permission Set

*@	VERSION  		AUTHOR             DATE              DETAIL
*@	1.0        Monalisa Halder      27/07/2021       Initial Development(ES20-10866)
**/

public with sharing class FieldPermissionTriggerHandler implements TriggerHandler
{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'FieldPermissionTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled()
    {        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) { 
       EDGE_FieldPermissionTriggerHelper.updateParentDependentFields(newItems);   
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
      
    }
    
     //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
         
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {

    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
     
}