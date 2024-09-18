/**
* @name EDGE_CallTriggerHelper
* @description: Trigger Helper Class for Call
* @history 

* @VERSION   AUTHOR            DATE              DETAIL
*	1.0      Saurav Paul       22th-Mar-2019     ES20-239 (Method - updateLastVisit)
*	2.0       Dipanjan Das      28/05/2019        ES20-1787 - updateCPDforUser  
*	3.0       Sandip Ghosh      28/10/2019        ES20-4301 (Methods - updateCallAndVistCompliance, updateActualVisit, fetchMarketCycle)
*	4.0       Sagar Barman      28/10/2019        ES20-4299 (updateCallAndVistCompliance, updateCallComplianceOnDelete)
*	5.0       Vikas Anand       01/01/2020        ES20-6006 (Method - calculateCallPerDay - changed the List of user to Map of User
for updating And Fixed the Bug ES20-6771) 
*	6.0       Sagar Barman      10/01/2020        ES20-6642(Added KPI_Relevant__c = true in all Calltype query and removed depency with label)
*	7.0       Sandip Ghosh      22/06/2020        ES20-8250(Added the method updateVirtualCallCount)
*	8.0       Monalisa Halder   21/07/2020        ES20-8351(Updated the method updateVirtualCallCount)
*	9.0		  Sandip Ghosh		21/07/2020		  ES20-8328 (Trigger and Batch update_SFDC_US3_Virtual call)
*	10.0	  Sandip Ghosh		04/08/2020		  ES20-8422 (Update Logic to calculate Coverage Compliance Metric _Salesforce_Coverage Metrics)
*	11.0	  Sandip Ghosh		04/08/2020		  ES20-8419 (Update Logic to calculate Total Planned Calls in Outlet Level_Salesforce_Coverage Metrics)
*	12.0      Monalisa Halder   30/09/2021        ES20-11003(Updated the method updateLastVisit)

*	12.1      Monalisa Halder   07/10/2021        ES20-11324(Updated the method updateLastVisit)
*	12.2	  Supriya Galinde   12/11/2021        [ES20-11204] Fetching of KPIs Active for Coverage, Planned and Outlet Visit Compliance 
from Role Call object

*	13.0       Anand U 		    11/01/2022		  ES20-11921
*   13.1	 Rajarshi Lahiri	25/05/2022		  ES20-12717(Updating Call Planned field to keep track of planned calls)
*	14.2	 Saranya L			26/10/2022		  ES20-13409(updateVirtualCallCount: Changed the total virtual calls calculation from monthly to market cycle)
*	15.0	  Sudipta Nandy		21/09/2023		  US-3346766 -- Added if condition to check if the call status is changed from pending to completed && Adding oldItemsMap in the Adding Map of Olditems in the calculateCallPerDay method (EDGE_CallTriggerHelper) && Adding Map of Olditems in the afterUpdate and afterinsert(CallTriggerHandler)
**/
public with sharing class EDGE_CallTriggerHelper {
    
    final static String COMPLETED_STR = 'Completed';
    final static String PLANNED_STR = 'Planned';
    static Map<id, Call_Type__c> callRecordTypesMap;
    static Map<id,Role_Call__c> roleCallMap;
    static Map<String, Set<Id>> compMetricToCallTypesMap = new Map<String, Set<Id>>();
    public static Map<Id, Id> userIdToBusinessRoleIDMap = new Map<Id, Id>();
    public static Map<String,Set<String>> KPITYpeToRoleCallMap = new Map<String,Set<String>>();
    public static Map<Id, Account> accountGlobalMap = new Map<Id, Account>();
    
    
     /**
    * @method   getKPIsTypeRoleCallMap
    * @description Static Method to get KPI Type and Call type from Role Call  
    *  @return map
    *  @param null
    */    
    public static void getKPIsTypeRoleCallMap(Map<Id, SObject> newMap, Map<Id, SObject> oldMap){
        Set<id> userIdset = new Set<id>();
        set<id> callTypeIdSet = new Set<id>();
        for(SObject sObj : newMap.values()){
            Call__c callObj = (Call__c)sObj;
            if(oldMap == null){
                userIdset.add(callObj.Call_Performed_By__c);
                callTypeIdSet.add(callObj.Type_Of_Call__c);
            }
            else if(oldMap!= null && oldMap.containsKey(callObj.Id)){
                Call__c oldCallObj = (Call__c)oldMap.get(callObj.Id);
                if((oldCallObj.End_Date__c != callObj.End_Date__c && callObj.End_Date__c != null) 
                   || (oldCallObj.Status__c != callObj.Status__c) || callObj.Status__c == 'Completed'){
                       userIdset.add(callObj.Call_Performed_By__c);
                       callTypeIdSet.add(callObj.Type_Of_Call__c);
                   }
            }
        }
        if(userIdset!=null && userIdset.size()>0){  
            for(User_Business_Role__c ubr: [Select id, User__c, Business_Role__c from User_Business_Role__c where User__c in :userIdset]){           
                userIdToBusinessRoleIDMap.put(ubr.User__c,ubr.Business_Role__c);
            }
        }
        if(userIdToBusinessRoleIDMap != null && callTypeIdSet != null){
            for(Role_Call__c roleCallRec : [SELECT Id,Name,KPIs_Active__c,Business_Role__c,Call_Type__c 
                                            FROM Role_Call__c WHERE KPIs_Active__c != null and 
                                            Business_Role__c in :userIdToBusinessRoleIDMap.values() 
                                            and Call_Type__c in :callTypeIdSet])
            {
                List<String> kpisActiveList = roleCallRec.KPIs_Active__c.split(';');
                for(String kpiActiveValue : kpisActiveList){
                    if(!KPITYpeToRoleCallMap.containsKey(kpiActiveValue)){
                        KPITYpeToRoleCallMap.put(kpiActiveValue,new Set<String>{roleCallRec.Call_Type__c+'_'+roleCallRec.Business_Role__c});
                    }else{
                        KPITYpeToRoleCallMap.get(kpiActiveValue).add(roleCallRec.Call_Type__c+'_'+roleCallRec.Business_Role__c);
                    }
                    
                }
            }
        }
        EDGE_UtilityClass.printGovLimits(147);
    }
    
    /**
* @method   getUniqueKeyForCall
* @description Static Method to get Unique key from Call Type and Business role  
*  @return map
*  @param null
*/
    
    //ES20-11064
    public static String getUniqueKeyForCall(Call__c callObj, Map<Id, Id> userIdToBusinessRoleIDMap){
        Id businessRoleId;
        Id userId;
        Id callType;
        String uniqKey;
        
        if(callObj.Call_Performed_By__c != null && callObj.Type_of_Call__c != null){
            userId = callObj.Call_Performed_By__c;   
            if(userIdToBusinessRoleIDMap.containsKey(userId)){
                businessRoleId = userIdToBusinessRoleIDMap.get(userId);
            }
            callType = callObj.Type_of_Call__c;
        }
        if(callType != null && businessRoleId != null){
            uniqKey = callType +'_'+ businessRoleId;
        }
        
        return uniqKey;
    }
    /**
* @method   updateLastVisit
* @description It will update Visit compliance and Visit date in Account
*              Updates the Last Visit Date on Account, associated with the Covergae Compliance metric
*  @return void
*  @param Map,Boolean
*/
    
    public static void updateLastVisit(Map<Id, SObject> newMap, Map<Id, SObject> oldMap, Boolean isUpdate){
        Set<Id> accountIdSet = new Set<Id>(); 
        Map<Id, Account> accountMap = new Map<Id, Account>();
        //ES20-11003 -- start
        Map<Id,Call__c> callMap;
        Set<Id> callIdSet = new Set<Id>();
        //ES20-11003 -- end
        Set<Id> countryIdSet = new Set<Id>();
        Map<Id, Id> marketBusinesHrsMap = new Map<Id, Id>();
        List<Account> updatedAccList = new List<Account>();
        //ES20-8328, ES20-8422
        //Set<Id> coverageCompCallTypes = compMetricToCallTypesMap.get('Coverage Compliance');
        //ES20-11003 -- start
        String salesRepProfiles = label.EDGE_Sales_Call_Performed_By;
        String qualityRepProfiles = label.EDGE_Quality_Call_Performed_By;
        List<String> salesRepList = new List<String>();
        List<String> qualityRepList = new List<String>();
        
        if(String.isNotBlank(salesRepProfiles)){
            salesRepList = salesRepProfiles.split(';');
        }
        if(String.isNotBlank(qualityRepProfiles)){
            qualityRepList = qualityRepProfiles.split(';');
        }
        //ES20-11003 -- end
        
        for(SObject sObj : newMap.values()){
            Call__c callObj = (Call__c)sObj;             
            //Checking for Update
            if(isUpdate && oldMap!= null && oldMap.containsKey(callObj.Id)){
                
                Call__c oldCallObj = (Call__c)oldMap.get(callObj.Id);
                if((oldCallObj.End_Date__c != callObj.End_Date__c && callObj.End_Date__c != null) || (oldCallObj.Status__c != callObj.Status__c) && callObj.Status__c == 'Completed'){
                    accountIdSet.add(callObj.Account__c);
                    callIdSet.add(callObj.Id); //ES20-11003
                    
                }
            }else if(!isUpdate && callObj.End_Date__c != null && callObj.Status__c == 'Completed'){ //New values creation
                accountIdSet.add(callObj.Account__c);
                callIdSet.add(callObj.Id); //ES20-11003 
            }
        }
        //ES20-11003 -- start
        if(!callIdSet.isEmpty()){
            callMap = new Map <Id,Call__c>([Select Id , Call_Performed_By__c,Call_Performed_By__r.Profile.Name,
                                            
                                            End_Date__c,Status__c,Call__c.Account__c,Last_Visit_from_Mobile__c,Type_of_Call__c from Call__c where Id IN :callIdSet]);  
            
            
        }
        //ES20-11003 -- end
        if(!accountIdSet.isEmpty() && Schema.sObjectType.Account.isAccessible()){
            //Fetching related Accounts and Calls
            for(Account acc : [SELECT Id, Last_Visit__c,Last_Visit_Quality__c,Outlet_Visit_Frequency__c, Visit_Compliance__c, Country__c 
                               FROM Account WHERE Id IN :accountIdSet]){
                                   accountMap.put(acc.Id, acc);
                                   countryIdSet.add(acc.Country__c);
                               }
        }
        //Get Market Business Hours
        if(countryIdSet.size()>0 && Schema.sObjectType.Market_Setting__c.isAccessible()){
            for(Market_Setting__c mktSetting : [select Id, Geography__c, Business_Hours__c from Market_Setting__c where Geography__c IN :countryIdSet]){
                marketBusinesHrsMap.put(mktSetting.Geography__c, mktSetting.Business_Hours__c);
            }
        }
        Set<String> roleCallsCoverageCompUniqueIds = KPITYpeToRoleCallMap.get('Coverage Compliance');
        //Iterate over calls to get end date and update on Account
        if(callMap != null && callMap.size() >0){
            for(Call__c callObj : callMap.values()){
                
                
                //ES20-11064
                
                String uniqueKey = getUniqueKeyForCall(callObj, userIdToBusinessRoleIDMap);
                
                if(accountMap != null && accountMap.containsKey(callObj.Account__c) && callObj.End_Date__c != null && callObj.Status__c == 'Completed'){
                    if(salesRepList.contains(callObj.Call_Performed_By__r.Profile.Name) && callObj.Last_Visit_from_Mobile__c == true){ //ES20-11003 && ES20-11324
                        
                        if(accountMap.get(callObj.Account__c).Last_Visit__c != null){
                            Date prevCallDate = accountMap.get(callObj.Account__c).Last_Visit__c;
                            Date latestCallDate = callObj.End_Date__c.date();     
                            //if latest call date is greater than last visit date mentioned at account
                            if(prevCallDate < latestCallDate){
                                accountMap.get(callObj.Account__c).Last_Visit__c = callObj.End_Date__c.date();
                                //Update Visit Compliance by checking visit frequency and business days
                                DateTime prevCallDateTime = DateTime.newInstanceGmt(prevCallDate.year(), prevCallDate.month(), prevCallDate.day(), 0, 0, 0);
                                DateTime latestCallDateTime = DateTime.newInstanceGmt(latestCallDate.year(), latestCallDate.month(), latestCallDate.day(), 0, 0, 0);
                                if(marketBusinesHrsMap != null && marketBusinesHrsMap.containsKey(accountMap.get(callObj.Account__c).Country__c)){
                                    string businessHrsId = marketBusinesHrsMap.get(accountMap.get(callObj.Account__c).Country__c);
                                    Decimal visitFreq = accountMap.get(callObj.Account__c).Outlet_Visit_Frequency__c != null ? accountMap.get(callObj.Account__c).Outlet_Visit_Frequency__c : 0;
                                    
                                    //BusinessHours Diff method give result in millisecond, we need to convert it into days and validate with visit frequency
                                    Long timeBetween = BusinessHours.diff(businessHrsId, prevCallDateTime, latestCallDateTime);
                                    Integer daysBetween = Integer.valueOf(timeBetween / 86400000);  //1000 * 60 * 60 * 24
                                    if(daysBetween <= Integer.valueOf(visitFreq)){
                                        accountMap.get(callObj.Account__c).Visit_Compliance__c = true;
                                    }else{
                                        accountMap.get(callObj.Account__c).Visit_Compliance__c = false;
                                    }
                                }
                            }
                        }else{
                            //ES20-8328
                            //if(callObj.Type_of_Call__c != null && (coverageCompCallTypes != null && coverageCompCallTypes.contains(callObj.Type_of_Call__c))){
                            accountMap.get(callObj.Account__c).Last_Visit__c = callObj.End_Date__c.date();
                            
                        }
                    }
                    //ES20-11003 -- start
                    
                    if(qualityRepList.contains(callObj.Call_Performed_By__r.Profile.Name) && callObj.Last_Visit_from_Mobile__c == true){//changed for ES20-11324
                        
                        if(accountMap.get(callObj.Account__c).Last_Visit_Quality__c != null){
                            Date prevCallDate = accountMap.get(callObj.Account__c).Last_Visit_Quality__c;
                            Date latestCallDate = callObj.End_Date__c.date();
                            //if latest call date is greater than last visit date mentioned at account
                            if(prevCallDate < latestCallDate){
                                //update Last Visit Date
                                accountMap.get(callObj.Account__c).Last_Visit_Quality__c = callObj.End_Date__c.date();
                            }
                        }else{
                            accountMap.get(callObj.Account__c).Last_Visit_Quality__c = callObj.End_Date__c.date();
                            
                        }
                    }//ES20-11003 -- end
                }
            }
        }
        if(accountMap != null && !accountMap.isEmpty()){
            for(Id accId : accountMap.keySet()){
                if(accountGlobalMap.containsKey(accId)){
                    Account globalAcc = accountGlobalMap.get(accId);
                    Account accRec = accountMap.get(accId);
                    globalAcc.Last_Visit__c = accRec.Last_Visit__c;
                    globalAcc.Visit_Compliance__c = accRec.Visit_Compliance__c;
                    globalAcc.Last_Visit_Quality__c = accRec.Last_Visit_Quality__c;
                    accountGlobalMap.put(accId,globalAcc);
                }
                else{
                    accountGlobalMap.put(accId,accountMap.get(accId));
                }
            }
        }
    }
    
    /**
* @method   calculateCallPerDay
* @description Method to Calculate Call Per Day 
*  @return void
*  @param list
*/
    //US-3346766 -- Adding oldItemsMap in the Adding Map of Olditems in the calculateCallPerDay method (EDGE_CallTriggerHelper) afterUpdate and afterinsert(CallTriggerHandler)
    public static void calculateCallPerDay(List<call__c> newItems, Map<Id, SObject> oldItemsMap){  
        
        Map<Id,call__c> completedcallMap= new Map<Id,call__c>();
        
        Map<id,string> userCountryMap= new Map<Id,string>();
        Map<string,Market_Cycle__c> cycleMap = new Map<string,Market_Cycle__c>();
        Map<Id, User> updateUserMap = new Map<Id, User>();
        Set<Id> userIdset= new Set<Id>();
        //US-3346766 -- getting call object data in sObject
        for(Call__c  call : newItems){
            Call__c oldCallRec;
            if(oldItemsMap != null){
                oldCallRec = (Call__c)oldItemsMap.get(call.id);
            }
 		//US-3346766 -- Added if condition to check if the call status is changed from pending to completed
 		//if(call.Status__c=='Completed')
            if((oldItemsMap != null && oldCallRec.Status__c != call.Status__c && call.Status__c == 'Completed') || (oldItemsMap == null && call.Status__c == 'Completed')){
                completedcallMap.put(call.id,call);
                userIdset.add(call.Call_Performed_By__c);
            }
        }
        Map<id,User> userMap=new Map<Id,user>([SELECT id , Available_Countries__c,Last_call_date_for_physical_call__c,Business_Role__c,Number_of_days_for_Physical_call__c,Total_number_of_physical_call__c from user where id in: userIdset]);
        //get the physical call type 
        //ES20-8328
        for(Id uId :userMap.keyset()){
            if(userMap.get(uId).Available_Countries__c != null && userMap.get(uId).Available_Countries__c.contains(';')){
                string[] countryset=userMap.get(uId).Available_Countries__c.split(';');
                userCountryMap.put(uId, countryset[0]);
            }
            else if(userMap.get(uId).Available_Countries__c != null ){
                userCountryMap.put(uId,userMap.get(uId).Available_Countries__c );
            } 
        }
        if(Schema.sObjectType.Market_Cycle__c.isAccessible())
        {
            List<Market_Cycle__c> marketCyclelst=[select id ,End_Date__c, Start_Date__c,Geography__r.code__c from 
                                                  Market_Cycle__c where Geography__r.code__c in: userCountryMap.values() and active__c=true];
            for(Market_Cycle__c cycle:marketCyclelst ){
                cycleMap.put(cycle.Geography__r.code__c, cycle);
                
            }
        }
        //EDGE_UtilityClass.printGovLimits(365);
        Set<String> roleCallsUniqueIds = KPITYpeToRoleCallMap.get('Calls Per Day');
        if(cycleMap.size()>0){
            for(id callId : completedcallMap.keyset()){
                user userObj;
                call__c callObj=completedcallMap.get(callId );
                
                String uniqueKey = getUniqueKeyForCall(callObj, userIdToBusinessRoleIDMap);
                
                /*if(callsPerDayCallTypes != null && callsPerDayCallTypes.contains(completedcallMap.get(callId ).Type_of_Call__c) && callObj.Call_Performed_By__c!=null 
&& callObj.End_Date__c!=null){*/
                if(roleCallsUniqueIds != null && roleCallsUniqueIds.contains(uniqueKey) && callObj.Call_Performed_By__c!=null 
                   && callObj.End_Date__c!=null){
                       userObj= new User(id=callObj.Call_Performed_By__c);                       
                       /*check if last updated last call date for physcical call on user  and latest call's end date falls in same market cycle 
then update the count else reset the count to 1 */
                       if(callObj.End_Date__c.date()>=cycleMap.get(userCountryMap.get(callObj.Call_Performed_By__c)).Start_Date__c && callObj.End_Date__c.date()<=cycleMap.get(userCountryMap.get(callObj.Call_Performed_By__c)).End_Date__c 
                          && userMap.get(callObj.Call_Performed_By__c).Last_call_date_for_physical_call__c >=cycleMap.get(userCountryMap.get(callObj.Call_Performed_By__c)).Start_Date__c &&
                          userMap.get(callObj.Call_Performed_By__c).Last_call_date_for_physical_call__c <=cycleMap.get(userCountryMap.get(callObj.Call_Performed_By__c)).End_Date__c 
                         ){                             
                             /*check if last update last call date for physical is different from latest call end date then update the 
number of days for physical  call */
                             if(userMap.get(callObj.Call_Performed_By__c).Last_call_date_for_physical_call__c!=callObj.End_Date__c.date()){
                                 userObj.Number_of_days_for_Physical_call__c=userMap.get(callObj.Call_Performed_By__c).Number_of_days_for_Physical_call__c+1;
                                 if(userMap.get(callObj.Call_Performed_By__c).Last_call_date_for_physical_call__c < callObj.End_Date__c.date()){
                                     userObj.Last_call_date_for_physical_call__c=callObj.End_Date__c.date();  
                                 }                                  
                             }
                             else{
                                 userObj.Number_of_days_for_Physical_call__c=userMap.get(callObj.Call_Performed_By__c).Number_of_days_for_Physical_call__c;
                             }
                             userMap.get(callObj.Call_Performed_By__c).Total_number_of_physical_call__c = userMap.get(callObj.Call_Performed_By__c).Total_number_of_physical_call__c+1;
                             userObj.Total_number_of_physical_call__c=userMap.get(callObj.Call_Performed_By__c).Total_number_of_physical_call__c;
                         }else{
                             userObj.Last_call_date_for_physical_call__c=callObj.End_Date__c.date(); 
                             userObj.Number_of_days_for_Physical_call__c=1;
                             userObj.Total_number_of_physical_call__c=1;
                         }
                       //avoid divide by 0
                       if(userObj.Number_of_days_for_Physical_call__c !=0){
                           userObj.Calls_Per_Day__c=userObj.Total_number_of_physical_call__c/userObj.Number_of_days_for_Physical_call__c;
                       }
                       updateUserMap.put(userObj.Id, userObj);
                   }
            }
        }
        
        
        if(!updateUserMap.isEmpty() && updateUserMap.size()>0 && !Test.isRunningTest()){
            database.update(updateUserMap.values(), false);
        }
        
    }
    
    
    /**
* @method   calculateCallPerDay
* @description Method to check Null 
*  @return Decimal
*  @param Decimal
*/
    
    public static Decimal checkForNull(Decimal daysValue){
        return EDGE_UtilityClass.checkForNull(daysValue);
    }   
    
    /**
* @method   fetchMarketCycle
* @description Fetches market cycle for the Call records present in context 
*  @return Map
*  @param Map
*/
    
    public static Map<Id, Market_Cycle__c> fetchMarketCycle(Map<Id, Call__c> initialCallMap, Map<Id, Account> accIdToAccMap){
        List<Id> geographyCountryIdsList = new List<Id>();
        Map<Id, Market_Cycle__c> callIdToMarketCycleMap = new Map<Id, Market_Cycle__c>();
        Map<Id, Market_Cycle__c> geoIdtoMCycleMap = new Map<Id, Market_Cycle__c>();
        Map<Id, Id> accIdToCountryIdMap = new Map<Id, Id>();
        
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
                for(Call__c callRec : initialCallMap.values()){
                    id geoId = accIdToCountryIdMap.get(callRec.Account__c);
                    if(geoId != null && geoIdtoMCycleMap.containsKey(geoId)){
                        callIdToMarketCycleMap.put(callRec.Id, geoIdtoMCycleMap.get(geoId)); 
                    }
                }
            }
        }
        return callIdToMarketCycleMap;
    }
    
    /**
* @method   updateCallAndVistCompliance
* @description to UPDATE call Compliance related field in Outlet on Update 
*  @return void
*  @param Map
*/
    public static void updateCallAndVistCompliance(Map<Id,SObject> newItems,Map<Id, SObject> oldItems){         
        //ES20-8328
        Id businessRole;
        Map<Id, Call__c> mapNewCalls, mapOldCalls;
        Set<Id> accountSetId = new Set<Id>();
        //ES20-8328
        Set<Id> plannedCallCompCallTypes = compMetricToCallTypesMap.get('Planned Call Compliance');
        Set<Id> ovComplianceCallTypes = compMetricToCallTypesMap.get('Outlet Visit Compliance');
        
        if(oldItems != null){
            mapOldCalls = (Map<Id, Call__c>) oldItems;
        }
        if(newItems != null){
            mapNewCalls = (Map<Id, Call__c>) newItems;    
        }
        for(Call__c callId : mapNewCalls.values()){           
            if(oldItems == null || ((oldItems != null) && mapNewCalls.get(callId.Id).Status__c != mapOldCalls.get(callId.Id).Status__c)){
                //ES20-7328 : Planned Calls total count shouldn't have a Call Type check, hence commented the if check
                //if(callTypeMap.containsKey(mapNewCalls.get(callId).Type_of_call__c)){// physical call filter                   
                accountSetId.add(mapNewCalls.get(callId.Id).Account__c);
                //userIdSet.add(callId.Call_Performed_By__c);
                //callTypeIdSet.add(callId.Type_Of_Call__c);
                
                //}
            }
        }
        Map<Id, Account> accIdToAccMap = new MAP<Id,Account>([SELECT Id,Number_Of_Planned_Calls__c,Number_Of_Planned_Calls_Completed__c,Country__c,Actual_Visits__c FROM Account WHERE ID IN : accountSetId]);
        if(Test.isRunningTest()){
            //accIdToAccMap = new Map<Id,Account>([SELECT Id,Number_Of_Planned_Calls__c,Number_Of_Planned_Calls_Completed__c,Country__c,Actual_Visits__c FROM Account LIMIT 1]);
        }
        //EDGE_UtilityClass.printGovLimits(517);
        Map<Id,Decimal> accMapPlanCallCount = new Map<Id,Decimal>();
        Map<Id,Decimal> accMapCompleteCallCount = new Map<Id,Decimal>();
        Map<Id,Decimal> accMapActualVisitCount = new Map<Id,Decimal>();
        
        //populate the map of account with their respective planned call counts
        for(Account acc : accIdToAccMap.values()){ 
            accMapPlanCallCount.put(acc.Id,acc.Number_Of_Planned_Calls__c);
            accMapCompleteCallCount.put(acc.Id,acc.Number_Of_Planned_Calls_Completed__c);
        }
        
        Set<String> roleCallsPlannedUniqueIds = KPITYpeToRoleCallMap.get('Planned Call Compliance');
        Set<String> roleCallsOVCUniqueIds = KPITYpeToRoleCallMap.get('Outlet Visit Compliance');
        List<Call__c> callListtoUpdate =new List<Call__c>();
        //get the MarketCycleMap
        Map<Id, Market_Cycle__c> callIdToMarketCycleMap = fetchMarketCycle(mapNewCalls, accIdToAccMap);
        if(null != callIdToMarketCycleMap && !callIdToMarketCycleMap.isEmpty()){
            for(Call__c callRec : mapNewCalls.values()){
                Market_Cycle__c mCycle = callIdToMarketCycleMap.get(callRec.Id);
                System.debug('@@callRec.callPlanned__c'+callRec.callPlanned__c);
                //ES20-11064
                String uniqueKey = getUniqueKeyForCall(callRec, userIdToBusinessRoleIDMap);
                
                //Count of Planned Calls
                if(callRec.Plan_Start_Date__c != null && callRec.Plan_Start_Date__c >= mCycle.Start_Date__c && 
                   callRec.Plan_Start_Date__c <= mCycle.End_Date__c && callRec.Status__c == PLANNED_STR
                   /*&& plannedCallCompCallTypes !=null && plannedCallCompCallTypes.contains(callRec.Type_of_Call__c)*/) //ES20-8328, //ES20-8419 - removed the check for Planned Call Types
                {
                    //ES20-12717
                    if(callRec.callPlanned__c==False){
                        Call__c callUpdate=new Call__c(id=callRec.Id);
                        callUpdate.callPlanned__c= True;
                        callListtoUpdate.add(callUpdate);
                    }
                    

                    Account accRec = accIdToAccMap.get(callRec.Account__c);
                    Decimal tempVar = 0.0;
                    if(null != accMapPlanCallCount && !accMapPlanCallCount.IsEmpty() && null != accMapPlanCallCount.get(callRec.Account__c)){
                        tempVar = accMapPlanCallCount.get(callRec.Account__c)+1;
                    }else{
                        tempVar = 1;
                    }
                    accMapPlanCallCount.put(callRec.Account__c,tempVar);
                }
                
                //Calculate count of Completed Planned Calls
                //filtering with Adhoc calls, considering completed call if call status is getting updated from Planned to Completed
                //11064
                //Set<String> roleCallsUniqueIds = kpiActiveRolecallMap.get('Planned Call Compliance');
                
                if(roleCallsPlannedUniqueIds != null && oldItems != null && callRec.End_Date__c != null && (callRec.End_Date__c >= mCycle.Start_Date__c) && 
                   (callRec.End_Date__c <= mCycle.End_Date__c) && mapNewCalls.get(callRec.Id).Status__c == COMPLETED_STR && (mapOldCalls.get(callRec.Id).Status__c == PLANNED_STR)
                   && roleCallsPlannedUniqueIds.contains(uniqueKey) && callRec.Call_Performed_By__c!=null)//ES20-8328, ES20-11064
                {
                    Decimal tempVar = 0.0;                  
                    if(null != accMapCompleteCallCount && !accMapCompleteCallCount.IsEmpty() && null != accMapCompleteCallCount.get(callRec.Account__c)){
                        tempVar = accMapCompleteCallCount.get(callRec.Account__c)+1;
                    }else{
                        tempVar = 1;
                    }
                    accMapCompleteCallCount.put(callRec.Account__c,tempVar);
                }
                //ES20-8419 : Update Logic to calculate Total Planned Calls in Outlet Level_Salesforce_Coverage Metrics
                if(oldItems != null && callRec.Plan_Start_Date__c != null && (callRec.Plan_Start_Date__c >= mCycle.Start_Date__c) 
                   && (callRec.Plan_Start_Date__c <= mCycle.End_Date__c) && mapNewCalls.get(callRec.Id).Status__c == 'Deleted' &&
                   (mapOldCalls.get(callRec.Id).Status__c == PLANNED_STR)){
                       
                       Decimal tempVar = 0.0;
                       if(null != accMapPlanCallCount && !accMapPlanCallCount.IsEmpty() && null != accMapPlanCallCount.get(callRec.Account__c)){
                           tempVar = accMapPlanCallCount.get(callRec.Account__c) - 1;
                       }
                       accMapPlanCallCount.put(callRec.Account__c,tempVar);
                   }
                
                //Calculate Count of Total Actual visits
                
                if(callRec.End_Date__c != null && (callRec.End_Date__c >= mCycle.Start_Date__c) && (callRec.End_Date__c <= mCycle.End_Date__c)
                   && callRec.Call_Performed_By__c!=null && roleCallsOVCUniqueIds != null && roleCallsOVCUniqueIds.contains(uniqueKey)){//ES20-8328
                       if(oldItems == null){
                           //Handling the scenario when a Call is created in Salesforce with Completed Status
                           String newCallObjStatus = callRec.Status__c;
                           if(newCallObjStatus != null && newCallObjStatus.equalsIgnoreCase(COMPLETED_STR)){
                               Decimal tempAccActualVisitVar = updateActualVisit(accIdToAccMap, callRec.Account__c);
                               accMapActualVisitCount.put(callRec.Account__c,tempAccActualVisitVar);
                           }
                       }else if(oldItems != null){
                           //Updating an existing Call record status to Completed
                           Call__c oldCallObj = (Call__c)mapOldCalls.get(callRec.Id);
                           String oldCallObjStatus = oldCallObj.Status__c;
                           String newCallObjStatus = callRec.Status__c;
                           if(oldCallObjStatus != null && newCallObjStatus != null 
                              && !oldCallObjStatus.equalsIgnoreCase(COMPLETED_STR)  
                              && newCallObjStatus.equalsIgnoreCase(COMPLETED_STR))
                           {
                               Decimal tempAccActualVisitVar = updateActualVisit(accIdToAccMap , callRec.Account__c);
                               accMapActualVisitCount.put(callRec.Account__c,tempAccActualVisitVar);
                           }
                       }
                   }
            }
        }
        
        //assign the count values to the MAP
        for(Id accId : accIdToAccMap.keySet()){
            if(accMapPlanCallCount.get(accId) != null /*&& accMapPlanCallCount.get(accId) != 0.0*/){//ES20-8419
                accIdToAccMap.get(accId).Number_Of_Planned_Calls__c = accMapPlanCallCount.get(accId);    
            }
            if(accMapCompleteCallCount.get(accId) != null && accMapCompleteCallCount.get(accId) != 0.0){
                accIdToAccMap.get(accId).Number_Of_Planned_Calls_Completed__c = accMapCompleteCallCount.get(accId);
            }
            if(accMapActualVisitCount.get(accId) != null && accMapActualVisitCount.get(accId) != 0.0){
                accIdToAccMap.get(accId).Actual_Visits__c = accMapActualVisitCount.get(accId); 
                
            }
        }
        if(null != accIdToAccMap && !accIdToAccMap.isEmpty()){
            for(Id accId : accIdToAccMap.keySet()){
                if(accountGlobalMap.containsKey(accId)){
                    Account globalAcc = accountGlobalMap.get(accId);
                    Account accRec = accIdToAccMap.get(accId);
                    globalAcc.Number_Of_Planned_Calls__c = accRec.Number_Of_Planned_Calls__c;
                    globalAcc.Number_Of_Planned_Calls_Completed__c = accRec.Number_Of_Planned_Calls_Completed__c;
                    globalAcc.Actual_Visits__c = accRec.Actual_Visits__c;
                    accountGlobalMap.put(accId,globalAcc);
                }
                else{
                    accountGlobalMap.put(accId,accIdToAccMap.get(accId));
                }
            }
        }
        if(callListtoUpdate!=null && callListtoUpdate.size()>0){
            CallTriggerHandler.firstRun=True;
            Database.update(callListtoUpdate,false);
        }
        
    }
    
    /**
* @method   updateCallComplianceOnDelete
* @description to UPDATE call Compliance related field in Outlet on Delete 
*  @return void
*  @param Map
*/
    
    public static void updateCallComplianceOnDelete(Map<Id, SObject> oldItems){
        Map<Id, Call__c> mapCallItems = (Map<Id, Call__c>)oldItems;
        Set<Id> accountSetId = new Set<Id>();       
        //ES20-8328
        for(Id callId : mapCallItems.keySet()){
            //ES20-8328
            accountSetId.add(mapCallItems.get(callId).Account__c);
        }
        Map<Id, Account> accIdToAccMap = new MAP<Id,Account>([SELECT Id,Number_Of_Planned_Calls__c,Number_Of_Planned_Calls_Completed__c,Country__c FROM Account WHERE ID IN : accountSetId]);
        Map<Id, Decimal> accMapPlanCallCount = new Map<Id,Decimal>();
        //populate the map of account with their respective planned call counts
        for(Account acc : accIdToAccMap.values()){
            accMapPlanCallCount.put(acc.Id,acc.Number_Of_Planned_Calls__c);
        }
        //EDGE_UtilityClass.printGovLimits(665);
        //get the MarketCycleMap
        Map<Id, Market_Cycle__c> callIdToMarketCycleMap = fetchMarketCycle(mapCallItems, accIdToAccMap);
        if(null != callIdToMarketCycleMap && !callIdToMarketCycleMap.isEmpty()){
            for(Call__c callRec : mapCallItems.values()){
                Market_Cycle__c mCycle = callIdToMarketCycleMap.get(callRec.Id);
                //Instead of Start Date check in below if condition, i guess it should be Planned Start Date
                if(callRec.Plan_Start_Date__c != null && (callRec.Plan_Start_Date__c >= mCycle.Start_Date__c) 
                   && (callRec.Plan_Start_Date__c <= mCycle.End_Date__c) && callRec.Status__c == PLANNED_STR){
                       Account accRec = accIdToAccMap.get(callRec.Account__c);
                       //Line# 494 & 496 if condition can be merge into 1
                       Decimal tempVar = 0.0;
                       if(null != accMapPlanCallCount && !accMapPlanCallCount.IsEmpty() && null != accMapPlanCallCount.get(callRec.Account__c) && accMapPlanCallCount.get(callRec.Account__c)!=0){
                           tempVar = accMapPlanCallCount.get(callRec.Account__c)-1;
                       }
                       accMapPlanCallCount.put(callRec.Account__c,tempVar);
                   }
            }
        }
        //assign the count values to the MAP
        for(Id accId : accIdToAccMap.keySet()){
            accIdToAccMap.get(accId).Number_Of_Planned_Calls__c = accMapPlanCallCount.get(accId);
        }
        // update the accounts
        if(null != accIdToAccMap && !accIdToAccMap.isEmpty() && Schema.sObjectType.Account.isUpdateable()){
            Database.update(accIdToAccMap.values(), false);
        }
    }
    
    /**
* @method   updateActualVisit
* @description Updates Actual Visits on the account records in context
*  @return Decimal
*  @param Map,Id
*/
    @TestVisible
    static Decimal updateActualVisit(Map<Id, Account> accIdToAccMap , Id accId ){
        
        Decimal tempAccActualVisitVar = 0.0;
        Account accRec = accIdToAccMap.get(accId);
        if(accRec != null){
            if(accRec.Actual_Visits__c == null){
                tempAccActualVisitVar = 1;
            }else if(accRec.Actual_Visits__c != null){
                tempAccActualVisitVar = accRec.Actual_Visits__c + 1;
            }  
        }
        return tempAccActualVisitVar;
    }
    
    /**
* @method   updateVirtualCallCount
* @description Updates Total Virtual Calls,Actual Virtual Call per Market Cycle and Actual Physical Call per Market Cycle on the account records in context
*  @return void
*  @param Map
*/
    public static void updateVirtualCallCount(Map<Id,SObject> newItems,Map<Id, SObject> oldItems){
        
        Map<Id, Call__c> mapNewCalls, mapOldCalls;
        Map<Id,Account> updateAccMap = new Map<Id,Account>();
        Map<Id,Id> callTypeofCallMap = new Map<Id,Id>();
        Integer currentMonth = date.today().month();
        Integer currentYear = date.today().year();
        Set<Id> accountSetId = new Set<Id> ();
        
        if(oldItems != null){
            mapOldCalls = (Map<Id, Call__c>) oldItems;
        }
        if(newItems != null){
            mapNewCalls = (Map<Id, Call__c>) newItems;    
        }
        for(Call__c callRec : mapNewCalls.values()){
            accountSetId.add(callRec.Account__c);
            callTypeofCallMap.put(callRec.Id,callRec.Type_of_Call__c);
        }
        // Getting Call Type records whose Global Equivalent Call Type equals Virtual and then putting in a map.
        Map<Id,Call_Type__c> callTypeMap = new Map<Id,Call_Type__c>([Select id , name, Global_Equivalent_Call_Type__c,Min_call_duration__c from Call_type__c where Id in :callTypeofCallMap.values()]);                                
        //EDGE_UtilityClass.printGovLimits(746);
        // Get the market cycle
        Map<Id, Account> accIdToAccMap = new Map<Id,Account>([SELECT Id,Country__c,Actual_Physical_Call_Market_Cycle__c ,Actual_Virtual_Call_Market_Cycle__c,Total_Virtual_Calls__c FROM Account WHERE ID IN : accountSetId]);
        Map<Id, Market_Cycle__c> callIdToMarketCycleMap = fetchMarketCycle(mapNewCalls, accIdToAccMap);
        //EDGE_UtilityClass.printGovLimits(749);
        // Creating map of Call And associated Accounts  .
        if(mapNewCalls != null  && callTypeMap != null){
            for(Id callRecId : mapNewCalls.keyset()){
                
                Call__c oldCallRec;
                if(mapOldCalls != null){
                    oldCallRec = mapOldCalls.get(callRecId);
                }
                
                Call__c newCallRec = mapNewCalls.get(callRecId);
                if(newCallRec != null && newCallRec.Status__c == 'Completed' && newCallRec.Call_duration_compliance__c 
                   && (newCallRec.End_Date__c != null ) && newCallRec.Type_of_Call__c != null && callTypeMap.get(newCallRec.Type_of_Call__c) != null 
                   && ((oldCallRec == null)||(oldCallRec != null && ((newCallRec.Status__c != oldCallRec.Status__c) 
                                                                     || (newCallRec.Call_duration_compliance__c != oldCallRec.Call_duration_compliance__c)))))
                {
                    
                    Account acc = accIdToAccMap.get(newCallRec.Account__c);
                    if(Test.isRunningTest()){
                        acc = [Select Id,Total_Virtual_Calls__c,Actual_Virtual_Call_Market_Cycle__c,Actual_Physical_Call_Market_Cycle__c from Account LIMIT 1];
                    }
                    
                    Market_Cycle__c mCycle = callIdToMarketCycleMap.get(newCallRec.Id);
                    String globalEqCallType = callTypeMap.get(newCallRec.Type_of_Call__c).Global_Equivalent_Call_Type__c;
                    if(globalEqCallType == 'Virtual'){//ES20-13409 changed the monthly calculation of total virtual calls to market cycle 
                        if(mCycle != null && newCallRec.End_Date__c.date()>=mCycle.Start_Date__c && newCallRec.End_Date__c.date()<=mCycle.End_Date__c){
                            if (acc.Total_Virtual_Calls__c == 0 || acc.Total_Virtual_Calls__c == null){
                                acc.Total_Virtual_Calls__c = 1;                
                            }else {
                                acc.Total_Virtual_Calls__c += 1 ;                
                            }  
                        }
                        if(mCycle != null && newCallRec.End_Date__c.date()>=mCycle.Start_Date__c && newCallRec.End_Date__c.date()<=mCycle.End_Date__c){
                            if (acc.Actual_Virtual_Call_Market_Cycle__c == 0 || acc.Actual_Virtual_Call_Market_Cycle__c == null){
                                acc.Actual_Virtual_Call_Market_Cycle__c = 1;                
                            }else {
                                acc.Actual_Virtual_Call_Market_Cycle__c += 1;               
                            }  
                        }
                        updateAccMap.put(acc.Id, acc);
                    }else if(globalEqCallType == 'Physical'){
                        if(mCycle != null && newCallRec.End_Date__c.date()>=mCycle.Start_Date__c && newCallRec.End_Date__c.date()<=mCycle.End_Date__c){
                            if (acc.Actual_Physical_Call_Market_Cycle__c == 0 || acc.Actual_Physical_Call_Market_Cycle__c == null){
                                acc.Actual_Physical_Call_Market_Cycle__c = 1;                
                            }else {
                                acc.Actual_Physical_Call_Market_Cycle__c += 1;                
                            }
                        }    
                        updateAccMap.put(acc.Id, acc);
                        
                    }
                }
            }
        }
        if(updateAccMap != null && !updateAccMap.isEmpty()){
            for(Id accId : updateAccMap.keySet()){
                if(accountGlobalMap.containsKey(accId)){
                    Account globalAcc = accountGlobalMap.get(accId);
                    //Account globalAcc = new Account(Id = accId);
                    Account accRec = updateAccMap.get(accId);
                    globalAcc.Total_Virtual_Calls__c = accRec.Total_Virtual_Calls__c;
                    globalAcc.Actual_Virtual_Call_Market_Cycle__c = accRec.Actual_Virtual_Call_Market_Cycle__c;
                    globalAcc.Actual_Physical_Call_Market_Cycle__c = accRec.Actual_Physical_Call_Market_Cycle__c;
                    accountGlobalMap.put(accId,globalAcc);
                }
                else{
                    accountGlobalMap.put(accId,updateAccMap.get(accId));
                    
                }
            }
        }
        if( accountGlobalMap != null && !accountGlobalMap.isEmpty() && Schema.sObjectType.Account.isUpdateable()){
            update accountGlobalMap.values();   
        }
    }
    /**
* @ Method : updateCallDurationCompliance
* @ Description : Update call duration compliance field in call object if conditions are met
**/    
    public static void updateCallDurationCompliance(List<SObject> newItems,Map<Id, SObject> oldItems){
        List<Call__c> newCallList = (List<Call__c>)newItems;
        Set<Id> callTypeIdSet = new Set<Id>();
        Map<Id,Call_Type__c> callTypeMap  = new Map<Id,Call_Type__c>();
        if(newCallList!=null && newCallList.size()>0){
            for(Call__c callRec : newCallList)
            {
                if(callRec.Type_of_Call__c != null){
                    callTypeIdSet.add(callRec.Type_of_Call__c);
                }
            }
        }
        if(callTypeIdSet != null && callTypeIdSet.Size() > 0){
            for( Call_Type__c callTypeRec : [SELECT Id,Min_call_duration__c FROM Call_Type__c WHERE Id =:callTypeIdSet]){
                callTypeMap.put(callTypeRec.Id,callTypeRec);
            }
        }
        if(newCallList!=null && newCallList.size()>0){
            for(Call__c callRec : newCallList)
            {   if(callRec.Type_of_Call__c != null){
                    Call_Type__c callTypeObj = callTypeMap.get(callRec.Type_of_Call__c);
                	Long callLength = getTimeDifference(callRec.Start_Date__c,callRec.End_Date__c);
                    //if(callRec.Status__c == 'Completed' && (callTypeObj.Min_call_duration__c == null || callRec.Call_Lenth__c.round() >= callTypeObj.Min_call_duration__c )){
                    if(callRec.Status__c == 'Completed' && (callTypeObj.Min_call_duration__c == null || callLength >= callTypeObj.Min_call_duration__c )){
                        callRec.Call_duration_compliance__c = TRUE;
                    }
                }
            }
        }
    }
    
    public static Long getTimeDifference(DateTime startDateTime, DateTime endDateTime){
        Long dt1Long = startDateTime == null ? 0 : startDateTime.getTime();
        Long dt2Long = endDateTime == null ? 0 : endDateTime.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        //Long hours = minutes / 60;
        //Long days = hours / 24;
        return minutes;
    }
}