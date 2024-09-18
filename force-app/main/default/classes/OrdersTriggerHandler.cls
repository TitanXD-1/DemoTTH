/**
 * @name: OrdersTriggerHandler
 * @description: Order Trigger Handler
 * @history
 * VERSION     AUTHOR         DATE          DETAIL
 * 1.0     Kapil,Sai Kumar    2021-10-19    NCP-3363
 * 
 **/
public with sharing class OrdersTriggerHandler implements TriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OrdersTrigger';

    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }

    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems){
        D1_OrdersTriggerHelper.validateNumberOfOrders(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

    }
    
    //Before Delete Trigsger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        
    }

    //After Update Trigger Handler
    public void afterUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems) {

    }

    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}