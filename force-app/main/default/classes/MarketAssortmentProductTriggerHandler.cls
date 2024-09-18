/**

* @description :  MarketAssortmentProductTriggerHandler

* @purpose : This is to handle MarketAssortmentProductTrigger

* Version   Developer          Date          User Story/Purpose

* 1.1       Sagar Barman     24/04/2019      Initial Development
* 1.2       Sayan Samaddar   26/04/2021		 NCP-2680
* 1.3       Aparajita        31/08/2021      ES20-10916 - populateProductNameMAP

*/

public with sharing class MarketAssortmentProductTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'MarketAssortmentProductTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {        
        EDGE_UtilityClass.populateGUID(newItems);
        
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_SharingUtil.deleteProductSharing(oldItems.values());   
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {  
        EDGE_MAPTriggerHelper.populateProductNameMAP(newItems.values(), null); //ES20-10916
        EDGE_MAPTriggerHelper.checkAndGenerateSharing(newItems.values());
        EDGE_MAPTriggerHelper.checkAndGenerateD1Sharing(newItems.values());
        
    }    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_MAPTriggerHelper.populateProductNameMAP(newItems.values(), oldItems); //ES20-10916
        EDGE_MAPTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);   
        EDGE_MAPTriggerHelper.validateAndReGenerateD1Sharing(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            
        
    }
}