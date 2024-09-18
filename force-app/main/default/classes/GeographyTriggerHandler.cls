/**********************************************************************
    Name: GeographyTriggerHandler
=======================================================================
    Purpose: Trigger Handler Class for Geography__c
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      Dipanjan Das      06/02/2019        Initial Development
2.0      Preyanka Ghosh    14/05/2019        ES20-1613 Custom Sharing - Geographies to Public Groups
3.0		 Saurav Pal		   02/12/2020		 NCP-1262 Implementing Sharing for D1
***********************************************************************/

public with sharing class GeographyTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'GeographyTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {    
         EDGE_GeographyTriggerHelper.globalTypeValidation(newItems);      
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_GeographyTriggerHelper.deleteGroupAsMember(oldItems);
        EDGE_GeographyTriggerHelper.removeOldQueue(oldItems.values());
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_GeographyTriggerHelper.updateCountryWeightage(newItems.Values());
        EDGE_GeographyTriggerHelper.createUpdatePublicGroup(newItems, null);
        EDGE_GeographyTriggerHelper.assignGroupAsMember(newItems, null);
        EDGE_GeographyTriggerHelper.createNewQueue(newItems.Values());
        D1_GeographySharing.createGroup(newItems,null,true);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_GeographyTriggerHelper.updateCountryWeightage(newItems.Values());
        EDGE_GeographyTriggerHelper.createUpdatePublicGroup(newItems, oldItems); 
        EDGE_GeographyTriggerHelper.assignGroupAsMember(newItems, oldItems);
        D1_GeographySharing.createGroup(newItems,oldItems,false);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}