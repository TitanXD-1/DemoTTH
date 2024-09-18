/**********************************************************************
Name: OutletBuyingGroupTrigger
=======================================================================
Purpose: This is to handle Outlet_Buying_Group__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Shahbaz Khan      8/7/2020             
***********************************************************************/

trigger OutletBuyingGroupTrigger on Outlet_Buying_Group__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new OutletBuyingGroupTriggerHandler());
}