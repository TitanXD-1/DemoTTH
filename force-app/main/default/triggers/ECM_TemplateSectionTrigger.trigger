trigger ECM_TemplateSectionTrigger on ECM_Template_Section__c (before insert, before update, after insert, after update) {

        TriggerDispatcher.run(new ECM_TemplateSectionTriggerHandler());

}