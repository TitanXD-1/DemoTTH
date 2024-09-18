/**********************************************************************
Name: EDGE_DeliveryPartnerTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for DeliveryPartnerTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh    17/06/2019        ES20-2230
***********************************************************************/
public with sharing class EDGE_DeliveryPartnerTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Delivery_Partner__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Delivery_Partner__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Delivery_Partner__c> mapOldItems;
        List<Delivery_Partner__c> lstNewChangeGeography = new List<Delivery_Partner__c>();
        List<Delivery_Partner__c> lstOldChangeGeography = new List<Delivery_Partner__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Delivery_Partner__c>)oldItems;
        }
        
        for(Delivery_Partner__c objDeliveryPartner : newItems){
            if(mapOldItems.containsKey(objDeliveryPartner.Id) && objDeliveryPartner.Country__c != mapOldItems.get(objDeliveryPartner.Id).Country__c){
                lstNewChangeGeography.add(objDeliveryPartner);
                lstOldChangeGeography.add(mapOldItems.get(objDeliveryPartner.Id));
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