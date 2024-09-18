/**********************************************************************
  Name: FieldChangeRequestTrigger
=======================================================================
  Purpose: This is to handle Field Change Request Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Name              30/04/2019      Initial Development
***********************************************************************/

trigger FieldChangeRequestTrigger on Field_Change_Request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new FieldChangeRequestTriggerHandler());
}