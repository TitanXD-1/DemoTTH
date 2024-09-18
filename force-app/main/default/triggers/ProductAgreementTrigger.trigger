/*
 * @Name: ProductAgreementTrigger 
 * @Description: This is to handle Product Agreement Trigger Events
 * @History                                                            
                                                         
    VERSION    AUTHOR                DATE              DETAIL
    1.0        Sayan Mullick         10/09/2021        Initial Development for ECM-4416
*/ 
trigger ProductAgreementTrigger on ECM_Product_Agreement__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ProductAgreementTriggerHandler()); // calling handler class
}