/*
 * @Name: AccrualItemTrigger
 * @Description: This is to drive Accrual Item Trigger 
 * @History                                                            
 *                                                        
 * VERSION    		AUTHOR       		DATE                DETAIL
 *  1.0     		Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country     
*/ 
trigger AccrualItemTrigger on ECM_Accrual_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AccrualItemTriggerHandler()); // calling handler class
}