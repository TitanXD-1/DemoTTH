/**
 * @name StockTriggerHandler
 * @description Trigger Handler for Stock Trigger
 * @History
 * VERSION      AUTHOR                  DATE            DETAIL
 * 1.0          Preyanka Ghosh          15/06/2019      Initial Development(ES20-2232)
 * 2.0          Prasanth T              28/02/2022      ES20-12144
 * 3.0          Prasanth T              20/10/2023      145869(dateValidationStock)
 * 4.0          Mukesh Kanth            11/02/2023      146144-BE_Allow ONLY unique POS Stock Allocation per Time Period per combination
 */
public with sharing class StockTriggerHandler implements TriggerHandler {
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'StockTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){ 
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }     
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_StockTriggerHelper.updateUniqueKey(newItems);
        EDGE_StockTriggerHelper.validateAllocation(newItems);
        EDGE_StockTriggerHelper.validateAllocationType(newItems);
        EDGE_StockTriggerHelper.areaMandatoryBasedOnMarket(newItems);
        EDGE_StockTriggerHelper.populateProductField(newItems,null);
        EDGE_StockTriggerHelper.dateValidationStock(newItems,null); //145869
        EDGE_StockTriggerHelper.validateStockAllocationTimePeriod(newItems,null); //146144
        
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //EDGE_StockTriggerHelper.validateAllocation(newItems.values());
        //EDGE_StockTriggerHelper.validateAllocationType(newItems.values());
        EDGE_StockTriggerHelper.areaMandatoryBasedOnMarket(newItems.values());
        EDGE_StockTriggerHelper.populateProductField(newItems.values(),oldItems);
        EDGE_StockTriggerHelper.dateValidationStock(newItems.values(),oldItems); //145869
        EDGE_StockTriggerHelper.validateStockAllocationTimePeriod(newItems.values(),oldItems); //146144
    
    }
    
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
          
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_StockTriggerHelper.checkAndGenerateSharing(newItems.values());
        EDGE_StockTriggerHelper.checkAndGenerateD1Sharing(newItems.values());
        EDGE_StockTriggerHelper.updateWarehouseStock(newItems.values(),null);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_StockTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
        EDGE_StockTriggerHelper.updateWarehouseStock(newItems.values(),oldItems);
        
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}