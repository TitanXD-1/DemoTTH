/**********************************************************************
    Name: InvoiceTrigger 
=======================================================================
    Purpose: This is to handle Invoice Trigger  Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Saurav Paul       04/09/2019      Initial Development
***********************************************************************/
trigger InvoiceTrigger on Invoice__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
 TriggerDispatcher.run(new InvoiceTriggerHandler());
}