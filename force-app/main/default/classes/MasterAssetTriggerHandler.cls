/**

* @description :  MasterAssetTriggerHandler

* @purpose : Trigger Handler Class for MasterAssetTrigger

* @history :

* Version   Developer         Date         User Story/Purpose

*  1.1     Dinesh Sharma     26/07/2021     Initial Development
*  1.2     Joshraj Sen       12/11/2021     ES20-11439


*/
public with sharing class MasterAssetTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'MasterAssetTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
         EDGE_MasterAssetTriggerHelper.hasPriorityActive(newItems,null);
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_MasterAssetTriggerHelper.hasPriorityActive(newItems.values(),oldItems);


        EDGE_MasterAssetTriggerHelper.hasPendingForBatchActive(newItems.values(),oldItems);
         
        


    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_MasterAssetTriggerHelper.checkAndGenerateSharing(newItems.values()); 
       
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_MasterAssetTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);  
       
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
        
    }
}