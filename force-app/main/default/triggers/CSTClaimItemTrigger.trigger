/*
 * Class Name : CSTClaimItemTrigger
 * @description: This is to handle CST Claim Item Events 
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        Sayan Mullick   		19/05/2021        Initial Development
*/


trigger CSTClaimItemTrigger on CST_Claim_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CSTClaimItemTriggerHandler());
}