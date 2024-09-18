/**********************************************************************
* @Name: OutletTerritoryTriggerHandler

* @Purpose: Trigger Handler Class for OutletTerritoryTrigger

* @History                                                            
                                                               
*  @VERSION    AUTHOR            DATE              DETAIL
*    1.0      Sagar Barman    12/02/2019        Initial Development
*    1.1      Saurav Paul	  8th-Mar-2019		Country Validation
**/
public with sharing class OutletTerritoryTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletTerritoryTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_OutletTerritoryTriggerHelper.validateOutletAssignmentsOnInsert(newItems);    
        //Calling validate Country
        EDGE_OutletTerritoryTriggerHelper.validateCountry(false,newItems, null);    
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    	//Calling validate Country
        EDGE_OutletTerritoryTriggerHelper.validateCountry(true,newItems.values(), oldItems); 
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