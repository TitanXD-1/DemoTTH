/**
 
* @description : CaseConfigurationTriggerHandler 

* @purpose : Trigger Handler Class for QualityCaseConfigurationTrigger

* @history

* Version   Developer        Date            User Story	          Purpose

*	1.0       Sudipta Nandi     26/07/2021        Initial Development
*/
public with sharing class CaseConfigurationTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'QualityCaseConfigurationTrigger';
    
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
         EDGE_CaseConfigurationTriggerHelper.enableDefaultRoleflag(newItems.values(),oldItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
       EDGE_CaseConfigurationTriggerHelper.checkAndGenerateSharing(newItems.values());              
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       EDGE_CaseConfigurationTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);  
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
        
    }
}