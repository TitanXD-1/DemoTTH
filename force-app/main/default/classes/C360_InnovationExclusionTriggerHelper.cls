/**
 
* @description : C360_InnovationExclusionTriggerHelper

* @purpose : Provide access to Innovation_Exclusion_Brand__c

* @history

* Version   Developer            Date            User Story	          Purpose

   1.0 -    Nidhi/Stuti         13/10/2023      146952 - Provide access to new Objects_Tech_SFDC
   2.0 -    Nidhi/Stuti         14/11/2023      147559 - Currency of I&E must match currency of the country
*/

public with sharing class C360_InnovationExclusionTriggerHelper {
     /**
    * @description To create sharing record on Insert
    * @return void
    * @param newItems (List<Innovation_Exclusion_Brand__c>)
    */
    public static void checkAndGenerateSharing(List<Innovation_Exclusion_Brand__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    

    /**
* @description Modify, Validate sharing record on update
* @return void
* @param newItems (List<Innovation_Exclusion_Brand__c>), oldItems(Map<Id, SObject>)
*/
    public static void validateAndReGenerateSharing(List<Innovation_Exclusion_Brand__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Innovation_Exclusion_Brand__c> mapOldItems;
        List<Innovation_Exclusion_Brand__c> lstNewChangeGeography = new List<Innovation_Exclusion_Brand__c>();
        List<Innovation_Exclusion_Brand__c> lstOldChangeGeography = new List<Innovation_Exclusion_Brand__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Innovation_Exclusion_Brand__c>)oldItems;
        }
        
        for(Innovation_Exclusion_Brand__c objBusinessRole : newItems){
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

    /**
    * @description updateInnovation&ExclusionBrandCurrency
    * Update Currency based on Geography Currency (User Story Numner:147559)
    * @param List    
    */
    
    public static void updateIECurrency(List<Innovation_Exclusion_Brand__c> recNew){
        
        Set<String> countryList = new Set<String>();
        Map<String, String> populateCurrency = new Map<String, String>();
        
        for(Innovation_Exclusion_Brand__c inn : recNew){
            if(inn.Country__c !=null){
                countryList.add(inn.Country__c);
            }
        }
        if(!countryList.isEmpty() && Schema.sObjectType.Geography__c.isAccessible()){
            for(Geography__c geographyCurrency: [SELECT CurrencyIsoCode
                                                 FROM Geography__c WHERE Id IN: countryList])
            {
                populateCurrency.put(geographyCurrency.id,geographyCurrency.CurrencyIsoCode);
            } 
        }
        for(Innovation_Exclusion_Brand__c inn : recNew){
            if(populateCurrency != null &&  populateCurrency.containskey(inn.Country__c)){
                inn.CurrencyIsoCode = populateCurrency.get(inn.Country__c);
            }
        }
    } 
}