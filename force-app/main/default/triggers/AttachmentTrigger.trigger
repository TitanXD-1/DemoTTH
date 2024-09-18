/*
 * @trigger: AttachmentTrigger
 * @description: This is trigger factory for Attachment object
 * 
 * */
trigger AttachmentTrigger on Attachment (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AttachmentTriggerHandler());
}