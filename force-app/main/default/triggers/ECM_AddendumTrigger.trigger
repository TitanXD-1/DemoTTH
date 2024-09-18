/*
* @Name: AddendumTrigger
* @Purpose: This is to handle Addendum Trigger Events
* @History:                                                                                                                       
* VERSION        AUTHOR            DATE              DETAIL
* 1.0        Pratap/Subhrojit   02/08/2022    Initial Development for ECM-5964
*/
trigger ECM_AddendumTrigger on ECM_Addendum__c (after insert,after update, before update,before insert,before delete,after delete,after undelete) {
    TriggerDispatcher.run(new ECM_AddendumTriggerHandler());    
}