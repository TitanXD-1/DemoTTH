/**	

 * @name : OutletStrategicFitTriggerHandler
 * @description : Trigger Handler Class for OutletStrategicFitTrigger
 * @history
 * VERSION      AUTHOR          	DATE            DETAIL
 * 1.0          Monalisa Halder    01/12/2023      148391 - Generate Unique ID in GUID field for each Strategic Fit object record
 * 2.0			Shivam Chauhan     11/12/2023      148432 - Validation checks on Outlet-Strategic Fit Junction Object Record creation
 * 3.0			Shivam Chauhan	   27/12/2023	   148622 - Define Approvers in Approval Flow for Strategic Fit updates based on FPS Setting
 * 4.0          Sakshi Shah        28/06/2024      154872 - Fix to generate Field Change Request
*/

public with sharing class OutletStrategicFitTriggerHandler implements TriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletStrategicFitTrigger';
    
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
       EDGE_OutletStrategicFitTriggerHelper.outletStrategicFitInsertUpdateCheck(newItems,null); 
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_OutletStrategicFitExtTriggerHelper.validateFieldsPerFS(newItems,oldItems);
        EDGE_OutletStrategicFitExtTriggerHelper.createFieldChangeRequest(newItems,oldItems);
        EDGE_OutletStrategicFitTriggerHelper.outletStrategicFitInsertUpdateCheck(newItems.values(),oldItems); //Moved to Line 35 for field change request to be initiated
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