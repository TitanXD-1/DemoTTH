/**********************************************************************
  Name: TerritoryTrigger
=======================================================================
  Purpose: This is to handle Territory Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Anuja           30-Apr-2019      Initial Development
***********************************************************************/

trigger TerritoryTrigger on Territory__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new TerritoryTriggerHandler());
}