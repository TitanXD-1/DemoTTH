/**********************************************************************
Name: MarketProduct2TriggerHandler
======================================================
Purpose: TriggerHandler for Market_Product2__c
======================================================
History
-------
VERSION     AUTHOR         DATE       DETAIL
1.0         Ajay                    Initial Development (NCP-2857)
***********************************************************************/
public with sharing class MarketProduct2TriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction	
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'MarketProduct2Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        if(!triggerDisabled){	
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);	
        }
        
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
        D1_MarketProduct2TriggerHelper.checkAndGenerateSharing(newItems.values());
        D1_MarketProduct2TriggerHelper.checkAndGenerateD1Sharing(newItems.values());
    }

    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        D1_MarketProduct2TriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
        D1_MarketProduct2TriggerHelper.validateAndReGenerateD1Sharing(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            

    }
}