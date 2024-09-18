/*
 * Class Name : CSTClaimTrigger
 * @description: This is Claim Trigger
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  		19/05/2021        Initial Development
*/


trigger CSTClaimTrigger on CST_Claim__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
   TriggerDispatcher.run(new CSTClaimTriggerHandler());
}