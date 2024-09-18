/**********************************************************************
	Name: TriggerDispatcher Class
=======================================================================
    Purpose: 
=======================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR            DATE              DETAIL
       1.0    Kapil Baliyan     06/02/2019      Initial Development
***********************************************************************/
public class TriggerDispatcher {
    public static void run(TriggerHandler handler){
        // Check to see if the trigger has been disabled. If it has, return
        if (handler.isDisabled()){
            return;
        }
        // Detect the current trigger context and fire the relevant methods
        // Before trigger logic
        if (Trigger.isBefore){
            if (Trigger.isInsert){
                handler.beforeInsert(trigger.new);
            }
            if (Trigger.isUpdate){
                handler.beforeUpdate(trigger.newMap, trigger.oldMap);
            }
            if (Trigger.isDelete){
                handler.beforeDelete(trigger.oldMap);
            }
        }
        // After trigger logic
        if (Trigger.isAfter){
            if (Trigger.isInsert){
                handler.afterInsert(Trigger.newMap);
            }
            if (Trigger.isUpdate){
                handler.afterUpdate(trigger.newMap, trigger.oldMap);
            }
            if (trigger.isDelete){
                handler.afterDelete(trigger.oldMap);
            }
            if (trigger.isUndelete){
                handler.afterUndelete(trigger.oldMap);
            }
        }
    }
}