/**********************************************************************
Name: BespokeTrigger
=======================================================================
Purpose: This is to handle Bespoke__c Trigger Events
=======================================================================*/
trigger BespokeTrigger on Bespoke__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    TriggerDispatcher.run(new BespokeTriggerHandler());
}