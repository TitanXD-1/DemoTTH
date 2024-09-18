/**
 
* @description : TradeTermBandDetailTriggerHandler 

* @purpose : Provide access to Trade_Term_Band_Detail__c

* @history

* Version   Developer        Date            User Story	          Purpose

1.0 -    Nidhi/Stuti         13/10/2023      146952 - Provide access to new Objects_Tech_SFDC
2.0 -    Nidhi/Stuti         14/11/2023      147559 - Currency of TT Band must match currency of the country
*/
public with sharing class TradeTermBandDetailTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'TradeTermBandDetailConfigurationTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        C360_TradeTermBandDetailTriggerHelper.updateTradeTermCurrency(newItems);
        System.debug(LoggingLevel.DEBUG, 'before insert');
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         System.debug(LoggingLevel.DEBUG, 'before update');
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.DEBUG, 'before delete');
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
       C360_TradeTermBandDetailTriggerHelper.checkAndGenerateSharing(newItems.values());              
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       C360_TradeTermBandDetailTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);  
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.DEBUG, 'after delete');
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.DEBUG, 'after undelete');
    }
}