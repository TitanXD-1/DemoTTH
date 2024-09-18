/*
 * Class Name : ECM_ApprovalLogTriggerHandler
 * @description: Class with all handler methods of ECM_ApprovalLogTrigger.
 * @history
 * AUTHOR           		 DATE              	DETAIL
 * Manikandan.T         	17/05/2022      	ECM-5586 : Initial Development
*/
public with sharing class ECM_ApprovalLogTriggerHandler implements TriggerHandler {
    
     public static Boolean triggerDisabled = false;
    public static string triggerName = 'ApprovalLogTrigger';
    public static Boolean isFirstTime = true;
    
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
        ECM_ApprovalLogTriggerHelper.ApprovalResponseHandler(newItems,oldItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
          ECM_ApprovalLogTriggerHelper.afterUpdateContractList(); //added as part of ECM-6450
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            
        
    }


}