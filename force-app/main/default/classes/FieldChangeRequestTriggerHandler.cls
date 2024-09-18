/**
* @description FieldChangeRequestTriggerHandler
* @Purpose Trigger Handler Class for Field Change Request
* @history
                    
VERSION     AUTHOR            DATE              DETAIL
1.0      Sandeep Sahoo     30/04/2019        Initial Development  
1.1     Sandip Ghosh       25/02/2022        ES20-11303
1.2.	Swaraj Samanta		27/09/2022		ES20-12995
**/

public with sharing class FieldChangeRequestTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'FieldChangeRequestTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {  
       
    	EDGE_FieldChangeRequestTriggerHelper.changeOwnerOfFCR(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_FieldChangeRequestTriggerHelper.checkAndGenerateSharing(newItems.values());
        //ES20-11303
       	if(!System.isBatch()){
        	EDGE_AsyncLookupFieldPopulator asyncLookupPoulator = new EDGE_AsyncLookupFieldPopulator(newItems.values());
            System.enqueueJob(asyncLookupPoulator);
        }
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {        
       
        EDGE_FieldChangeRequestTriggerHelper.approveFieldUpdateRequests(newItems.values(),oldItems,true); 
        EDGE_FieldChangeRequestTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
        EDGE_FieldChangeRequestTriggerHelper.sendPushNotificationForApprovedRejectedFCR(newItems.values(),oldItems);//ES20-12995

    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}