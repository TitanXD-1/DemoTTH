/**********************************************************************
Name: EDGE_TerritoryHierarchyTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for TerritoryHierarchyTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       21/05/2019        ES20-1615
***********************************************************************/
public with sharing class EDGE_TerritoryHierarchyTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Territory_Hierarchy__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Territory_Hierarchy__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Territory_Hierarchy__c> mapOldItems;
        List<Territory_Hierarchy__c> lstNewChangeGeography = new List<Territory_Hierarchy__c>();
        List<Territory_Hierarchy__c> lstOldChangeGeography = new List<Territory_Hierarchy__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Territory_Hierarchy__c>)oldItems;
        }
        
        for(Territory_Hierarchy__c objTerritoryHierarchy : newItems){
            if(mapOldItems.containsKey(objTerritoryHierarchy.Id) && objTerritoryHierarchy.Geography__c != mapOldItems.get(objTerritoryHierarchy.Id).Geography__c){
                lstNewChangeGeography.add(objTerritoryHierarchy);
                lstOldChangeGeography.add(mapOldItems.get(objTerritoryHierarchy.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Down', 'Edit');
        }       
    }
}