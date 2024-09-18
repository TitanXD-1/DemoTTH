/*
Name: EDGE_StockTransactionTriggerHelper

Purpose: Trigger Helper Class for StockTransactionTriggerHandler

History                                                            
-------                                                            
VERSION   AUTHOR              DATE              DETAIL
1.0       Preyanka Ghosh      15/06/2019        ES20-2232
1.1       Anuja Chattopadhyay 18/06/2019        ES20-2233,stockRollup method added to roll up Quantity field to Stock
1.2       Amar Deep           12/11/2019        ES20-5487,areaMandatoryBasedOnMarket method added
1.3       Manikant Prasad     14/11/2019        ES20-5488 , Modifield existing method stockRollUp (Added Logic for Area level)
1.4       Doman Murmu         04/10/2023        146443 - EDGE Static Code Violation
*/
public with sharing class EDGE_StockTransactionTriggerHelper {
    
/*
Method  : checkAndGenerateSharing
Purpose : To create sharing record on Insert
*/
    public static void checkAndGenerateSharing(List<Stock_Transaction__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
/*
Method  : validateAndReGenerateSharing
Purpose : Modify, Validate sharing record on update
*/
    public static void validateAndReGenerateSharing(List<Stock_Transaction__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Stock_Transaction__c> mapOldItems;
        List<Stock_Transaction__c> lstNewChangeGeography = new List<Stock_Transaction__c>();
        List<Stock_Transaction__c> lstOldChangeGeography = new List<Stock_Transaction__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Stock_Transaction__c>)oldItems;
        }
        
        for(Stock_Transaction__c objStock : newItems){
            if(mapOldItems.containsKey(objStock.Id) && objStock.Country__c != mapOldItems.get(objStock.Id).Country__c){
                lstNewChangeGeography.add(objStock);
                lstOldChangeGeography.add(mapOldItems.get(objStock.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
    
/*
Method  : stockRollup
Purpose : Rolling up quantity amount from stock transaction to related stock
*/
    public static void stockRollup(List<Stock_Transaction__c> newItems){
        Set<Id> productSet = new  Set<Id>();
        Set<Id> countrytSet = new  Set<Id>();
        Set<Id> areaSet = new Set<Id>();
        //Map<String,Stock_Transaction__c> stockTranMap = new Map<String,Stock_Transaction__c>();
        Map<String,Stock__c> stockMap = new Map<String,Stock__c>();
        Map<Id,Boolean> warehouseLevelMap = new Map<Id,Boolean>();
        List<Stock__c> stockListToUpdate = new List<Stock__c>();
        //List<Stock__c> stockListToInsert = new List<Stock__c>();
        Id recordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        String recordTypeWarehouse;
        recordTypeWarehouse = 'Warehouse';   //146443
        String queryStr = '';
        
        //Preparing product and country set to fetch related stock records in next step
        if(newItems!=NULL){
            for(Stock_Transaction__c newStockTran : newItems){
                productSet.add(newStockTran.Product__c);
                countrytSet.add(newStockTran.Country__c);
                if(newStockTran.Area__c != null){
                    areaSet.add(newStockTran.Area__c);  
                }
            }
        }
        
        for(Market_Setting__c marketSetting : [SELECT Id,Geography__c,Warehouse_Level__c FROM Market_Setting__c WHERE Geography__c  IN : countrytSet]){                
            warehouseLevelMap.Put(marketSetting.Geography__c, marketSetting.Warehouse_Level__c);
        }
        queryStr = 'Select Id, Product__c, Country__c, Area__c, Original_Stock__c, Unique_key__c from Stock__c '+ 
            +' where Country__c IN : countrytSet AND Product__c IN :productSet AND recordtype.Name =: recordTypeWarehouse '; //146443
        if(!areaSet.isEmpty()){
            queryStr =  queryStr + 'and  Area__c IN :areaSet';
        }
        for(Stock__c stkObj: Database.query(String.escapeSingleQuotes(queryStr))) //146443
        {
            stockMap.put((stkObj.Unique_key__c), stkObj);
        }
        
        Map<Id,Geography__c> geographyMap = new Map<Id,Geography__c>([Select Id,Code__c from Geography__c where Id IN :countrytSet]);
        Map<Id,Product__c> productMap = new Map<Id,Product__c>([Select Id,Product_Code__c from Product__c where Id IN :productSet]);
        Map<Id,Geography__c>  areaMap;
        if(!areaSet.isEmpty()){
            areaMap = new Map<Id,Geography__c>([Select Id, Code__c from Geography__c where Id IN :areaSet]);
        }
        
        //Iterating over newly inserted Stock Transaction records to populate Original Stock
        for(Stock_Transaction__c newStockTran : newItems){
            String countryCode = geographyMap.get(newStockTran.Country__c).Code__c;
            String productCode = productMap.get(newStockTran.product__c).Product_Code__c;
            String tempUniqueKey = countryCode + '_' + productCode;
            
            if(warehouseLevelMap.get(newStockTran.Country__c) != null && warehouseLevelMap.get(newStockTran.Country__c) && areaMap.size()>0){
                string areaCode = areaMap.get(newStockTran.Area__c).Code__c;
                if(areaCode != null){
                    tempUniqueKey += '_' + areaCode;
                }
            } 
            Boolean stockMapUniqueVar = stockMap.containsKey(tempUniqueKey) ;
            //If there is any record presents in database
            if(stockMap.size()>0 && stockMapUniqueVar){
                Decimal stockTranQuantity = newStockTran.Quantity__c;
                Stock__c existingStck = stockMap.get(tempUniqueKey);
                Decimal stockOrignlStock = checkForNull(existingStck.Original_Stock__c);
                Stock__c tempStck = new Stock__c(Id=existingStck.Id);
                tempStck.Original_Stock__c  = stockTranQuantity + stockOrignlStock; //checkforNull for stockOrignlStock
                stockListToUpdate.add(tempStck);
            }
            //If there is no record presents in database
            else if((stockMap.size()==0) || (!stockMapUniqueVar)){
                Stock__c tempStck = new Stock__c();
                tempStck.RecordTypeId = recordTypeId;
                tempStck.Original_Stock__c = newStockTran.Quantity__c;
                tempStck.Product__c = newStockTran.Product__c;
                tempStck.Country__c = newStockTran.Country__c;
                if(newStockTran.Area__c != null){
                    tempStck.Area__c = newStockTran.Area__c;
                }
                tempStck.Unique_Key__c = tempUniqueKey;
                stockListToUpdate.add(tempStck);
            }
        }
        
        if(stockListToUpdate != null && stockListToUpdate.size()>0 && Schema.sObjectType.Stock__c.isUpdateable() && Schema.sObjectType.Stock__c.isCreateable()){
            database.upsert(stockListToUpdate, false);
        }
    }
    
/*
method  : areaMandatoryBasedOnMarket
Purpose : when the Warehouse Level field has been checked in Market setting then Area field is mandatory  
*/
    public static void areaMandatoryBasedOnMarket(List<Stock_Transaction__c> newItems){
        set<Id> countrySetId = new set<Id>();
        Map<Id,Boolean> warehouseLevelMap = new Map<Id,Boolean>();
        
        
        for(Stock_Transaction__c stockTran :newItems ){
            countrySetId.add(stockTran.Country__c);
        }
        
        if(Schema.sObjectType.Market_Setting__c.isAccessible()){
            for(Market_Setting__c marketSetting :  [SELECT Id,Geography__c,Warehouse_Level__c FROM Market_Setting__c WHERE Geography__c  IN : countrySetId]){
                warehouseLevelMap.Put(marketSetting.Geography__c,marketSetting.Warehouse_Level__c );                
            } 
            
            for(Stock_Transaction__c stockTran :newItems ){
                if(warehouseLevelMap.containsKey(stockTran.Country__c)){
                    if(warehouseLevelMap.get(stockTran.Country__c)){
                        if(stockTran.Area__c == null){
                            stockTran.Area__c.addError('Please provide the value in Area field');
                        }
                    }
                }
            }
        }
    }
    public static Decimal checkForNull(Decimal kpiValue){
        return EDGE_UtilityClass.checkForNull(kpiValue);
    } 
}