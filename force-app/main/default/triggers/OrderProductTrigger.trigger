/**********************************************************************
Name: OrderProductTrigger
=======================================================================
Purpose: This is to handle Order_Item__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Sagar Barman      26/07/2019              
***********************************************************************/
trigger OrderProductTrigger on Order_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new OrderProductTriggerHandler());
}