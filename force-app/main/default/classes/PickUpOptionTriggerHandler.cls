/**
* @Name: PickUpOptionTriggerHandler

* @Purpose: Trigger Handler Class for PickUpOptionTrigger

* @History                                                            
                                                           
* @VERSION    AUTHOR            DATE              DETAIL
* @1.0       Saurav Paul       25/03/2019        Initial Development And Populate GUID Value
* @1.1		 Sayan Mullick	   15/12/2021		 Added Pickup Option sharing on the basis of Sales Organisation -CST-162
*/
public with sharing class PickUpOptionTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'PickUpOptionTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_PickupOptionTriggerHelper.insertNameField(newItems);
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_PickupOptionTriggerHelper.markforDeletion(newItems.values(),oldItems);
        EDGE_PickupOptionTriggerHelper.updateNameField(newItems.values(),oldItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_PickupOptionTriggerHelper.checkAndGenerateSharing(newItems.values());
        EDGE_PickupOptionTriggerHelper.checkAndGenerateSharingfromSalesOrg(newItems.values());//CST-162        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_PickupOptionTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
        EDGE_PickupOptionTriggerHelper.validateAndReGenerateSharingfromSalesOrg(newItems.values(), oldItems);//CST-162
        EDGE_PickupOptionTriggerHelper.reCalcKPIAchievements(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}