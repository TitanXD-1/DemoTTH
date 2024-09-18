/**********************************************************************
  Name: MarketCycleTriggerHandler
=======================================================================
  Purpose: Trigger Handler Class for MarketCycleTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION    AUTHOR                   DATE              DETAIL
     1.0       Anuja Chattopadhyay      03/04/2019        Initial Development And Populate GUID Value
***********************************************************************/
public with sharing class MarketCycleTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'MarketCycleTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
      EDGE_MarketCycleTriggerHelper.checkMarketCycleOverlap(newItems,null);
      EDGE_MarketCycleTriggerHelper.calculateMarketCycleWeek(newItems,null);
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
      EDGE_MarketCycleTriggerHelper.checkMarketCycleOverlap(newItems.values(), oldItems);
      EDGE_MarketCycleTriggerHelper.calculateMarketCycleWeek(newItems.values(), oldItems);  
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_MarketCycleTriggerHelper.checkAndGenerateSharing(newItems.values());             
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_MarketCycleTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);    
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
    }
}