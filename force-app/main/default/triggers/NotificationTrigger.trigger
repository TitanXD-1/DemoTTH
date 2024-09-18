/**********************************************************************
	Name: NotificationTrigger
=======================================================================
	Purpose: This is to handle Notification Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Shahbaz Khan     16/03/2020        Initial Development  
***********************************************************************/
trigger NotificationTrigger on Notification__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
TriggerDispatcher.run(new NotificationTriggerHandler());
}