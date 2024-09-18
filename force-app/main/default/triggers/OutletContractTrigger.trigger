/**********************************************************************
  Name: OutletContractTrigger
=======================================================================
  Purpose: This is to handle Outlet Contract Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                        DATE             DETAIL
    1.0 -    Dipanjan Das           21/06/2019      Initial Development
***********************************************************************/
trigger OutletContractTrigger on Outlet_Contract__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new OutletContractTriggerHandler());
}