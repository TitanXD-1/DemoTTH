/*
 * @Name: PaymentAgreementTrigger
 * @Description: This is to handle Payment Agreement Trigger Events
 * @History                                                            
                                                         
	VERSION    AUTHOR                DATE              DETAIL
	1.0        Subhrojit Majumdar    13/09/2021        Initial Development for ECM-4416
*/ 
trigger PaymentAgreementTrigger on ECM_Payment_Agreement__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new PaymentAgreementTriggerHandler());
}