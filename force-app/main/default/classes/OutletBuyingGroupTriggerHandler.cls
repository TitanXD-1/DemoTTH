/**********************************************************************
Name: OutletBuyingGroupTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for Outlet_Buying_Group__c
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR             DATE              DETAIL
1.0         Shahbaz Khan     8/7/2020           
***********************************************************************/
public with sharing class OutletBuyingGroupTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletBuyingGroupTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){   
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    public void beforeInsert(List<SObject> newItems){
        EDGE_UtilityClass.populateGUID(newItems);
       
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