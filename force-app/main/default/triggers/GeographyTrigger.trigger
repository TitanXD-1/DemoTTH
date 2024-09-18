/**********************************************************************
  Name: GeographyTrigger
=======================================================================
  Purpose: This is to handle Geography__c Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0   Dipanjan Das      12/03/2019        Initial Development
***********************************************************************/

trigger GeographyTrigger on Geography__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new GeographyTriggerHandler());
}