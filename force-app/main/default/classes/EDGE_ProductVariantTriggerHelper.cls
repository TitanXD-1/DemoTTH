/**********************************************************************
Name: EDGE_ProductVariantTriggerHelper
=======================================================================
Req:  
User Story : ES20-4177
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sagar Barman        03/09/2019      Initial Development
1.1   Sagar Barman        14/10/2019      ES20-4312
***********************************************************************/
public with sharing class EDGE_ProductVariantTriggerHelper {
    public static void activateProduct(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> parentProductIdSet = new Set<Id>();
        List<Product__c> productListToUpdate = new List<Product__c>();
        Map<Id,List<Product_Variant__c>> mapProductWithVariant = new Map<Id,List<Product_Variant__c>>();
        Map<Id,Boolean> activeProductMap = new Map<Id,Boolean>();
        //get the parent Product SetIDss
        for(SObject sob :newItems.values()){
            Product_Variant__c newProdVariant = (Product_Variant__c)sob;
            Product_Variant__c oldProdVariant;
            if(oldItems != null){                
                oldProdVariant = (Product_Variant__c)oldItems.get(newProdVariant.Id);    
            }
            if((oldItems == null) || (oldItems!= null && ((newProdVariant.Product__c != null && (newProdVariant.Product__c != oldProdVariant.Product__c))
                                                          || (newProdVariant.Unit_Price__c != oldProdVariant.Unit_Price__c))))
            {
                parentProductIdSet.add(newProdVariant.Product__c);
            }
        }
        
        //get the Parent ProductList 
        Map<Id,Product__c> parentProductMap = new Map<Id,Product__c>([SELECT Id,IsActive__c,Pricing_Type__c,Expiry_Date__c,Start_Date__c FROM Product__c WHERE ID IN : parentProductIdSet]);        
        
        //get the existing child Product Variants
        List<Product_Variant__c> childProductVariantList = new List<Product_Variant__c>();     
        if(Schema.SObjectType.Product_Variant__c.isAccessible() && Schema.SObjectType.Product__c.isAccessible()){
            childProductVariantList = [SELECT Id,Unit_Price__c,Product__c FROM Product_Variant__c WHERE Product__c IN : parentProductIdSet];
        }
        
        //populate mapProductWithVariant
        if(childProductVariantList != null && !childProductVariantList.isEmpty()){
            for(Product_Variant__c pvar : childProductVariantList){
                if(mapProductWithVariant.containsKey(pvar.Product__c)){
                    mapProductWithVariant.get(pvar.Product__c).add(pvar);
                }
                else{
                    mapProductWithVariant.put(pvar.Product__c, new List<Product_Variant__c>{pvar});
                }
            }
        }
        
        if(null != mapProductWithVariant && !mapProductWithVariant.isEmpty()){
            for(Id prodId : mapProductWithVariant.keySet()){
                Boolean isActive = false;
                for(Product_Variant__c pvar : mapProductWithVariant.get(prodId)){
                    if(null != pvar.Unit_Price__c && pvar.Unit_Price__c >= 0){ 
                        isActive = true; 
                        break;
                    }
                }
                activeProductMap.put(prodId, isActive);
            }
        }
        
        for(SObject sob :newItems.values()){
            Product_Variant__c newProdVariant = (Product_Variant__c)sob;
            
            if(parentProductMap.containsKey(newProdVariant.Product__c)){
                Product__c prod = parentProductMap.get(newProdVariant.Product__c);
                if(prod.Pricing_Type__c == 'By Size' && (prod.Expiry_Date__c > System.today() || prod.Expiry_Date__c == null)
                   && prod.Start_Date__c <= System.today())
                {
                    prod.IsActive__c = activeProductMap.get(newProdVariant.Product__c);
                    productListToUpdate.add(prod);
                }
            }
        }
        //update the productList
        if(productListToUpdate.size()>0 && Schema.SObjectType.Product__c.isUpdateable()){
            update productListToUpdate;
        }
    }
}