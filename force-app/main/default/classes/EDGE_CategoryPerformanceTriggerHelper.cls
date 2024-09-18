/**********************************************************************
Name: EDGE_CategoryPerformanceTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for CategoryPerformanceTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       01/04/2019        ES20-1615
***********************************************************************/
public with sharing class EDGE_CategoryPerformanceTriggerHelper {
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Category_Performance__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Category_Performance__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Category_Performance__c> mapOldItems;
        List<Category_Performance__c> lstNewChangeGeography = new List<Category_Performance__c>();
        List<Category_Performance__c> lstOldChangeGeography = new List<Category_Performance__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Category_Performance__c>)oldItems;
        }
        
        for(Category_Performance__c objCatPerformance : newItems){
            if(mapOldItems.containsKey(objCatPerformance.Id) && objCatPerformance.Country__c != mapOldItems.get(objCatPerformance.Id).Country__c){
                lstNewChangeGeography.add(objCatPerformance);
                lstOldChangeGeography.add(mapOldItems.get(objCatPerformance.Id));
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