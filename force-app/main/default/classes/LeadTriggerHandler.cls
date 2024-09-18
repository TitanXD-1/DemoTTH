/**
  * @name LeadTriggerHandler
  * @purpose Trigger Handler Class for LeadTrigger
  * @history                                                                                                                       
  * @VERSION  	AUTHOR            DATE              DETAIL
  * @1.0      	Sayan			13/08/2021         NCP-4081
  * 2.0         Narayana        22/04/2022         NCP-6561
  **/
public class LeadTriggerHandler implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'LeadTrigger';
    
    /**
     * @description Checks to see if the trigger has been disabled either by custom setting or by code
     * @return  `Boolean`
     */ 
    public Boolean isDisabled(){        
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
	
    /**
     * @description Before Insert Trigger Handler
     * @param newItems 
     */ 
    public void beforeInsert(List<SObject> newItems){
        D1_LeadTriggerHelper.validatePhoneNumber(newItems, null);//NCP-4081
        D1_LeadTriggerHelper.setGeographyTree( newItems, null);
        D1_LeadTriggerHelper.populatePardotBUCountryCode( newItems, null);
        D1_UtilityClass.validatePreferredLanguage(newItems,'Country__c','Preferred_Language__c');//NCP-6561
    }
    
    /**
     * @description Before Update Trigger Handler
     * @param newItems 
     * @param oldItems 
     */
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        D1_LeadTriggerHelper.validatePhoneNumber(newItems.values(), oldItems);//NCP-4081
        D1_LeadTriggerHelper.setGeographyTree(newItems.values(), oldItems.values());//NCP-4082
        D1_LeadTriggerHelper.mapUINumberField(newItems, oldItems);//NCP-4082
        D1_LeadTriggerHelper.populatePardotBUCountryCode(newItems.values() , oldItems);
        D1_UtilityClass.validatePreferredLanguage(newItems.values(),'Country__c','Preferred_Language__c');//NCP-6561
    }
    
    /**
     * @description Before Delete Trigger Handler
     * @param oldItems 
     */ 
    public void beforeDelete(Map<Id, SObject> oldItems){
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {  
    }

    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    /**
     * @description After Delete Trigger Handler
     * @param oldItems 
     */
    public void afterDelete(Map<Id, SObject> oldItems){
        
    }
    
    /**
     * @description After Undelete Trigger Handler
     * @param oldItems 
     */  
    public void afterUndelete(Map<Id, SObject> oldItems){
        
    }
}