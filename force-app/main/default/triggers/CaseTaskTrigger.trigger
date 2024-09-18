/**
* @description This is to handle Case Tasks trigger events
* @history
* 1.1     Mayank Singh       11/08/2021
*/

trigger CaseTaskTrigger on Case_Task__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CaseTaskTriggerHandler());
}