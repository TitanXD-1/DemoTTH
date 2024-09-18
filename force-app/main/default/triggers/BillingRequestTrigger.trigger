/*
Name: BillingRequestTrigger

Purpose: This is to handle Billing_Request__c Trigger Events

History                                                            
                                                            
VERSION      AUTHOR              DATE              DETAIL
1.0          Sukanya Chatterjee  7/10/2021         ES20-10979    
*/
trigger BillingRequestTrigger on Billing_Request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new BillingRequestTriggerHandler());
    
}