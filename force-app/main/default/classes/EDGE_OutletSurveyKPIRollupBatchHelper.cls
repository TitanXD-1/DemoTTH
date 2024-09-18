/**

* @Description: EDGE_OutletSurveyKPIRollupBatchHelper

* @Purpose : ES20-4026 - Helper class for EDGE_OutletSurveyKPIRollupBatch 

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*   1.1        Sandip Ghosh        	20/01/2020      [ES20-4595] Helper class for EDGE_OutletSurveyKPIRollupBatch
*	1.2        Sandip Ghosh        	01/04/2020      [ES20-6613] Logic incorporation for Activation Survey KPI
*	1.3		   Sandip Ghosh			10/04/2020		[ES20-7826] SFDC_US 13- Calculation of Total Activation KPI
*	1.4		   Sandip Ghosh			22/05/2020		[ES20-7920] Enhancing  Calculation of Total Activation KPI_SFDC_US 17
*   1.5		   Monalisa Halder		11/12/2020		[ES20-8858] Enhancing  Calculation of Total Activation KPI to exclude Activation Specialist pickup option records
*	1.6		   Aparajita            26/10/2021		[ES20-11188] Logic to include the Survey KPI/ activation KPI for Quality roles at Quality territory level. 
*   1.7        Anand Uppalapati     11/11/2021      [ES20-11470] Logic to solve Actual Numerator value  getting multiplied by 2 issue.
*	1.8		   Rajarshi Lahiri		22/03/2022		[ES20-12217] Logic to include Activation Specialist roles at Activation Territory level
*	1.9		   Rajarshi Lahiri		24/06/2022		[ES20-13029] Added empty checks to prevent execution of methods unnecessarily
*	2.0		   Rajarshi Lahiri		03/08/2022		[ES20-13190]
*/

public with sharing class EDGE_OutletSurveyKPIRollupBatchHelper {
    
    //Global Variable
    public static Set<Id> surveyIdSet = new Set<Id>();
    public static Map<String, Id> existingKPIAchivementMap = new Map<String, Id>();
    public static Id surveyKPIRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey KPI').getRecordTypeId();
    public static Id terrKPIRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
    public static Id salesTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId(); //ES20-11188
    public static Id qualityTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId(); //ES20-11188
    public static Id actTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
    //Method to populate survey kpi which is called from batch
    public static void populateSurveyKPI(Map<Id, Territory__c> territoryMap, Market_Cycle__c marketCycle){ /*, String countryCode*/
        
        //Assignment
        Map<Id, List<Outlet_Survey_Response__c>> outletActKPIResponseMap = new Map<Id, List<Outlet_Survey_Response__c>>();
        Map<Id, Boolean> surveyKPICheckedMap = new Map<Id, Boolean>(); //ES20-7826 : Added the below map to hold the 'Include in Total Activation Survey KPI' field value for Survey KPI pickupoption records
        Map<Id, Boolean> actSpKPIPickUpOptMap = new Map<Id, Boolean>(); //ES20-8858 : map of pickup option id and pickup option's applicable business role is not equal to Activation Specialist, value will be true
        Map<Id, Boolean> onlyActSpKPIPickUpOptMap=new Map<Id, Boolean>();
        Map<Id, List<Account>> territoryOutletMap = new Map<Id, List<Account>>();
        Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMap = new Map<Id, List<Outlet_Survey_Response__c>>();
        Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMapQuality = new Map<Id, List<Outlet_Survey_Response__c>>();
        Map<Id, String> surveyAnswerMap = new Map<Id, String>();
        Map<String, KPI_Achivement__c> kpiAchievementMap = new Map<String, KPI_Achivement__c>();
        Map<String, KPI_Achivement__c> kpiAchievementMapQuality = new Map<String, KPI_Achivement__c>();
        Map<Id,Territory__c> salesTerrMap = new Map<Id,Territory__c>(); //ES20-11188
        Map<Id,Territory__c> qualityTerrMap = new Map<Id,Territory__c>(); //ES20-11188
        Map<Id, List<Account>> territoryOutletMapQuality = new Map<Id, List<Account>>();//ES20-11188
        Set<Id> actSurveyResponseIds = new Set<Id> (); //ES20-11470
        //ES20-12217
        Map<Id,Territory__c> actTerrMap = new Map<Id,Territory__c>();
        Map<Id, List<Account>> territoryOutletMapAct = new Map<Id, List<Account>>();
        Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMapACT = new Map<Id, List<Outlet_Survey_Response__c>>();
        Map<String, KPI_Achivement__c> kpiAchievementMapACT = new Map<String, KPI_Achivement__c>();
        
        
        //Creating two different maps for Sales and Quality Territories
        if(marketCycle != null && !territoryMap.isEmpty()){
            for(Id terrId : territoryMap.keySet()){
                if(territoryMap.get(terrId).RecordTypeID == salesTerrRecordTypeId && !salesTerrMap.keySet().contains(terrId)){
                    salesTerrMap.put(terrId,territoryMap.get(terrId));                    
                }
                if(territoryMap.get(terrId).RecordTypeID == qualityTerrRecordTypeId && !qualityTerrMap.keySet().contains(terrId)){
                    qualityTerrMap.put(terrId,territoryMap.get(terrId));                    
                }             
                if(territoryMap.get(terrId).RecordTypeID == actTerrRecordTypeId && !actTerrMap.keySet().contains(terrId)){ //ES20-12217 Added AT records to Map
                    actTerrMap.put(terrId,territoryMap.get(terrId));                    
                }  
            }
            
            //Get Territory's corresponding Outlets - Sales
            if(!salesTerrMap.isEmpty() && salesTerrMap.values().size()>0){
            	territoryOutletMap = getTerritoryOutlets(salesTerrMap.values(),null,null); //ES20-11188 : Added parameter for Quality Territories
            }
            //Get Territory's corresponding Outlets - Quality
            if(!qualityTerrMap.isEmpty() && qualityTerrMap.values().size()>0){
            	territoryOutletMapQuality = getTerritoryOutlets(null,qualityTerrMap.values(),null); //ES20-11188 : Added parameter for Quality Territories
            }
            //Get Territory's corresponding Outlets - ACT
            if(!actTerrMap.isEmpty() && actTerrMap.values().size()>0){
            	territoryOutletMapAct=getTerritoryOutlets(null,null,actTerrMap.values());// ES20-12217 : Added parameter for Activation Territories
            }
            //Get Existing KPI Achievement Records
            //ES20-12217 : Added parameter for Activation Territories
            getKPIAchievements(salesTerrMap.values(),qualityTerrMap.values(),actTerrMap.values()); //ES20-11188 : Added parameter for Quality Territories
            
            //Get Outlet Survey Response
            
            //ES20-7826 - added extra parameter surveyKPICheckedMap
            //ES20-8858 -- added parameter actSpKPIPickUpOptMap
            //ES20-11188 : Added parameter for Quality Territories
            
            
            
            //Added empty checks as part of ES20-13029
            if(!salesTerrMap.isEmpty() && salesTerrMap.values().size()>0){
            	outletSurveyResponseMap = getOutletSurveyResponse(marketCycle, outletActKPIResponseMap, surveyKPICheckedMap,actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap, salesTerrMap.keySet(), null , null,null, actSurveyResponseIds );
            }
            if(!qualityTerrMap.isEmpty() && qualityTerrMap.values().size()>0){
                outletSurveyResponseMapQuality = getOutletSurveyResponse(marketCycle, outletActKPIResponseMap, surveyKPICheckedMap,actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap, null, qualityTerrMap.keySet(), null,null, actSurveyResponseIds);
            }
            //ES20-12217 : Added parameter for Activation Territories
            if(!actTerrMap.isEmpty() && actTerrMap.values().size()>0){
            	outletSurveyResponseMapACT=getOutletSurveyResponse(marketCycle, outletActKPIResponseMap, surveyKPICheckedMap,actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap, null, null,actTerrMap.keySet(), null, actSurveyResponseIds);
            }
			//ES20-13190
            //Get Survey Response
            surveyAnswerMap = getSurveyQuestionAnswer(surveyIdSet);
			if(!outletSurveyResponseMap.isEmpty() && outletSurveyResponseMap.values().size()>0){
                //Create KPI Achievement Records - Sales
                kpiAchievementMap = calculateSurveyKPI(territoryOutletMap, outletSurveyResponseMap, surveyAnswerMap, territoryMap, outletActKPIResponseMap, surveyKPICheckedMap, actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap); //ES20-8858 -- added parameter actSpKPIPickUpOptMap
            }
            if(!outletSurveyResponseMapQuality.isEmpty() && outletSurveyResponseMapQuality.values().size()>0){
                //Create KPI Achievement Records - Quality
                kpiAchievementMapQuality = calculateSurveyKPI(territoryOutletMapQuality, outletSurveyResponseMapQuality, surveyAnswerMap, territoryMap, outletActKPIResponseMap, surveyKPICheckedMap, actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap);
            }
            //ES20-12217 : Added parameter for Activation Territories
            if(!outletSurveyResponseMapACT.isEmpty() && outletSurveyResponseMapACT.values().size()>0){
                //Create KPI Achievement Records - ACT
                kpiAchievementMapACT = calculateSurveyKPI(territoryOutletMapAct, outletSurveyResponseMapACT, surveyAnswerMap, territoryMap, outletActKPIResponseMap, surveyKPICheckedMap, actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap);
            }
            
            try{ 
                //Create KPI Achievement Records - Sales
                //kpiAchievementMap = calculateSurveyKPI(territoryOutletMap, outletSurveyResponseMap, surveyAnswerMap, territoryMap, outletActKPIResponseMap, surveyKPICheckedMap, actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap); //ES20-8858 -- added parameter actSpKPIPickUpOptMap
                
                //Upsert KPI Achievement Records
                if(!kpiAchievementMap.isEmpty() && kpiAchievementMap.values().size()>0){
                    Database.upsert(kpiAchievementMap.values(),false);
                }
                //Create KPI Achievement Records - Quality
                //kpiAchievementMapQuality = calculateSurveyKPI(territoryOutletMapQuality, outletSurveyResponseMapQuality, surveyAnswerMap, territoryMap, outletActKPIResponseMap, surveyKPICheckedMap, actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap);
                
                //Upsert KPI Achievement Records
                if(!kpiAchievementMapQuality.isEmpty() && kpiAchievementMapQuality.values().size()>0){
                    Database.upsert(kpiAchievementMapQuality.values(),false);
                } 
                
                //ES20-12217 : Calculating KPIs for Activation Territories
                //Create KPI Achievement Records - ACT
                //kpiAchievementMapACT = calculateSurveyKPI(territoryOutletMapAct, outletSurveyResponseMapACT, surveyAnswerMap, territoryMap, outletActKPIResponseMap, surveyKPICheckedMap, actSpKPIPickUpOptMap,onlyActSpKPIPickUpOptMap);
                
                //Upsert KPI Achievement Records
                if(!kpiAchievementMapACT.isEmpty() && kpiAchievementMapACT.values().size()>0){
                    Database.upsert(kpiAchievementMapACT.values(),false);
                } 
                 
                
             
            }catch(Exception ex){
                System.debug('ex.getCause() : ' + ex.getCause()); 
                System.debug('ex : ' + ex); 
                System.debug('stack trace :'+ ex.getStackTraceString());
            }
            
        }
    }
    
    //Method to get Outlets
    public static Map<Id, List<Account>> getTerritoryOutlets(List<Territory__c> salesTerritoryList, List<Territory__c> qualityTerritoryList, List<Territory__c> actTerritoryList){ //ES20-11188 : Added parameter for Quality Territories
        //Assignment
        Map<Id, List<Account>> territoryOutletMap = new Map<Id, List<Account>>();
        Map<Id,Account> accMap = new Map<Id,Account>();
        
        //Fetching outlets from Sales Territory
        if(salesTerritoryList!=null && salesTerritoryList.size()>0){
            for(Account acc : [SELECT Id, Primary_Sales_Territory__c FROM Account WHERE Primary_Sales_Territory__c IN :salesTerritoryList AND Status__c = 'Active']){
                if(territoryOutletMap.containsKey(acc.Primary_Sales_Territory__c)){
                    territoryOutletMap.get(acc.Primary_Sales_Territory__c).add(acc);
                }else{
                    territoryOutletMap.put(acc.Primary_Sales_Territory__c, new List<Account>{acc});
                }
            }
        }
        
        //Fetching outlets from Quality Territory(ES20-11188)
        if(qualityTerritoryList!=null && qualityTerritoryList.size()>0){
            for(Outlet_Territory__c outletTerr : [SELECT Id, Territory__c, Outlet__c from Outlet_Territory__c 
                                                  WHERE Territory__c IN : qualityTerritoryList //OR salesTerritoryList
                                                  AND Outlet__r.Status__c = :EDGE_Constant.ACTIVE
                                                  AND Active__c = :EDGE_Constant.ACTIVE])
            {
                Account acc = new Account(Id=outletTerr.Outlet__c);
                if(territoryOutletMap.containsKey(outletTerr.Territory__c)){
                    territoryOutletMap.get(outletTerr.Territory__c).add(acc);
                }else{
                    territoryOutletMap.put(outletTerr.Territory__c, new List<Account>{acc});
                }
            }
        }   
         //Fetching outlets from Activation Territory(ES20-12217)
        if(actTerritoryList!=null && actTerritoryList.size()>0){
            for(Account acc : [SELECT Id, Activation_Territory_LT__c FROM Account WHERE Activation_Territory_LT__c IN :actTerritoryList AND Status__c = 'Active']){
                if(territoryOutletMap.containsKey(acc.Activation_Territory_LT__c)){
                    territoryOutletMap.get(acc.Activation_Territory_LT__c).add(acc);
                }else{
                    territoryOutletMap.put(acc.Activation_Territory_LT__c, new List<Account>{acc});
                }
            }
        }
        
        return territoryOutletMap;
    }
    
    //Method to get KPI Achievement Records of Survey KPI
    public static void getKPIAchievements(List<Territory__c> salesTerritoryList, List<Territory__c> qualityTerritoryList, List<Territory__c> actTerritoryList){ //ES20-11188 : Added parameter for Quality territories
        //ES20-6613: Added crietria to include KPI achievement with KPI types applicable for Activation type. Changed the key formation logic as applicable.
        //ES20-11188 : Added condition for Quality territories
        //ES20-12217 : Added condition for Activation territories
        for(KPI_Achivement__c kpiAchive : [SELECT Id, Territory__c, KPI_Type__c, Survey_KPI__c, Activation_Type__c, RecordTypeId FROM KPI_Achivement__c WHERE (Territory__c IN :salesTerritoryList OR Territory__c IN :qualityTerritoryList OR Territory__c IN :actTerritoryList)
                                           AND (recordTypeId = :surveyKPIRecordTypeId OR (recordTypeId = :terrKPIRecordTypeId AND (KPI_Type__c = 'Activation Survey KPI' OR KPI_Type__c = 'Total Activation Survey' )))])
        {
            String key = '';
            //String key = (kpiAchive.RecordTypeId == surveyKPIRecordTypeId ) ? (kpiAchive.Territory__c + '_' + kpiAchive.Survey_KPI__c) : (kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c + '_' + (kpiAchive.Activation_Type__c != null ? kpiAchive.Activation_Type__c : '')); //EDGE_UtilityClass.checkForNullId(kpiAchive.Activation_Type__c));
            if(kpiAchive.RecordTypeId == surveyKPIRecordTypeId ){
                key = kpiAchive.Territory__c + '_' + kpiAchive.Survey_KPI__c;
            }else{
                if(kpiAchive.Activation_Type__c != null){
                    key = kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c + '_' + kpiAchive.Activation_Type__c;
                }else{
                    key = kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c + '_';
                }
            }
            existingKPIAchivementMap.put(key, kpiAchive.Id);
        }
    }
    
    //Method to get Survey KPI Question Answer
    public static Map<Id, String> getSurveyQuestionAnswer(Set<Id> surveyIdSet){
        Map<Id, String> surveyAnswerMap = new Map<Id, String>();
        if(!surveyIdSet.isEmpty()){
            for(Survey_Answer__c surveyAnswer : [SELECT Id, Survey_Question__c, Option_Value__c FROM Survey_Answer__c WHERE Bonus_Applicable_Response__c = TRUE
                                                 AND Survey_Question__r.Survey__c IN :surveyIdSet])
            {
                surveyAnswerMap.put(surveyAnswer.Survey_Question__c, surveyAnswer.Option_Value__c);
            }
        }
        return surveyAnswerMap;
    }
    
    //Method to get Outlet Survey Response
    public static Map<Id, List<Outlet_Survey_Response__c>> getOutletSurveyResponse(Market_Cycle__c marketCycle, Map<Id, List<Outlet_Survey_Response__c>> outletActKPIResponseMap, Map<Id, Boolean> surveyKPICheckedMap,Map<Id, Boolean> actSpKPIPickUpOptMap,Map<Id, Boolean> onlyActSpKPIPickUpOptMap, Set<Id> salesTerrIds, Set<Id> qualityTerrIds,Set<Id> actTerrIds, Set<Id> operatordIds, Set<Id> actSurveyResponseIds){
        Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMap = new Map<Id, List<Outlet_Survey_Response__c>>();      
        Set<string> outletSurveyKPISet = new Set<string>();
        
        //ES20-7920: Enhancing  Calculation of Total Activation KPI_SFDC_US 17
        Date startDate = marketCycle.Start_Date__c;
        Date endDate = marketCycle.End_Date__c;
        
        List<Outlet_Territory__c> qualityOutletTerr = new List<Outlet_Territory__c>();
        Set<Id> qualityOutletIds = new Set<Id>();
        
        //Set<Id> actSurveyResponseIds = new Set<Id> ();
        
        //8858 - Added the field 'Applicable_Business_Role__c' in the query
        String sqlQuery = 'SELECT Id, Outlet_Survey__c, Response__c, Survey_Question__c, Survey_Question__r.Survey_KPI__c, Outlet_Survey__r.Outlet__c,'+ 
            +' Outlet_Survey__r.Survey__c, Outlet_Survey__r.Completion_Date__c, Survey_Question__r.Activation_Type__c, Survey_Question__r.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c,'+
            +' Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c, Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c FROM Outlet_Survey_Response__c'+ 
            +' WHERE (Survey_Question__r.Survey_KPI__c != NULL OR Survey_Question__r.Activation_Type__c != NULL) AND Outlet_Survey__r.Achievement_status__c = \'Complete\'';
        
        if(operatordIds!=null && operatordIds.size()>0){//operator not null
            sqlQuery += ' AND Outlet_Survey__r.Outlet__r.Operator__c IN :operatordIds';
        }
        else if(salesTerrIds!=null && salesTerrIds.size()>0){ 
            sqlQuery += ' AND Outlet_Survey__r.Outlet__r.Primary_Sales_Territory__c IN :salesTerrIds';
        }        
        //ES20-12217: Added condition for Activation territories
        else if(actTerrIds!=null && actTerrIds.size()>0){
            sqlQuery += ' AND Outlet_Survey__r.Outlet__r.Activation_Territory_LT__c IN :actTerrIds';
        }        
        //ES20-11188 : Adding condition for Quality territories
        else if(qualityTerrIds!=null && qualityTerrIds.size()>0){
            qualityOutletTerr = [SELECT Outlet__c from Outlet_Territory__c WHERE Territory__c IN : qualityTerrIds
                                 AND Outlet__r.Status__c = :EDGE_Constant.ACTIVE
                                 AND Active__c = :EDGE_Constant.ACTIVE];
            for(Outlet_Territory__c outletTerr : qualityOutletTerr){
                qualityOutletIds.add(outletTerr.Outlet__c);
            }
            sqlQuery += 'AND Outlet_Survey__r.Outlet__c IN :qualityOutletIds ';
        }
        sqlQuery += ' AND Outlet_Survey__r.Completion_Date__c >= :startDate AND Outlet_Survey__r.Completion_Date__c <= :endDate'+
            +' ORDER BY Outlet_Survey__r.Completion_Date__c DESC, Outlet_Survey__r.Outlet__c, Survey_Question__r.Survey_KPI__c, Survey_Question__r.Activation_Type__c';     
        
        //System.debug('Sqlquery'+Database.query(sqlQuery));
        //ES20-6613: Added criteria to include responses from questions of type Activation KPI,
        //ES20-7826 : Added the 'Include in Total Activation Survey KPI' field in the Query
        for(Outlet_Survey_Response__c surveyResponse : Database.query(sqlQuery))//Check the query response how the grouping is done
        {
            Id outletId = surveyResponse.Outlet_Survey__r.Outlet__c;
            Id questionId = surveyResponse.Survey_Question__c;
            Id surveyKPIId = surveyResponse.Survey_Question__r.Survey_KPI__c;
            Id activationKPIId = surveyResponse.Survey_Question__r.Activation_Type__c;
            Id surveyId = surveyResponse.Outlet_Survey__r.Survey__c;
            String key = outletId + '_' + surveyKPIId;
            String kpiActivationKey = outletId + '_'+ surveyId +'_' + activationKPIId; //ES20-6613: Key for Activation KPI; Survey should be added as a key
            //ES20-7826
            Boolean isSurveyKPIChecked = surveyResponse.Survey_Question__r.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c;
            //If survey kpi latest response is already added in response list dont add it again because we only need to consider latest response in combination of Outlet-Survey KPI 
            if(surveyKPIId != null && !outletSurveyKPISet.contains(key)){
                if(surveyResponse.Outlet_Survey__r.Survey__c != null){
                    surveyIdSet.add(surveyResponse.Outlet_Survey__r.Survey__c);
                }
                if(outletSurveyResponseMap.containsKey(outletId)){
                    outletSurveyResponseMap.get(outletId).add(surveyResponse);
                }else{
                    outletSurveyResponseMap.put(outletId, new List<Outlet_Survey_Response__c>{surveyResponse});
                }
                outletSurveyKPISet.add(key);
                
                //ES20-7826
                if(!surveyKPICheckedMap.containsKey(surveyKPIId)){
                    surveyKPICheckedMap.put(surveyKPIId, isSurveyKPIChecked);
                }
                
                // ES20-8858 - putting in the Map pickup option id and pickup option's applicable business role is not equal to Activation Specialist, value will be true
                // ES20-11188 - Added condition for Quality Territories
                if((salesTerrIds!=null && salesTerrIds.size()>0) ||(qualityTerrIds!=null && qualityTerrIds.size()>0)){
                    if(actSpKPIPickUpOptMap!=null && !actSpKPIPickUpOptMap.containsKey(surveyKPIId) && surveyResponse.Survey_Question__r.Survey_KPI__c != null //Added null-check for ES20-11893
                       &&(surveyResponse.Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c == null 
                          || surveyResponse.Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c != 'Activation Specialist')){
                              actSpKPIPickUpOptMap.put(surveyKPIId, true);
                          }
                    if(actSpKPIPickUpOptMap!=null && !actSpKPIPickUpOptMap.containsKey(activationKPIId) && surveyResponse.Survey_Question__r.Activation_Type__c != null //Added null-check for ES20-11893
                       && (surveyResponse.Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c == null
                           || surveyResponse.Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c != 'Activation Specialist')){
                               actSpKPIPickUpOptMap.put(activationKPIId, true);  
                           }
                }
                
                //ES20-12217 : Added condition for Activation Territory(to include the Pick up option (Survey KPI/ activation KPI) and it will only include Activation Specialist roles at Activation Territory level)
                else if(actTerrIds!=null && actTerrIds.size()>0){
                    if(onlyActSpKPIPickUpOptMap!=null && !onlyActSpKPIPickUpOptMap.containsKey(surveyKPIId) && surveyResponse.Survey_Question__r.Survey_KPI__c != null //Added null-check for ES20-11893
                       &&(surveyResponse.Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c == 'Activation Specialist')){
                              onlyActSpKPIPickUpOptMap.put(surveyKPIId, true);
                          }
                    if(onlyActSpKPIPickUpOptMap!=null && !onlyActSpKPIPickUpOptMap.containsKey(activationKPIId) && surveyResponse.Survey_Question__r.Activation_Type__c != null //Added null-check for ES20-11893
                       && (surveyResponse.Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c == 'Activation Specialist')){
                               onlyActSpKPIPickUpOptMap.put(activationKPIId, true);  
                           }
                	}
                
                    
            }
            
   
            //ES20-6613: Added new map - outletActKPIResponseMap for Activation KPI, passed outletActKPIResponseMap as parameter
            //ES20-7920: Enhancing  Calculation of Total Activation KPI_SFDC_US 17 - Commented the check for outletActivationSurveyKPISet
 			if(surveyId != null && activationKPIId != null /*&& !outletActivationSurveyKPISet.contains(kpiActivationKey)*/){
                if(surveyId != null){
                    surveyIdSet.add(surveyId);
                }
               // if(actSurveyResponseIds!=null && actSurveyResponseIds.size()>0){ //Added null-check for ES20-11893
                    if(outletActKPIResponseMap.containsKey(outletId)){
                        if(actSurveyResponseIds != null && !actSurveyResponseIds.contains(surveyResponse.Id)){//ES20-11470
                       		 outletActKPIResponseMap.get(outletId).add(surveyResponse);
                             actSurveyResponseIds.add(surveyResponse.Id);
                        }
                         else if(actSurveyResponseIds == null){
                            actSurveyResponseIds = new Set<Id> ();
                            actSurveyResponseIds.add(surveyResponse.Id);
                        }
                    }else{
                        if(actSurveyResponseIds != null && !actSurveyResponseIds.contains(surveyResponse.Id)){//ES20-11470
                        	outletActKPIResponseMap.put(outletId, new List<Outlet_Survey_Response__c>{surveyResponse});
                            actSurveyResponseIds.add(surveyResponse.Id);
                    	}
                        else if(actSurveyResponseIds == null){
                            actSurveyResponseIds = new Set<Id> ();
                            actSurveyResponseIds.add(surveyResponse.Id);
                            outletActKPIResponseMap.put(outletId, new List<Outlet_Survey_Response__c>{surveyResponse});
                        }
                       
                    }
               // }
                
                //ES20-7920: Enhancing  Calculation of Total Activation KPI_SFDC_US 17
                //outletActivationSurveyKPISet.add(kpiActivationKey);
            }
        }
        return outletSurveyResponseMap;
    }
    
    //Method to calculate SURVEY KPI
    public static Map<String, KPI_Achivement__c> calculateSurveyKPI(Map<Id, List<Account>> territoryOutletMap, Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMap, Map<Id, String> surveyAnswerMap, Map<Id, Territory__c> territoryMap, Map<Id, List<Outlet_Survey_Response__c>> outletActKPIResponseMap, Map<Id, Boolean> surveyKPICheckedMap, Map<Id, Boolean> actSpKPIPickUpOptMap,Map<Id, Boolean> onlyActSpKPIPickUpOptMap){
        Map<String, KPI_Achivement__c> kpiAchievementMap = new Map<String, KPI_Achivement__c>();
        
        //ES20-6613: Added check for outletActKPIResponseMap in the if condition
        if(!territoryOutletMap.isEmpty() && (!outletSurveyResponseMap.isEmpty() || !outletActKPIResponseMap.isEmpty())){
            for(Id terrId : territoryOutletMap.keySet()){
                Integer numberOfOutlets = territoryOutletMap.get(terrId).size();
                for(Account acc : territoryOutletMap.get(terrId)){
                    //Block for calculating achievement for Survey KPI type
                    if(outletSurveyResponseMap.containsKey(acc.Id)){
                        for(Outlet_Survey_Response__c outletResponse : outletSurveyResponseMap.get(acc.Id)){                            
                            Id surveyKPIId = outletResponse.Survey_Question__r.Survey_KPI__c;
                            Id activationKPIId = outletResponse.Survey_Question__r.Activation_Type__c;
                            String key = terrId + '_' + outletResponse.Survey_Question__r.Survey_KPI__c;
                            String activationKPIKey = terrId + '_' + outletResponse.Survey_Question__r.Activation_Type__c;
                            KPI_Achivement__c kpiAchievement;
                            Double outletResp = validateResponse(surveyAnswerMap, outletResponse) ? 1 : 0;
                            if(kpiAchievementMap.containsKey(key)){
                                kpiAchievement = kpiAchievementMap.get(key);
                                kpiAchievement.Actual_Numerator__c = validateResponse(surveyAnswerMap, outletResponse) ? kpiAchievement.Actual_Numerator__c + 1 : kpiAchievement.Actual_Numerator__c;
                                kpiAchievement.Achievement__c = calculateAchievement(kpiAchievement);                     
                                kpiAchievementMap.put(key, kpiAchievement);                                
                            }else{
                                kpiAchievement = createKPIAchievement(terrId, surveyKPIId, numberOfOutlets, territoryMap.get(terrId),null,null);
                                kpiAchievement.Actual_Numerator__c = validateResponse(surveyAnswerMap, outletResponse) ? 1 : 0;
                                kpiAchievement.Achievement__c = calculateAchievement(kpiAchievement);
                                kpiAchievementMap.put(key, kpiAchievement);                                
                            }
                            
                            //ES20-7826 : Including Survey KPIs whose Include_in_Total_Activation_Survey_KPI__c field is checked in the Total Activation Survey Calculation
                            //ES20-8858 : Only including the pick up options where Applicable Business Role not equal to Activation Specialist  in the Total Activation Calcution at territory level
                            if(kpiAchievement != null && surveyKPICheckedMap != null && surveyKPICheckedMap.get(surveyKPIId) && actSpKPIPickUpOptMap != null && (territoryMap.get(terrId).RecordTypeID == salesTerrRecordTypeId || territoryMap.get(terrId).RecordTypeID == qualityTerrRecordTypeId)){
                                if((actSpKPIPickUpOptMap.containsKey(surveyKPIId) && actSpKPIPickUpOptMap.get(surveyKPIId)) || (actSpKPIPickUpOptMap.containsKey(activationKPIId) && actSpKPIPickUpOptMap.get(activationKPIId))){
                                    calcTotalAcvSrvyKPI(terrId, kpiAchievement, outletResp, kpiAchievementMap, numberOfOutlets, territoryMap); 
                                }
                                
                            }
                            

                           if(kpiAchievement != null && surveyKPICheckedMap != null && surveyKPICheckedMap.get(surveyKPIId) && onlyActSpKPIPickUpOptMap != null && territoryMap.get(terrId).RecordTypeID == actTerrRecordTypeId){

                                if((onlyActSpKPIPickUpOptMap.containsKey(surveyKPIId) && onlyActSpKPIPickUpOptMap.get(surveyKPIId)) || (onlyActSpKPIPickUpOptMap.containsKey(activationKPIId) && onlyActSpKPIPickUpOptMap.get(activationKPIId))){
                                    calcTotalAcvSrvyKPI(terrId, kpiAchievement, outletResp, kpiAchievementMap, numberOfOutlets, territoryMap); 
                                }
                                
                            }
                        }
                    }

                    //ES20-6613 : block for calculating Achievement for Activation KPI Type
                    if(outletActKPIResponseMap.containsKey(acc.Id)){
                        for(Outlet_Survey_Response__c outletResponse : outletActKPIResponseMap.get(acc.Id)){                            
                            Id actKPIId = outletResponse.Survey_Question__r.Activation_Type__c;
                            String activationKPIKey = terrId + '_' + actKPIId;
                            KPI_Achivement__c kpiAchievement;
                            Decimal outletResp = 0;
                            if(outletResponse.Response__c != null && isNumeric(outletResponse.Response__c)){
                                outletResp = Decimal.valueOf(outletResponse.Response__c);
                            }
                            //Decimal outletResp = outletResponse.Response__c != null ? Decimal.valueOf(outletResponse.Response__c) : 0;
                            
                            //ES20-6613 : The following section is responsible for calculating Achievement relevant to 'Activation Survey KPI' KPI Type
                            if(kpiAchievementMap.containsKey(activationKPIKey)){
                                kpiAchievement = kpiAchievementMap.get(activationKPIKey);
                                kpiAchievement.Actual_Numerator__c =  kpiAchievement.Actual_Numerator__c + outletResp;
                                kpiAchievementMap.put(activationKPIKey, kpiAchievement);                                
                            }else{
                                kpiAchievement = createKPIAchievement(terrId, null, numberOfOutlets, territoryMap.get(terrId), actKPIId, 'Activation Survey KPI');
                                kpiAchievement.Actual_Numerator__c = outletResp;                                
                                kpiAchievementMap.put(activationKPIKey, kpiAchievement);                                      
                            }
                            if(kpiAchievement != null){
                                kpiAchievement.Achievement__c = kpiAchievement.Actual_Numerator__c;
                            }
                            
                            // ES20-6613 & ES20-7826
                            // Added the if loop for ES20-8858 to exclude 'Activation Specialist' pick up option
                            // ES20-12217: Added condition to handle Activation Territory and include pickup option with Business role Activation Specialist
                            if(territoryMap.get(terrId).RecordTypeID == salesTerrRecordTypeId ||territoryMap.get(terrId).RecordTypeID == qualityTerrRecordTypeId ){
                            if((outletResponse.Survey_Question__r.Survey_KPI__c!= null && outletResponse.Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c != 'Activation Specialist') || 
                               (outletResponse.Survey_Question__r.Activation_Type__c!= null && outletResponse.Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c != 'Activation Specialist')){
                                   calcTotalAcvSrvyKPI(terrId, kpiAchievement, outletResp, kpiAchievementMap, numberOfOutlets, territoryMap);     
                               }                      
                        }
                            if(territoryMap.get(terrId).RecordTypeID == actTerrRecordTypeId){
                                if((outletResponse.Survey_Question__r.Survey_KPI__c!= null && outletResponse.Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c == 'Activation Specialist') || 
                                   (outletResponse.Survey_Question__r.Activation_Type__c!= null && outletResponse.Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c == 'Activation Specialist')){
                                       calcTotalAcvSrvyKPI(terrId, kpiAchievement, outletResp, kpiAchievementMap, numberOfOutlets, territoryMap);     
                                   }
                            }
                            
                            
                        }
                    }
                }
            }
        }
        return kpiAchievementMap;
    }
    
    //Method to calculate Total Activation Survey KPI, ES20-7826
    public static void calcTotalAcvSrvyKPI(Id terrId, KPI_Achivement__c kpiAchievement, Decimal outletResp, Map<String, KPI_Achivement__c> kpiAchievementMap, Integer numberOfOutlets, Map<Id, Territory__c> territoryMap){
        
        //outletResp = kpiAchievement.Actual_Numerator__c;
        //ES20-6613 : The following section is responsible for calculating Achievement relevant to 'Total Activation Survey' KPI Type
        if(kpiAchievement != null){
            KPI_Achivement__c kpiAchievementTotal;
            if(kpiAchievementMap.containsKey(terrId)){
                kpiAchievementTotal = kpiAchievementMap.get(terrId);
                kpiAchievementTotal.Actual_Numerator__c = kpiAchievementTotal.Actual_Numerator__c + outletResp;               
                kpiAchievementMap.put(terrId, kpiAchievementTotal);  
            }else{
                kpiAchievementTotal = createKPIAchievement(terrId, null, numberOfOutlets, territoryMap.get(terrId), null, 'Total Activation Survey');
                kpiAchievementTotal.Actual_Numerator__c = outletResp;
                kpiAchievementMap.put(terrId, kpiAchievementTotal); 
            }
            if(kpiAchievementTotal != null){
                kpiAchievementTotal.Achievement__c = kpiAchievementTotal.Actual_Numerator__c;
            }
            //System.debug('kpiAchievementTotal.Actual_Numerator__c'+kpiAchievementTotal.Actual_Numerator__c);
        }        
    }
    
    //Method to create KPI Achievement Instance
    public static KPI_Achivement__c createKPIAchievement(Id territoryId, Id surveyKPIId, Integer numberOfOutlets, Territory__c territory, Id actTypeKPIId, String activationType){//String actTypeKPIId
        
        KPI_Achivement__c kpiAchievement = new KPI_Achivement__c();       
        String key = '';
        
        if(surveyKPIId != null || !String.isBlank(activationType)){
            
            //Block for populating fields common to both Survey and Activation KPI
            kpiAchievement.Territory__c = territoryId;
            kpiAchievement.Country__c = territory.Country__c;
            kpiAchievement.Region__c = territory.Region__c;
            kpiAchievement.Total_Denominator__c = numberOfOutlets;
            
            //Block for populating fields relevant for Survey KPI
            if(surveyKPIId != null){
                key = territoryId + '_' + surveyKPIId;
                kpiAchievement.RecordTypeId = surveyKPIRecordTypeId;           
                kpiAchievement.KPI_Type__c = 'Survey';
                kpiAchievement.Survey_KPI__c = surveyKPIId;
            }
            //ES20-6613 : following section is used for populating Activation KPI related fields
            if(!String.isBlank(activationType)){
                
                kpiAchievement.RecordTypeId = terrKPIRecordTypeId;
                kpiAchievement.KPI_Type__c = activationType;
                if(actTypeKPIId != null){
                    kpiAchievement.Activation_Type__c = actTypeKPIId;
                }
                if(actTypeKPIId != null){
                    key = territoryId + '_' + kpiAchievement.KPI_Type__c + '_' + actTypeKPIId;
                }else{
                    key = territoryId + '_' + kpiAchievement.KPI_Type__c + '_' ;
                }
            }
            if(!existingKPIAchivementMap.isEmpty() && existingKPIAchivementMap.containsKey(key)){
                kpiAchievement.Id = existingKPIAchivementMap.get(key);
            } 
        }
        
        return kpiAchievement;
    } 
    
    //Method to check Response
    public static boolean validateResponse(Map<Id, String> surveyAnswerMap, Outlet_Survey_Response__c outletResponse){
        boolean isValidResponse = false;
        if(surveyAnswerMap != null && surveyAnswerMap.containsKey(outletResponse.Survey_Question__c) && surveyAnswerMap.get(outletResponse.Survey_Question__c) == outletResponse.Response__c){
            isValidResponse = true;
        }
        return isValidResponse;
    }
    
    //Method to calculate KPI Achievement Achievement
    public static double calculateAchievement(KPI_Achivement__c kpiAchievement){
        double achievement = 0.0;
        achievement = (kpiAchievement.Actual_Numerator__c/kpiAchievement.Total_Denominator__c)*100;
        
        return achievement;    
    }
    
    public static Boolean isNumeric(String s){
        Boolean ReturnValue;
        try{
            Decimal.valueOf(s);
            ReturnValue = TRUE; 
        } catch (Exception e) {
            ReturnValue = FALSE;
        }
        return ReturnValue;
    }
}