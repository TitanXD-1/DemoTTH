/**
 * @name D1TermsConditionsHandler
 * @purpose Trigger Handler Class for Terms and conditions
 * @history                                                                                                                        
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0      Praveen Mundinamani   27/01/2021        NCP-1583
**/
public without sharing class D1TermsConditionsHandler implements TriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'D1TermsAndConditionTrigger';
 
    /**
     * @description Checks to see if the trigger has been disabled either by custom setting or by code
     * @return  `Boolean`
     */    
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }

    /**
     * @description Before Insert Trigger Handler
     * @param newItems 
     */    
    public void beforeInsert(List<SObject> newItems) {
        D1_TermsAndConditionTriggerHelper.activateordraftJML(newItems,null);
    }

    /**
     * @description Before Update Trigger Handler
     * @param newItems 
     * @param oldItems 
     */    
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        D1_TermsAndConditionTriggerHelper.activateordraftJMLValidation(newItems.values(), oldItems);    	
    }

    /**
     * @description Before Delete Trigger Handler
     * @param oldItems 
     */    
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }

    /**
     * @description After Insert Trigger Handler
     * @param newItems 
     */    
    public void afterInsert(Map<Id, SObject> newItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }

    /**
     * @description After Update Trigger Handler
     * @param newItems 
     * @param oldItems 
     */    
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        D1_TermsAndConditionTriggerHelper.activateordraftJML(newItems.values(), oldItems);
    }

    /**
     * @description After Delete Trigger Handler
     * @param oldItems 
     */    
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }

    /**
     * @description After Undelete Trigger Handler
     * @param oldItems 
     */    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
}