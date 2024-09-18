trigger ECM_TemplateSubSectionTrigger on ECM_Template_Sub_Section__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) { 
    TriggerDispatcher.run(new ECM_TemplateSubSectionTriggerHandler());
}