/**********************************************************************
  Name: CallTrigger
=======================================================================
  Purpose: This is to handle Call Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Anuja            18/03/2019      Initial Development
***********************************************************************/
trigger CallTrigger on Call__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new CallTriggerHandler());
}