/**********************************************************************
Name: EDGE_CallTypeTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for CallTypeTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       21/05/2019        ES20-1615
***********************************************************************/
public with sharing class EDGE_CallTypeTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Call_Type__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Call_Type__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Call_Type__c> mapOldItems;
        List<Call_Type__c> lstNewChangeGeography = new List<Call_Type__c>();
        List<Call_Type__c> lstOldChangeGeography = new List<Call_Type__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Call_Type__c>)oldItems;
        }
        
        for(Call_Type__c objCallType : newItems){
            if(mapOldItems.containsKey(objCallType.Id) && objCallType.Country__c != mapOldItems.get(objCallType.Id).Country__c){
                lstNewChangeGeography.add(objCallType);
                lstOldChangeGeography.add(mapOldItems.get(objCallType.Id));
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