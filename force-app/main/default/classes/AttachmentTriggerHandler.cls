public class AttachmentTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;	
    public static string triggerName = 'AttachmentTrigger';
    // Checks to see if the trigger has been disabled either by custom setting or by code	
    public Boolean isDisabled(){     	
        if(!triggerDisabled){	
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);	
        }	
        
        return triggerDisabled;	
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {}
    
    //Before Update Trigger Handler	
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    //Before Delete Trigger Handler	
    public void beforeDelete(Map<Id, SObject> oldItems) {
        PNR_AttachmentTriggerHelper.beforeDelete(oldItems.values());//PION-1715 change;
    }
    
    //After Insert Trigger Handler	
    public void afterInsert(Map<Id, SObject> newItems) {}
    
    //After Update Trigger Handler	
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    //After Delete Trigger Handler	
    public void afterDelete(Map<Id, SObject> oldItems) {}
    
    //After Undelete Trigger Handler	
    public void afterUndelete(Map<Id, SObject> oldItems) {}	
    
}