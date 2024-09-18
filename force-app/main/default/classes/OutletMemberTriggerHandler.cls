/**
* @Name: OutletMemberTriggerHandler

* @Purpose: Trigger Handler Class for Outlet Member

* @History                                                            
                                                                
* @VERSION     AUTHOR                  DATE              DETAIL
*  1.0         Anuja Chattopadhyay     22/02/2019        Initial Development
*  2.0         Monalisa Halder         25/02/2021        ES20-9804
*  3.0         Aparajita			   08/04/2022	     ES20-12436(Method:removeContactSharing)
*  4.0		   Rajarshi Lahiri		   01/11/2022		 ES20-13475
*  5.0         Mayukh SRoy             08/11/2022        ES20-13505 - Fix for Batch Failure

*/

public with sharing class OutletMemberTriggerHandler implements TriggerHandler{
  // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OutletMemberTrigger';
    
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
        EDGE_OutletMemberTriggerHelper.removePrimarySalesDetails(null,oldItems); 
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        //ES20-13475- Removed not(!) from EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch
        if(!system.isBatch() || (system.isBatch() && !EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch)){//ES20-9804
        	EDGE_OutletMemberTriggerHelper.populatePrimarySalesDetails(newItems.values(),null); 
            EDGE_OutletMemberTriggerExtnHelper.createAccTeam(newItems.values(),null);
            EDGE_OutletMemberTriggerHelper.createContactSharing(newItems.values(),null); //ES20-13505
        }
        
      //  EDGE_OutletMemberTriggerHelper.createContactSharing(newItems.values(),null);//ES20-12449 ES20-13505
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       if(!system.isBatch() || (system.isBatch() && !EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch)){ //ES20-9804
        EDGE_OutletMemberTriggerHelper.populatePrimarySalesDetails(newItems.values(),oldItems); 
       } 
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        EDGE_OutletMemberTriggerHelper.removeContactSharing(oldItems.values()); //ES20-12436
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}