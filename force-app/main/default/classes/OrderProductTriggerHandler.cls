/**


*@ description : OrderTriggerHandler - Trigger Handler Class for Order_Item__c


*@ History                                                            
1.0         Sagar Kumar Barman    20/07/2019  

**/

public with sharing class OrderProductTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OrderProductTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    public void beforeInsert(List<SObject> newItems){
        EDGE_UtilityClass.populateGUID(newItems);
        
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       	EDGE_OrderProductTriggerHelper.updateStockAllocation(newItems.values() ,oldItems);
        
    }
    
    //Before Delete Trigsger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {        
        EDGE_OrderProductTriggerHelper.updateParentOrderStatus(newItems,oldItems);


        
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}