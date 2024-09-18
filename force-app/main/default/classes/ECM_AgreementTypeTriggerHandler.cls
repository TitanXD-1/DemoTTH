/**********************************************************************
Name: ECM_AgreementTypeTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for AgreementTypeTrigger
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0      Anivesh Muppa       09/12/2020        Initial Development
***********************************************************************/
public with sharing class ECM_AgreementTypeTriggerHandler implements TriggerHandler{
	public static Boolean triggerDisabled = false;
    public static string triggerName = 'AgreementTypeTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        //EDGE_UtilityClass.populateGUID(newItems);
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        
        ECM_AgreementTypeTriggerHelper.checkAndGenerateSharing(newItems.values());         
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_AgreementTypeTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);   
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}