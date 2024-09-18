/**********************************************************************
Name: BonusHeaderTrigger
=======================================================================
Purpose: This is to handle Bonus_Header__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -  Shahbaz Khan      20/01/2020      Initial Development
***********************************************************************/


trigger BonusHeaderTrigger on Bonus_Header__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new BonusHeaderTriggerHandler());
    //TriggerDispatcher.run(new TerritoryMemberTriggerHandler());
}