/**********************************************************************
  Name: OutletSurveyResponseTrigger
=======================================================================
  Purpose: This is to handle Outlet Survey Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0 -   Monalisa Halder     02/04/2019      Initial Development
***********************************************************************/
trigger OutletSurveyResponseTrigger on Outlet_Survey_Response__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new OutletSurveyResponseTriggerHandler());
}