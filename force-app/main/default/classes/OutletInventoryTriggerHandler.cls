/**********************************************************************
Name: OutletInventoryTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for OutletInventoryTrigger
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            		DATE              DETAIL
1.0      Shahbaz Khan        12-10-2020        Initial Development
***********************************************************************/
public with sharing class OutletInventoryTriggerHandler implements TriggerHandler{
	// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletInventoryTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
   public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_OutletInventoryTriggerHelper.populateUniqueId(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_OutletInventoryTriggerHelper.populateUniqueId(newItems.values());
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