/**********************************************************************
Name: EDGE_TerritoryHistoricUpdate
=======================================================================
Req: 
ES20-5364- Territory Historic Record Update
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                      DATE              DETAIL
1.0         Anuja Chattopadhyay         16/11/2019        ES20-5364
***********************************************************************/
public with sharing class EDGE_TerritoryHistoricUpdate {
    public static  Map<Id,Territory_Historic__c> territoryHistoricCalculation(Set<Id> territoryIdSet ){
        
     Map<Id,List<KPI_Achivement__c>> territoryKPIAchivementMap = new  Map<Id,List<KPI_Achivement__c>>();
        Map<Id,Territory_Historic__c> territoryHistoricMap = new Map<Id,Territory_Historic__c>();
        Integer currentMonth = Date.Today().Month();
        Integer currentYear=system.today().Year();
        Territory_Historic__c newTerrHistRecord;
        List<KPI_Achivement__c> kpiAchivementList = new List<KPI_Achivement__c>();
        Set<String> kpiTypes = new Set<String>{'MAS','MPA','NPD','OES','Distribution'};
        String monthlyRecTypeId = Territory_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Territory_KPIs').getRecordTypeId();
        
        if( Schema.SObjectType.KPI_Achivement__c.isAccessible() && Schema.SObjectType.Territory__c.isAccessible() && Schema.SObjectType.Geography__c.isAccessible()){           
            kpiAchivementList = [SELECT Id, Achievement__c, Current_National_Ranking__c, Country__c, KPI_Type__c, Territory__c FROM KPI_Achivement__c WHERE Territory__c IN :territoryIdSet AND recordType.developerName = 'Territory_KPI' AND KPI_Type__c IN :kpiTypes];
        }
        //prepare a map between territory and different type of KPI present for that territory
             if(kpiAchivementList!=null){
                for(KPI_Achivement__c kpiAchvmntRecord : kpiAchivementList) {
                    if(territoryKPIAchivementMap.containsKey(kpiAchvmntRecord.Territory__c)){
                        territoryKPIAchivementMap.get(kpiAchvmntRecord.Territory__c).add(kpiAchvmntRecord);
                    } else{
                        territoryKPIAchivementMap.put(kpiAchvmntRecord.Territory__c, new List<KPI_Achivement__c>{kpiAchvmntRecord});
                    }
                } 
            }
            
            //query existing Territory Historic records for current month
            for(Territory_Historic__c terHisRecord : [SELECT Id,Territory_Name__c,Date_Of_Execution__c FROM Territory_Historic__c WHERE Territory_Name__c IN :territoryKPIAchivementMap.KeySet()
                                                      AND CALENDAR_MONTH(Date_Of_Execution__c) =:currentMonth AND CALENDAR_YEAR(Date_Of_Execution__c) =:currentYear
                                                      AND RecordTypeId =: monthlyRecTypeId]){   
                                             territoryHistoricMap.put(terHisRecord.Territory_Name__c,terHisRecord);
                                                      }
           System.debug('@@territoryHistoricMap' +territoryHistoricMap);
            
            //Iterate over all the KPI Achivement records
            for(Id terrRecord : territoryKPIAchivementMap.Keyset()){ 
                for(KPI_Achivement__c kpiAchvmentRecord : territoryKPIAchivementMap.get(terrRecord)) {      
                  if(territoryHistoricMap!=null & territoryHistoricMap.size()>0 && territoryHistoricMap.ContainsKey(terrRecord)){
                       
                       newTerrHistRecord = territoryHistoricMap.get(terrRecord);
                       newTerrHistRecord.Territory_Name__c = terrRecord;
                       newTerrHistRecord.RecordTypeId = monthlyRecTypeId;
                     }
                    else{
                        newTerrHistRecord = new Territory_Historic__c();
                        newTerrHistRecord.Date_Of_Execution__c = date.newInstance(currentYear, currentMonth, 1);
                        newTerrHistRecord.Territory_Name__c = terrRecord; 

                    }
                    System.debug('@@newTerrHistRecord' +newTerrHistRecord);
                    //Check for Distribution
                    if(kpiAchvmentRecord.KPI_Type__c!=null && kpiAchvmentRecord.KPI_Type__c=='Distribution'){
                         newTerrHistRecord.Distribution__c = kpiAchvmentRecord.Achievement__c; 
                          
                        }
                  
                    //Check for Minimum Standard Activations
                  else if(kpiAchvmentRecord.KPI_Type__c!=null && kpiAchvmentRecord.KPI_Type__c=='MAS'){
                         newTerrHistRecord.Minimum_Standard_Activations__c = kpiAchvmentRecord.Achievement__c; 
                          
                        } 
                      
                    //Check for Minimum Product_Assortment
                    else if(kpiAchvmentRecord.KPI_Type__c!=null && kpiAchvmentRecord.KPI_Type__c=='MPA'){
                          newTerrHistRecord.Minimum_Product_Assortment__c = kpiAchvmentRecord.Achievement__c; 
                         }
                       
                    //Check for Outlet Execution Score
                    else if(kpiAchvmentRecord.KPI_Type__c!=null && kpiAchvmentRecord.KPI_Type__c=='OES'){
                          newTerrHistRecord.Outlet_Execution_Score__c = kpiAchvmentRecord.Achievement__c; 
                          
                        }

                    //Check for New Product Distribution
                    else if(kpiAchvmentRecord.KPI_Type__c!=null && kpiAchvmentRecord.KPI_Type__c=='NPD'){
                          newTerrHistRecord.New_Product_Distribution__c = kpiAchvmentRecord.Achievement__c; 
                          
                          }
                  territoryHistoricMap.put(newTerrHistRecord.Territory_Name__c,newTerrHistRecord); 

                }
        }
        return territoryHistoricMap;
    }
}