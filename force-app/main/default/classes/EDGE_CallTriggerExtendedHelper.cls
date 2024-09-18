/**
* @name EDGE_CallTriggerHelper
* @description: Trigger Helper Class for Call
* @history                                                         
*  @VERSION   AUTHOR            DATE              DETAIL
*	1.0       Vikas Anand       01/01/2020        ES20-6006 (Method - calculateCallPerDay - changed the List of user to Map of User 
for updating And Fixed the Bug ES20-6771) 
*	2.0       Sandip Ghosh      21/07/2020        ES20-8328(Trigger and Batch update_SFDC_US3_Virtual call)
*	2.1	      Supriya Galinde   12/11/2021        [ES20-11604] Fetching of KPIs Active for Days In Trade from Role Call object

*   2.0 	  Anand U 		    10/01/2022		  ES20-11921
*   3.0 	  Swaraj Samanta    25/10/2022		  ES20-13390[DIT KPI should be reset every Market cycle_SFDC_KPI Enhancements]

**/
public without sharing class EDGE_CallTriggerExtendedHelper { 
    /**
* @method   fetchMarketCycleBasedOnUser- ES20-13390
* @description Fetches market cycle for the User records present in context 
*  @return Map
*  @param Map
*/
    
    public static Map<String, Market_Cycle__c> fetchMarketCycleBasedOnUser(Map<Id, Call__c> newCallMap,Set<Id> accountSetId){
        List<Id> geographyCountryIdsList = new List<Id>();
        Map<String, Market_Cycle__c> userIdToMarketCycleMap = new Map<String, Market_Cycle__c>();
        Map<Id, Market_Cycle__c> geoIdtoMCycleMap = new Map<Id, Market_Cycle__c>();
        Map<Id, Id> accIdToCountryIdMap = new Map<Id, Id>();
        Map<Id, Account> accIdToAccMap = new MAP<Id,Account>([SELECT Id,Country__c FROM Account WHERE ID IN : accountSetId]);
        
        for(Account accRec : accIdToAccMap.values()){
            geographyCountryIdsList.add(accRec.Country__c);
            accIdToCountryIdMap.put(accRec.Id, accRec.Country__c);
        }
        
        
        if(!geographyCountryIdsList.isEmpty()){
            for(Market_Cycle__c marketCycle : [Select Id, Geography__c, Start_Date__c, End_Date__c, Active__c from Market_Cycle__c
                                               where Geography__c in :geographyCountryIdsList and Active__c = TRUE])
            { 
                geoIdtoMCycleMap.put(marketCycle.Geography__c, marketCycle);   
            }
            if(geoIdtoMCycleMap != null && !geoIdtoMCycleMap.isEmpty()){
                for(Call__c callRec : newCallMap.values()){
                    id geoId = accIdToCountryIdMap.get(callRec.Account__c);
                    if(geoId != null && geoIdtoMCycleMap.containsKey(geoId)){
                        userIdToMarketCycleMap.put(callRec.Call_Performed_By__c , geoIdtoMCycleMap.get(geoId)); 
                    }
                }
            }
        }
        return userIdToMarketCycleMap;
    }
    
    
    
    /*
*    @Name : calculateDaysinTrade
*    @Description  : Method to Calculate Days In Trade
*/
    public static void calculateDaysinTrade(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){  
        Map<Id, Call__c> mapNewCalls;
        Set<Id> managerIdSet = new Set<Id>();
        List<User> userListToUpdate = new List<User>(); 
        Map<Id, Date> userWithCallEndDateMap = new Map<Id, Date>();
        Map<Id, Integer> managerWithRepsMap = new Map<Id, Integer>();
        Map<Id, Decimal> managerWithRepsValueMap = new Map<Id, Decimal>();
        Map<Id, Decimal> userWithDaysInTradeMap = new Map<Id, Decimal>();   
        string[] physicalCallset= label.EDGE_Physical_Call.split(';');  
        Map<id,Call_Type__c> callTypeMap = new Map<Id,Call_Type__c>([select id,Name from Call_Type__c where KPI_Relevant__c = true]); //Removed Name in:physicalCallset
        Map<Id, Call__c> initialCallMap = new Map<Id, Call__c>();
        Set<Id> outletIds = new Set<Id>();
        Map<Id, Account> accIdToAccMap = new Map<Id, Account>();
        Map<Id, Boolean> incrDecrIndicatorMap = new Map<Id, Boolean>();
        if(newItems != null){//ES20-13390
            mapNewCalls = (Map<Id, Call__c>) newItems;    
        }
        Map<String,Market_Cycle__c> userIdToMarketCycleMap = new Map<String,Market_Cycle__c>();//ES20-13390
        
        //Map<Id, Id> userIdToBusinessRoleIDMap = new Map<Id, Id>();
        //ES20-8328
        //Map<String, Set<Id>> compMetricToCallTypesMap = EDGE_CallTriggerHelper.getCallRecordTypesMap();
        
        
        for(SObject call : newItems.values()){
            Call__c callObj = (Call__c)call;
            Call__c oldCallObj;
            outletIds.add(callObj.Account__c);
            //Map<String, Set<String>> kpiActiveRolecallMap = EDGE_CallTriggerHelper.getKPIsTypeRoleCallMap(userIdset,callTypeIdSet, userIdToBusinessRoleIDMap);
            Set<String> roleCallsDITUniqueIds = EDGE_CallTriggerHelper.KPITYpeToRoleCallMap.get('Days In Trade');
            //ES20-8328
            Id businessRoleId = EDGE_CallTriggerHelper.userIdToBusinessRoleIDMap.get(callObj.Call_Performed_By__c);
            String uniqueKey = callObj.Type_of_Call__c + '_' + businessRoleId;//EDGE_CallTriggerHelper.getUniqueKeyForCall(callObj, userIdToBusinessRoleIDMap);
            
            if(callObj.Status__c == 'Completed' && roleCallsDITUniqueIds != null && roleCallsDITUniqueIds.contains(uniqueKey) && callObj.Call_Performed_By__c!=null)
            {
                if(oldItems != null){                
                    oldCallObj = (Call__c)oldItems.get(callObj.Id);  
                    if(callObj.End_Date__c != null && oldCallObj.Status__c != 'Completed' /*&& callTypeMap.containsKey(callObj.Type_of_call__c)*/){
                        userWithCallEndDateMap.put(callObj.Call_Performed_By__c, callObj.End_Date__c.Date());   
                    }               
                }else{
                    if(callObj.End_Date__c != null && callObj.Status__c == 'Completed' /*&& callTypeMap.containsKey(callObj.Type_of_call__c)*/){ 
                        userWithCallEndDateMap.put(callObj.Call_Performed_By__c, callObj.End_Date__c.Date());   
                    }               
                }                
            }
            
        }
        
        userIdToMarketCycleMap = fetchMarketCycleBasedOnUser(mapNewCalls,outletIds);//ES20-13390
      
        for(User userRec :[SELECT Id, profile.name, ManagerId, Days_In_Trade__c, Last_call_date_for_physical_call__c from user where Id IN :userWithCallEndDateMap.keyset()  AND  Last_call_date_for_physical_call__c != :userWithCallEndDateMap.values()]){                         
            //   if(userRec.Last_call_date_for_physical_call__c != null && userWithCallEndDateMap.get(userRec.Id).year() != userRec.Last_call_date_for_physical_call__c.year()){
            ////ES20-13390
            if(userRec.Last_call_date_for_physical_call__c != null && userIdToMarketCycleMap.get(userRec.Id) != null
               && userWithCallEndDateMap.get(userRec.Id) > userIdToMarketCycleMap.get(userRec.Id).Start_Date__c  
               && userWithCallEndDateMap.get(userRec.Id) <= userIdToMarketCycleMap.get(userRec.Id).End_Date__c )
            {
                userRec.Days_In_Trade__c = checkForNull(userRec.Days_In_Trade__c) + 1; 
               
            }else{
                userRec.Days_In_Trade__c = 1;              
            }
            if(userRec.managerId != null){
                managerIdSet.add(userRec.managerId);
            }   
            userWithDaysInTradeMap.put(userRec.Id, userRec.Days_In_Trade__c);                
            userListToUpdate.add(userRec);                          
        }
        //Code to check if a Sales Rep is performing a call and Update it's manager's Days_In_Trade_Of_Sales_Reps__c field. Not requied when manager is performing a call.
        for(User userRec : [Select Id, ManagerId, Days_In_Trade__c from user where managerId IN:managerIdSet]){                
            if(managerWithRepsValueMap.containsKey(userRec.ManagerId)){
                managerWithRepsMap.put(userRec.ManagerId, managerWithRepsMap.get(userRec.ManagerId) + 1);
                if(userWithDaysInTradeMap.containsKey(userRec.Id)){
                    managerWithRepsValueMap.put(userRec.ManagerId, managerWithRepsValueMap.get(userRec.ManagerId) + userWithDaysInTradeMap.get(userRec.Id));
                }else{
                    managerWithRepsValueMap.put(userRec.ManagerId, managerWithRepsValueMap.get(userRec.ManagerId) + checkForNull(userRec.Days_In_Trade__c));
                }                
            }else{
                managerWithRepsMap.put(userRec.managerId, 1);
                if(userWithDaysInTradeMap.containsKey(userRec.Id)){
                    managerWithRepsValueMap.put(userRec.managerId, userWithDaysInTradeMap.get(userRec.Id)); 
                }else{
                    managerWithRepsValueMap.put(userRec.managerId, checkForNull(userRec.Days_In_Trade__c));  
                }                
            }           
        }
        for(User managerRec : [SELECT Id FROM User WHERE Id IN:managerWithRepsValueMap.keyset()]){
            managerRec.Days_In_Trade_Of_Sales_Reps__c = managerWithRepsValueMap.get(managerRec.Id) / managerWithRepsMap.get(managerRec.Id);
            userListToUpdate.add(managerRec);
        }
        //End Days_In_Trade_Of_Sales_Reps__c code       
        if(!userListToUpdate.isEmpty() && userListToUpdate.size()>0 && !Test.isRunningTest()){
            database.update(userListToUpdate, false);
        }
        
    }
    
    //Method to check Null - Redudndant Method
    public static Decimal checkForNull(Decimal daysValue){
        return EDGE_UtilityClass.checkForNull(daysValue);
    } 
}