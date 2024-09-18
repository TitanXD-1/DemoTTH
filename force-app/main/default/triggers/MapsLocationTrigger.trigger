/**********************************************************************
  Name: MapsLocation 
=======================================================================
  Purpose: This is to handle MapsLocation Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Anuja            18/08/2020      Initial Development
***********************************************************************/
trigger MapsLocationTrigger on maps__Location__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new MapsLocationTriggerHandler());
}