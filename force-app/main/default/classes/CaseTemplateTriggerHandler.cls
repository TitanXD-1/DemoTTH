/**
* @Name: CaseTemplateTriggerHandler

* @Purpose: Trigger Handler Class for CaseTemplateTrigger

* @History                                                            
                                                 
* @VERSION     AUTHOR             DATE              DETAIL
*   1.0        Anand Uppalapati   10/01/2022        ES20-11891   
**/
public with sharing class CaseTemplateTriggerHandler implements TriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CaseTemplateTrigger';
    
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
       EDGE_CaseTemplateTriggerHelper.checkAndGenerateSharing(newItems.values());             
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       EDGE_CaseTemplateTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }

}