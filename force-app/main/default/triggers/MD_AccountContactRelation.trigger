trigger MD_AccountContactRelation on AccountContactRelation (before insert, before update, after insert, after update, before delete, after delete) {
   new MD_AccountContactRelationTriggerHandler(trigger.new, trigger.old).run();
}