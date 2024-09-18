/**********************************************************************
Name: CoachingReportTrigger
=======================================================================
Purpose: This is to handle Coaching Report Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0      Dipanjan D        16-09-2019        Initial Development
***********************************************************************/

trigger CoachingReportTrigger on Coaching_Report__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new CoachingReportTriggerHandler());
}