/**********************************************************************
  Name: OpportunityTrigger
=======================================================================
  Purpose: This is to handle Opportunity Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Sagar Barman     23-Apr-2019      Initial Development
***********************************************************************/
trigger OpportunityTrigger on Opportunity(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new OpportunityTriggerHandler());
}