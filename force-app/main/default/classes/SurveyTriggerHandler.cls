/**********************************************************************
  Name: SurveyTriggerHandler
=======================================================================
  Purpose: Trigger Handler Class for SurveyTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0       Monalisa Halder   05/04/2019        Initial Development
***********************************************************************/
public with sharing class SurveyTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'SurveyTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);   
        
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_SurveyTriggerHelper.checkAndGenerateSharing(newItems.values());              
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_SurveyTriggerHelper.surveyFreqChange(newItems,oldItems);
        EDGE_SurveyTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
        
    }
}