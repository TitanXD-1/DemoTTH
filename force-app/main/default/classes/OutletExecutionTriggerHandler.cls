/**********************************************************************
  Name: OutletExecutionTriggerHandler
=======================================================================
  Purpose: This is to handle OutletExecutionTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Sagar Barman   01/04/2019      Initial Development
	1.1		 Saurav Paul	19/04/2019		ES20-128
***********************************************************************/
public with sharing class OutletExecutionTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletExecutionTrigger';
    
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
    	EDGE_OutletExecutionTriggerHelper.createMarketAssortmentProduct(newItems);	
        EDGE_OutletExecutionTriggerHelper.createOpportunity(newItems, null, false);   
    }    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	EDGE_OutletExecutionTriggerHelper.closeOpportunity(newItems, oldItems);
        EDGE_OutletExecutionTriggerHelper.createOpportunity(newItems, oldItems, false);
    }
    
    //After Delete Trigger Handler    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            

    }
}