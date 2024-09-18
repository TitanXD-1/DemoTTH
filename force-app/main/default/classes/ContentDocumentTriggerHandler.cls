/*
* @Name: ContentDocumentTriggerHandler
* @Purpose: Trigger Handler Class for ContentDocumentTrigger
* @History:                                                           
* @VERSION     	AUTHOR         	   DATE             DETAIL
*	1.0        Monalisa Halder   18/03/2019        ES20-198   
*	1.1			Aparajita		 20/04/2023		   CONS-528
*/
public with sharing class ContentDocumentTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ContentDocumentTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);  
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock') //CONS-995
    public void beforeInsert(List<SObject> newItems) {
        
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_ContentDocumentTriggerHelper.checkDocExtforUpdate(newItems);
        EDGE_ContentDocumentTriggerHelper.readOnlyAttach(newItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_ContentDocumentTriggerHelper.clearFieldDetails(oldItems); 
        EDGE_ContentDocumentTriggerHelper.readOnlyAttach(oldItems);
        EDGE_ContentDocumentTriggerHelper.uncheckPsInvoiceAttachment(oldItems);//ECM-6787
        CO_ContentDocumentTriggerHelper.restrictFileDeletion(oldItems);//CONS-528
    }
    
    //After Insert Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock') //CONS-995
    public void afterInsert(Map<Id, SObject> newItems) {
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_ContentDocumentTriggerHelper.updateContentVersionId(newItems);
    }
    
    //After Delete Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock') //CONS-995
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    @SuppressWarnings ('PMD.EmptyStatementBlock') //CONS-995
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}