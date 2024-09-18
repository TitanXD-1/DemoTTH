/**********************************************************************
* @description FieldPermissionTrigger
* @history
* @Purpose: This is to handle Field Permission object Trigger Events

VERSION  		AUTHOR             DATE              DETAIL
1.0        Monalisa Halder      27/07/2021       Initial Development(ES20-10866)

***********************************************************************/
trigger FieldPermissionTrigger on Field_Permission__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)
{
    TriggerDispatcher.run(new FieldPermissionTriggerHandler());    
}