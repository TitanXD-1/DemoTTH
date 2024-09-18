/**********************************************************************
    Name: BonusAssignmentTriggerHandler
=======================================================================
    Purpose: Trigger Handler Class for BonusAssignmentTrigger
=======================================================================
    History                                                            
    -------                                                            
 VERSION      AUTHOR            DATE              DETAIL
  1.0       Vikas Anand      08-Jan-2020      Initial Development
***********************************************************************/
public with sharing class BonusAssignmentTriggerHandler implements TriggerHandler{
// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'BonusAssignmentTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_BonusAssignmentTriggerHelper.updateuniquekey(newItems);
        EDGE_BonusAssignmentTriggerHelper.validateBonusAssignment(newItems);
        EDGE_BonusAssignmentTriggerHelper.syncGlblAndTerrWtForHeader(newItems);
        //EDGE_BonusAssignmentTriggerHelper_Sruta.syncGlblAndTerrWtForHeader(newItems);
        
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_BonusAssignmentTriggerHelper.updateuniquekey(newItems.values());
        EDGE_BonusAssignmentTriggerHelper.validateBonusAssignment(newItems.values());
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_BonusAssignmentTriggerHelper.validateBonusAssignment(oldItems.values());
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_BonusAssignmentTriggerHelper.updateGlblAndTerrWtFrmDetails(newItems.values(), null);
       //EDGE_BonusAssignmentTriggerHelper_Sruta.updateGlblAndTerrWtFrmDetails(newItems.values(), null);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_BonusAssignmentTriggerHelper.updateGlblAndTerrWtFrmDetails(newItems.values(), oldItems);
        //EDGE_BonusAssignmentTriggerHelper_Sruta.updateGlblAndTerrWtFrmDetails(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}