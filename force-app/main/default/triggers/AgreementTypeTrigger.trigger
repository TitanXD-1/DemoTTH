trigger AgreementTypeTrigger on ECM_Contract_Type__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	TriggerDispatcher.run(new ECM_AgreementTypeTriggerHandler());
}