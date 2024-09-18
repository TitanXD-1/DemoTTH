/**********************************************************************
    Name: TemplateWeighingTrigger 
=======================================================================
    Purpose: This is to handle TemplateWeighing Trigger  Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Saurav paul       17/05/2019        Initial Development
***********************************************************************/
trigger TemplateWeighingTrigger on Template_Weighing__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new TemplateWeighingTriggerHandler());
}