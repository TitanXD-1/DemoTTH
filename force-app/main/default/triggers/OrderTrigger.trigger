/**********************************************************************
Name: OrderTrigger
=======================================================================
Purpose: This is to handle Order__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    20/06/2019              
***********************************************************************/
trigger OrderTrigger on Order__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    TriggerDispatcher.run(new OrderTriggerHandler());
}