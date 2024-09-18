/**
* @description This is to handle Return Beer Tags trigger events
* @history
* 1.1     Mayank Singh       12/08/2021
*/

trigger ReturnBeerTagTrigger on Return_Beer_Tag__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ReturnBeerTagTriggerHandler());
}