/**********************************************************************
Name: EDGE_BusinessRoleTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for BusinessRoleTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       21/05/2019        ES20-1615
***********************************************************************/
public with sharing class EDGE_BusinessRoleTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Business_Role__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Business_Role__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Business_Role__c> mapOldItems;
        List<Business_Role__c> lstNewChangeGeography = new List<Business_Role__c>();
        List<Business_Role__c> lstOldChangeGeography = new List<Business_Role__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Business_Role__c>)oldItems;
        }
        
        for(Business_Role__c objBusinessRole : newItems){
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
        }       
    }
}