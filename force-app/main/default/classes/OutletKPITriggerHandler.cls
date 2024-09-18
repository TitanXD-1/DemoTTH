/*
* @Name: OutletKPITriggerHandler
* @Purpose: Trigger Handler Class for Outlet KPI Target

* @History                                                            
                                                            
* @VERSION		AUTHOR			DATE			DETAIL
	1.0			Preyanka Ghosh	20/02/2020		Initial Development
	        
*/
public with sharing class OutletKPITriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletKPITrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) { 
        EDGE_OutletKPITriggerHelper.populateAchievementField(newItems);
        EDGE_OutletKPITriggerHelper.populateUniqueIdField(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_OutletKPITriggerHelper.updateOutletKPITargets(newItems.values(), oldItems); 
        EDGE_OutletKPITriggerHelper.populateAchievementField(newItems.values());
        EDGE_OutletKPITriggerHelper.populateUniqueIdField(newItems.values());
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_OutletKPITriggerHelper.updatePendingForBatch(newItems.values(),null);
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_OutletKPITriggerHelper.updatePendingForBatch(newItems.values(), oldItems);
               
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}