/**
 * @name MarketSettingTriggerHandler
 * @description Trigger Handler for Market Setting Trigger
 * @History
 * VERSION          AUTHOR                      DATE                DETAIL
 * 1.0              Aniket Sen                  30/06/2020          Initial Development
 * 2.0              Mukesh Kant                 17/10/2023          145867(validatePosOrderLimit)
 */
public with sharing class MarketSettingTriggerHandler implements TriggerHandler {
	
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'MarketSettingTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        if(Test.isRunningTest()==true){
            triggerDisabled = false;
        }
        return triggerDisabled;
    }

    public void beforeInsert(List<SObject> newItems) {
        EDGE_MarketSettingTriggerHelper.validatePosOrderLimit(newItems,null); //Added for 145867
    }

    public void afterInsert(Map<Id, SObject> newItems){
        
    }

    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        EDGE_MarketSettingTriggerHelper.validatePosOrderLimit(newItems.values(),oldItems); //Added for 145867
    }

    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_MarketSettingTriggerHelper.trackHistory(newItems,oldItems);    
    }

    public void beforeDelete(Map<Id, SObject> oldItems){
        
    }

    public void afterDelete(Map<Id, SObject> oldItems){
        
    }

    public void afterUndelete(Map<Id, SObject> oldItems){
        
    }
}