/**********************************************************************
	Name: UserBusinessRoleTrigger
=======================================================================
	Purpose: This is to handle User Business Role Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Sandeep Sahoo     27/02/2019        Initial Development
***********************************************************************/
trigger UserBusinessRoleTrigger on User_Business_Role__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new UserBusinessRoleTriggerHandler());
}