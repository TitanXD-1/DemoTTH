/**

* @description :  EDGE_MAPTriggerHelper

* @purpose : Trigger Helper Class for MarketAssortmentProductTrigger

* Version   Developer          Date            User Story/Purpose

* 1.1       Preyanka Ghosh     01/04/2019      ES20-1615
* 1.2		Sayan Samaddar	   23/04/2021	   NCP-2680(Method: checkAndGenerateD1Sharing, validateAndReGenerateD1Sharing)
* 1.3       Aparajita          31/08/2021      ES20-10916 - populateProductNameMAP

*/

public with sharing class EDGE_MAPTriggerHelper {
    
    /**

* @description : checkAndGenerateSharing - To create sharing record on Insert

* @return : void

* @param : List<Market_Assortment_Product__c>

*/
    public static void checkAndGenerateSharing(List<Market_Assortment_Product__c> newItems){
        
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Market_Assortment__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Market_Assortment__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Market_Assortment__c', 'Down', 'Edit');
        //Inserting the product sharing records
        EDGE_SharingUtil.insertProductSharing(newItems);
    }
    
    /**

* @description : validateAndReGenerateSharing - Modify, Validate sharing record on update

* @return : void

* @param : List<Market_Assortment_Product__c>, Map<Id, SObject>

*/
    public static void validateAndReGenerateSharing(List<Market_Assortment_Product__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Market_Assortment_Product__c> mapOldItems;
        List<Market_Assortment_Product__c> lstNewChangeGeography = new List<Market_Assortment_Product__c>();
        List<Market_Assortment_Product__c> lstOldChangeGeography = new List<Market_Assortment_Product__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Market_Assortment_Product__c>)oldItems;
        }
        
        for(Market_Assortment_Product__c objMAP : newItems){
            if(mapOldItems.containsKey(objMAP.Id) && objMAP.Market_Assortment__c != mapOldItems.get(objMAP.Id).Market_Assortment__c){
                lstNewChangeGeography.add(objMAP);
                lstOldChangeGeography.add(mapOldItems.get(objMAP.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Market_Assortment__c');
            // Deleting the existing product sharing records first for the old geography then inserting the sharing for new geography 
            EDGE_SharingUtil.deleteProductSharing(oldItems.values());
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Market_Assortment__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Market_Assortment__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Market_Assortment__c', 'Down', 'Edit');
            EDGE_SharingUtil.insertProductSharing(newItems);            
        }    
    }
    
    /**

* @description : checkAndGenerateD1Sharing

* @return : void

* @param : List<Market_Assortment_Product__c>

*/
    public static void checkAndGenerateD1Sharing(List<Market_Assortment_Product__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Market_Assortment__c');
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Market_Assortment__c', 'Read'); 
    }
    
    /**

* @description : validateAndReGenerateD1Sharing

* @return : void

* @param : List<Market_Assortment_Product__c>, Map<Id, SObject>

*/
    public static void validateAndReGenerateD1Sharing(List<Market_Assortment_Product__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Market_Assortment_Product__c> mapOldItems = new Map<Id, Market_Assortment_Product__c>();
        List<Market_Assortment_Product__c> lstNewChangeGeography = new List<Market_Assortment_Product__c>();
        List<Market_Assortment_Product__c> lstOldChangeGeography = new List<Market_Assortment_Product__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Market_Assortment_Product__c>)oldItems;
        }
        
        for(Market_Assortment_Product__c objMAP : newItems){
            if(mapOldItems.containsKey(objMAP.Id) && objMAP.Market_Assortment__c != mapOldItems.get(objMAP.Id).Market_Assortment__c){
                lstNewChangeGeography.add(objMAP);
                lstOldChangeGeography.add(mapOldItems.get(objMAP.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Market_Assortment__c');
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Market_Assortment__c');
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Market_Assortment__c', 'Read');
        }      
    }
    
    /**

* @description : populateProductNameMAP - populates Product_Name_MAP__c when record is created or Product__c is updated or removed

* @return : void

* @param : List<Market_Assortment_Product__c>, Map<Id, SObject>

*/
    public static void populateProductNameMAP(List<Market_Assortment_Product__c> newItems, Map<Id, SObject> oldItems)
    {
        List<Market_Assortment_Product__c> mapListToUpdate = new List<Market_Assortment_Product__c>();
        Set<Id> mapIds = (new Map<Id,Market_Assortment_Product__c>(newItems)).keySet();
        if(mapIds!=null && mapIds.size()>0)
        {
            for(Market_Assortment_Product__c mapObj : [SELECT Id, Product__c, Product__r.Name, Product_Name_MAP__c, Unique_ID__c FROM Market_Assortment_Product__c WHERE Id IN : mapIds])
            {
                //inserting & updating a product
                if(mapObj.Product__c!=null && (mapObj.Product_Name_MAP__c==null || (mapObj.Product_Name_MAP__c!=null && !mapObj.Product_Name_MAP__c.equals(mapObj.Product__r.Name))))
                {
                    mapObj.Product_Name_MAP__c = mapObj.Product__r.Name;
                    mapListToUpdate.add(mapObj);
                }
                //removing a product
                else if(mapObj.Product__c==null && mapObj.Product_Name_MAP__c!=null && mapObj.Unique_ID__c!=null)
                {
                    mapObj.Product_Name_MAP__c = null;
                    mapObj.Unique_ID__c = null;
                    mapListToUpdate.add(mapObj);
                } 	
            }
        }                
        if(mapListToUpdate!=null && mapListToUpdate.size()>0)
            Database.update(mapListToUpdate);
    }
}