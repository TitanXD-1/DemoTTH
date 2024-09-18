/*
 * Class Name : CSTApproverMatrixHandler
 * @description: This is to handle CST Approver Matrix Handler
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        Sayan Mullick   		19/05/2021        Initial Development
*/



public with sharing class CSTApproverMatrixHandler  implements TriggerHandler{
    
    // Allows unit tests (or other code) to disable this trigger for the transaction
     public static Boolean triggerDisabled = false;
     public static string triggerName = 'CSTApproverMatrixTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
        public Boolean isDisabled(){ 
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
             
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_CSTApproverMatrixTriggerHelper.updateApproverUser(newItems);
         CST_SharingUtil.updateSalesOrganization(newItems,null, 'Sales_Org__c'); //CST-385
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       	EDGE_CSTApproverMatrixTriggerHelper.updateApproverUser(newItems.values());
        CST_SharingUtil.updateSalesOrganization(newItems.values(),oldItems.values(), 'Sales_Org__c');//CST-385
        
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_CSTApproverMatrixTriggerHelper.checkAndGenerateSharingfromSalesOrg(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       EDGE_CSTApproverMatrixTriggerHelper.validateAndReGenerateSharingfromSalesOrg(newItems.values(), oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}