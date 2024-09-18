/**
 * @name CartItemTriggerHandler
 * @description Trigger Handler Class for CartItem
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0      Darshi Arpitha   28/12/2020          NCP-1485     
 * 2.0
 **/
public without sharing class CartItemTriggerHandler implements TriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CartItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        CartItemTriggerHelper.updateOrdersplit(newItems);
        
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
        CartItemTriggerHelper.updateCartOrderSplit(newItems);
        //CartItemTriggerHelper.afterInsertCartItem(newItems);        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        CartItemTriggerHelper.deleteCartOrderSplit(oldItems);
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
}