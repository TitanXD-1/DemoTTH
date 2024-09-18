/**********************************************************************
Name: ProductTrigger
=======================================================================
Purpose: This is to handle Product__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    23/06/2019        ES20-2624      
***********************************************************************/
trigger ProductTrigger on Product__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ProductTriggerHandler());
}