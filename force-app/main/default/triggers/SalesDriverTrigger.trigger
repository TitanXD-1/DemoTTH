trigger SalesDriverTrigger on ECM_Sales_Driver__c  (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	TriggerDispatcher.run(new ECM_SalesDriverTriggerHandler());
}