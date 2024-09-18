/*
* Name: EDGE_POSAllocationController
* Req: The requirement is to adjust Stock Allocation for POS Products.
    ES20-2999
    ES20-3000
* HISTORY                                                                                                        
* VERSION   AUTHOR            DATE              DETAIL
* 1.0       Sandeep Sahoo     20/07/2019        Initial Development
*/

public with sharing class EDGE_POSAllocationController {
    Static String warehouseRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
    Static String allocationRecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
    
    @AuraEnabled
    public static List<Stock__c> searchStockDetails(String productId,String countryId,String areaId,Boolean recordTypeCheck){
        try{ 
            String strQuery = 'SELECT Id, Area__c, Area__r.Name, Product__c, Product__r.Limit_Per_Order__c,Product__r.Expiry_Date__c, Original_Stock__c, Consumed_Stock__c, Allocated__c,Start_Date__c,End_Date__c,';
            strQuery += ' Allocated_Available__c, Unallocated_Available__c, Internal_Allocation__c ';
            List<Stock__c> stockWarehouselist = new List<Stock__c>();
            if(Schema.sObjectType.Stock__c.isAccessible() && String.isNotBlank(productId) && String.isNotBlank(countryId)){                                                
                if(!recordTypeCheck){
                    strQuery += ', Type__c, State__r.Name, Territory__r.Name, Global_Segment__c, Local_Outlet_Segment1__r.Name, Local_Outlet_Segment_2__r.Name, Target_List__r.Name, Outlet__r.Name';
                }
                
                strQuery += ' FROM Stock__c WHERE Country__c =:countryId AND Product__c =:productId';
                if(recordTypeCheck){
                	strQuery += ' AND RecordTypeId =:warehouseRecordTypeId';
                }else{
                    strQuery += ' AND RecordTypeId =:allocationRecordTypeId';
                    if(String.isNotBlank(areaId)){
                        strQuery += ' AND Area__c =:areaId';
                    }
                }
                stockWarehouselist = Database.query(strQuery);                                       
            }
            
            return stockWarehouselist;                
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }        
    }
    
    @AuraEnabled
    public static Product__c getProduct(String productId){
        try{ 
            Product__c product;
            if(Schema.sObjectType.Product__c.isAccessible() && String.isNotBlank(productId)){                                                
                product = [Select Id, Name, Country__c from Product__c where Id =:productId LIMIT 1];
            }
            return product;                
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }        
    }
    
    @AuraEnabled
    public static String getRecordType(){
        try{
            String recordTypeId;           
            recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Allocation' AND SobjectType ='Stock__c' LIMIT 1].Id;
            return recordTypeId;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveAllocation(Stock__c allocationUpdateRec){
        try{
            if(Schema.sObjectType.Stock__c.isUpdateable()){
                Database.update(allocationUpdateRec);
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void adjustAlloc(Stock__c allocationUpdateRec){
        try{
            allocationUpdateRec.Allocated__c = allocationUpdateRec.Consumed_Stock__c;
            if(Schema.sObjectType.Stock__c.isUpdateable()){
                Database.update(allocationUpdateRec);
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void adjustAllocateList(List<Stock__c> allocationList){
        try{
            for(Stock__c stockRecId : allocationList){
                stockRecId.Allocated__c = stockRecId.Consumed_Stock__c;
            }
            if(Schema.sObjectType.Stock__c.isUpdateable()){
                Database.update(allocationList);
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveWarehouseAllocation(Integer orderLim, Stock__c updateRec){
        try{   
            if(Schema.sObjectType.Stock__c.isUpdateable()){
                Database.update(updateRec);
            }
            
            if(orderLim != null){
                Product__c updateProductRec = [Select Id,Limit_Per_Order__c from Product__c where Id =: updateRec.Product__c];
                updateProductRec.Limit_Per_Order__c = orderLim;
                if(Schema.sObjectType.Product__c.isUpdateable()){
                    Database.update(updateProductRec);
                }
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean getPOSTimeBasedMarketSetting(String countryId){
        List<Market_Setting__c> marketSettingList = new List<Market_Setting__c>();
        Boolean timeBasedPOS = false;
        try{
                marketSettingList = [SELECT POS_Time_Based_Allocation__c FROM Market_Setting__c WHERE Geography__c=:countryId WITH SECURITY_ENFORCED];
                if(marketSettingList != null && marketSettingList.size()>0){
                    timeBasedPOS = marketSettingList[0].POS_Time_Based_Allocation__c;
                }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return timeBasedPos;
    }

}