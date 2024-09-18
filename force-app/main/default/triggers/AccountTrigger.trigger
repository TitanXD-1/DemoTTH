/**********************************************************************
	Name: AccountTrigger
=======================================================================
	Purpose: This is to handle Account Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 -    Name               06/02/2019      Initial Development
***********************************************************************/

trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new AccountTriggerHandler());
}