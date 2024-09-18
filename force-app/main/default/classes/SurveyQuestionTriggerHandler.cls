/**********************************************************************
Name: SurveyQuestionTriggerHandler
=======================================================================
Purpose: This is to handle Survey Questions Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR          DATE            DETAIL
1.0         Saurav Paul     05/04/2019      Initial Development
1.1         Preyanka Ghosh  08/01/2020      ES20-4593 - Assign Bonus Type Questions in a Survey
***********************************************************************/
public with sharing class SurveyQuestionTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'SurveyQuestionTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_SurveyQuestionTriggerHelper.checkDuplicateSurveyKPI(newItems,null);
        EDGE_SurveyQuestionTriggerHelper.validateChildQuestion(newItems,null,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_SurveyQuestionTriggerHelper.checkDuplicateSurveyKPI(newItems.values(),oldItems);
        EDGE_SurveyQuestionTriggerHelper.validateChildQuestion(newItems.values(),newItems,oldItems);
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