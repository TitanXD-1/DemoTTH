/**
Name: EDGE_CaseTemplateTriggerHelper

Purpose: Trigger Helper Class for CaseTemplateTriggerHandler

History                                                            
                                                          
VERSION   AUTHOR              DATE              DETAIL
1.0       Anand Uppalapati    10/01/2022        ES20-11891
**/
public with sharing class EDGE_CaseTemplateTriggerHelper {
    
    /**
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    **/
    public static void checkAndGenerateSharing(List<Case_Template__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /**
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    **/
    public static void validateAndReGenerateSharing(List<Case_Template__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Case_Template__c> mapOldItems;
        List<Case_Template__c> lstNewChangeGeography = new List<Case_Template__c>();
        List<Case_Template__c> lstOldChangeGeography = new List<Case_Template__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Case_Template__c>)oldItems;
        }
        
        for(Case_Template__c objCaseTemplate : newItems){
            if(mapOldItems.containsKey(objCaseTemplate.Id) && objCaseTemplate.Country__c != mapOldItems.get(objCaseTemplate.Id).Country__c){
                lstNewChangeGeography.add(objCaseTemplate);
                lstOldChangeGeography.add(mapOldItems.get(objCaseTemplate.Id));
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