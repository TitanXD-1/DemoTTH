/**********************************************************************
Name: Product2TriggerHandler
=======================================================================
Purpose: Trigger Handler Class for Product2
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0         Kapil Baliyan     16/12/2020        NCP-1403
1.1       	Mukesh Kanth      09/02/2021        NCP-1942
2           Ajay              25/05/2021        NCP-3357(setupProductCategory)
***********************************************************************/
public with sharing class Product2TriggerHandler implements TriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Product2Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){   
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
    	D1_Product2TriggerHandler.updateProductCardTitle(newItems,null); 
        D1_Product2TriggerHandler.setProductHierarchies(newItems); //NCP-2259
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	D1_Product2TriggerHandler.updateProductCardTitle(newItems.values(), oldItems); 	
        D1_Product2TriggerHandler.setProductHierarchies(newItems.values()); //NCP-2259
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
          
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        D1_Product2TriggerHandler.setupProductCategory(newItems.values(), null);        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id,SObject> newItems, Map<Id, SObject> oldItems) {
        D1_Product2TriggerHandler.setupProductCategory(newItems.values(), oldItems); 
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}