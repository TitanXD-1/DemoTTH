/**
 * Name: CallTriggerHandler
 * Purpose: Trigger Handler Class for OutletTerritoryTrigger
 * History                                                            
 * VERSION    AUTHOR            DATE              DETAIL
 * 1.0      Anuja              18/03/2019        Initial Development 

 * 2.0 		Anand U 		   11/01/2022		 ES20-11921
 * 2.1		Rajarshi Lahiri	   27/05/2022		 ES20-12717(Added check to prevent re invoking of all methods in After Update when call records are updated)
 * 3.0		Sudipta Nandy		21/09/2023		 US-3346766 -- Adding Map of Olditems in the afterUpdate 
**/
public with sharing class CallTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CallTrigger';
    public static Boolean triggerDisabledPopulated = false;
    public static Boolean firstRun=False;
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabledPopulated){
        	triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
            triggerDisabledPopulated = true;
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_CallTriggerHelper.updateCallDurationCompliance(newItems,null);
        
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_CallTriggerHelper.updateCallDurationCompliance(newItems.values(),oldItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler // US-3346766 -- Adding null for OldItem
    public void afterInsert(Map<Id, SObject> newItems) { 

            EDGE_CallTriggerHelper.getKPIsTypeRoleCallMap(newItems,null);

            EDGE_CallTriggerExtendedHelper.calculateDaysinTrade(newItems,null);
            EDGE_CallTriggerHelper.calculateCallPerDay(newItems.values(),null);  
            EDGE_CallTriggerHelper.updateLastVisit(newItems,null,false);         
            EDGE_CallTriggerHelper.updateCallAndVistCompliance(newItems,null);
            //ES20-8250
        	EDGE_CallTriggerHelper.updateVirtualCallCount(newItems,null);
        
    }
    
    //After Update Trigger Handler // US-3346766 -- Adding Map of Olditems in the afterUpdate
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        if(!firstRun){
            EDGE_CallTriggerHelper.getKPIsTypeRoleCallMap(newItems,oldItems);

            EDGE_CallTriggerExtendedHelper.calculateDaysinTrade(newItems,oldItems);
            EDGE_CallTriggerHelper.calculateCallPerDay(newItems.values(), oldItems);
            EDGE_CallTriggerHelper.updateLastVisit(newItems,oldItems,true);       
            EDGE_CallTriggerHelper.updateCallAndVistCompliance(newItems,oldItems);
            //ES20-8250
        	EDGE_CallTriggerHelper.updateVirtualCallCount(newItems,oldItems);
        }
            
        
    }
    
    //After Delete Trigger Handler 
    public void afterDelete(Map<Id, SObject> oldItems) {
    	EDGE_CallTriggerHelper.updateCallComplianceOnDelete(oldItems); 
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
        
    }
}