/**********************************************************************
Name: EDGE_TargetListHelper
=======================================================================
Purpose: Trigger Helper Class for TargetListTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       21/05/2019        ES20-1615
***********************************************************************/
public with sharing class EDGE_TargetListHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Target_List__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Target_List__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Target_List__c> mapOldItems;
        List<Target_List__c> lstNewChangeGeography = new List<Target_List__c>();
        List<Target_List__c> lstOldChangeGeography = new List<Target_List__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Target_List__c>)oldItems;
        }
        
        for(Target_List__c objTargetList : newItems){
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