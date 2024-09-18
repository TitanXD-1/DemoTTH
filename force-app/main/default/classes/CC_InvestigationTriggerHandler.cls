public class CC_InvestigationTriggerHandler implements TriggerHandler{
	 // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Investigation Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            //triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        Set<Id> caseIds = new Set<Id>();        
     	for(sObject obj : newItems)
        {
            CC_Investigation__c c = (CC_Investigation__c)obj;
            caseIds.add(c.CC_Case__c);
        }
        
        List<CC_Investigation__c> existingInvestigationList = [Select id,CC_Case__c from CC_Investigation__c where CC_Case__c IN : caseIds];
        for(sObject obj : newItems)
        {
            if(existingInvestigationList.size()>0)
                obj.addError('Duplicate investigation form. Please use the existing investigation form for this case.');
        }
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