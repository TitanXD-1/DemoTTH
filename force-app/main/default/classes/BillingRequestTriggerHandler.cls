/*
@name BillingRequestTriggerHandler

@description Trigger Handler Class for Billing_Request__c

@history                                                            

VERSION     AUTHOR               DATE              DETAIL
1.0         Sukanya Chatterjee   7/10/2021         ES20-10979

*/
public class BillingRequestTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'BillingRequestTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    public void beforeInsert(List<SObject> newItems){
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_BillingRequestTriggerHelper.checkdelrecords(oldItems);
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