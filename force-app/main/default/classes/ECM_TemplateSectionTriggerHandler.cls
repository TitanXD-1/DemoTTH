public class ECM_TemplateSectionTriggerHandler implements TriggerHandler {
    
     public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_TemplateSectionTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }

        
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
        ECM_TemplateSectionTriggerhelper.replaceText(newItems);
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        ECM_TemplateSectionTriggerhelper.checkAndGenerateSharing(newItems.values());         
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         ECM_TemplateSectionTriggerhelper.replaceText(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_TemplateSectionTriggerhelper.validateAndReGenerateSharing(newItems.values(), oldItems);   
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
    

}