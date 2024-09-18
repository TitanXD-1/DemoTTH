/**********************************************************************
  Name: OutletExecutionHistoricTrigger
=======================================================================
  Purpose: This is to handle Outlet Execution Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                        DATE             DETAIL
    1.0 -    Anuja Chattopadhyay           11/06/2019      Initial Development
***********************************************************************/
trigger OutletExecutionHistoricTrigger on Outlet_Execution_Historic__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new OutletExecutionHistoricTriggerHandler());
}