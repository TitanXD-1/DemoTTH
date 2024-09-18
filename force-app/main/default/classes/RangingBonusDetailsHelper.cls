/*
@ Name: RangingBonusDetailsHelper

@ Description: This is a helper class of RangingBonusDetailsTriggerHandler

@ History:                                                            
                                                            
VERSION        AUTHOR               DATE              DETAIL
1.0            Sagnik Sanyal        04/09/2024        156151 - Enable Country based Sharing _SFDC
*/

public with sharing class RangingBonusDetailsHelper {
    
    /*
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    */
    public static void checkAndGenerateSharing(List<Ranging_Bonus_Details__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');      
    }
    
    /*
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    */
    public static void validateAndReGenerateSharing(List<Ranging_Bonus_Details__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Ranging_Bonus_Details__c> mapOldItems;
        List<Ranging_Bonus_Details__c> lstNewChangeGeography = new List<Ranging_Bonus_Details__c>();
        List<Ranging_Bonus_Details__c> lstOldChangeGeography = new List<Ranging_Bonus_Details__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Ranging_Bonus_Details__c>)oldItems;
        }
        
        for(Ranging_Bonus_Details__c rangingBonusDetails : newItems){
            if(mapOldItems.containsKey(rangingBonusDetails.Id) && rangingBonusDetails.Country__c != mapOldItems.get(rangingBonusDetails.Id).Country__c){
                lstNewChangeGeography.add(rangingBonusDetails);
                lstOldChangeGeography.add(mapOldItems.get(rangingBonusDetails.Id));
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