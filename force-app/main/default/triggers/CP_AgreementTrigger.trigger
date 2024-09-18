trigger CP_AgreementTrigger on CP_Agreement__c (before insert, before update, after insert, after update, after delete) {
   new CP_AgreementTriggerHandler(trigger.new, trigger.old).run();
}