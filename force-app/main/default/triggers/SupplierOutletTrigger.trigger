/**********************************************************************
  Name: SupplierOutletTrigger
=======================================================================
  Purpose: This is to handle Supplier Outlet Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Saurav           06-Mar-2019      Initial Development
***********************************************************************/

trigger SupplierOutletTrigger on Supplier_Outlet__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new SupplierOutletTriggerHandler());
}