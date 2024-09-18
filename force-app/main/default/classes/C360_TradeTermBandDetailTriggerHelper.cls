/**
 
* @description : C360_TradeTermBandDetailTriggerHelper

* @purpose : Provide access to Trade_Term_Band_Detail__c

* @history

* Version   Developer            Date            User Story	          Purpose

   1.0 -    Nidhi/Stuti         13/10/2023      146952 - Provide access to new Objects_Tech_SFDC
   2.0 -    Nidhi/Stuti         14/11/2023      147559 - Currency of TT Band must match currency of the country
*/


public with sharing class C360_TradeTermBandDetailTriggerHelper {
    

    /**
    * @description To create sharing record on Insert
    * @return void
    * @param newItems (List<Trade_Term_Band_Detail__c>)
    */
    public static void checkAndGenerateSharing(List<Trade_Term_Band_Detail__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    

    /**
* @description Modify, Validate sharing record on update
* @return void
* @param newItems (List<Trade_Term_Band_Detail__c>), oldItems(Map<Id, SObject>)
*/
    public static void validateAndReGenerateSharing(List<Trade_Term_Band_Detail__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Trade_Term_Band_Detail__c> mapOldItems;
        List<Trade_Term_Band_Detail__c> lstNewChangeGeography = new List<Trade_Term_Band_Detail__c>();
        List<Trade_Term_Band_Detail__c> lstOldChangeGeography = new List<Trade_Term_Band_Detail__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Trade_Term_Band_Detail__c>)oldItems;
        }
        
        for(Trade_Term_Band_Detail__c objBusinessRole : newItems){
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
    * @description updateTradeTermCurrency
    * Update Currency based on Geography Currency (User Story Numner:147559)
    * @param List    
    */
    
    public static void updateTradeTermCurrency(List<Trade_Term_Band_Detail__c> recNew){
        
        Set<String> countryList = new Set<String>();
        Map<String, String> populateCurrency = new Map<String, String>();
        
        for(Trade_Term_Band_Detail__c trade : recNew){
            if(trade.Country__c !=null){
                countryList.add(trade.Country__c);
            }
        }
        if(!countryList.isEmpty() && Schema.sObjectType.Geography__c.isAccessible()){
            for(Geography__c geographyCurrency: [SELECT CurrencyIsoCode
                                                 FROM Geography__c WHERE Id IN: countryList])
            {
                populateCurrency.put(geographyCurrency.id,geographyCurrency.CurrencyIsoCode);
            } 
        }
        for(Trade_Term_Band_Detail__c trade : recNew){
            if(populateCurrency != null &&  populateCurrency.containskey(trade.Country__c)){
                trade.CurrencyIsoCode = populateCurrency.get(trade.Country__c);
            }
        }
    } 
}