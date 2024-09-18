/**********************************************************************
Name: DeliveryPartnerTrigger
=======================================================================
Purpose: This is to handle DeliveryPartnerTrigger Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Monalisa Halder    17/06/2019        ES20-2230    
***********************************************************************/
trigger DeliveryPartnerTrigger on Delivery_Partner__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new DeliveryPartnerTriggerHandler());
}