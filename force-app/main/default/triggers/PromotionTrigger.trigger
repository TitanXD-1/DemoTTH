/**********************************************************************
  Name: PromotionTrigger
=======================================================================
  Purpose: This is to handle Promotion Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 - Preyanka Ghosh    18/03/2019      Initial Development
***********************************************************************/

trigger PromotionTrigger on Promotion__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new PromotionTriggerHandler());
}