/**
 * @name : PartnerFunctionHandler
 * @description : Trigger Handler Class for Partner Function
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          -               -               Initial Development
 * 2.0          Kapil Baliyan   09/08/2023      143347
 */

public with sharing class PartnerFunctionHandler implements TriggerHandler{
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'PartnerFunctionTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems){
        EDGE_PartnerFunctionTriggerHelper.updateSalesArea(newItems, null);//Added for NCP-2278
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        EDGE_PartnerFunctionTriggerHelper.updateSalesArea(newItems.values(), oldItems);//Added for NCP-2278
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems){
        EDGE_PartnerFunctionTriggerHelper.updateShipToAccounts(newItems,null);  
        //EDGE_PartnerFunctionTriggerHelper.d1CheckDirectAccount(newItems,null); //Commeted because this is no more relevant (143347)  
        //EDGE_PartnerFunctionTriggerHelper.updateCustomerAndSoldToAccountsPF(newItems.values(), null);//NCP-3024,NCP-3488 //Commented by KB because code is merged with updateAccountsType
        EDGE_PartnerFunctionTriggerHelper.updateAccountsType(newItems, null);
        EDGE_PartnerFunctionTriggerHelper.createContactPointAddress(newItems,null);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        EDGE_PartnerFunctionTriggerHelper.updateShipToAccounts(newItems, oldItems);
        //EDGE_PartnerFunctionTriggerHelper.updateCustomerAndSoldToAccountsPF(newItems.values(), oldItems);//NCP-3024,NCP-3488 //Commented by KB because code is merged with updateAccountsType
        EDGE_PartnerFunctionTriggerHelper.updateAccountsType(newItems, oldItems);
        EDGE_PartnerFunctionTriggerHelper.createContactPointAddress(newItems, oldItems);
        EDGE_PartnerFunctionTriggerHelper.handleItemProposalUpdate(newItems, oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        EDGE_PartnerFunctionTriggerHelper.updateCustomerInfoAccountsPFDelete(oldItems);//NCP-3488
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
    
}