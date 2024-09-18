/*
 * @Name: ProductRecommendationTriggerHandler
 * @Description: This is the handler class for Product Recommendation  trigger
 * @History                                                            
                                                         
VERSION    AUTHOR                DATE              DETAIL
1.0        Pratap Sen         22-02-2023       Initial Development
*/ 
public class ProductRecommendationTriggerHandler implements TriggerHandler{
	public static Boolean triggerDisabled = false;
    public static string triggerName = 'ProductRecommendationTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        D1_ProductRecommendationTriggerHelper.populateUniqueKey(newItems, null); 
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) { 
        D1_ProductRecommendationTriggerHelper.populateUniqueKey(newItems.values(), oldItems); 
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        D1_ProductRecommendationTriggerHelper.checkAndGenerateSharing(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        D1_ProductRecommendationTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems); 
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
       
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}