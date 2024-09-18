/**********************************************************************
  Name: PriceListTrigger
=======================================================================
  Purpose: This is to handle Price List Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            		DATE              DETAIL
    1.0 -    Pravalika             07/12/2020      Initial Development
***********************************************************************/
trigger PriceListTrigger on ECM_Price_List__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
     ECM_PriceListTriggerHandler handler = new ECM_PriceListTriggerHandler();
    /* After Insert */
    if(Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }
    /* After Update */
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }
}