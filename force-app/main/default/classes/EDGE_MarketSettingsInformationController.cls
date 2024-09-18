/**********************************************************************
Name: EDGE_MarketSettingsInformationController
=======================================================================
Purpose: This is to handle EDGE_MarketSettingsInformationCmp component
=======================================================================  
-------                                                            
VERSION  		AUTHOR            DATE              DETAIL
1.0     	Monalisa Halder      21/12/2020        ES20-9129
2.0         Joshraj Sen          21/12/2021        ES20-11062
***********************************************************************/
public with sharing class EDGE_MarketSettingsInformationController {
    
    //Query all custom metadata records
    @AuraEnabled
    public static List<Market_Label__mdt > getMarketLabels(){
        List<Market_Label__mdt> marketLabelList = new List<Market_Label__mdt>();
        marketLabelList = [SELECT Id, MasterLabel, Name__c, Description__c   
                           FROM Market_Label__mdt ORDER BY MasterLabel ASC];
        
        return marketLabelList;
    }
    
    //Get all the existing Info Label records for respective market settings
    @AuraEnabled
    public static Map<String,Info_Label__c> getInfoLabels(Id marketSettingId){
        List<Info_Label__c> infoLabelList = new List<Info_Label__c >();
        Map<String,Info_Label__c> fieldNameInfoLabelMap = new Map<String,Info_Label__c>();
        if(marketSettingId != null  && Schema.SObjectType.Market_Setting__c .isAccessible() && Schema.SObjectType.Info_Label__c .isAccessible()
           && Schema.sObjectType.Info_Label__c.fields.Id.isAccessible()
           && Schema.sObjectType.Info_Label__c.fields.Field_Name__c.isAccessible()
           && Schema.sObjectType.Info_Label__c.fields.Market_Setting__c.isAccessible()
           && Schema.sObjectType.Info_Label__c.fields.Unique_Id__c .isAccessible()
           && Schema.sObjectType.Info_Label__c.fields.Value__c.isAccessible()){
               infoLabelList = [Select Id,Field_Name__c,Market_Setting__c,Unique_Id__c,Value__c FROM Info_Label__c WHERE Market_Setting__c =: marketSettingId];
               for(Info_Label__c infoLabelRec :infoLabelList){
                 fieldNameInfoLabelMap.put(infoLabelRec.Field_Name__c,infoLabelRec);  
               }
           }
        return fieldNameInfoLabelMap;
    }
   
    public static Map<String, List<String>> getNameUniqueIdValueMap(Id marketSettingId){
        Map<String,List<String>> fieldNameValueUniqueIdMap = new Map<String,List<String>>();
        List<Market_Label__mdt> marketLabelList = getMarketLabels();
        Map<String,Info_Label__c> fieldNameInfoLabelMap = getInfoLabels(marketSettingId);
        for(Market_Label__mdt  marketLabelRec :marketLabelList){
            if(fieldNameInfoLabelMap != null && fieldNameInfoLabelMap.get(marketLabelRec.Name__c) != null 
               /*&& fieldNameInfoLabelMap.get(marketLabelRec.Name__c).Value__c != null*/){
                   List<String> valueUniqueIdList = new List<String>(); 
                   Info_Label__c infoLabelRec = fieldNameInfoLabelMap.get(marketLabelRec.Name__c);
                   valueUniqueIdList.add(infoLabelRec.Value__c);
                   valueUniqueIdList.add(infoLabelRec.Unique_Id__c);
                   valueUniqueIdList.add(infoLabelRec.Id);
                   fieldNameValueUniqueIdMap.put(marketLabelRec.Name__c,valueUniqueIdList);
                   
               }
        }
        return fieldNameValueUniqueIdMap;
    }
    
    // Return a map of Field Label with Api Name,existing value and description.Method is called from 
    // lightning component to get existing value of the fields
    @AuraEnabled
    public static Map<String,List<String>> getMarketSettingsInfo(Id marketSettingId){
        Map<String,List<String>> marketLabelNameValueDescMap = new Map<String,List<String>>();
        List<Market_Label__mdt> marketLabelList = getMarketLabels();
        Map<String,Info_Label__c> fieldNameInfoLabelMap = getInfoLabels(marketSettingId);
        for(Market_Label__mdt  marketLabelRec :marketLabelList){
            List<String> nameDescValueList = new List<String>();
            nameDescValueList.add(marketLabelRec.Name__c);
            nameDescValueList.add(marketLabelRec.Description__c != null ? marketLabelRec.Description__c : '');
            marketLabelNameValueDescMap.put(marketLabelRec.MasterLabel, nameDescValueList);
           
            if(fieldNameInfoLabelMap != null && fieldNameInfoLabelMap.get(marketLabelRec.Name__c) != null 
               && fieldNameInfoLabelMap.get(marketLabelRec.Name__c).Value__c != null){
                marketLabelNameValueDescMap.get(marketLabelRec.MasterLabel).add(fieldNameInfoLabelMap.get(marketLabelRec.Name__c).Value__c);
            }
            
        }
        return marketLabelNameValueDescMap;
    }
    
    //Insert and update Info Label records for respective market settings
    @AuraEnabled
    public static void insertUpdateInfoLabel(Id marketSettingId, Map<String,String> infoNames){
        Map<String, List<String>> fieldNameValueUniqueIdMap = getNameUniqueIdValueMap(marketSettingId);
        List<Info_Label__c> insertInfoLabelList = new List<Info_Label__c>();
        List<Info_Label__c> updateInfoLabelList = new List<Info_Label__c>();
        for(String fieldName :infoNames.keySet()){
            Info_Label__c infoLabelRec = new Info_Label__c();
            infoLabelRec.Field_Name__c = fieldName;
            infoLabelRec.Market_Setting__c = marketSettingId;
            infoLabelRec.Value__c = infoNames.get(fieldName);
            if(fieldNameValueUniqueIdMap.containsKey(fieldName)){
                if(fieldNameValueUniqueIdMap.get(fieldName)[0] != infoNames.get(fieldName)){
                    infoLabelRec.Unique_Id__c = fieldNameValueUniqueIdMap.get(fieldName)[1];
                    infoLabelRec.Id = fieldNameValueUniqueIdMap.get(fieldName)[2];
                    updateInfoLabelList.add(infoLabelRec); 
                }
            }
            else{
                insertInfoLabelList.add(infoLabelRec); 
            }
        }
        if(insertInfoLabelList != null && insertInfoLabelList.size()>0 && Schema.sObjectType.Info_Label__c.isCreateable()){
            Database.insert(insertInfoLabelList,true);     
        }
        if(updateInfoLabelList != null && updateInfoLabelList.size()>0 && Schema.sObjectType.Info_Label__c.isUpdateable()){
            Database.update(updateInfoLabelList,true);     
        }
    }

}