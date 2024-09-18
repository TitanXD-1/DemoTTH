/*
 * @Name: RoleAgreementTriggerHandler
 * @Description: This is the Handler class for RoleAgreementTrigger
 * @History                                                            
 *                                                       
 * VERSION    AUTHOR       DATE                 DETAIL
 *  1.0     Pratap Sen  13-09-2021  Initial Development for ECM-4416
*/ 

public class RoleAgreementTriggerHandler implements TriggerHandler {
	public static Boolean triggerDisabled = false;
    public static string triggerName = 'RoleAgreementTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
           triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
       }
        return triggerDisabled;
    }
   
    //before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        ECM_RoleAgreementTriggerHelper.RoleAgreementDuplicateCheck(newItems,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        ECM_RoleAgreementTriggerHelper.RoleAgreementDuplicateCheck(newItems.values(),oldItems);
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