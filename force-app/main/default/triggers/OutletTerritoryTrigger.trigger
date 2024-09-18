/**********************************************************************
  Name: OutletTerritoryTrigger
=======================================================================
  Purpose: This is to handle OutletTerritoryTriggerEvents
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 -    Sagar Barman 26/02/2019      Initial Development
***********************************************************************/
trigger OutletTerritoryTrigger on Outlet_Territory__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new OutletTerritoryTriggerHandler());
}