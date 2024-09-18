/**********************************************************************
Name: BespokeTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for Bespoke__c
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR             DATE              DETAIL
1.0         Sandeep Sahoo      07/08/2019        ES20-3468  
***********************************************************************/

public with sharing class BespokeTriggerHandler implements TriggerHandler{
// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'BespokeTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    public void beforeInsert(List<SObject> newItems){
        EDGE_BespokeTriggerHelper.updateCountry(newItems);
        EDGE_BespokeTriggerHelper.updateUserFields(newItems);
        EDGE_BespokeTriggerHelper.autoPopulateDeliveryPartner(newItems);
        EDGE_UtilityClass.populateGUID(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       EDGE_BespokeTriggerHelper.updateBespokeStatus(newItems.values(),OldItems);
       EDGE_UtilityClass.populateGUID(newItems.values()); 
    }
    
    //Before Delete Trigsger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_BespokeTriggerHelper.sendEmailToDeliveryPartner(newItems.values());    
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}