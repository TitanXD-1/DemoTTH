/**
 * @name : OpportunityTemplateTriggerHandler
 * @description : Trigger Handler Class for Opportunity Template
 * @history
 * VERSION      AUTHOR              DATE            DETAIL
 * 1.0          Sandeep Sahoo       16/04/2019      Initial Development (NCP-4192)
 * 2.0          Rithika Chaudhary   08/12/2021      NCP-5508(validateContentKeyAndType)
 */

public with sharing class OpportunityTemplateTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OpportunityTemplateTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_OpportunityTemplateTriggerHelper.checkDuplicateOppTemplate(newItems,null,false);
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_OpportunityTemplateTriggerHelper.checkTerritoryGeoOppTemplate(newItems,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_OpportunityTemplateTriggerHelper.checkDuplicateOppTemplate(newItems.values(),oldItems,true);
        EDGE_OpportunityTemplateTriggerHelper.checkTerritoryGeoOppTemplate(newItems.values(),oldItems);
        D1_OpportunityTemplateTriggerHelper.validateContentKeyAndType(newItems.values(),oldItems); //NCP-5508
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_OpportunityTemplateTriggerHelper.checkAndGenerateSharing(newItems.values());   
        D1_OpportunityTemplateTriggerHelper.sendNotification(newItems.values(),null);          
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_OpportunityTemplateTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
        D1_OpportunityTemplateTriggerHelper.sendNotification(newItems.values(),oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}