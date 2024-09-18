/*
* Class Name : ECM_PaymentSummaryTriggerHandler
* @description: Class with all handler methods of ECM_PaymentSummaryTrigger.
* @history
* AUTHOR            DATE              	DETAIL
* Keshav         	08/04/2020      	ECM-1055 : SFDC_GLO_Logic: Promo-prepayment payment summary status change flow
* Keshav         	01/06/2020      	ECM-1720 : SFDC_GLO_Logic: Internal order_Spent amount calculation    
* Keshav         	18/06/2020      	ECM-2242 : SFDC_GLO_Logic: Fiscal year auto-determination for Payment summary
* veerendra      	08/02/2021      	ECM-3803 : Missing table in the Evidence request email
* veerendra      	05/03/2021      	ECM-4070 : CM Spain - INC19720170 Promotional Payment Summary creation  - from CI to SDI items 
* Saurav Prasad  	02/06/2021      	ECM-4490 : UAT_Defect : Mail not getting trigerred to email address from the field "email for contracts/payments" on outlet and  in the field "Payment Management Email" of the market settings
* Anivesh Muppa  	16/06/2021	   		ECM-4516 : Before Insert Update the Approver fields 
* Saurav Prasad  	21/06/2021	   		ECM-4515 : Update status to rejected for Promo-PrePayment
* Manikandan.T   	28/07/2021      	ECM-4569 : Initaite Approval process for Extra Approvers and CIO Approvers
* Manikandan.T		26/11/2021    		ECM-4958 : Trigger Handler Class Refactoring
* Tanishq           09/03/2022          ECM-5292,ECM-5301,ECM-5294 : Calling updateCTDValues method from helper in afterUpdate
* Tanishq & Pratik  21/11/2022          ECM-6351: Regression_Defect : Request for evidence mail is triggering twice
*/
public class ECM_PaymentSummaryTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'PaymentSummaryTrigger';
    public static Boolean isFirstTime = true;
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        ECM_PaymentSummaryTriggerHelper.fetchContractDetails(newItems);
        ECM_PaymentSummaryTriggerHelper.updateIOCode(newItems);
        ECM_PaymentSummaryTriggerHelper.updateCurrencyCode(newItems);
        ECM_PaymentSummaryTriggerHelper.fiscalYearCalculate(newItems);
        ECM_PaymentSummaryTriggerHelper.ECM_Update_PS_BudgetType(newItems);  
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
        if(isFirstTime || Test.isRunningTest()){
            ECM_PaymentSummaryTriggerHelper.fetchContractDetails(newItems.Values());
            ECM_PaymentSummaryTriggerHelper.validatePaymentSummaryApproval((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);	
            ECM_PaymentSummaryTriggerHelper.updatePaymentSummaryFields((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);
            ECM_PaymentSummaryTriggerHelper.initiateApprovalProcess((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);
            ECM_PaymentSummaryTriggerHelper.updatePSInvoiceStatus((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);
            ECM_PaymentSummaryTriggerHelper.updateEmailSent((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);//ECM-6351        
        }
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        
        ECM_PaymentSummaryTriggerHelper.insertPaymentSummaryLineItemsForAustralia((Map<Id,ECM_Payment_Summary__c>)newItems);
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
        if(isFirstTime){
            ECM_PaymentSummaryTriggerHelper.fetchContractDetails(newItems.Values());
            ECM_PaymentSummaryTriggerHelper.UpdatePaymentSummaryConfirmedAmountOnContracts((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);
            ECM_PaymentSummaryTriggerHelper.updateContractWithPaymentSummaryValues((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);
            ECM_PaymentSummaryTriggerHelper.updateInternalOrderSpentAmount((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);
            ECM_PaymentSummaryTriggerHelper.initiateSAPCallout((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);				
            ECM_PaymentSummaryTriggerHelper.sendRejectionEmail((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>)oldItems);
            
            isFirstTime=false;
        }
        ECM_PaymentSummaryTriggerHelper.sendPushNotificationForPF((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);
       
        ECM_PaymentSummaryTriggerHelper.sendInvocePSEmail((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);
    	ECM_PaymentSummaryTriggerHelper.updateCTDValues((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);
        ECM_PaymentSummaryTriggerHelper.createRollOverPaymentSummary((Map<Id,ECM_Payment_Summary__c>)newItems,(Map<Id,ECM_Payment_Summary__c>) oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            
        
    }
    
}