/*
@Name: CustomerRequestTrigger

@Purpose: This class is a trigger for Customer Request

@History                                                            
                                                          
VERSION    AUTHOR               DATE              DETAIL
1.0        Venkatesh Varma      22-12-2022        Initial Development

*/
trigger CustomerRequestTrigger on Customer_Request__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
   TriggerDispatcher.run(new CustomerRequestTriggerHandler());
}