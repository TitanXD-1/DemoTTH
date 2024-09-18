/**********************************************************************
Name: AchievementTierTrigger
=======================================================================
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0			Shahbaz Khan	07/01/2020			Initial Development	
***********************************************************************/
trigger AchievementTierTrigger on Achievement_Tier__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
		TriggerDispatcher.run(new AchievementTierTriggerHandler());
}