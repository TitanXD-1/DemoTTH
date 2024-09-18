/*
 * Class Name : SalesOrganisationTriggerHandler
 * @description: This is Sales Organisation Trigger Handler
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  		19/05/2021        Initial Development
*/

public with sharing class SalesOrganisationTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'SalesOrganisationTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
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
        EDGE_SalesOrganisationTriggerHelper.checkAndGenerateSharing(newItems.values()); 
        EDGE_SalesOrganisationTriggerHelper.createSalesOrgPublicGroup(newItems);
        PNR_SalesOrganizationTriggerHelper.createPublicGroup(newItems);
        PNR_SalesOrganizationTriggerHelper.shareSalesOrgs(newItems, null);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_SalesOrganisationTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
        EDGE_SalesOrganisationTriggerHelper.createSalesOrgPublicGroup(newItems); 
        PNR_SalesOrganizationTriggerHelper.shareSalesOrgs(newItems, oldItems);      
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        EDGE_SalesOrganisationTriggerHelper.deleteSalesOrgPublicGroup(oldItems);
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}