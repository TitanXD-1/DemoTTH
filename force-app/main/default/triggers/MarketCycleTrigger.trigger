/**********************************************************************
  Name: MarketCycleTrigger
=======================================================================
  Purpose: This is to handle Market Cycle Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                DATE              DETAIL
    1.0 -    Anuja Chattopadhyay   03/04/2019      Initial Development
***********************************************************************/
trigger MarketCycleTrigger on Market_Cycle__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new MarketCycleTriggerHandler());
}