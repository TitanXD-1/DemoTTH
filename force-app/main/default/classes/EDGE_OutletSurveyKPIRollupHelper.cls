/**

* @Description: EDGE_OutletSurveyKPIRollupHelper

* @Purpose : ES20-13499 - Helper class for EDGE_OutletSurveyKPIRollupBatch 

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*	1.0		   Rajarshi/Mayukh		12/01/2023		[ES20-13499] Logic to calculate Outlet Survey KPI
*   2.0		   Rajarshi				28/02/2023		[ES20-13865]
*/

public with sharing class EDGE_OutletSurveyKPIRollupHelper {
    
    //Global Variable
    public static Set<Id> surveyIdSet = new Set<Id>();
    public static Id surveyKPIRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey KPI').getRecordTypeId();
    public static Id terrKPIRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
    public static Map<Id, String> surveyAnswerMap = new Map<Id, String>();
    public static Map<String,KPI_Achivement__c> kpiAchivMap = new Map<String,KPI_Achivement__c>();
    public static Set<Id> terrSet = new Set<Id>();
    public static Set<Id> surActKPISet = new Set<Id>();
    public static Map<String,EDGE_OutletSurveyRespWrapper> osrMap=new Map<String,EDGE_OutletSurveyRespWrapper>();
    
    //Main method to calculate and upsert KPI records
    public static List<String> populateSurveyKPI(Set<Id> outletSet,List<Outlet_Survey_Response__c> osrList,List<String> outSurKPIKey){
        Map<String,EDGE_OutletSurveyRespWrapper> osrWrapperMap=new Map<String,EDGE_OutletSurveyRespWrapper>();
        Map<String,KPI_Achivement__c> kpiAchivMaptoUpsert = new Map<String,KPI_Achivement__c>();
        
        //Set Outlet Survey Response Wrapper Map
        osrWrapperMap = getOSRWrapperMap(outletSet,osrList,outSurKPIKey);
        
        //Get SurveyAnswer Map
        surveyAnswerMap = EDGE_OutletSurveyKPIRollupExtendedHelper.getSurveyQuestionAnswer(surveyIdSet);
        
        //Get Existing KPIs already updated
        getExisitingKPIs();
        
        //Calculate the KPIs for the OSR records
        if(osrWrapperMap!=null){
            kpiAchivMaptoUpsert = getKPIs(osrWrapperMap);
        }
        
        //DML to upsert KPI Achievement Records
        if(kpiAchivMaptoUpsert!=null){
            Database.upsert(kpiAchivMaptoUpsert.values(),KPI_Achivement__c.Unique_Key__c,false);
        }
        return outSurKPIKey;
    }
    
    
    //To populate EDGE_OutletSurveyRespWrapper properties
    public static Map<String,EDGE_OutletSurveyRespWrapper> getOSRWrapperMap(Set<Id> outletIds, List<Outlet_Survey_Response__c> osrList,List<String> outSurKPIKey){
        //Get the map of OTs with Outlets
        Map<Id,List<Outlet_Territory__c>> outletTerritoryMap = EDGE_OutletSurveyKPIRollupExtendedHelper.getOutletTerritoryMap(outletIds);
        
        for(Outlet_Survey_Response__c osr:osrList){
            if(outletTerritoryMap.containsKey(osr.Outlet_Survey__r.Outlet__c)){
                setOSRWrapperMap(osr,outSurKPIKey,outletTerritoryMap);
            }
            //add the osr key for Survey KPI
            EDGE_OutletSurveyKPIRollupExtendedHelper.setLatestSurveyResponseKey(osr,outSurKPIKey);
        }
        return osrMap;
    }
    
    
    //Set OSR Wrapper Records based on Outlet Territory Records
    public static void setOSRWrapperMap(Outlet_Survey_Response__c osr,List<String> outSurKPIKey,Map<Id,List<Outlet_Territory__c>> outletTerritoryMap){
        for(Outlet_Territory__c outletTerr : outletTerritoryMap.get(osr.Outlet_Survey__r.Outlet__c)){
            if(osr.Outlet_Survey__r.Outlet__c==outletTerr.Outlet__c && EDGE_OutletSurveyKPIRollupExtendedHelper.isSurveyLatestResp(osr,outSurKPIKey)){
                EDGE_OutletSurveyRespWrapper osrWrap=new EDGE_OutletSurveyRespWrapper();
                osrWrap.outletid=osr.Outlet_Survey__r.Outlet__c;
                osrWrap.question=osr.Survey_Question__c;
                osrWrap.response=osr.Response__c;
                osrWrap.totalNoofOutlets=outletTerr.Territory__r.Total_Number_Of_Active_Outlets__c;
                osrWrap.surActkpi=EDGE_OutletSurveyKPIRollupExtendedHelper.setSurActkpi(osr);
                osrWrap.survey=osr.Outlet_Survey__r.Survey__c;
                Territory__c terr=new Territory__c(Id=outletTerr.Territory__c);
                terr.Country__c=outletTerr.Territory__r.Country__c;
                terr.Region__c=outletTerr.Territory__r.Region__c;
                terr.RecordTypeId=outletTerr.Territory__r.RecordTypeID;
                osrWrap.terr=terr;
                System.debug(LoggingLevel.DEBUG,'@@osrWrapKey'+osrWrap.surActkpi.Id+'_'+osrWrap.outletid);
                surActKPISet.add(osrWrap.surActkpi.Id);
                terrSet.add(outletTerr.Territory__c);
                if(osr.Outlet_Survey__r.Survey__c != null){
                    surveyIdSet.add(osr.Outlet_Survey__r.Survey__c);
                }
                osrMap.put(osr.Id+'_'+outletTerr.Territory__c,osrWrap);
            }
        }
    }
    
    
    
    //To fetch existing KPI records that will be used to update
    //Only picking up KPI Achiv records that have Pending Reset flag as true
    public static void getExisitingKPIs(){
        for(KPI_Achivement__c kpiAchive : [SELECT Id, Territory__c, Actual_Numerator__c,Total_Denominator__c,Achievement__c,KPI_Type__c, Survey_KPI__c, Activation_Type__c, RecordTypeId,Unique_Key__c,	Pending_Reset__c FROM KPI_Achivement__c WHERE Territory__c IN :terrSet
                                           AND (((KPI_Type__c = 'Survey' OR KPI_Type__c = 'Activation Survey KPI') AND (Survey_KPI__c IN:surActKPISet OR Activation_Type__c IN:surActKPISet)) OR KPI_Type__c = 'Total Activation Survey' ) AND 	Pending_Reset__c=TRUE])
        {
            kpiAchivMap.put(kpiAchive.Unique_Key__c,kpiAchive);
        }
    }
    
    //To calculate KPI values and return a Map with the key and KPI Record
    public static Map<String,KPI_Achivement__c> getKPIs(Map<String,EDGE_OutletSurveyRespWrapper> osrWrapperMap){
        for(String osrKey:osrWrapperMap.keySet()){
            EDGE_OutletSurveyRespWrapper osrWrap = osrWrapperMap.get(osrKey);
            String key = EDGE_OutletSurveyKPIRollupExtendedHelper.getUniqKPIKey(osrWrap);
            if(EDGE_OutletSurveyKPIRollupExtendedHelper.isValidActivationOsr(osrWrap) || EDGE_OutletSurveyKPIRollupExtendedHelper.isValidSalesQualityOsr(osrWrap)){
                Decimal numerator = getkpiValue(osrWrap).get('Numerator');
                Decimal denominator = getkpiValue(osrWrap).get('Denominator');
                System.debug(LoggingLevel.DEBUG,'osrKey - '+osrKey);
                System.debug(LoggingLevel.DEBUG,'KPI - '+osrWrap.surActkpi.Id);
                System.debug(LoggingLevel.DEBUG,'Numerator - '+numerator);
                if(kpiAchivMap.containsKey(key)){
                    kpiAchivMap.get(key).Actual_Numerator__c += numerator;
                    kpiAchivMap.get(key).Achievement__c = EDGE_OutletSurveyKPIRollupExtendedHelper.calculateAchievement(kpiAchivMap.get(key));
                }
                else{
                    KPI_Achivement__c kpi= new  KPI_Achivement__c();
                    kpi=createKPIAchievement(osrWrap);
                    kpi.Actual_Numerator__c = numerator;
                    kpi.Total_Denominator__c = denominator;
                    kpi.Achievement__c=EDGE_OutletSurveyKPIRollupExtendedHelper.calculateAchievement(kpi);
                    kpi.Pending_Reset__c=true;//Setting flag as true so that it is picked up later as exisitng KPI for calculation
                    kpiAchivMap.put(key,kpi);
                }
                
                KPI_Achivement__c totalkpi= new  KPI_Achivement__c();
                if(kpiAchivMap.containsKey(getTotalUniqKPIKey(osrWrap))){
                    totalkpi=kpiAchivMap.get(getTotalUniqKPIKey(osrWrap));
                    totalkpi.Actual_Numerator__c+=getTotalNumerator(osrWrap.surActkpi,numerator);
                    totalkpi.Achievement__c=EDGE_OutletSurveyKPIRollupExtendedHelper.calculateAchievement(totalkpi);                      
                }
                else{
                    totalkpi=EDGE_OutletSurveyKPIRollupExtendedHelper.createTotalKPIAchievement(osrWrap);
                    totalkpi.Actual_Numerator__c=getTotalNumerator(osrWrap.surActkpi,numerator);
                    totalkpi.Total_Denominator__c=denominator;
                    totalkpi.Achievement__c=EDGE_OutletSurveyKPIRollupExtendedHelper.calculateAchievement(totalkpi);
                    totalkpi.Pending_Reset__c=true;//Setting flag as true so that it is picked up later as exisitng KPI for calculation
                    kpiAchivMap.put(totalkpi.Unique_Key__c,totalkpi);
                }
            }
        }
        return kpiAchivMap;
    }
    
    
    //To get total Numerator for KPI where Include in Total Activation Survey is checked
    public static Decimal getTotalNumerator(Pick_Up_Options__c surActkpi,Decimal numerator){
        if((surActkpi.Type__c=='Survey KPI' && surActkpi.Include_in_Total_Activation_Survey_KPI__c) || (surActkpi.Type__c=='Activation Type')){
            return numerator;
        }
        else{
            return 0.0;
        }
        
    }
    
    
    //Method to generate Unique Key For KPI Achievement
    public static String getTotalUniqKPIKey(EDGE_OutletSurveyRespWrapper osrWrap){
        return osrWrap.terr.Id + '_' + 'Total Activation Survey';
    }    
    
    
    //Method to create KPI Achievement Instance
    public static KPI_Achivement__c createKPIAchievement(EDGE_OutletSurveyRespWrapper osrWrap){
        KPI_Achivement__c kpiAchievement = new KPI_Achivement__c();       
        String key = '';
        //Block for populating fields common to both Survey and Activation KPI and Total
        kpiAchievement.Territory__c = osrWrap.terr.Id;
        kpiAchievement.Country__c = osrWrap.terr.country__c;
        kpiAchievement.Region__c = osrWrap.terr.region__c;
        kpiAchievement.Total_Denominator__c = osrWrap.totalNoofOutlets;
        
        //Block for populating fields relevant for Survey KPI
        if(osrWrap.surActkpi != Null && osrWrap.surActkpi.Type__c == 'Survey KPI' ){
            kpiAchievement.RecordTypeId = surveyKPIRecordTypeId;           
            kpiAchievement.KPI_Type__c = 'Survey';
            kpiAchievement.Survey_KPI__c = osrWrap.surActkpi.Id;
            key = osrWrap.terr.Id + '_' + 'Survey' + '_' + osrWrap.surActkpi.Id;
            kpiAchievement.Unique_Key__c = key;
        }
        else if(osrWrap.surActkpi != Null && osrWrap.surActkpi.Type__c == 'Activation Type' ){
            kpiAchievement.RecordTypeId = terrKPIRecordTypeId;
            kpiAchievement.KPI_Type__c = 'Activation Survey KPI';
            kpiAchievement.Activation_Type__c = osrWrap.surActkpi.Id;
            key = osrWrap.terr.Id + '_' + 'Activation' + '_' + osrWrap.surActkpi.Id;
            kpiAchievement.Unique_Key__c = key;
        }
        return kpiAchievement;
    }
    
    
    //To fetch numerator and denominator of KPI Record based on KPI Type
    public static Map<String,Decimal> getkpiValue(EDGE_OutletSurveyRespWrapper osrWrap){
        Map<String,Decimal> kpiValue = new Map<String,Decimal>();
        Decimal outletResp=0.0;
        Decimal numerator=0.0;
        Decimal denominator=0.0;
        if(osrWrap.surActkpi.Type__c == 'Survey KPI'){
            numerator = (validateResponse(surveyAnswerMap,osrWrap ) ? 1 : 0);
            denominator = osrWrap.totalNoofOutlets;
        }
        else if(osrWrap.surActkpi.Type__c == 'Activation Type'){
            if(osrWrap.response != null && EDGE_OutletSurveyKPIRollupExtendedHelper.isNumeric(osrWrap.response)){
                outletResp = Decimal.valueOf(osrWrap.response);
                numerator=outletResp;
            }
            denominator = osrWrap.totalNoofOutlets;
        }
        kpiValue.put('Numerator',numerator);
        kpiValue.put('Denominator',denominator);
        return kpiValue;
    }
    
         //Method to check if a Survey Response is valid
    public static boolean validateResponse(Map<Id, String> surveyAnswerMap,EDGE_OutletSurveyRespWrapper osrWrap){
        boolean isValidResponse = false;
        if(surveyAnswerMap != null && surveyAnswerMap.containsKey(osrWrap.question) && surveyAnswerMap.get(osrWrap.question) == osrWrap.response){
            isValidResponse = true;
        }
        return isValidResponse;
    }
    
}