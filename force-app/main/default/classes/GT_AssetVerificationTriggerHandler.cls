/**
* @Name: GT_AssetVerificationTriggerHandler
* @Purpose: Handler for GT_AssetVerificationTrigger on GT_Asset_Verification__c object
* @Test Class: GT_AssetVerificationTriggerHelperTest
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     26/07/2023  140748 : [GT-134] Asset Verification Automations
*/

public class GT_AssetVerificationTriggerHandler implements TriggerHandler {
    
    public static Boolean isDisabled = false;
    public static String triggerName = 'GT_AssetVerificationTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled() {        
        isDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return isDisabled;
    }
    
    // Before Insert Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void beforeInsert(List<SObject> newItems) {
        
    }
    
    // After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        GT_AssetVerificationTriggerHelper.updateAssetOnInsertOrUpdate(newItems.values(), null);
    }
    
    // Before Update Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    // After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        GT_AssetVerificationTriggerHelper.updateAssetOnInsertOrUpdate(newItems.values(), oldItems);
    }
    
    // Before Delete Trigger Handler   
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void beforeDelete(Map<Id, SObject> oldItems) {
       
    }   
   
    // After Delete Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    // After Undelete Trigger Handler    
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}