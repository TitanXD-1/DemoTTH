/**********************************************************************
	Name: ExternalLinksTrigger
=======================================================================
	Purpose: This is to handle External Links Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Amar Deep         04/03/2020        Initial Development  
***********************************************************************/
trigger ExternalLinksTrigger on External_Links__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new ExternalLinksTriggerHandler());
}