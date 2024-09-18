/**********************************************************************
Name: CoachingSurveyTrigger
=======================================================================
Purpose: This is to handle Coaching Survey Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Shahbaz Khan    20-09-2019        Initial Development
***********************************************************************/

trigger CoachingSurveyTrigger on Coaching_Survey__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new CoachingSurveyTriggerHandler());
}