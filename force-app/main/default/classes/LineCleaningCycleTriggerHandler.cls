/**

* @Description : LineCleaningCycleTriggerHandler

* @Purpose : Calls EDGE_LineCleaningHolidayHelper

* @History:

* Version     Developer       Date           User Story	        

*   1.1		  Aparajita    06/12/2021      ES20-10779(Method:checkAndGenerateSharing,validateAndReGenerateSharing)
*   1.2      Joshraj Sen   03/12/2021      ES20-10430(Method:calculateLineCleaningCycleEndDate,validateDuplicateStartdate,updateLineCleaningCycleHolidays)
*/
public class LineCleaningCycleTriggerHandler implements TriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Line Cleaning Cycle Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_LineCleaningCycleHelper.calculateLineCleaningCycleEndDate(newItems,null,false,true);
        EDGE_LineCleaningCycleHelper.validateDuplicateStartdate(newItems,null,false);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_LineCleaningCycleHelper.calculateLineCleaningCycleEndDate(newItems.values(),oldItems,true,false); 
        EDGE_LineCleaningCycleHelper.validateDuplicateStartdate(newItems.values(),oldItems,true);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_LineCleaningCycleHelper.checkAndGenerateSharing(newItems.values());       
        EDGE_LineCleaningCycleHelper.updateLineCleaningCycleHolidays(newItems.values(),null); 
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_LineCleaningCycleHelper.validateAndReGenerateSharing(newItems.values(), oldItems);  
        EDGE_LineCleaningCycleHelper.updateLineCleaningCycleHolidays(newItems.values(),oldItems); 
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }   
}