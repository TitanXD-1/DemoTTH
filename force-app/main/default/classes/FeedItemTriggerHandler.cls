/**

* @description : FeedItemTriggerHandler

* @purpose : Trigger Handler Class for FeedItemTrigger

* @history  :                                                          

* Version    Author         Date         Purpose
*  1.0    Sandip Ghosh   19/08/2020      Initial Development(ES20-8463)
*  2.0    Swagat Shaw    09/03/2023      CUS-115
*/

public class FeedItemTriggerHandler implements TriggerHandler{
    
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'FeedItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_FeedItemTriggerHelper.insertingChatterPostOnClaim(newItems);
        EDGE_FeedItemTriggerHelper.preventPostingOnFeedCaseClosed(newItems);//CUS-115

		
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_FeedItemTriggerHelper.deleteingOrEditingChatterPostOnClaim(newItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        //EDGE_FeedItemTriggerHelper.unCheckOperatorNotesPresent(oldItems);
        EDGE_FeedItemTriggerHelper.deleteingOrEditingChatterPostOnClaim(oldItems);
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
    	EDGE_FeedItemTriggerHelper.markOperatorNotesPresent(newItems);
        EDGE_FeedItemTriggerHelper.sendPushNotification(newItems);
        EDGE_CaseFeedtoCaseCommentTriggerHelper.convertCaseFeedtoComments(newItems);
        EDGE_FeedItemTriggerHelper.sendCustomerCasePushNotification(newItems); //144402
        D1_FeedItemTriggerHelper.sendNotificationToCaseCreater(newItems);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
         EDGE_FeedItemTriggerHelper.sendPushNotification(newItems);   
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        EDGE_FeedItemTriggerHelper.unCheckOperatorNotesPresent(oldItems);
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
    }

}