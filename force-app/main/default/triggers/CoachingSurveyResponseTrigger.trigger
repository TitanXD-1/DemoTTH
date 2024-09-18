/**********************************************************************
Name: CoachingSurveyResponseTrigger
=======================================================================
Purpose: This is to handle Coaching Survey Response Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Amar Deep        20-09-2019        Initial Development
***********************************************************************/

trigger CoachingSurveyResponseTrigger on Coaching_Survey_Response__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new CoachingSurveyResponseTriggerHandler());
}