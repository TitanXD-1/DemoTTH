/**********************************************************************
	Name: BatchApexErrorEventHandler
=======================================================================
	Purpose: This is to handle BatchApexErrorEvent
=======================================================================
	History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Kapil Baliyan	   29/12/2019		 Initial Development ES20-6594
***********************************************************************/
public with sharing class BatchApexErrorEventHandler implements TriggerHandler {
	
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'BatchApexErrorEventTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_BatchApexErrorEventHelper.handleBatchException(newItems);
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