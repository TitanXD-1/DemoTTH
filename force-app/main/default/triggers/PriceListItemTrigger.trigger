/*
 * @Name: PriceListItemTrigger
 * @Description: This is to handle Price List Item Trigger Events
 * @History                                                            
                                                         
VERSION    AUTHOR                DATE              DETAIL
1.0        Tanishq              01/09/2021         Initial Development for ECM-4763
*/ 
trigger PriceListItemTrigger on ECM_Price_List_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new PriceListItemTriggerHandler());
}