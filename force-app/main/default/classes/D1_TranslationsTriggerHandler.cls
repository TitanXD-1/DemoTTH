/**
 * @name: D1_TranslationsTriggerHandler
 * @description: Trigger Handler Class for D1_TranslationsTrigger
 * @history
 * VERSION      AUTHOR              DATE            DETAIL
 * 1.0          Gaurav Singh      18/04/2022        Initial Development
 **/
public with sharing class D1_TranslationsTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'D1_TranslationsTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        D1_TranslationsTriggerHelper.validatePreferredLanguage(newItems);
    }

    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        D1_TranslationsTriggerHelper.validatePreferredLanguage(newItems.values());
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
}