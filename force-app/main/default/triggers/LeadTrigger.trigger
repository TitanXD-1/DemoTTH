/**
  * @name LeadTrigger
  * @description This is to handle LeadTrigger Events
  * @history                                                                                                                       
  * @VERSION  	AUTHOR            DATE              DETAIL
  * @1.0      	Sayan			13/08/2021      Initial Development(NCP-4081)
 **/
trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new LeadTriggerHandler());
}