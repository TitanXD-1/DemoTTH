/**********************************************************************
Name: FasciaTrigger
=======================================================================
Purpose: This is to handle Fascia__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    21/05/2019        ES20-1615      
***********************************************************************/
trigger FasciaTrigger on Fascia__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new FasciaTriggerHandler());
}