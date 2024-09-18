/*
* Class Name : ECM_SalesDriverItemTriggerHandler
* @description: Class with all handler methods of ECM_SalesDriverItemTrigger.
* @history
* AUTHOR            	DATE              	DETAIL
* Keshava Murthy M     27/01/2022      	ECM-5127 : Disable Edit for related objects of Contract_SFDC_GLO

* Pratap Sen           11/02/2022       ECM-5218 : Fix for the Bug - Enable Profile Check

*/
public class ECM_SalesDriverItemTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_SalesDriverItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
    }
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

        ECM_SalesDriverItemTriggerHelper.disableSdItem(newItems,oldItems);

    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {

        ECM_SalesDriverItemTriggerHelper.disableSdItem(null,oldItems);

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