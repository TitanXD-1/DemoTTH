/*
 * Class Name : CSTClaimItemTriggerHandler
 * @description: This is to handle CST Claim Item Events 
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        Sayan Mullick   		19/05/2021        Initial Development
*/

public with sharing class CSTClaimItemTriggerHandler implements TriggerHandler{
// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CSTClaimItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
            EDGE_CSTClaimItemTriggerHelper.updateCurrencyFromClaim(newItems);       
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
      // EDGE_CSTClaimItemTriggerHelper.updateCurrencyFromClaim(newItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
         EDGE_CSTClaimItemTriggerHelper.deletiononOnApproveRejectStatus(oldItems.values());
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
           
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}