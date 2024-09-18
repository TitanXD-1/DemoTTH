/**

* @Description : LineCleaningCycleTrigger

* @Purpose : Calls LineCleaningCycleTriggerHandler

*/
trigger LineCleaningCycleTrigger on Line_Cleaning_Cycle__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new LineCleaningCycleTriggerHandler());
}