/*
* @description : Test Class for Agreement Approval Trigger
* @history:
* VERSION    AUTHOR                             DATE              DETAIL
* 1.1        Anuja Chattopadhyay                13/08/2021        Initial Developement 
*/
public class AgreementApprovalTriggerHandler implements TriggerHandler{
// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'AgreementApprovalTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){   
           
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
   
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
      	ECM_AgreementApprovalTriggerHelper.salesDriverItemExtraApprovalValidation(newItems,null);  
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	ECM_AgreementApprovalTriggerHelper.salesDriverItemExtraApprovalValidation(newItems.values(),oldItems);
      
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