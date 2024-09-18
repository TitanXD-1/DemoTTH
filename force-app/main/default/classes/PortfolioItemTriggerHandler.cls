/**********************************************************************
Name: PortfolioItemTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for PortfolioItem
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      Darshi Arpitha     08/02/2021         NCP-1881
***********************************************************************/
public without sharing class PortfolioItemTriggerHandler implements TriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'PortfolioItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
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
    	
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
         D1_PortfolioItemTriggerHelper.updateEntitlementPolicy(newItems,null);
         D1_PortfolioItemTriggerHelper.createPricebookEntry(newItems,null);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       D1_PortfolioItemTriggerHelper.updateEntitlementPolicy(newItems,oldItems);
       D1_PortfolioItemTriggerHelper.createPricebookEntry(newItems,oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}