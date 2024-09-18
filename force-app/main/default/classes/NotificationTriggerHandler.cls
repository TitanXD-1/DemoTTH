/**
	Name: NotificationTriggerHandler
	Purpose: This is to handle NotificationTrigger
    History                                                                                                                      
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Shahbaz Khan     16/03/2020        Initial Development
	2.0		 Sayan			  17/06/2021		NCP-3195
    3.0      Narayana         22/04/2022        NCP-6450
**/

public class NotificationTriggerHandler implements TriggerHandler{
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'NotificationTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
        	triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);    
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_NotificationTriggerHelper.checkOverlappingNotification(newItems, null); //NCP-3195
        D1_NotificationTriggerHelper.validatePreferredLanguage(newItems);//NCP-6450
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_NotificationTriggerHelper.checkOverlappingNotification(newItems.values(), oldItems); //NCP-3195
        D1_NotificationTriggerHelper.validatePreferredLanguage(newItems.values());//NCP-6450
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_NotificationTriggerHelper.checkAndGenerateSharing(newItems.values());
        EDGE_NotificationTriggerHelper.checkAndGenerateD1Sharing(newItems.values()); //NCP-3195
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_NotificationTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
        EDGE_NotificationTriggerHelper.validateAndReGenerateD1Sharing(newItems.values(), oldItems); //NCP-3195
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }

}