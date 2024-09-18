/**********************************************************************
  Name: FieldPermissionSetTrigger
=======================================================================
  Purpose: This is to handle Field Permission Set object Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION      AUTHOR            DATE              DETAIL
     1.0 -     Aparajita        01/02/2021      Initial Development
***********************************************************************/
trigger FieldPermissionSetTrigger on Field_Permission_Set__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerDispatcher.run(new FieldPermissionSetTriggerHandler());    
}