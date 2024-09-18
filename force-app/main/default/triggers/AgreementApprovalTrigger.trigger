/*
* @description : This is to handle Agreement Approval Trigger Events
* @history:
* VERSION    AUTHOR                DATE              DETAIL
* 1.1        Anuja                 13/08/2021        Initial Developement 
*/
trigger AgreementApprovalTrigger on ECM_Agreement_Approval__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AgreementApprovalTriggerHandler());
}