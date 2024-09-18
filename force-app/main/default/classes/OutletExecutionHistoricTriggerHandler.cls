/**********************************************************************
  Name: OutletExecutionHistoricTriggerHandler
=======================================================================
  Purpose: Trigger Handler Class for OutletExecutionHistoricTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION    AUTHOR                   DATE              DETAIL
     1.0       Anuja Chattopadhyay       12/06/2019        Initial Development 
     1.1       Shaunak Bhattacharjee    02/12/2019        CR 1396 - After Update Trigger
***********************************************************************/
public with sharing class OutletExecutionHistoricTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletExecutionHistoricTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
    EDGE_OutletExHistoricTriggerHelper.updateContract(newItems);    
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
     EDGE_OutletExHistoricTriggerHelper.updateUoSErntOnContract(newItems.values());            
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    //CR 1396 -- Shaunak Bhattacharjee
      EDGE_OutletExHistoricTriggerHelper.updateUoSErntOnContract(newItems.values());  
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
    }
}