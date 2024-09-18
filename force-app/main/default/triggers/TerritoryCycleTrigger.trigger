/**********************************************************************
  Name: TerritoryCycleTrigger
=======================================================================
  Purpose: This is to handle Territory Cycle Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                DATE              DETAIL
    1.0 -    Sagar Kumar Barman   05/28/2019      Initial Development
***********************************************************************/
trigger TerritoryCycleTrigger on Territory_Cycle__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new TerritoryCycleTriggerHandler());
}