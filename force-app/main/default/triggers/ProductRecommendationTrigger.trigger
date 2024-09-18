/*
 * @Name: ProductRecommendationTrigger 
 * @Description: This is to handle Product Recommendation Trigger Events
 * @History                                                            
                                                         
    VERSION    AUTHOR               DATE               DETAIL
    1.0        Pratap Sen         22-02-2023       Initial Development
*/ 
trigger ProductRecommendationTrigger on D1_Product_Recommendation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new ProductRecommendationTriggerHandler()); // calling handler class
}