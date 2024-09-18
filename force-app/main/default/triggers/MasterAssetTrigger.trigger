/**********************************************************************
Name: MasterAssetTrigger
=======================================================================
Purpose: This is to handle Master Asset Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                    DATE              DETAIL
1.0 -    Dinesh Sharma            26/07/2021      Initial Development
***********************************************************************/
trigger MasterAssetTrigger on Master_Asset__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new MasterAssetTriggerHandler());
}