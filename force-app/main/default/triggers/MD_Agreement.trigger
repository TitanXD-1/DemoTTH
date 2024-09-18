trigger MD_Agreement on MD_Agreement__c (before insert, before update, after insert, after update) {
   new MD_AgreementTriggerHandler(trigger.new, trigger.old).run();
}