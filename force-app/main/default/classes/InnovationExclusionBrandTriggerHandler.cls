/**
 
* @description : InnovationExclusionBrandTriggerHandler 

* @purpose : Provide access to Innovation_Exclusion_Brand__c

* @history

* Version   Developer        Date            User Story	          Purpose

1.0 -    Nidhi/Stuti         13/10/2023      146952 - Provide access to new Objects_Tech_SFDC
*/
public with sharing class InnovationExclusionBrandTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'InnovationAndExclusionBrandTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        C360_InnovationExclusionTriggerHelper.updateIECurrency(newItems);
         System.debug(LoggingLevel.DEBUG, 'beforeInsert');
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
          System.debug(LoggingLevel.DEBUG, 'beforeUpdate');
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
         System.debug(LoggingLevel.DEBUG, 'beforeDelete');
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
       C360_InnovationExclusionTriggerHelper.checkAndGenerateSharing(newItems.values());              
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       C360_InnovationExclusionTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);  
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
         System.debug(LoggingLevel.DEBUG, 'afterDelete');
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
         System.debug(LoggingLevel.DEBUG, 'after undelete');
    }
}