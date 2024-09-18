/**
* @Name: GT_ProjectTriggerHandler
* @Purpose: Handler for GTProjectTrigger on GT_Project__c object
* @Test Class: GT_ProjectTriggerHandlerTest
* 
* @History
* Version  Author          Date        Description
* 1.0      Tanishq     01/09/2023     140668 [GT-42] Implementation of Auto generation of Predefined Tasks when a project moves through phases
*/

public class GT_ProjectTriggerHandler implements TriggerHandler {
    
	public static Boolean triggerDisabled = false;
    public static string triggerName = 'GT_ProjectTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName); 
        return triggerDisabled;
    }

        
    //Before Insert Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void beforeInsert(List<SObject> newItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        GT_ProjectTriggerHelper.createAndValidateTasks(newItems,null);   
    }
    
    //Before Update Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        GT_ProjectTriggerHelper.createAndValidateTasks(newItems,oldItems);
    }
    
    //Before Delete Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
   
    //After Delete Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock')
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler  
    @SuppressWarnings ('PMD.EmptyStatementBlock')  
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}