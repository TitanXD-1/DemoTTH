/*
 * @Name: AccrualItemTriggerHandler
 * @Description: This is the Handler class for AccrualItemTrigger
 * @History                                                            
 *                                                       
 * VERSION    		AUTHOR       		DATE                DETAIL
 *  1.0     		Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country     
*/ 

public class AccrualItemTriggerHandler implements TriggerHandler {
	public static Boolean triggerDisabled = false;
    public static string triggerName = 'AccrualItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
   public Boolean isDisabled(){     
        if(!triggerDisabled){
           triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
       }
        return triggerDisabled;
    }
   
    //before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        ECM_AccrualItemTriggerHelper.populatecurrency(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
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