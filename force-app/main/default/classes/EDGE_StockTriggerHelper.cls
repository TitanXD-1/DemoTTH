/**
Name: EDGE_StockTriggerHelper
Purpose: Trigger Helper Class for StockTriggerHandler
History                                                                                                                     
VERSION   AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh    15/06/2019        ES20-2232
2.0       Manikant Prasad   05/08/2019        ES20-3465
3.0       Shahbaz Khan      12/11/2019        ES20-5489 (Method: areaMandatoryBasedOnMarket)
4.0		  Kapil Baliyan		08/03/2021		  NCP-2089 (Method: updateUniqueKey)
5.0		  Kapil Baliyan		16/03/2021		  NCP-2091 (Method: checkAndGenerateD1Sharing, validateAndReGenerateD1Sharing)
6.0		  Anamika Shukla 	04/05/2021		  ES20-10152
7.0		  Prasanth T		25/02/2022		  ES20-12144
8.0		  Monalisa Halder	24/03/2022		  ES20-12384
9.0		  Prasanth T		19/10/2023		  145869(dateValidationStock) - Added Start and End Date validation to Stock.
10.0	  Mukesh Kanth 		02/11/2023		  146144(validateStockAllocationTimePeriod, updateUniqueKey) - This method is used for validation on "Start Date" and "End Date" fields in the POS Stock Allocation record Only if the Market Setting "POS Time Based Allocation" is TRUE 
                                              and there are any other records in the system with the same combination of Time Period AND (Product, Country, Area, Type, Global Segment, Local Outlet Segment1, Local Outlet Segment 2, Target List)

10.1      Sandeep Bhowmik   21/12/2023        149526 - POS - Allow BE Users to edit existing stock allocation start and end date
**/ 
public with sharing class EDGE_StockTriggerHelper {
    
    /**
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    **/
    public static void checkAndGenerateSharing(List<Stock__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /**
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    **/
    public static void validateAndReGenerateSharing(List<Stock__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Stock__c> mapOldItems;
        List<Stock__c> lstNewChangeGeography = new List<Stock__c>();
        List<Stock__c> lstOldChangeGeography = new List<Stock__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Stock__c>)oldItems;
        }
        
        for(Stock__c objStock : newItems){
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
    
    /**
    Method  : updateWarehouseStock
    Purpose : Update the warehouse stock once the fields are in stock allocation
    depending on Product and Geography
    **/
    public static void updateWarehouseStock(List<Stock__c> newItems,Map<Id, SObject> mapOldItems){
        Map<Id,Stock__c> oldItems;
        if(mapOldItems != null){
            oldItems = (Map<Id,Stock__c>)mapOldItems;
        }
        List<Stock__c> lstAllocationStock = new List<Stock__c>();
        //List<String> allocationStockUniqueKey = new List<String>();
        Map<String, Stock__c> warehouseStockMap = new Map<String, Stock__c>();
        Map<String, Double> allocationConsumedStockMap = new Map<String, Double>();
        Map<String, Double> allocationStockAllocatedMap = new Map<String, Double>();
        Map<Id,Boolean> warehouseLevelMap = new Map<Id,Boolean>();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();
        String allocationStockProductCountry;
        String warehouseStockProductCountry;
        Double consumedQuantity =0.00;
        Double allocatedQuantity=0.00;
        String allocationRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        String warehouseRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        
        try{
            if(newItems != null && newItems.size()>0){
                for(Stock__c newStock : newItems){
                    if(mapOldItems == null || (newStock.RecordTypeId == allocationRecordTypeId && newStock.Consumed_Stock__c != oldItems.get(newStock.id).Consumed_Stock__c) ||
                       (newStock.RecordTypeId == allocationRecordTypeId && newStock.Allocated__c != oldItems.get(newStock.id).Allocated__c)){
                           lstAllocationStock.add(newStock);
                           productIdSet.add(newStock.Product__c);
                           countryIdSet.add(newStock.Country__c);
                       }
                }
                
                //Get the Market Settings Data
                if(Schema.sObjectType.Market_Setting__c.isAccessible()){
                    for(Market_Setting__c marketSetting :  [SELECT Id,Geography__c,Warehouse_Level__c FROM Market_Setting__c WHERE Geography__c  IN : countryIdSet]){
                        warehouseLevelMap.put(marketSetting.Geography__c,marketSetting.Warehouse_Level__c );                    
                    } 
                }
                
                //Get the Allocation Data
                if(lstAllocationStock != null && lstAllocationStock.size()>0){
                    // Quering all the allocation stocks with the Product and Country , present in the newly inserted or updated allocation stock
                    for(Stock__c allocationStock : newItems){
                        if(warehouseLevelMap.containsKey(allocationStock.Country__c) && warehouseLevelMap.get(allocationStock.Country__c)){
                            allocationStockProductCountry = allocationStock.Product__c+'_'+allocationStock.Country__c+'_'+allocationStock.Area__c;                            
                        } else {
                            allocationStockProductCountry = allocationStock.Product__c+'_'+allocationStock.Country__c;
                        }
                        
                        // If the product and country are same , summing up the consumed stock and allocated , and putting them in two separate maps - allocationConsumedStockMap,allocationStockAllocatedMap
                        if(allocationConsumedStockMap.containsKey(allocationStockProductCountry) && allocationStockAllocatedMap.containsKey(allocationStockProductCountry) ){
                            consumedQuantity = allocationConsumedStockMap.get(allocationStockProductCountry);
                            consumedQuantity += allocationStock.Consumed_Stock__c == null ? 0.00 : allocationStock.Consumed_Stock__c - (oldItems == null ? 0.00 : oldItems.get(allocationStock.id).Consumed_Stock__c);
                            allocatedQuantity = allocationStockAllocatedMap.get(allocationStockProductCountry);
                            allocatedQuantity += allocationStock.Allocated__c == null ? 0.00 : allocationStock.Allocated__c - (oldItems == null ? 0.00 : oldItems.get(allocationStock.id).Allocated__c);
                            allocationConsumedStockMap.put(allocationStockProductCountry,consumedQuantity);
                            allocationStockAllocatedMap.put(allocationStockProductCountry, allocatedQuantity);
                            
                        }else{
                            consumedQuantity = allocationStock.Consumed_Stock__c == null ? 0.00 : allocationStock.Consumed_Stock__c - (oldItems == null ? 0.00 : oldItems.get(allocationStock.id).Consumed_Stock__c);
                            allocationConsumedStockMap.put(allocationStockProductCountry,consumedQuantity); 
                            allocatedQuantity = allocationStock.Allocated__c == null ? 0.00 : allocationStock.Allocated__c- (oldItems == null ? 0.00 : oldItems.get(allocationStock.id).Allocated__c);
                            allocationStockAllocatedMap.put(allocationStockProductCountry,allocatedQuantity);
                        }
                    }
                    
                    //Quering all the warehouse stocks with the Product and Country , present in the newly inserted or updated allocation stock
                    for(Stock__c warehouseStock : [SELECT Id,Consumed_Stock__c,Product__c,Country__c,Allocated__c,Area__c from Stock__c where Product__c IN: productIdSet and  Country__c IN: countryIdSet and RecordTypeId =: warehouseRecordTypeId]){
                        if(warehouseLevelMap.containsKey(warehouseStock.Country__c) && warehouseLevelMap.get(warehouseStock.Country__c)){
                            warehouseStockProductCountry = warehouseStock.Product__c+'_'+warehouseStock.Country__c+'_'+warehouseStock.Area__c;                            
                        } else {
                            warehouseStockProductCountry = warehouseStock.Product__c+'_'+warehouseStock.Country__c;
                        } 
                        warehouseStockMap.put(warehouseStockProductCountry,warehouseStock);
                    }
                    
                    //Updating the warehouse stock , with the accumulated Consumed Stock and Allocated
                    for(String uniqueKey : allocationStockAllocatedMap.keySet()){    
                        if(warehouseStockMap.containsKey(uniqueKey)){
                            //warehouseStockMap.get(uniqueKey).Consumed_Stock__c += allocationConsumedStockMap.get(uniqueKey);
                            //warehouseStockMap.get(uniqueKey).Allocated__c += allocationStockAllocatedMap.get(uniqueKey);                            
                            if(warehouseStockMap.get(uniqueKey).Consumed_Stock__c != null){
                                warehouseStockMap.get(uniqueKey).Consumed_Stock__c += allocationConsumedStockMap.get(uniqueKey);
                            }else{
                                warehouseStockMap.get(uniqueKey).Consumed_Stock__c = allocationConsumedStockMap.get(uniqueKey);
                            }
                            if(warehouseStockMap.get(uniqueKey).Allocated__c != null){
                                warehouseStockMap.get(uniqueKey).Allocated__c += allocationStockAllocatedMap.get(uniqueKey);  
                            }else{
                                warehouseStockMap.get(uniqueKey).Allocated__c = allocationStockAllocatedMap.get(uniqueKey);
                            }
                        }
                    }
                    
                    if(warehouseStockMap != null && warehouseStockMap.size()>0){
                        update warehouseStockMap.values();
                    }
                }
            }
        }catch (Exception stockException){
            System.debug(LoggingLevel.ERROR, stockException.getLineNumber()+stockException.getMessage()+stockException.getCause());
            new EDGE_GenericException(stockException, newItems[0]);
        }
    }
    
    /**
    Method  : validateAllocation
    Purpose : To check Allocation While Inserting Stock Records
    **/
    public static void validateAllocation(List<Stock__c> newItems){
        String warehouseRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        Map<String, Decimal> staticWarehouseStockMap = new Map<String, Decimal>();
        
        try{
            for(Stock__c stockRecID : [Select Id,Product__c,Country__c,Unallocated_Available__c from Stock__c where recordTypeId =: warehouseRecordTypeId]){
                String uniqueKey =  String.valueOf(stockRecId.Product__c)+'_'+String.valueOf(stockRecId.Country__c);
                staticWarehouseStockMap.put(uniqueKey,stockRecId.Unallocated_Available__c); // static Map to Compare Stock Values from Warehouse
            }
            for(Stock__c stockNewRecId : newItems){
                String uniqueKey =  String.valueOf(stockNewRecId.Product__c)+'_'+String.valueOf(stockNewRecId.Country__c);
                if(staticWarehouseStockMap.size()>0 && staticWarehouseStockMap.containsKey(uniqueKey) && (staticWarehouseStockMap.get(uniqueKey) >= stockNewRecId.Allocated__c)){
                    Decimal remWarehouseQty = staticWarehouseStockMap.get(uniqueKey) - stockNewRecId.Allocated__c;
                    staticWarehouseStockMap.put(uniqueKey,remWarehouseQty);
                }else if(staticWarehouseStockMap.size()>0 && staticWarehouseStockMap.containsKey(uniqueKey) && (staticWarehouseStockMap.get(uniqueKey) < stockNewRecId.Allocated__c)){
                    stockNewRecId.addError('Allocated Quantity cannot be greater than Unallocated Quantity');                  
                }
            }
        }catch(Exception orderException){
            System.debug(LoggingLevel.ERROR, orderException.getLineNumber()+orderException.getMessage()+orderException.getCause());
            new EDGE_GenericException(orderException, newItems[0]);
        }   
    }
    
    //Method for Updating Unique Key
    public static void updateUniqueKey(List<Stock__c> newItems){
        String allocationRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        String warehouseRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        String shedRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        Set<Id> geoIdSet = new Set<Id>();
        Map<Id,String> geoMap = new Map<Id,String>();
        Map<Id,Boolean> warehouseLevelMap = new Map<Id,Boolean>();
        Set<Id> productIdSet = new Set<Id>();
        String unikey;
        Map<Id,String> productMap = new Map<Id,String>();
        List<Stock__c> allocationList = new List<Stock__c>();
        List<Stock__c> shedList = new List<Stock__c>();
        List<Stock__c> warehouseList = new List<Stock__c>();
        Map<Id, Boolean> timeBaseAllocationMap = new Map<Id, Boolean>();
        
        try{
            for(Stock__c stockNewRecId : newItems){
                geoIdSet.add(stockNewRecId.Country__c);
                productIdSet.add(stockNewRecId.Product__c);
                if(stockNewRecId.State__c != null){
                    geoIdSet.add(stockNewRecId.State__c);                    
                }
                if(stockNewRecId.Area__c != null){
                    geoIdSet.add(stockNewRecId.Area__c);                    
                }
            }
            
            if(Schema.sObjectType.Market_Setting__c.isAccessible()){
                for(Market_Setting__c marketSetting :  [SELECT Id,Geography__c,Warehouse_Level__c, POS_Time_Based_Allocation__c FROM Market_Setting__c WHERE Geography__c  IN : geoIdSet]){
                    warehouseLevelMap.put(marketSetting.Geography__c,marketSetting.Warehouse_Level__c);
                    timeBaseAllocationMap.put(marketSetting.Geography__c, marketSetting.POS_Time_Based_Allocation__c);
                } 
            }
            
            for(Geography__c geoRecId : [Select Id,Code__c from Geography__c where ID IN: geoIdSet ]){
                geoMap.put(geoRecId.Id,geoRecId.Code__c);
            }
            for(Product__c productRecId : [Select Id,Product_Code__c from Product__c where ID IN: productIdSet ]){
                productMap.put(productRecId.Id,productRecId.Product_Code__c);
            }
            
            for(Stock__c stockNewRecId : newItems){
                if(stockNewRecId.RecordTypeId == warehouseRecordTypeId && stockNewRecId.Unique_Key__c == NULL){
                    warehouseList.add(stockNewRecId);
                }else if(stockNewRecId.RecordTypeId == shedRecordTypeId && stockNewRecId.Unique_Key__c == NULL){
                    shedList.add(stockNewRecId);
                }else if(stockNewRecId.RecordTypeId == allocationRecordTypeId && stockNewRecId.Unique_Key__c == NULL){
                    allocationList.add(stockNewRecId);
                }
                //Updating Unique Key for Warehouse
                if(warehouseList!=null && !warehouseList.isEmpty()){
                    for(Stock__c warehouseRec : warehouseList){
                        if(geoMap.get(warehouseRec.Country__c) != null && productMap.get(warehouseRec.Product__c) != null){
                            if(warehouseLevelMap.get(warehouseRec.Country__c) == true && geoMap.get(warehouseRec.Area__c) != null ){
                                warehouseRec.Unique_Key__c = String.valueOf(geoMap.get(warehouseRec.Country__c))+'_'+String.valueOf(productMap.get(warehouseRec.Product__c))+'_'+String.valueOf(geoMap.get(warehouseRec.Area__c));
                            }
                            else{
                                warehouseRec.Unique_Key__c = String.valueOf(geoMap.get(warehouseRec.Country__c))+'_'+String.valueOf(productMap.get(warehouseRec.Product__c));
                            }
                        }
                    }
                }
                
                //Updating Unique Key for Shed-ES20-10152
                if(shedList!=null && !shedList.isEmpty()){
                    for(Stock__c shedRec : shedList){
                        if(shedRec.Product__c!=null ){
                            shedRec.Unique_Key__c = String.valueOf(geoMap.get(shedRec.Country__c))+'_'+String.valueOf(shedRec.Product__c) + '_'+ String.valueOf(shedRec.Sales_Rep__c);
                        }
                        else if(shedRec.Market_Assortment_Product__c!=null) {    
                            shedRec.Unique_Key__c= String.valueOf(geoMap.get(shedRec.Country__c))+'_'+String.valueOf(shedRec.Shed__c) +'_'+String.valueOf(shedRec.Market_Assortment_Product__c);
                        }
                    }
                }
                
                //Updating Unique Key for Allocation
                if(allocationList!=null && !allocationList.isEmpty()){
                    for(Stock__c allocationRec : allocationList){
                        if(allocationRec.Type__c == 'State'){
                            if(warehouseLevelMap.get(allocationRec.Country__c) == true && geoMap.get(allocationRec.Area__c)!=null){
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_'+ String.valueOf(geoMap.get(allocationRec.Area__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_'+ String.valueOf(geoMap.get(allocationRec.State__c)); 
                            }
                            else{
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_'+ String.valueOf(geoMap.get(allocationRec.State__c));
                            }
                        }else if(allocationRec.Type__c == 'Territory/Rep'){
                            if(warehouseLevelMap.get(allocationRec.Country__c) == true && geoMap.get(allocationRec.Area__c)!=null){
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(geoMap.get(allocationRec.Area__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_'+ String.valueOf(allocationRec.Territory__c);
                            }
                            else{
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_'+ String.valueOf(allocationRec.Territory__c);
                            }
                        }else if(allocationRec.Type__c == 'Outlet (Target List)'){
                            if(warehouseLevelMap.get(allocationRec.Country__c) == true && geoMap.get(allocationRec.Area__c)!=null){
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' +String.valueOf(geoMap.get(allocationRec.Area__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_'+ String.valueOf(allocationRec.Target_List__c);   
                            }
                            else{
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_'+ String.valueOf(allocationRec.Target_List__c);
                            }
                        }else if(allocationRec.Type__c == 'Segment'){
                            if(warehouseLevelMap.get(allocationRec.Country__c) == true && geoMap.get(allocationRec.Area__c)!=null){
                                unikey = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(geoMap.get(allocationRec.Area__c)) + '_' +String.valueOf(allocationRec.Type__c)+'_';  
                            }
                            else{
                                unikey = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_';
                            }
                            //NCP-6062[Fix for same segment but different outlet segment]
                            if(allocationRec.Global_Segment__c != null){
                                allocationRec.Unique_Key__c = unikey + String.valueOf(allocationRec.Global_Segment__c);                             
                            }
                            if(allocationRec.Local_Outlet_Segment1__c !=null){
                                allocationRec.Unique_Key__c = unikey + String.valueOf(allocationRec.Local_Outlet_Segment1__c);  
                            }
                            if(allocationRec.Local_Outlet_Segment_2__c !=null){
                                allocationRec.Unique_Key__c = unikey + String.valueOf(allocationRec.Local_Outlet_Segment_2__c); 
                            }
                        }else if(allocationRec.Type__c == 'Outlet'){ //Added for NCP-2089
                            if(warehouseLevelMap.get(allocationRec.Country__c) == true && geoMap.get(allocationRec.Area__c)!=null){
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(geoMap.get(allocationRec.Area__c)) + '_' +String.valueOf(allocationRec.Type__c) + '_' + String.valueOf(allocationRec.Outlet__c);  
                            }
                            else{
                                allocationRec.Unique_Key__c = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(allocationRec.Type__c) + '_' + String.valueOf(allocationRec.Outlet__c);
                            }
                        }
                        else{
                            if(warehouseLevelMap.get(allocationRec.Country__c) == true && geoMap.get(allocationRec.Area__c)!=null){
                                unikey = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(geoMap.get(allocationRec.Area__c)) + '_' +String.valueOf(allocationRec.Type__c)+'_' + String.valueOf(geoMap.get(allocationRec.State__c));  
                            }
                            else{
                                unikey = String.valueOf(geoMap.get(allocationRec.Country__c))+'_'+String.valueOf(productMap.get(allocationRec.Product__c)) + '_' + String.valueOf(allocationRec.Type__c)+'_' + String.valueOf(geoMap.get(allocationRec.State__c));  
                            }
                            
                            //NCP-6062[Fix for same segment but different outlet segment]
                            if(allocationRec.Global_Segment__c != null){
                                allocationRec.Unique_Key__c = unikey + String.valueOf(allocationRec.Global_Segment__c);                             
                            }
                            if(allocationRec.Local_Outlet_Segment1__c !=null){
                                allocationRec.Unique_Key__c = unikey + String.valueOf(allocationRec.Local_Outlet_Segment1__c);  
                            }
                            if(allocationRec.Local_Outlet_Segment_2__c !=null){
                                allocationRec.Unique_Key__c = unikey + String.valueOf(allocationRec.Local_Outlet_Segment_2__c); 
                            }
                        }

                        //Add Start Date to Unique Key if Time Based Allocation is Enabled (146144)
                        if(timeBaseAllocationMap.get(allocationRec.Country__c) && allocationRec.Start_Date__c != null){
                            allocationRec.Unique_Key__c = allocationRec.Unique_Key__c + '_' + String.valueOf(allocationRec.Start_Date__c);
                        }
                    }
                } 
            }
        }catch(Exception orderException){
            System.debug(LoggingLevel.ERROR, orderException.getLineNumber()+orderException.getMessage()+orderException.getCause());
            new EDGE_GenericException(orderException, newItems[0]);
        }
    }
    
    /* Method  : validateAllocationType 
    purpose : ES20-3465 Allocation : one Allocation per type  
    */
    public static void validateAllocationType(List<Stock__c> newItems){
        Set<id> countryIdSet = new set<id>();
        Set<id> productIdSet = new set<id>();
        Map<String,string> existingStockRecAllocMap = new Map<String,string>();
        Map<Id,Boolean> warehouseLevelMap = new Map<Id,Boolean>();
        Id allocationrecordtype= Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        
        for(Stock__c newStockRec : newItems){
            If(newStockRec.recordtypeId==allocationrecordtype){
                countryIdSet.add(newStockRec.Country__c);
                productIdSet.add(newStockRec.Product__c);
            }
        }
        if(Schema.sObjectType.Market_Setting__c.isAccessible()){
            for(Market_Setting__c marketSetting :  [SELECT Id,Geography__c,Warehouse_Level__c FROM Market_Setting__c WHERE Geography__c  IN : countryIdSet]){
                warehouseLevelMap.put(marketSetting.Geography__c,marketSetting.Warehouse_Level__c );                    
            } 
        }
        if(Schema.SObjectType.Stock__c.isAccessible() && Schema.SObjectType.Product__c.isAccessible() && Schema.SObjectType.Geography__c.isAccessible()){
            List<Stock__c> existingStockRecAlloc = [select id,Area__c,Country__c,Product__c,Type__c from Stock__c 
                                                    where Country__c in :countryIdSet and Product__c in :productIdSet and RecordType.name='Allocation'];
            
            for(Stock__c existingStock : existingStockRecAlloc ){
                String uniqueKeyOld;
                if(warehouseLevelMap.get(existingStock.Country__c) && existingStock.Area__c!=null){
                    uniqueKeyOld =  String.valueOf(existingStock.Product__c)+'_'+String.valueOf(existingStock.Country__c)+'_'+String.valueOf(existingStock.Area__c);  
                }
                else{
                    uniqueKeyOld =  String.valueOf(existingStock.Product__c)+'_'+String.valueOf(existingStock.Country__c);
                }
                if(existingStockRecAllocMap.get(uniqueKeyOld) == null){
                    existingStockRecAllocMap.put(uniqueKeyOld,existingStock.Type__c); 
                }
            }
            
            for(Stock__c newStockRec : newItems){
                If(newStockRec.recordtypeId==allocationrecordtype){
                    string productCountryset;
                    if( newStockRec.Area__c!=null && warehouseLevelMap.get(newStockRec.Country__c)){
                        productCountryset=String.valueOf(newStockRec.Product__c)+'_'+String.valueOf(newStockRec.Country__c)+'_'+String.valueOf(newStockRec.Area__c);  
                    }else{
                        productCountryset=String.valueOf(newStockRec.Product__c)+'_'+String.valueOf(newStockRec.Country__c);
                    }
                    if((existingStockRecAllocMap.get(productCountryset) != null) && (newStockRec.type__c!=existingStockRecAllocMap.get(productCountryset))){
                        newStockRec.addError( +Label.EDGE_Allocation_error+ ' ' +existingStockRecAllocMap.get(productCountryset));
                    }
                }   
            }
        }
    }
    
    /**
    * @description : areaMandatoryBasedOnMarket - when the Warehouse Level field has been checked in Market setting then Area field is mandatory
    * @return : void
    * @param : List<Stock__c>
    */
    public static void areaMandatoryBasedOnMarket(List<Stock__c> newItems){
        set<Id> countrySetId = new set<Id>();
        Map<Id,Boolean> warehouseLevelMap = new Map<Id,Boolean>();
        Id allocationrecordtype= Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        Id warehouseRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        
        for(Stock__c stockRec :newItems ){
            if(stockRec.RecordTypeId == allocationrecordtype || stockRec.RecordTypeId == warehouseRecordTypeId){
                countrySetId.add(stockRec.Country__c);
            } 
        }
        if(Schema.sObjectType.Market_Setting__c.isAccessible()){
            for(Market_Setting__c marketSetting :  [SELECT Id,Geography__c,Warehouse_Level__c FROM Market_Setting__c WHERE Geography__c  IN : countrySetId]){
                warehouseLevelMap.Put(marketSetting.Geography__c,marketSetting.Warehouse_Level__c );
            }
            
            for(Stock__c stockRec :newItems ){
                if(warehouseLevelMap.containsKey(stockRec.Country__c)){
                    if(warehouseLevelMap.get(stockRec.Country__c)){
                        if(stockRec.Area__c == null && (stockRec.RecordTypeId == allocationrecordtype || stockRec.RecordTypeId ==warehouseRecordTypeId)){
                            stockRec.Area__c.addError('Please provide the value in Area field for this Country');
                        }
                    }
                }
            }
        }
    }
    
    /**
    * @description : checkAndGenerateD1Sharing(NCP-2091) - Modify, Validate sharing record on update
    * @return : void
    * @param : List<Stock__c>
    */
    public static void checkAndGenerateD1Sharing(List<Stock__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Edit');        
    }
    
    /**
    * @description : validateAndReGenerateD1Sharing(NCP-2091) - Modify, Validate sharing record on update
    * @return : void
    * @param : List<Stock__c>, Map<String, Object>
    */
    public static void validateAndReGenerateD1Sharing(List<Stock__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Stock__c> mapOldItems;
        List<Stock__c> lstNewChangeGeography = new List<Stock__c>();
        List<Stock__c> lstOldChangeGeography = new List<Stock__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Stock__c>)oldItems;
        }
        
        for(Stock__c objStock : newItems){
            if(mapOldItems.containsKey(objStock.Id) && objStock.Country__c != mapOldItems.get(objStock.Id).Country__c){
                lstNewChangeGeography.add(objStock);
                lstOldChangeGeography.add(mapOldItems.get(objStock.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Edit');
        }       
    }
    
    /**
    * @description : populateProductField - if the stock is associated with MAP then related Product will be set for Product in Stock Object.
    * @return : void
    * @param : List<Stock__c>, Map<String, Object>
    */
    public static void populateProductField(List<sObject> newItems,Map<Id, SObject> oldItems){
        
        List<Stock__c> newStocksList = (List<Stock__c>)newItems;
        Map<Id,Stock__c> oldStocksMap = new Map<Id,Stock__c>();
        oldStocksMap = (Map<Id,Stock__c>)oldItems;
        Set<Id> marketAssortmentProductSet = new Set<Id>();
        Map<Id,Id> marketAssortmentProductMap = new Map<Id,Id>();
        
        //collecting all MAP from Old and New Values
        for(Stock__c newStock: newStocksList){
            Id newMAPId = newStock.Market_Assortment_Product__c;
            if(oldStocksMap == null){//Stock Insert scenario
                if(newMAPId != null){
                    marketAssortmentProductSet.add(newMAPId);
                }
            }else if(oldStocksMap!= null && oldStocksMap.size()>0){//Stock Update Scenario
                Stock__c oldStock =  oldStocksMap.get(newStock.Id);
                if(newMAPId != null && oldStock != null){
                    marketAssortmentProductSet.add(newMAPId);                    
                }
            }
        }
        //Map of Market assortment product and Product
        if(marketAssortmentProductSet!= null && marketAssortmentProductSet.Size()>0){
            for(Market_Assortment_Product__c marketAssortment: [Select Id,Product__c FROM Market_Assortment_Product__c 
                                                                WHERE Id IN :marketAssortmentProductSet ])
            {
                if(marketAssortment.Product__c != null){
                    marketAssortmentProductMap.put(marketAssortment.Id,marketAssortment.Product__c);
                }
            }
        }
        //new stocks before insert and before update
        
        if(marketAssortmentProductSet != null ){//if condition for ES20-12384
            setProductFieldValue(newStocksList, marketAssortmentProductMap); 
        }
    }
    
    /**
    * @description : setProductFieldValue - set value of Product field in Market Assortment Product
    * @return : void
    * @param : List<Stock__c> ,  Map<Id,Id>  
    */
    @TestVisible
    private static void setProductFieldValue(List<Stock__c> newStocksList,  Map<Id,Id> marketAssortmentProductMap){
        for(Stock__c newStock: newStocksList){
            if(newStock.Market_Assortment_Product__c != null && marketAssortmentProductMap.containskey(newStock.Market_Assortment_Product__c)){
                newStock.Product__c = marketAssortmentProductMap.get(newStock.Market_Assortment_Product__c);
                
            }/*else{
                newStock.Product__c = null;
            }*/ //commented for ES20-12384
        }
    }
    
    /**
    * @description : dateValidationStock - validation for start date and end date in stock with Market Setting POS Time Allocation Limit.
    * @return : void
    * @param : List<Stock__c>, Map<String, Object>
    * 145869
    */
    public static void dateValidationStock(List<sObject> newItems, Map<Id, SObject> oldItems){    
        String allocationRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByDeveloperName().get('Allocation').getRecordTypeId();
        List<Stock__c> newStocksList = (List<Stock__c>)newItems;
        Map<Id, Stock__c> mapOldItems;
        if(oldItems != null){
            mapOldItems = (Map<Id, Stock__c>)oldItems;
        }
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();
        Map<Id,Boolean> countryIdposTimebasedMap = new Map<Id,Boolean>();
        Map<Id,Date> productIdExpiryDateMap = new Map<Id,Date>();

        for(Stock__c stockObj :newStocksList){
            if(stockObj.RecordTypeId == allocationRecordTypeId){
                productIdSet.add(stockObj.Product__c);
                countryIdSet.add(stockObj.Country__c);
            }
        }
        
        if(productIdSet.size()>0 && countryIdSet.size()>0){
            for(Product__c productObj: [SELECT Id,Expiry_Date__c,Name FROM Product__c WHERE Id=:productIdSet WITH SECURITY_ENFORCED ]){
                productIdExpiryDateMap.put(productObj.Id,productObj.Expiry_Date__c);
            }
            
            for(Market_Setting__c marketSettingObj: [SELECT Id,Name,POS_Time_Based_Allocation__c,Geography__c FROM Market_Setting__c WHERE Geography__c=:countryIdSet]){
                countryIdposTimebasedMap.put(marketSettingObj.Geography__c,marketSettingObj.POS_Time_Based_Allocation__c);
            }
            
            for(Stock__c stockNewRecobj : newStocksList){
                if(countryIdposTimebasedMap.size()>0 && countryIdposTimebasedMap.get(stockNewRecobj.Country__c) && stockNewRecobj.RecordTypeId == allocationRecordTypeId && mapOldItems == null){
                    String errorMsg = insertStockDateValidation(stockNewRecobj.Start_Date__c,stockNewRecobj.End_Date__c,productIdExpiryDateMap.get(stockNewRecobj.Product__c));
                    if(errorMsg != null){
                        stockNewRecobj.addError(errorMsg);
                    }
                }else if(countryIdposTimebasedMap.size()>0 && countryIdposTimebasedMap.get(stockNewRecobj.Country__c) && stockNewRecobj.RecordTypeId == allocationRecordTypeId && mapOldItems != null){
                    String errorMsg =   updateStockDateValidation(stockNewRecobj,mapOldItems,productIdExpiryDateMap.get(stockNewRecobj.Product__c));
                    if(errorMsg != null){
                        stockNewRecobj.addError(errorMsg);
                    }
                }
            }
        }
    } 

    /**
     * insertStockDateValidation
     * @param startDate 
     * @param endDate 
     * @param productExpiryDate 
     * @return  `String`
     * description : This method is used to validate start date and end date for inserts
     */
    public static String insertStockDateValidation(Date startDate, Date endDate, Date productExpiryDate){
        Date todayDate = system.Today();
        String errorMsg ;
        if(startDate == null || startDate < todayDate){
            errorMsg = Label.D1_StockStartDateErrorMsg;
        }else if(endDate != null && startDate > endDate){
            errorMsg = Label.D1_StockStartDateGreaterErrorMsg;
        }else if(endDate == null || endDate < startDate){
            errorMsg = Label.D1_StockEndDateErrorMsg;
        }
        else if(endDate == null || endDate > productExpiryDate){
            errorMsg = Label.D1_StockEndDateProductExpiryErrorMsg;
        }
        return errorMsg;
    }
    
    /**
     * updateStockDateValidation
     * @param stockNewRecobj 
     * @param mapOldItems 
     * @param productExpiryDate 
     * @return  `String`
     * description : This method is used to validate start date and end date for updates
     */
    public static String updateStockDateValidation(Stock__c stockNewRecobj, Map<Id, Stock__c> mapOldItems, Date productExpiryDate){
        String errorMsg ;
        Date todayDate = system.Today();
        if(mapOldItems.size()>0 && mapOldItems.get(stockNewRecobj.Id).Start_Date__c != stockNewRecobj.Start_Date__c && ((stockNewRecobj.Start_Date__c < todayDate) || stockNewRecobj.Start_Date__c == null)){
            errorMsg = Label.D1_StockStartDateErrorMsg;
        }else if((mapOldItems.size()>0 && mapOldItems.get(stockNewRecobj.Id).Start_Date__c != stockNewRecobj.Start_Date__c )&&(stockNewRecobj.End_Date__c != null && stockNewRecobj.Start_Date__c > stockNewRecobj.End_Date__c)){
            errorMsg = Label.D1_StockStartDateGreaterErrorMsg;
        }else if((mapOldItems.size()>0 && mapOldItems.get(stockNewRecobj.Id).End_Date__c != stockNewRecobj.End_Date__c) && ((stockNewRecobj.End_Date__c < stockNewRecobj.Start_Date__c) || stockNewRecobj.End_Date__c == null)){
            errorMsg = Label.D1_StockEndDateErrorMsg;
        }else if(stockNewRecobj.End_Date__c > productExpiryDate){
            errorMsg =  Label.D1_StockEndDateProductExpiryErrorMsg;
        }
        return errorMsg;
    }
    
    /*
     * @name validateStockAllocationTimePeriod
     * @description 146144-This method is used for validation on "Start Date" and "End Date" fields in the POS Stock Allocation record Only 
     * if the Market Setting "POS Time Based Allocation" is TRUE and there are any other records in the system with the same combination of Time Period AND (Product, Country, Area, Type, Global Segment, Local Outlet Segment1, Local Outlet Segment 2, Target List)  
     * @param newItems 
     * @param oldItemsMap 
     */
    public static void validateStockAllocationTimePeriod(List<sObject> newItems, Map<Id, SObject> oldItemsMap){
        String allocationRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByDeveloperName().get('Allocation').getRecordTypeId();
        List<Stock__c> newStocksList = (List<Stock__c>)newItems;
        Map<Id, Stock__c> mapOldItems;
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> territoryIdSet = new Set<Id>();
        Set<Id> stateIdSet = new Set<Id>();
        Map<String, List<Stock__c>> existingStockMap = new Map<String, List<Stock__c>>();

        if(oldItemsMap != null){
            mapOldItems = (Map<Id, Stock__c>)oldItemsMap;
        }
        
        for(Stock__c newStockRecord : newStocksList){
            if(newStockRecord.RecordTypeId == allocationRecordTypeId){
                productIdSet.add(newStockRecord.Product__c);
                countryIdSet.add(newStockRecord.Country__c);
                territoryIdSet.add(newStockRecord.Territory__c);             
                stateIdSet.add(newStockRecord.State__c);
            }
        }
        if(productIdSet.size()>0 && countryIdSet.size()>0){
            Map<Id, Market_Setting__c> marketSettingRecordMap = new Map<Id, Market_Setting__c>();
            //Get Existing Stock Allocation
            for(Stock__c stockRecord : [SELECT Id, Product__c, Country__c, Area__c, Type__c, Start_Date__c, End_Date__c, Target_List__c, State__c, Territory__c, Global_Segment__c, Local_Outlet_Segment1__c, Local_Outlet_Segment_2__c FROM Stock__c 
                                        WHERE RecordTypeId =:allocationRecordTypeId AND Product__c IN:productIdSet 
                                        AND Country__c IN:countryIdSet AND Territory__c IN:territoryIdSet AND State__c IN:stateIdSet]){
                    String uniqueKey = String.valueOf(stockRecord.Product__c);
                    if(existingStockMap.containsKey(uniqueKey)){
                        existingStockMap.get(uniqueKey).add(stockRecord);
                    }
                    else {
                        existingStockMap.put(uniqueKey, new List<Stock__c>{stockRecord});
                    }
            }
            //Get Market Setting                            
            for(Market_Setting__c newMarketSetting : [SELECT Id, Name, Geography__c, POS_Time_Based_Allocation__c FROM Market_Setting__c WHERE Geography__c IN :countryIdSet]){
                marketSettingRecordMap.put(newMarketSetting.Geography__c, newMarketSetting);
            }
            
            for(Stock__c newStock : newStocksList){
                if(mapOldItems == null || (mapOldItems!= null && (newStock.Start_Date__c != mapOldItems.get(newStock.Id).Start_Date__c || newStock.End_Date__c != mapOldItems.get(newStock.Id).End_Date__c))){
                    String uniqueKey = String.valueOf(newStock.Product__c);
                    if(existingStockMap.containsKey(uniqueKey)){
                        for(Stock__c existingStock : existingStockMap.get(uniqueKey)){
                            if(marketSettingRecordMap.get(newStock.Country__c).POS_Time_Based_Allocation__c 
                                && ((newStock.Start_Date__c >= existingStock.Start_Date__c 
                                && newStock.End_Date__c <= existingStock.End_Date__c) || (newStock.Start_Date__c >= existingStock.Start_Date__c 
                                && newStock.Start_Date__c <= existingStock.End_Date__c)||(newStock.End_Date__c >= existingStock.Start_Date__c 
                                && newStock.End_Date__c <= existingStock.End_Date__c )|| (newStock.Start_Date__c <= existingStock.Start_Date__c && newStock.End_Date__c >= existingStock.End_Date__c)) 
                                && newStock.Product__c == existingStock.Product__c 
                                && newStock.Area__c == existingStock.Area__c && newStock.Global_Segment__c == existingStock.Global_Segment__c 
                                && newStock.Local_Outlet_Segment1__c == existingStock.Local_Outlet_Segment1__c 
                                && newStock.Local_Outlet_Segment_2__c == existingStock.Local_Outlet_Segment_2__c 
                                && newStock.Type__c == existingStock.Type__c && newStock.Target_List__c == existingStock.Target_List__c && newStock.Id != existingStock.Id){ //149526 - Sandeep Bh
                                newStock.addError(System.label.D1_Duplicate_Time_Period_Error_Msg);
                            }
                        }
                    }
                }
            }
        }
    }
}