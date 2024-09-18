/**********************************************************************
  Name: TravelLogTrigger
=======================================================================
  Purpose: This is to handle Travel Log Trigger Events
=======================================================================
    History                                                            
    -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  1.0       Shahbaz Khan      24/02/2020     Initial Development
***********************************************************************/

trigger TravelLogTrigger on Travel_Log__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
		TriggerDispatcher.run(new TravelLogTriggerHandler());
}