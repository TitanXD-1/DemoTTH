/**********************************************************************
Name: ECM_AgreementTypeTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for AgreementTypeTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Anivesh Muppa       12/12/2020         ECM-3573
***********************************************************************/
public with sharing class ECM_AgreementTypeTriggerHelper {
        
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<ECM_Contract_Type__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<ECM_Contract_Type__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, ECM_Contract_Type__c> mapOldItems;
        List<ECM_Contract_Type__c> lstNewChangeGeography = new List<ECM_Contract_Type__c>();
        List<ECM_Contract_Type__c> lstOldChangeGeography = new List<ECM_Contract_Type__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, ECM_Contract_Type__c>)oldItems;
        }
        
        for(ECM_Contract_Type__c objAgreementType : newItems){
            if(mapOldItems.containsKey(objAgreementType.Id) && objAgreementType.Geography__c != mapOldItems.get(objAgreementType.Id).Geography__c){
                lstNewChangeGeography.add(objAgreementType);
                lstOldChangeGeography.add(mapOldItems.get(objAgreementType.Id));
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