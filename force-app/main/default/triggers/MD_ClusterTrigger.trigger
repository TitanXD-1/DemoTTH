trigger MD_ClusterTrigger on DiageoCMS__Cluster__c (before insert, before update, after insert, after update) {
    new MD_ClusterTriggerHandler(trigger.new, trigger.old).run();
}