/**

* @Description : LineCleaningHolidayTriggerHandler

* @Purpose : Calls EDGE_LineCleaningHolidayHelper

* @History:

* Version     Developer       	Date           User Story	        

*   1.1		  Aparajita     	06/12/2021      ES20-10780(Method:checkAndGenerateSharing,validateAndReGenerateSharing)
	1.2		  Supriya Galinde   03/12/2021      ES20-10437(Method:calculateLineCleaningEndDateFromHoliday)
	1.3       Rajarshi Lahiri   10/02/2022		ES20-11643

*/

public class LineCleaningHolidayTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Line Cleaning Holiday Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }    
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {    
        EDGE_LineCleaningHolidayHelper.calculateLineCleaningEndDateFromHoliday(newItems,false,false,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_LineCleaningHolidayHelper.calculateLineCleaningEndDateFromHoliday(newItems.values(),false,true,oldItems);        
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_LineCleaningHolidayHelper.calculateLineCleaningEndDateFromHoliday(oldItems.values(),true,false,null);
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_LineCleaningHolidayHelper.checkAndGenerateSharing(newItems.values());              
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_LineCleaningHolidayHelper.validateAndReGenerateSharing(newItems.values(), oldItems);     
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}