/**********************************************************************
  Name: TemplateWeighingTriggerHandler
=======================================================================
  Purpose: This is to handle TemplateWeighingTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR             DATE               DETAIL
    1.0       Saurav Paul        17/05/2019         ES20-1324
***********************************************************************/
public with sharing class TemplateWeighingTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'TemplateWeighingTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_TemplateWeighingTriggerHelper.validateDuplicateRecord(newItems,false,null);               
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_TemplateWeighingTriggerHelper.validateDuplicateRecord(newItems.values(),true,oldItems);   
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {        
        
    }    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //After Delete Trigger Handler    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            

    }
}