/**********************************************************************
Name: ECM_PaymentSummaryTrigger
=======================================================================
Purpose: This is to handle ECM_PaymentSummaryTrigger Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE              DETAIL
1.0		    Manikandan.T 	26/11/2021      Trigger Refactoring
***********************************************************************/
trigger ECM_PaymentSummaryTrigger on ECM_Payment_Summary__c (after insert,after update, before update,before insert,before delete,after delete,after undelete) {
    
	 TriggerDispatcher.run(new ECM_PaymentSummaryTriggerHandler());    
}