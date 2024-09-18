/**
 * @name SalesOrderTriggerHandler
 * @description Trigger Handler Class for Sales Order
 * @History   
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Saurav Paul       23/12/2020        Initial Development
 * 2.0         Ajay              06/12/2021        SAP Order update validation(NCP-5366)
**/

public with sharing class SalesOrderTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'SalesOrderTrigger';

    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
    	
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {        
        D1_SalesOrderTriggerHelper.updateSalesOrderStatus(newItems.values()); 
        D1_SalesOrderTriggerHelper.validateSAPOrderUpdate(newItems.values(), oldItems); 
    } 
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        D1_SalesOrderTriggerHelper.updateOrderNumber(newItems.keySet());
        D1_SalesOrderTriggerHelper.updateFirstOrderEmailCheck(newItems); //NCP-6705
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