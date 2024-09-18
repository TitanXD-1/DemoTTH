/**********************************************************************
Name: FeedCommentTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for FeedCommentTrigger
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -    Amar Deep 	      10/02/2021      Initial Development(ES20-9704)
2.0     Swagat Shaw       10/03/2023      CUS-115
***********************************************************************/

public class FeedCommentTriggerHandler implements TriggerHandler{
    
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'FeedCommentTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_FeedCommentTriggerHelper.preventCommentOnFeedCaseClosed(newItems);//CUS-115
		
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_FeedCommentTriggerHelper.sendPushNotificationForComment(newItems);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_FeedCommentTriggerHelper.sendPushNotificationForComment(newItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
    }

}