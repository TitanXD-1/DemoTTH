/**********************************************************************
Name: CategoryPerformanceTrigger
=======================================================================
Purpose: This is to handle Category_Performance__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    20/05/2019        ES20-1615      
***********************************************************************/
trigger CategoryPerformanceTrigger on Category_Performance__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
       
    TriggerDispatcher.run(new CategoryPerformanceTriggerHandler());

}