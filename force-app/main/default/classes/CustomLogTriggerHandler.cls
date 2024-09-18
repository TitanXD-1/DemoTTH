/**
* @name CustomLogTriggerHandler
* @purpose - Trigger Handler Class for CustomLogTrigger
* @history
* Version        Author               Date          Detail
 * 1.0         Shameer/Syed Ali      23/12/2022    Initial Development  

*/

public with sharing class CustomLogTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CustomLogTrigger';
    public static Boolean triggerDisabledPopulated = false;
    public static Boolean firstRun=False;
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabledPopulated){
        	triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
            triggerDisabledPopulated = true;
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);
        
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) { 
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        
        }
            
    
    //After Delete Trigger Handler 
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
    }
}