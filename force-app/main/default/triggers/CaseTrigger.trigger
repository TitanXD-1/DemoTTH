/**********************************************************************
Name: CaseTrigger
=======================================================================
Purpose: This is to handle Cases trigger events 
=======================================================================
History                                                            
-------                                                            
VERSION  			AUTHOR            DATE              DETAIL
1.0 			Saurav Prasad	 	12/06/2020      Initial Development
***********************************************************************/
trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CaseTriggerHandler());
}