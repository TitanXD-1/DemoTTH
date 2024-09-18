/**********************************************************************
Name: OutletInventoryTrigger
=======================================================================
Purpose: This is to handle Outlet Inventory Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR      DATE          DETAIL
1.0      Shahbaz Khan  12/10/2020    Initial Development
***********************************************************************/
trigger OutletInventoryTrigger on Outlet_Inventory__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new OutletInventoryTriggerHandler());
}