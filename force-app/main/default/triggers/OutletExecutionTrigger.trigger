/**********************************************************************
  Name: OutletExecutionTrigger
=======================================================================
  Purpose: This is to handle OutletExecutionTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 - Sagar Barman   01/04/2019      Initial Development
***********************************************************************/
trigger OutletExecutionTrigger on Outlet_Execution__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new OutletExecutionTriggerHandler());
}