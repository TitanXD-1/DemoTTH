/**

* @description : CaseCommentTriggerHandler

* @purpose : Trigger Handler Class for CaseComment

* @history:

*Version             Developer          Date             Purpose
*1.0 				 Juned khan		 19/03/2021      Initial Development
*2.0				 Prasanth T		 02/08/2021		 ES20-9673[Case Comment to SNOW in After Insert]

*/
public with sharing class  CaseCommentTriggerHandler implements TriggerHandler{
    
     // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'CaseCommentTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {        
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
   }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        //EDGE_CaseCommentTriggerHelper.createChatterComments(newItems);
        EDGE_CaseCommentTriggerHelper.createChatterFeeds(newItems);
        EDGE_CaseCommentTriggerHelper.createCaseCommentSnowTicket(newItems);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(LoggingLevel.INFO, 'EmptyBlockPMD');
    }
    

    

}