public class EDGE_CreatePromotionHelper {    
    @AuraEnabled    
    public static string getRecordTypesAll(){
        Id promotionByWholslrRecTypeId = Promotion__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Promotions by wholesaler').getRecordTypeId();
        return promotionByWholslrRecTypeId;
    }
}