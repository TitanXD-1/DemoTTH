/**********************************************************************
Name: CorrDocuTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for Correction Document
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      	Saurav Paul    11/08/2019        Initial Development

***********************************************************************/

public with sharing class CorrDocuTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CorrectionDocumentTrigger';
    
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
		PNR_CorrDocuTriggerHelper.getInvoiceData(newItems.values(),null,false);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {   
		PNR_CorrDocuTriggerHelper.getInvoiceData(newItems.values(),oldItems,true);	
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}