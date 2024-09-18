/**********************************************************************
Name: BusinessRoleTrigger
=======================================================================
Purpose: This is to handle Business_Role__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    20/05/2019        ES20-1615      
***********************************************************************/
trigger BusinessRoleTrigger on Business_Role__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
       
    TriggerDispatcher.run(new BusinessRoleTriggerHandler());

}