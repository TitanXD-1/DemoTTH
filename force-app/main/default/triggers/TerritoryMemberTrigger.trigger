/**********************************************************************
  Name: TerritoryMemberTrigger
=======================================================================
  Purpose: This is to handle Territory Member Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -  Monalisa Halder     22/02/2019      Initial Development
***********************************************************************/

trigger TerritoryMemberTrigger on Territory_Member__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
   TriggerDispatcher.run(new TerritoryMemberTriggerHandler());
}