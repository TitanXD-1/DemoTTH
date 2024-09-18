/**

* @Description : LineCleaningHolidayTrigger

* @Purpose : Calls LineCleaningHolidayTriggerHandler

*/
trigger LineCleaningHolidayTrigger on Line_Cleaning_Holiday__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new LineCleaningHolidayTriggerHandler());
}