/**
* @name CustomLogTrigger
* @purpose - This is to handle Custom Log Trigger Events
* @history
* Version          Author              Date         Detail
 * 1.0         Shameer/Syed Ali      23/12/2022    Initial Development  

**/

trigger CustomLogTrigger on Custom_Log__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new CustomLogTriggerHandler());

}