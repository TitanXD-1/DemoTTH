/**********************************************************************
	Name: MasterBundleTrigger
=======================================================================
	Purpose: This is to handle Master Bundle Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Shivam Chauhan    08/12/2022      Initial Development(ES20-13531)
***********************************************************************/
trigger MasterBundleTrigger on Master_Bundle__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new MasterBundleTriggerHandler());
}