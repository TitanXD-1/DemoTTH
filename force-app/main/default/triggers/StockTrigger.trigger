/**********************************************************************
Name: StockTrigger
=======================================================================
Purpose: This is to handle StockTrigger Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    15/06/2019        ES20-2232    
***********************************************************************/
trigger StockTrigger on Stock__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new StockTriggerHandler());
}