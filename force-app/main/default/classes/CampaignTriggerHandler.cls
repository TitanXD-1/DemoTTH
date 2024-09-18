/**
 * @name CampaignHandler
 * @description Trigger Handler Class for CampaignTrigger
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0         Rithika       09/12/21     
 * 2.0
 **/
public with sharing class CampaignTriggerHandler implements TriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CampaignTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){ 
         if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
         return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
        
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        D1_CampaignTriggerHelper.checkAndGenerateSharing(newItems.values());             
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        D1_CampaignTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }

}