/**
 * Name: OutletStrategicFitTrigger
 * Purpose: This is to handle Outle-Strategic Fit Trigger Events
 * History
 * VERSION       AUTHOR               DATE            DETAIL
 * 1.0          Monalisa Halder    01/12/2023      Initial Development(148391)
 * 
 */

trigger OutletStrategicFitTrigger on Outlet_Strategic_Fit__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new OutletStrategicFitTriggerHandler());
}