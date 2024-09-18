/**********************************************************************
Name: EDGE_ExternalLinksTriggerHelper
=======================================================================
Purpose: This is to handle External Links Trigger Handler Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE			DETAIL
1.0         Amar Deep       04/03/2020      Initial Development
***********************************************************************/
public with sharing class EDGE_ExternalLinksTriggerHelper {
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<External_Links__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<External_Links__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, External_Links__c> mapOldItems;
        List<External_Links__c> lstNewChangeGeography = new List<External_Links__c>();
        List<External_Links__c> lstOldChangeGeography = new List<External_Links__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, External_Links__c>)oldItems;
        }
        
        for(External_Links__c extLinksObj : newItems){
            if(mapOldItems.containsKey(extLinksObj.Id) && extLinksObj.Country__c != mapOldItems.get(extLinksObj.Id).Country__c){
                lstNewChangeGeography.add(extLinksObj);
                lstOldChangeGeography.add(mapOldItems.get(extLinksObj.Id));
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