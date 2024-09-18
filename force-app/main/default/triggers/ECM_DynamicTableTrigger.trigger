trigger ECM_DynamicTableTrigger on ECM_Dynamic_Table_Generator__c (before insert, before update,after insert, after update) {
    TriggerDispatcher.run(new ECM_DynamicTableGeneratorTriggerHandler());
}