/**
* @Description: Trigger Handler Class for Case Task

* @History:

* @Version   Developer             Date   

* 1.1        Mayank Singh        11/08/2021
*/

public class CaseTaskTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Case Task Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        //Populated GUID Field --- ES20-10906
        EDGE_UtilityClass.populateGUID(newItems); 
       //populate user assigned to field
       EDGE_QualityCaseTaskTriggerHelper.populateUserAssignedTo(newItems, null);
       EDGE_QualityCaseTaskTriggerHelper.populateSuggestedUser(newItems, null);
       EDGE_QualityCaseTaskTriggerHelper.populateActionedWithinSLA(newItems,null);
	   EDGE_QualityCaseTaskTriggerHelper.populateLastModifyUserId(newItems,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
      	//populate user assigned to field
       EDGE_QualityCaseTaskTriggerHelper.populateUserAssignedTo(newItems.values(), oldItems);
       EDGE_QualityCaseTaskTriggerHelper.populateSuggestedUser(newItems.values(), oldItems);
       EDGE_QualityCaseTaskTriggerHelper.populateActionedWithinSLA(newItems.values(),oldItems);
       EDGE_QualityCaseTaskTriggerHelper.populateLastModifyUserId(newItems.values(),oldItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {

        EDGE_QualityCaseTaskTriggerHelper.updateCaseStatus(newItems,null);
        EDGE_QualityCaseTaskTriggerHelper.createAccess(newItems.values(),null);


        EDGE_QualityCaseTaskTriggerHelper.sendPushNotificationCaseTask(newItems,null);


        EDGE_QualityCaseTaskTriggerHelper.createCaseTaskKPIRecords(newItems.values(),null);
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
		EDGE_QualityCaseTaskTriggerHelper.updateCaseStatus(newItems,oldItems);
        EDGE_QualityCaseTaskTriggerHelper.createAccess(newItems.values(),oldItems);



        EDGE_QualityCaseTaskTriggerHelper.sendPushNotificationCaseTask(newItems,oldItems);       
        //EDGE_QualityCaseTaskTriggerHelper.deleteAccess(newItems.values(),oldItems);
		EDGE_QualityCaseTaskTriggerHelper.createCaseTaskKPIRecords(newItems.values(),oldItems);       
        EDGE_QualityCaseTaskTriggerHelper.updateAssetWithCaseTaskStatus(newItems,oldItems);
    



    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}