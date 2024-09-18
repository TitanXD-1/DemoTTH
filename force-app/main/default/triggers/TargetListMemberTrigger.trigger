/**********************************************************************
  Name: TargetListMemberTrigger
=======================================================================
  Purpose: This is to handle Target List Member Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Saurav           06-Mar-2019      Initial Development
***********************************************************************/
trigger TargetListMemberTrigger on Target_List_Member__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new TargetListMemberTriggerHandler());
}