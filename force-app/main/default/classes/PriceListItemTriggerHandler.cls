/*
 * @Name: PriceListItemTriggerHandler
 * @Description: This is the handler class for PriceListItem Trigger
 * @History                                                            
                                                         
VERSION    AUTHOR                DATE              DETAIL
1.0        Tanishq	        	01/09/2021         Initial Development for ECM-4763
*/ 
public class PriceListItemTriggerHandler  implements TriggerHandler{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'PriceListItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        ECM_PriceListItemTriggerHelper.priceListItemValidation(newItems,null);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        ECM_PriceListItemTriggerHelper.priceListItemValidation(newItems.values(),oldItems);
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