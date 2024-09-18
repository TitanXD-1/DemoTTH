/**
* @Name: KPIAchivementTriggerHandler
* @Purpose: Trigger Handler Class for KPI Achivement Trigger
* @History                                                            
                                                              
* @VERSION     AUTHOR         DATE              DETAIL
*     1.0      Manikant P     29-Oct-2019       Initial Development   
**/

public with sharing class KPIAchivementTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'KPIAchivementTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
         EDGE_KPIAchivementTriggerHelper.populateKpiAchievementUniqueId(newItems);
        EDGE_KPIAchivementTriggerHelper.updateKpiAchievementCountry(newItems,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_KPIAchivementTriggerHelper.populateKpiAchievementUniqueId(newItems.values());
         EDGE_KPIAchivementTriggerHelper.updateKpiAchievementCountry(newItems.values(),oldItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_KPIAchivementTriggerHelper.checkAndGenerateSharing(newItems.values());
        EDGE_KPIAchivementTriggerHelper.populateActKPITarget(newItems.values(), null, false);
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_KPIAchivementTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
        EDGE_KPIAchivementTriggerHelper.populateActKPITarget(newItems.values(), oldItems, false);
        
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}