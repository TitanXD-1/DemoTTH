/**********************************************************************
	Name: UserNotificationTrigger
=======================================================================
	Purpose: This is to handle User Notification Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Amar Deep         04/03/2020        Initial Development  
***********************************************************************/
trigger UserNotificationTrigger on User_Notification__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new UserNotificationTriggerHandler());
}