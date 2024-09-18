trigger ECM_InternalOrderTrigger on ECM_Internal_Order__c (after insert,after update, before update,before insert,before delete,after delete,after undelete) {
    TriggerDispatcher.run(new ECM_InternalOrderTriggerHandler()); 
}