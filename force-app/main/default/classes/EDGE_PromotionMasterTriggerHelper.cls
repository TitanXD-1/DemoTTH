/*
* @name PromotionMasterTrigger
* @purpose - This is to execute the trigger helper methods
* @history
* Version              Author                   Date            Detail
   1.0              Mayukh/Geethika           17/06/2022      ES20-12989 - To make a Promotion master record visible across all the users in the country_ SFDC_ Promo Transfer Order
*/



public with sharing class EDGE_PromotionMasterTriggerHelper {
    
    
/*
* @description To create sharing record on Insert
* @return void
* @param newItems (List<Promotion_Master__c>)
*/
    public static void checkAndGenerateSharing(List<Promotion_Master__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    
/*
* @description Modify, Validate sharing record on update
* @return void
* @param newItems (List<Promotion_Master__c>), oldItems(Map<Id, SObject>)
*/
    public static void validateAndReGenerateSharing(List<Promotion_Master__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Promotion_Master__c> mapOldItems;
        List<Promotion_Master__c> lstNewChangeGeography = new List<Promotion_Master__c>();
        List<Promotion_Master__c> lstOldChangeGeography = new List<Promotion_Master__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Promotion_Master__c>)oldItems;
        }
        
        for(Promotion_Master__c obj : newItems){
            if(mapOldItems.containsKey(obj.Id) && obj.Country__c != mapOldItems.get(obj.Id).Country__c){
                lstNewChangeGeography.add(obj);
                lstOldChangeGeography.add(mapOldItems.get(obj.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
}