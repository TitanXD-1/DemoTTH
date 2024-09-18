trigger MD_Contact on Contact (before insert, before update, after insert, after update, before delete, after delete) {
   new MD_ContactTriggerHandler(trigger.new, trigger.old).run();
}