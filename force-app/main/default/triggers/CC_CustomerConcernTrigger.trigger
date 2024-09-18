/**********************************************************************
Name: CC_CustomerConcernTrigger
=======================================================================
Purpose: Handling Customer Concern Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S		06/05/2021		Initial Development
***********************************************************************/
trigger CC_CustomerConcernTrigger on CC_Customer_Concern__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CC_CustomerConcernTriggerHandler());
}