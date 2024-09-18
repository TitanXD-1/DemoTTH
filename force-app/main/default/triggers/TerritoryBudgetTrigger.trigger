trigger TerritoryBudgetTrigger on Territory_Budget__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    ECM_TerritoryBudgetHandler handler= new ECM_TerritoryBudgetHandler();
         /* Before Insert */
         if(Trigger.isInsert && Trigger.isBefore){
            handler.onBeforeInsert(Trigger.new, Trigger.newMap);
        }
    /* Before Update */
        if(Trigger.isUpdate && Trigger.isBefore){
           handler.onBeforeUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
        }
}