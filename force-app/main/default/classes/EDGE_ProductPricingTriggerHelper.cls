/**********************************************************************
Name: EDGE_ProductPricingTriggerHelper
=======================================================================
Req: 
ES20-4028 : SFDC_New Object 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE           DETAIL
1.0     Manikant Pr     21/08/2019     ES20-4028 : SFDC_New Object
1.1     Sagar Barman    14/10/2019     ES20-4312 
***********************************************************************/
public with sharing class EDGE_ProductPricingTriggerHelper {
    
    //Method to validate Product Range
    public static void validateProductRange(List<Product_Pricing__c> newItems){
        Set<Id> productSetId = new Set<Id>();
        String errorRange = '';
        Map<Id,String > errorMap = new Map<Id,String >();
        List<Product_Pricing__c> existingProductPricingList = new List<Product_Pricing__c>();
        for(Product_Pricing__c productPricRec : newItems){
            productSetId.add(productPricRec.Product__c);
        } 
        if(Schema.SObjectType.Product_Pricing__c.isAccessible()){
            existingProductPricingList = [Select id ,Product__c,Range_End__c,Range_Start__c from Product_Pricing__c where product__c IN :productSetId ]; 
        }
        for (Product_Pricing__c existingproductPricingRec : existingProductPricingList){
            for(Product_Pricing__c newProductPricingRec : newItems){
                if(newProductPricingRec.Product__c == existingproductPricingRec.Product__c){                    
                    String temp = '[' +String.valueOf(existingproductPricingRec.Range_Start__c)+'-'+String.valueOf(existingproductPricingRec.Range_End__c) +']';
                    errorRange += ' ' +temp;
                    system.debug('productValue '+existingproductPricingRec.Product__c);
                    errorMap.put(existingproductPricingRec.Product__c , errorRange);
                }
                if(newProductPricingRec.Product__c == existingproductPricingRec.Product__c && errorMap != null &&
                   newProductPricingRec.Range_Start__c >= existingproductPricingRec.Range_Start__c
                   && newProductPricingRec.Range_Start__c <= existingproductPricingRec.Range_End__c 
                   ||(newProductPricingRec.Range_End__c >= existingproductPricingRec.Range_Start__c && 
                      newProductPricingRec.Range_End__c <= existingproductPricingRec.Range_End__c)
                   || (newProductPricingRec.Range_Start__c < existingproductPricingRec.Range_Start__c &&
                       newProductPricingRec.Range_End__c > existingproductPricingRec.Range_End__c)) 
                {
                    if((newProductPricingRec.Id!= existingproductPricingRec.Id) || newProductPricingRec.Id==null)
                    {
                        newProductPricingRec.addError(+Label.EDGE_ProductPricingError+ ' ' +errorMap.get(existingproductPricingRec.Product__c) +' . '+Label.EDGE_ProductPricingError1);                          
                    }
                }
            }
        }
    }
    
    // the below method is to activate the product
    public static void activateProduct(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> parentProductIdSet = new Set<Id>();
        List<Product__c> productListToUpdate = new List<Product__c>();
        Map<Id,List<Product_Pricing__c>> mapProductWithPricing = new Map<Id,List<Product_Pricing__c>>();
        Map<Id,Boolean> activeProductMap = new Map<Id,Boolean>();
        //get the parent Product SetIDss
        for(SObject sob :newItems.values()){
            Product_Pricing__c newProdPricing = (Product_Pricing__c)sob;
            Product_Pricing__c oldProdPricing;
            if(oldItems != null){
                oldProdPricing = (Product_Pricing__c)oldItems.get(newProdPricing.Id);
            }
            if((oldItems == null) || (oldItems!= null && ((newProdPricing.Product__c != null && (newProdPricing.Product__c != oldProdPricing.Product__c))
                                                          || (newProdPricing.Range_Price__c != oldProdPricing.Range_Price__c))))
            {
                parentProductIdSet.add(newProdPricing.Product__c);          
            }
        }
        
        //get the Parent ProductList and its Range_Price__c
        Map<Id,Product__c> parentProductMap = new Map<Id,Product__c>([SELECT Id,IsActive__c,Pricing_Type__c,Expiry_Date__c,Start_Date__c FROM Product__c WHERE ID IN : parentProductIdSet]);        
        
        //get the existing child Product Pricing
        List<Product_Pricing__c> childProductPricingList = new List<Product_Pricing__c>();// existing child Product Variant List        
        
        //add isAccessible check
        if(Schema.SObjectType.Product_Pricing__c.isAccessible()){
            childProductPricingList = [SELECT Id,Range_Price__c,Product__c FROM Product_Pricing__c WHERE Product__c IN : parentProductIdSet];
        }
        
        //populate mapProductWithPricing
        if(childProductPricingList != null && !childProductPricingList.isEmpty()){
            for(Product_Pricing__c pvar : childProductPricingList){
                if(mapProductWithPricing.containsKey(pvar.Product__c)){
                    mapProductWithPricing.get(pvar.Product__c).add(pvar);                        
                }
                else{
                    mapProductWithPricing.put(pvar.Product__c, new List<Product_Pricing__c>{pvar});
                }
            }
        }
        
        if(null != mapProductWithPricing && !mapProductWithPricing.isEmpty()){
            for(Id prodId : mapProductWithPricing.keySet()){
                Boolean isActive = false;
                for(Product_Pricing__c ppr : mapProductWithPricing.get(prodId)){
                    if(null != ppr.Range_Price__c && ppr.Range_Price__c >= 0){ 
                        isActive = true; 
                        break;
                    }
                }
                activeProductMap.put(prodId, isActive);
            }       
        }
        
        for(SObject sob :newItems.values()){
            Product_Pricing__c newProdPricing = (Product_Pricing__c)sob;  
            if(parentProductMap.containsKey(newProdPricing.Product__c)){
                Product__c prod = parentProductMap.get(newProdPricing.Product__c);
                if(prod.Pricing_Type__c == 'By Quantity' && (prod.Expiry_Date__c > System.today() || prod.Expiry_Date__c == null)
                   && prod.Start_Date__c <= System.today())
                {
                    prod.IsActive__c = activeProductMap.get(newProdPricing.Product__c);
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