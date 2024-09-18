/**********************************************************************
Name: OutletKPITrigger
=======================================================================
Purpose: This is to handle KPI Target Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE			DETAIL
1.0			Preyanka Ghosh	20/02/2020		Initial Development
***********************************************************************/
trigger OutletKPITrigger on Outlet_KPI_Achievement__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new OutletKPITriggerHandler());
}