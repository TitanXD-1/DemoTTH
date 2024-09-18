public with sharing class EDGE_CreateProductVariantController {
    
    @AuraEnabled
    public static RecordType getProductVariantRecordType(string productId){
        RecordType pRecordType = new RecordType();
        if(string.isNotBlank(productId)){
            //Get Product Details
            Product__c prod = [SELECT Id, Name, Product_Type__c, Product_Type__r.Name FROM Product__c WHERE Id =:productId LIMIT 1];
            
            //Get RecordType Details
            if(prod.Product_Type__c != null){
                string productType = prod.Product_Type__r.Name;
                for(RecordType rType : [SELECT Id, DeveloperName, Name, SobjectType FROM RecordType WHERE SobjectType = 'Product_Variant__c']){
                    if(rType.Name == 'POS Uniform'){
                        if(productType.containsIgnoreCase('uniform')){
                            pRecordType = rType;
                            break;
                        }
                    }else{
                        if(!productType.containsIgnoreCase('uniform')){
                            pRecordType = rType;
                            break;
                        }
                    }
                }
            }
        }
        return pRecordType;
    }
}