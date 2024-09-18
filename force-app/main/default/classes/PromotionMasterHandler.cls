/**
* @name PromotionMasterTrigger
* @purpose - Trigger Handler Class for PromotionMasterTrigger
* @history
* Version              Author                   Date            Detail
   1.0             Mayukh/Geethika           17/06/2022      ES20-12989 - Initial Development

*/

public with sharing class PromotionMasterHandler implements TriggerHandler{
    
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'PromotionMasterTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_PromotionMasterTriggerHelper.checkAndGenerateSharing(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_PromotionMasterTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }

}