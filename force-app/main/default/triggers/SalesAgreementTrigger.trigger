/*
 * @Name: SalesAgreementTrigger
 * @Description: This is to handle Sales Agreement Trigger Events
 * @History                                                            
                                                         
    VERSION    AUTHOR                DATE              DETAIL
    1.0        Sayan Mullick         10/09/2021        Initial Development for ECM-4416
*/ 
trigger SalesAgreementTrigger on ECM_Sales_Agreement__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new SalesAgreementTriggerHandler()); // calling handler class
}