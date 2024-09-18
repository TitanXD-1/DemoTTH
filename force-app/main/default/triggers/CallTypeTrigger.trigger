/**********************************************************************
Name: CallTypeTrigger
=======================================================================
Purpose: This is to handle Call_Type__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    21/05/2019        ES20-1615      
***********************************************************************/
trigger CallTypeTrigger on Call_Type__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CallTypeTriggerHandler());
}