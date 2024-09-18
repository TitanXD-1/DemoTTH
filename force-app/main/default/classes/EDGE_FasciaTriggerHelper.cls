/**********************************************************************
Name: EDGE_FasciaTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for FasciaTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh    21/05/2019        ES20-1615
***********************************************************************/
public with sharing class EDGE_FasciaTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Fascia__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Fascia__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Fascia__c> mapOldItems;
        List<Fascia__c> lstNewChangeGeography = new List<Fascia__c>();
        List<Fascia__c> lstOldChangeGeography = new List<Fascia__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Fascia__c>)oldItems;
        }
        
        for(Fascia__c objFascia : newItems){
            if(mapOldItems.containsKey(objFascia.Id) && objFascia.Country__c != mapOldItems.get(objFascia.Id).Country__c){
                lstNewChangeGeography.add(objFascia);
                lstOldChangeGeography.add(mapOldItems.get(objFascia.Id));
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