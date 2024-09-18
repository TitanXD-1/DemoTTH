/*
 * @Name: RoleAgreementTrigger
 * @Description: This is to drive Role Agreement Trigger Events
 * @History                                                            
 *                                                        
 *  VERSION    AUTHOR       DATE                 DETAIL
 *   1.0     Pratap Sen  11-09-2021  Initial Development for ECM-4416
*/ 
trigger RoleAgreementTrigger on ECM_Role_Agreement__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    	TriggerDispatcher.run(new RoleAgreementTriggerHandler()); // calling handler class
}