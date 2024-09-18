/**
 * @name : SupplierOutletTriggerHandler
 * @description : Trigger Handler Class for Supplier Outlet
 * @history
 * VERSION      AUTHOR              DATE            DETAIL
 * 1.0          Saurav Paul         06/03/2019      Initial Development
 * 2.0          Monalisa Halder     13/11/2020      ES20-8662
 * 3.0          Monalisa Halder     01/02/2021      ES20-9212
 * 4.0          Vikash Chaudhary    20/09/2022      NCP-7326
 */

public with sharing class SupplierOutletTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'SupplierOutletTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){      
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_SupplierOutletTriggerHelper.checkPrimarySuppOutlt(newItems,null,false);
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_SupplierOutletTriggerHelper.syncPreferredWholesaler(null,newItems); // added ncp-7326
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_SupplierOutletTriggerHelper.checkPrimarySuppOutlt(newItems.values(),oldItems,true);
        EDGE_SupplierOutletTriggerHelper.validateFieldsPerFS(newItems,oldItems);      
        EDGE_SupplierOutletTriggerHelper.createFieldChangeRequest(newItems,oldItems); //for Approval process  
        EDGE_SupplierOutletTriggerHelper.syncPreferredWholesaler(oldItems,newItems.values()); //added ncp-7326
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
         
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_DistributorPersonRespBatchHelper.insertAccountTeamMember(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_SupplierOutletTriggerHelper.updateLastModMasterFld(newItems, oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        EDGE_SupplierOutletTriggerHelper.removePrimarySupplier(oldItems.values());
        EDGE_DistributorPersonRespBatchHelper.deleteAccountTeamMember(oldItems);
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
        
    }
}