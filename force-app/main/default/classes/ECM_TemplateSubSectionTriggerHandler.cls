/**********************************************************************
Name: ECM_TemplateSubSectionTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for ECM_TemplateSubSectionTrigger
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0        Keshav         04/1/2021        Initial Development
***********************************************************************/
public class ECM_TemplateSubSectionTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_TemplateSubSectionTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }  
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
        ECM_TemplateSubSectionTriggerhelper.replaceText(newItems);
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        ECM_TemplateSubSectionTriggerhelper.checkAndGenerateSharing(newItems.values());         
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_TemplateSubSectionTriggerhelper.replaceText(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_TemplateSubSectionTriggerhelper.validateAndReGenerateSharing(newItems.values(), oldItems);   
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