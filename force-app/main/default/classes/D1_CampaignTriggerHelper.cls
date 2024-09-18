/**
 * @name D1_CampaignHelper
 * @description Trigger Helper Class for CampaignTrigger
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0        Rithika        09/12/21         
 **/
public with sharing class D1_CampaignTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Campaign> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Campaign> newItems,Map<Id, SObject> oldItems){
        Map<Id, Campaign> mapOldItems;
        List<Campaign> lstNewChangeGeography = new List<Campaign>();
        List<Campaign> lstOldChangeGeography = new List<Campaign>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Campaign>)oldItems;
        }
        for(Campaign objTargetList : newItems){
            if(mapOldItems.containsKey(objTargetList.Id) && objTargetList.Country__c != mapOldItems.get(objTargetList.Id).Country__c){
                lstNewChangeGeography.add(objTargetList);
                lstOldChangeGeography.add(mapOldItems.get(objTargetList.Id));
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