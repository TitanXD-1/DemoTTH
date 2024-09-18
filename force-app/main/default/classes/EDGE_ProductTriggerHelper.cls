/**********************************************************************
Name: EDGE_ProductTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for ProductTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh    23/06/2019        ES20-2624
1.1       Sagar Barman      14/10/2019        ES20-4312 
***********************************************************************/
public with sharing class EDGE_ProductTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Product__c> newItems){
        String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        List<Product__c> lstPOSProduct = new List<Product__c>();
        
        for(Product__c newProduct : newItems){
            if(newProduct.RecordTypeId == posRecordTypeId){
                lstPOSProduct.add(newProduct);
            }
        }
        
        if(lstPOSProduct != null && lstPOSProduct.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstPOSProduct, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstPOSProduct, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstPOSProduct, 'Country__c', 'Down', 'Edit');
        }      
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Product__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Product__c> mapOldItems;
        List<Product__c> lstNewChangeGeography = new List<Product__c>();
        List<Product__c> lstOldChangeGeography = new List<Product__c>();
        String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Product__c>)oldItems;
        }
        
        
        
        for(Product__c objProduct : newItems){
            if(objProduct.RecordTypeId == posRecordTypeId && mapOldItems.containsKey(objProduct.Id) && objProduct.Country__c != mapOldItems.get(objProduct.Id).Country__c){
                lstNewChangeGeography.add(objProduct);
                lstOldChangeGeography.add(mapOldItems.get(objProduct.Id));
            }
        }
        
        
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateEditPermission(lstNewChangeGeography);
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
    /**************************************************
    method : ActivateProduct
    Purpose : This method will activate the product based on the condition of product type during update. 
    *****************************************************/    
    public static void activateProduct(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set <Id> productIdSet = new Set<Id>();
        String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        Map<Id, Product__c> mapNewProduct, mapOldProduct;        
        if(oldItems != null){
            mapOldProduct = (Map<Id, Product__c>) oldItems;
        }       
        if(newItems != null && Schema.SObjectType.Product_Pricing__c.isAccessible() && Schema.SObjectType.Product_variant__c.isAccessible()){
            mapNewProduct = (Map<Id, Product__c>) newItems;            
            List<Product_variant__c> prodVariList = [Select Id,Product__c,Unit_Price__c from Product_variant__c where Product__c IN : mapNewProduct.keySet()]; 
            List<Product_Pricing__c> prodPricList = [Select Id,Product__c,Range_Price__c From Product_Pricing__c where Product__c IN : mapNewProduct.keySet()];   
            Map<Id,List<Product_variant__c>> mapProductVariant = new Map<Id,List<Product_variant__c>>();
            Map<Id,List<Product_Pricing__c>> mapProductPricing = new Map<Id,List<Product_Pricing__c>>();
            //populate mapProductWithVariant
            if(prodVariList != null && !prodVariList.isEmpty()){
                for(Product_variant__c pvar : prodVariList){
                    if(mapProductVariant.containsKey(pvar.Product__c)){
                        mapProductVariant.get(pvar.Product__c).add(pvar);                        
                    }
                    else{
                        mapProductVariant.put(pvar.Product__c, new List<Product_variant__c>{pvar});
                    }
                }
            }
            //populate mapProductPricing
            if(prodPricList != null && !prodPricList.isEmpty()){
                for(Product_Pricing__c ppr : prodPricList){
                    if(mapProductPricing.containsKey(ppr.Product__c)){
                        mapProductPricing.get(ppr.Product__c).add(ppr);                        
                    }
                    else{
                        mapProductPricing.put(ppr.Product__c, new List<Product_Pricing__c>{ppr});
                    }
                }
            }
            
            for(Id productId : mapNewProduct.keySet()){ 
                Product__c productNewRec = mapNewProduct.get(productId);
                Product__c productOldRec = mapOldProduct.get(productId);
                if(((productNewRec.Expiry_Date__c > System.today() || productNewRec.Expiry_Date__c == null) 
                        && productNewRec.Start_Date__c <= System.today()) && (productNewRec.RecordTypeId == posRecordTypeId)
                        && ((productOldRec.Start_Date__c != productNewRec.Start_Date__c) 
                        || (productOldRec.Expiry_Date__c != productNewRec.Expiry_Date__c) 
                        || (productOldRec.Pricing_Type__c != productNewRec.Pricing_Type__c)
                        || ((productOldRec.A_P_Cost__c != productNewRec.A_P_Cost__c) && (productNewRec.Pricing_Type__c == 'By Unit'))))
                {
                    
                    if(productNewRec.Pricing_Type__c == 'By Unit' && productNewRec.A_P_Cost__c >= 0){
                        productNewRec.IsActive__c = true;
                    }
                    else if(productNewRec.Pricing_Type__c == 'By Unit' && productNewRec.A_P_Cost__c < 0){
                        productNewRec.IsActive__c = false;
                    }
                    else if(productNewRec.Pricing_Type__c == 'By Size'){
                        Boolean isActive = false;
                        if(null != mapProductVariant && !mapProductVariant.isEmpty()){
                            for(Product_variant__c prodVarRec : mapProductVariant.get(productId)){ 
                                if(null != prodVarRec.Unit_Price__c && prodVarRec.Unit_Price__c >= 0){
                                    isActive = true; 
                                    break;
                                }                        
                            }
                        }
                        productNewRec.IsActive__c = isActive; 
                    }
                    else if(productNewRec.Pricing_Type__c == 'By Quantity'){
                        Boolean isActive = false;
                        if(null != mapProductPricing && !mapProductPricing.isEmpty()){
                            for(Product_Pricing__c prodPricRec : mapProductPricing.get(productId)){ 
                                if(null != prodPricRec.Range_Price__c && prodPricRec.Range_Price__c >= 0){
                                    isActive = true; 
                                    break;
                                }
                            }
                        }
                        productNewRec.IsActive__c = isActive;   
                    }
                }else if(productNewRec.Expiry_Date__c <= System.today()){
                    productNewRec.IsActive__c = false; 
                }else if(productNewRec.Start_Date__c > System.today() && (productNewRec.Expiry_Date__c > productNewRec.Start_Date__c 
                                                                          || productNewRec.Expiry_Date__c == NULL))
                {
                    productNewRec.IsActive__c = false;
                }
            }
        }
    } 
    
   /**************************************************
    method : activateProductOnInsert
    Purpose : This method will activate the product on insert  if the pricing type is 'by unit'. 
    *****************************************************/ 
    public static void activateProductOnInsert(List<Product__c> newItems){
        String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        for(Product__c newProduct : newItems){
            if(newProduct.RecordTypeId == posRecordTypeId && newProduct.Pricing_Type__c == 'By Unit' && newProduct.A_P_Cost__c >= 0 
              && (newProduct.Expiry_Date__c > System.today() || newProduct.Expiry_Date__c == null) && newProduct.Start_Date__c == System.today()){
                newProduct.IsActive__c = true;
            }
        }        
    }
}