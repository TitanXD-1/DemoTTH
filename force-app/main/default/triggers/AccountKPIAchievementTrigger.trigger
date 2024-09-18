/**********************************************************************
Name: AccountKPIAchievementTrigger
=======================================================================
Purpose: This is to handle KPI Target Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE			DETAIL
1.0			Juned Khan	15/09/2020		Initial Development
***********************************************************************/
trigger AccountKPIAchievementTrigger on Account_KPI_Achievement__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AccountKPIAchievementTriggerHandler());
}