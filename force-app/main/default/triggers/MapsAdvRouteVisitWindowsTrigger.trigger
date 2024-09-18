/**********************************************************************
Name: MapsAdvRouteVisitWindowsTrigger
=======================================================================
Purpose: This is to handle Maps Advanced Route Visit Windows Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Amar Deep        29-06-2020        Initial Development
***********************************************************************/
trigger MapsAdvRouteVisitWindowsTrigger on maps__AdvRouteVisitWindows__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new MapsAdvRouteVisitWindowsTriggerHandler());
}