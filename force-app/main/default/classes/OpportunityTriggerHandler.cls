/*
    @Name: OpportunityTriggerHandler
    @Purpose: Trigger Handler Class for Opportunity 
    @History                                                            
                                                               
    VERSION     AUTHOR            DATE              DETAIL
       1.0      Sagar Barman     23-Apr-2019        Initial Development
	   2.0		Kapil Baliyan	 17-02-2020			ES20-7040
	   3.0		Sudipta Nandy	 07-08-2023			US-3280049 -- After Insert, added IsBatch condition
	   4.0		Shivam Chauhan	 08/06/2024			155299	
*/
public class OpportunityTriggerHandler implements TriggerHandler{
	 // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OpportunityTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
    	EDGE_UtilityClass.populateGUID(newItems);
        EDGE_OpportunityTriggerHelper.updateUserFields(newItems);
        EDGE_OpportunityTriggerHelper.createOpportunities(newItems,null);//155299
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	//EDGE_UtilityClass.populateGUID(newItems);
    	EDGE_OpportunityTriggerHelper.changeOwner(newItems.values());
    	EDGE_OpportunityTriggerHelper.updateUserFields(newItems.values());
        EDGE_OpportunityTriggerHelper.createOpportunities(newItems.values(),oldItems.values());//155299
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        /*US-3280049 -- After Insert, added IsBatch condition */ if(!System.isBatch()){
        EDGE_OpportunityTriggerHelper.autoPopulateAssignedTo(newItems.values());
        }
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