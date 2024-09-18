/**********************************************************************
  Name: AccountPromotionTrigger
=======================================================================
  Purpose: This is to handle AccountPromotion Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION      AUTHOR            DATE              DETAIL
     1.0 -    Monalisa Halder    13/05/2019      Initial Development
***********************************************************************/
trigger AccountPromotionTrigger on Account_Promotion__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new AccountPromotionTriggerHandler());
}