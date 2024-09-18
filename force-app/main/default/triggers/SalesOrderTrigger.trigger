/**********************************************************************
  Name: SalesOrderTrigger
=======================================================================
  Purpose: This is to handle Sales Order Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 -    Name               06/02/2019      Initial Development
***********************************************************************/

trigger SalesOrderTrigger on Sales_Order__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new SalesOrderTriggerHandler());
}