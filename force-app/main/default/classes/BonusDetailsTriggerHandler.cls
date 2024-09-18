/**********************************************************************
 Name: BonusDetailsTriggerHandler
=======================================================================
 Purpose: Trigger Handler Class for BonusDetailTrigger
=======================================================================
 History                                                            
 -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  1.0       Sandip Ghosh      08-Jan-2020      Initial Development(ES20-4995)
***********************************************************************/
public class BonusDetailsTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'BonusDetailsTrigger';
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_BonusDetailsTriggerHelper.validateBonusDetailRecord(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         EDGE_BonusDetailsTriggerHelper.validateBonusDetailRecord(newItems.values());
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItemsMap) {
    	EDGE_BonusDetailsTriggerHelper.createBonusAssignments(newItemsMap);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       EDGE_BonusDetailsTriggerHelper.updateBonusAssignments(newItems, oldItems); //moved to after
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_BonusDetailsTriggerHelper.validateBonusDetailRecord(oldItems.values());
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
        
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }

}