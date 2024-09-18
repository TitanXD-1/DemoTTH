/*
@Name: CustomerRequestTriggerHandler

@Purpose: This class is a handler for CustomerRequestTrigger

@History                                                            
                                                          
VERSION    AUTHOR            	DATE              DETAIL
1.0        Venkatesh Varma      22-12-2022        Initial Development

*/
@SuppressWarnings ('PMD.EmptyStatementBlock')
public class CustomerRequestTriggerHandler implements TriggerHandler{
	// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CustomerRequestTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        CO_CustomerRequestTriggerHelper.checkMarketSpecificFields(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        CO_CustomerRequestTriggerHelper.checkMarketSpecificFieldsbeforeUpdate(oldItems, newItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        CO_CustomerRequestTriggerHelper.checkAndGenerateSharing(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        CO_CustomerRequestTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}