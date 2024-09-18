/**********************************************************************
Name: RAGThresholdTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for ContentDocumentLinkTrigger
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      Preyanka Ghosh       29/04/2019        ES20-1034
***********************************************************************/

public with sharing class RAGThresholdTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'RAGThresholdTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        //EDGE_RAGThresholdTriggerHelper.checkDuplicateEntry(newItems);
        EDGE_RAGThresholdTriggerHelper.updateRecordType(newItems, null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //EDGE_RAGThresholdTriggerHelper.checkDuplicateEntry(newItems.values());
        EDGE_RAGThresholdTriggerHelper.updateRecordType(newItems.values(), oldItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_RAGThresholdTriggerHelper.checkAndGenerateSharing(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_RAGThresholdTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}