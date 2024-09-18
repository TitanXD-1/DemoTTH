/**
 * @description Trigger Helper for Master Bundle
 * @name: EDGE_MasterBundleTriggerHelper
 * @history
 * @version     Developer           Date            User-Story/Purpose
 * 1.1          Shivam Chauhan      12/05/2022      ES20-13531(Access to Master Bundle Object_SFDC_Quality Equipments)
 * 1.2          Swagat Shaw         14/01/2023      NCP-7825(Implement Sharing for D1 External Users)
*/

public with sharing class EDGE_MasterBundleTriggerHelper {

	/**
* @description: checkAndGenerateSharing - To create sharing record on Insert
* @return: void
* @param: List<Master_Bundle__c>
*/
    public static void checkAndGenerateSharing(List<Master_Bundle__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Read');//NCP-7825
    }
    
    /**
* @description: validateAndReGenerateSharing - Modify, Validate sharing record on update
* @return: void
* @param: List<Master_Bundle__c>, Map<Id, SObject>
*/
    public static void validateAndReGenerateSharing(List<Master_Bundle__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Master_Bundle__c> mapOldItems;
        List<Master_Bundle__c> lstNewChangeGeography = new List<Master_Bundle__c>();
        List<Master_Bundle__c> lstOldChangeGeography = new List<Master_Bundle__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        if(oldItems != null){
            mapOldItems = (Map<Id, Master_Bundle__c>)oldItems;
        }
        
        for(Master_Bundle__c objBusinessRole : newItems){
            if(mapOldItems.containsKey(objBusinessRole.Id) && objBusinessRole.Country__c != mapOldItems.get(objBusinessRole.Id).Country__c){
                lstNewChangeGeography.add(objBusinessRole);
                lstOldChangeGeography.add(mapOldItems.get(objBusinessRole.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');//NCP-7825
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Read');//NCP-7825
        }       
    } 
}