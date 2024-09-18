/*
  @Name: DepletionsTrigger
  @Purpose: This is to handle Depletions Trigger Events
  @History                                                            
   
   @VERSION  AUTHOR            		DATE              DETAIL
    1.0 -    Pravalika             07/12/2020      Initial Development
	2.0			Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country

*/
trigger DepletionsTrigger on Depletions__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
     ECM_DepletionsTriggerHandler handler = new ECM_DepletionsTriggerHandler();

    /* After Insert */
    if(Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }
    /* After Update */
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }
    //Added as a part of ECM-6256
    /* Before Insert */
    if(Trigger.isInsert && Trigger.isBefore){
        handler.onBeforeAddCountry(Trigger.new, null);
    }
    /* Before Update */
    if(Trigger.isUpdate && Trigger.isBefore){
        handler.onBeforeAddCountry(Trigger.new, Trigger.oldMap);
    }
}