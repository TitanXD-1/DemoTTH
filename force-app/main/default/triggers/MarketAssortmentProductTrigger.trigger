/**********************************************************************
  Name: MarketAssortmentProductTrigger
=======================================================================
  Purpose: This is to handle MarketAssortmentProductTrigger
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 - Sagar Barman   24/04/2019      Initial Development
***********************************************************************/
trigger MarketAssortmentProductTrigger on Market_Assortment_Product__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
 TriggerDispatcher.run(new MarketAssortmentProductTriggerHandler());
}