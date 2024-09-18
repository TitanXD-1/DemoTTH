/**
*@ Description Name: EDGE_ProductKPIAchivementOperations
					ES20-4589 - Actuals and Achievement Calculation for Product Level KPIs
*@ History : 

Author              Version       Date           Detail
Dipanjan D           1.0         12/12/2019     [ES20-4589]
Monalisa Halder      2.0         17/10/2022     [ES20-13380]
**/

public with sharing class EDGE_ProductKPIAchivementOperations {
    
    public static void calculateProductKPIAchivements(Map<Id, Territory__c> territoryMap){
        
        String queryFieldsString = '';        
        Set<String> kpiTypes = new Set<String>();
        Set<Id> territoryIdSet = territoryMap.keySet();
        Map<String, Id> kpiAchivementMap = new Map<String, Id>();
        Map<Id, Integer> territoryWithOutletsNumberMap = new Map<Id, Integer>();  
        List<KPI_Achivement__c> kpiAchivementsToUpsert = new List<KPI_Achivement__c>(); 
        Map<Id, Map<Id, Map<String, Decimal>>> terrKPINameWithProdValMap = new Map<Id, Map<Id, Map<String, Decimal>>>();    
        String prodRecTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
        String prodKPIRecTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product KPI').getRecordTypeId();
        
        //Iterating over Sales Area KPI Fields Mapping
        for(Sales_Area_KPI_Fields_Mapping__mdt kpiMap : [SELECT KPI_Achievement_Type__c, Outlet_Execution_KPI_Field__c FROM Sales_Area_KPI_Fields_Mapping__mdt WHERE Outlet_Execution_KPI_Field__c != null]){           
            if(!kpiTypes.contains(kpiMap.KPI_Achievement_Type__c)){
                kpiTypes.add(kpiMap.KPI_Achievement_Type__c);
                queryFieldsString += 'SUM(' + kpiMap.Outlet_Execution_KPI_Field__c + ') '+ kpiMap.KPI_Achievement_Type__c + ' ,';
            }
        }
        
        for(Account outlet :[SELECT Id, Primary_Sales_Territory__c FROM Account WHERE Primary_Sales_Territory__c IN :territoryIdSet AND Status__c = 'Active']){
            
            Id territoryId = outlet.Primary_Sales_Territory__c;
            //Mapping Territory with number of Outlets
            if(territoryWithOutletsNumberMap.containsKey(territoryId)){
                territoryWithOutletsNumberMap.put(territoryId, territoryWithOutletsNumberMap.get(territoryId) + 1);
            }else{
                territoryWithOutletsNumberMap.put(territoryId, 1);
            }           
        }
        
        //Quering on KPI Achievement object for Upserting Records
        for(KPI_Achivement__c kpiAchive : [SELECT Id, Territory__c, Product__c, KPI_Type__c FROM KPI_Achivement__c WHERE Territory__c IN :territoryIdSet AND recordTypeId = :prodKPIRecTypeId AND KPI_Type__c IN :kpiTypes]){
            string key = kpiAchive.Territory__c + kpiAchive.KPI_Type__c + kpiAchive.Product__c;
            kpiAchivementMap.put(key , kpiAchive.Id);
        }       
        
        String queryString = 'SELECT COUNT(Id), '+ queryFieldsString + ' Outlet__r.Primary_Sales_Territory__c territoryId, Product__c FROM Outlet_Execution__c WHERE Outlet__r.Primary_Sales_Territory__c IN :territoryIdSet AND  Outlet__r.Status__c = \'Active\' AND recordTypeId = :prodRecTypeId and (Distribution_TRAX__c = \'Yes\' OR NPA__c = \'Yes\') GROUP By Outlet__r.Primary_Sales_Territory__c, Product__c';
       
        for (AggregateResult ar : Database.query(queryString)){
            Id prodId = (Id)ar.get('Product__c');
            Id territoryId = (Id)ar.get('territoryId');
            for(String kpiType : kpiTypes){
                String key = territoryId + kpiType + prodId;
                KPI_Achivement__c kpiAchive = new KPI_Achivement__c(Id = kpiAchivementMap.containsKey(key) ? kpiAchivementMap.get(key) : null);
                kpiAchive.RecordTypeId = prodKPIRecTypeId;
                kpiAchive.Territory__c = territoryId;
                kpiAchive.Country__c = territoryMap.get(territoryId).Country__c;
                kpiAchive.KPI_Type__c = kpiType;
                kpiAchive.Region__c = territoryMap.get(territoryId).Region__c;
                kpiAchive.Product__c = prodId;  
                kpiAchive.Total_Denominator__c = territoryWithOutletsNumberMap.get(territoryId);
                kpiAchive.Actual_Numerator__c = (Decimal)ar.get(kpiType);
                kpiAchive.Achievement__c = kpiAchive.Total_Denominator__c > 0 ? (kpiAchive.Actual_Numerator__c / kpiAchive.Total_Denominator__c) * 100 :0;
                if(kpiAchive.Product__c != null){// ES20-13380
                   kpiAchivementsToUpsert.add(kpiAchive); 
                }
                
            }
            
        }
        
        if(kpiAchivementsToUpsert != null && kpiAchivementsToUpsert.size() > 0 && Schema.sObjectType.KPI_Achivement__c.isCreateable() && Schema.sObjectType.KPI_Achivement__c.isUpdateable()){
            upsert kpiAchivementsToUpsert;
        }       
        
    }

}