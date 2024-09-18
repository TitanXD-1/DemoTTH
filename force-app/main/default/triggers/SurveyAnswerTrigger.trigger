/**********************************************************************
  Name: SurveyAnswerTrigger
=======================================================================
  Purpose: This is to handle Survey Answer Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Saurav Paul      05/04/2019      Initial Development
***********************************************************************/
trigger SurveyAnswerTrigger on Survey_Answer__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new SurveyAnswerTriggerHandler());
}