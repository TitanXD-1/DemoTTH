trigger CC_InvestigationTrigger on CC_Investigation__c (before insert, before update, after insert, after update) {
    
    TriggerDispatcher.run(new CC_InvestigationTriggerHandler());
}