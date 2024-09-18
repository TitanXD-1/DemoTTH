/*
* @name: D1_MarketProduct2TriggerHelper
* @discription: Trigger Helper for Market_Product2__c
* @History
* VERSION     AUTHOR         DATE       DETAIL
* 1.0         Ajay                    Initial Development (NCP-2857)
*/
public with sharing class D1_MarketProduct2TriggerHelper {
    
    /*
    * @name  : checkAndGenerateSharing
    * @discription : To create sharing record on Insert
    */
    public static void checkAndGenerateSharing(List<Market_Product2__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Market__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Market__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Market__c', 'Down', 'Edit');
    }

    /*
    * @name  : validateAndReGenerateSharing
    * @discription : Modify, Validate sharing record on update
    */
    public static void validateAndReGenerateSharing(List<Market_Product2__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Market_Product2__c> mapOldItems;
        List<Market_Product2__c> lstNewChangeGeography = new List<Market_Product2__c>();
        List<Market_Product2__c> lstOldChangeGeography = new List<Market_Product2__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Market_Product2__c>)oldItems;
        }
        
        for(Market_Product2__c objMAP : newItems){
            if(mapOldItems.containsKey(objMAP.Id) && objMAP.Market__c != mapOldItems.get(objMAP.Id).Market__c){
                lstNewChangeGeography.add(objMAP);
                lstOldChangeGeography.add(mapOldItems.get(objMAP.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Market__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Market__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Market__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Market__c', 'Down', 'Edit');
        }  
    }

    /*
    * @name  : checkAndGenerateD1Sharing
    * @discription : Modify, Validate D1 sharing record on Insert
    */
    public static void checkAndGenerateD1Sharing(List<Market_Product2__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Market__c');
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Market__c', 'Read'); 
    }

    /*
    * @name  : checkAndGenerateD1Sharing
    * @discription : Modify, Validate D1 sharing record on update
    */
    public static void validateAndReGenerateD1Sharing(List<Market_Product2__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Market_Product2__c> mapOldItems = new Map<Id, Market_Product2__c>();
        List<Market_Product2__c> lstNewChangeGeography = new List<Market_Product2__c>();
        List<Market_Product2__c> lstOldChangeGeography = new List<Market_Product2__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Market_Product2__c>)oldItems;
        }
        
        for(Market_Product2__c objMAP : newItems){
            if(mapOldItems.containsKey(objMAP.Id) && objMAP.Market__c != mapOldItems.get(objMAP.Id).Market__c){
                lstNewChangeGeography.add(objMAP);
                lstOldChangeGeography.add(mapOldItems.get(objMAP.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Market__c');
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Market__c');
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Market__c', 'Read');
        }       
    }

}