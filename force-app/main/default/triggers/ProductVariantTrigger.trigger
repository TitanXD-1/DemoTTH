/**********************************************************************
  Name: ProductVariantTrigger
=======================================================================
  Purpose: This is to handle ProductVariantTrigger
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -   Sagar Barman      03/09/2019      To make related Product Active
***********************************************************************/
trigger ProductVariantTrigger on Product_Variant__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new ProductVariantTriggerHanlder());
}