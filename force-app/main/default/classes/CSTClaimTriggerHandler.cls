/**
    * @description CSTClaimTriggerHandler    
    * @history    
    * 1.0         CST Team              19/05/2021        Initial Development    
    */

public with sharing class CSTClaimTriggerHandler implements TriggerHandler{
// Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CSTClaimTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {          
           EDGE_CSTClaimTriggerHelper.updateClaimPaymentTerm(newItems);
           EDGE_CSTClaimTriggerHelper.checkDuplicateBeforeInsert(newItems);
		   EDGE_CSTClaimTriggerHelper.insertClaimCurrency(newItems);
           EDGE_CSTClaimTriggerHelper.checkAccountSalesOrgCountry(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_CSTClaimTriggerHelper.checkDuplicateBeforeInsert(newItems.values());
        EDGE_CSTClaimTriggerHelper.updateRejectionReason(newItems, oldItems);
        EDGE_CSTClaimTriggerHelper.rejectionCommentOnApproval(newItems, oldItems);
        EDGE_CSTClaimTriggerHelper.approverCommentOnApproval(newItems, oldItems);
     	
        // testing for the 764 
        EDGE_CSTClaimTriggerHelper.updateApprover(newItems, oldItems);
        EDGE_CSTClaimTriggerHelper.reassignAndUpdateApprover(newItems, oldItems);
        EDGE_CSTClaimTriggerHelper.checkAccountSalesOrgCountry(newItems.values());
        EDGE_CSTClaimTriggerHelper.updateDateFields(newItems, oldItems);
       
        //EDGE_CSTClaimTriggerHelper.validateApproverUser(newItems, oldItems);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_CSTClaimTriggerHelper.deletiononNewstatus(oldItems.values());
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
          EDGE_CSTClaimTriggerHelper.checkAndGenerateSharing(newItems.values()); 
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_CSTClaimTriggerHelper.updateClaimItemCurrency(newItems, oldItems);
        EDGE_CSTClaimTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
        EDGE_CSTClaimTriggerHelper.claimApprovalProcess(newItems, oldItems); 
        EDGE_CSTClaimTriggerHelper.defaultApproverNotification(newItems, oldItems);
        EDGE_CSTClaimTriggerHelper.unLockRecord(newItems, oldItems);
       
        
       
        //EDGE_CSTClaimTriggerHelper.lockClaimItem(newItems.values());
        //EDGE_CSTClaimTriggerHelper.lockClaimAttachedContentDocuments(newItems.values());
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}