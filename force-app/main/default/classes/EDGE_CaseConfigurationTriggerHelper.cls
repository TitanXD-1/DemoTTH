/**
 
* @description : EDGE_CaseConfigurationTriggerHelper

* @purpose : Creation of Quality Case Configuration Object : Sharing Rules - ES20-10796


* @history

* Version   Developer        Date            User Story	          Purpose

*  VERSION   AUTHOR            DATE              DETAIL
1.0     Sudipta Nandi    26/07/2021        Initial Development
*/


public with sharing class EDGE_CaseConfigurationTriggerHelper {
    

    /**
* @description To create sharing record on Insert
* @return void
* @param newItems (List<Quality_Case_Configuration__c>)
*/
    public static void checkAndGenerateSharing(List<Quality_Case_Configuration__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    

    /**
* @description Modify, Validate sharing record on update
* @return void
* @param newItems (List<Quality_Case_Configuration__c>), oldItems(Map<Id, SObject>)
*/
    public static void validateAndReGenerateSharing(List<Quality_Case_Configuration__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Quality_Case_Configuration__c> mapOldItems;
        List<Quality_Case_Configuration__c> lstNewChangeGeography = new List<Quality_Case_Configuration__c>();
        List<Quality_Case_Configuration__c> lstOldChangeGeography = new List<Quality_Case_Configuration__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Quality_Case_Configuration__c>)oldItems;
        }
        
        for(Quality_Case_Configuration__c objBusinessRole : newItems){
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
     public static void enableDefaultRoleflag(List<SObject> newItems,Map<Id,SObject> oldItems){
        List<Quality_Case_Configuration__c> caseConfigList = (List<Quality_Case_Configuration__c>)newItems;
        Map<Id,Quality_Case_Configuration__c> oldCaseConfigMap= (Map<Id,Quality_Case_Configuration__c>) oldItems;
        
        if(caseConfigList != null && caseConfigList.Size() > 0){
            for(Quality_Case_Configuration__c configRec:caseConfigList){
                if(oldCaseConfigMap != null && oldCaseConfigMap.Size() > 0){
                    Quality_Case_Configuration__c oldConfig = oldCaseConfigMap.get(configRec.Id);
                    if(oldConfig.Default_Business_Role__c != configRec.Default_Business_Role__c){
                        configRec.Is_Default_Role_Changed__c = true;
                    }
                }
            }
        }               
    }
}