/**********************************************************************
Name: SurveyTriger
=======================================================================
Purpose: This is to handle Survey Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR                     DATE              DETAIL
1.0 -    Monalisa Halder            05/04/2019      Initial Development
***********************************************************************/
trigger SurveyTrigger on Survey__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new SurveyTriggerHandler());
}