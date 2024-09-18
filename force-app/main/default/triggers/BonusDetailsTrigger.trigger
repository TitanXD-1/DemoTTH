/**********************************************************************
 Name: BonusDetailsTrigger
=======================================================================
 Purpose: This is to handle Bonus Details Trigger Events
=======================================================================
 History                                                            
 -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  1.0       Vikas Anand      08-Jan-2020      Initial Development(ES20-4995)
***********************************************************************/
trigger BonusDetailsTrigger on Bonus_Detail__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new BonusDetailsTriggerHandler());
}