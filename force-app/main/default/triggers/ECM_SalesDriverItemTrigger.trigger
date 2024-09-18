/**********************************************************************
Name: ECM_SalesDriverItemTrigger
=======================================================================
Purpose: This is to handle ECM_SalesDriverItemTrigger Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR				DATE            DETAIL
1.0		    Keshava Murthy M 	27/01/2022      Initial Development
***********************************************************************/
trigger ECM_SalesDriverItemTrigger on ECM_Sales_Driver_Item__c (after insert,after update, before update,before insert,before delete,after delete,after undelete) {
    TriggerDispatcher.run(new ECM_SalesDriverItemTriggerHandler());    
}