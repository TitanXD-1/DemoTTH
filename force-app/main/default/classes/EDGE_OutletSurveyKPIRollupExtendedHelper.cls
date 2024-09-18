/**

* @Description: EDGE_OutletSurveyKPIRollupExtendedHelper

* @Purpose : ES20-13499 - Helper class for EDGE_OutletSurveyKPIRollupBatch 

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*	1.0		   Rajarshi/Mayukh		12/01/2023		[ES20-13499] Logic to calculate Outlet Survey KPI
*   2.0		   Rajarshi				28/02/2023		[ES20-13865]
*	3.0		   Doman Murmu			26/07/2023		143480
*/


public with sharing class EDGE_OutletSurveyKPIRollupExtendedHelper {
    
    public static Id salesTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    public static Id qualityTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
    public static Id actTerrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
	public static Id terrKPIRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();    
    
    public static Map<Id,List<Outlet_Territory__c>> getOutletTerritoryMap(Set<Id> outletIds){
        Map<Id,List<Outlet_Territory__c>> outletTerritoryMap = new Map<Id,List<Outlet_Territory__c>>();
        for(Outlet_Territory__c ot : [SELECT Id, Territory__c,Territory__r.RecordTypeID,Territory__r.Country__c,Territory__r.Total_Number_Of_Active_Outlets__c,Territory__r.Region__c,Outlet__c 
                                      from Outlet_Territory__c WHERE Outlet__c IN : outletIds AND Outlet__r.Status__c = :EDGE_Constant.ACTIVE AND Active__c = :EDGE_Constant.ACTIVE WITH SECURITY_ENFORCED]){
                                          if(outletTerritoryMap.containsKey(ot.Outlet__c)){
                                              outletTerritoryMap.get(ot.Outlet__c).add(ot);          
                                          }
                                          else{
                                              outletTerritoryMap.put(ot.Outlet__c,new List<Outlet_Territory__c>{ot});
                                          }                                      
                                      }
        return outletTerritoryMap;
    }
    
    //Method to get Survey KPI Question Answer
    public static Map<Id, String> getSurveyQuestionAnswer(Set<Id> surveyIdSet){
        Map<Id, String> surveyAnswerMap = new Map<Id, String>();
        if(!surveyIdSet.isEmpty()){
            for(Survey_Answer__c surveyAnswer : [SELECT Id, Survey_Question__c, Option_Value__c FROM Survey_Answer__c WHERE Bonus_Applicable_Response__c = TRUE
                                                 AND Survey_Question__r.Survey__c IN :surveyIdSet WITH SECURITY_ENFORCED])
            {
                surveyAnswerMap.put(surveyAnswer.Survey_Question__c, surveyAnswer.Option_Value__c);
            }
        }
        return surveyAnswerMap;
    }
    
    
    //Method To set Pickup Option values
    public static Pick_Up_Options__c setSurActkpi(Outlet_Survey_Response__c osr){
        Pick_Up_Options__c surActkpi = new Pick_Up_Options__c();
        if(osr.Survey_Question__r.Survey_KPI__c!=Null){
            surActkpi = new Pick_Up_Options__c(Id=osr.Survey_Question__r.Survey_KPI__c);
            surActkpi.Type__c = 'Survey KPI';
            surActkpi.Include_in_Total_Activation_Survey_KPI__c=osr.Survey_Question__r.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c;
            surActkpi.Applicable_Business_Role__c=osr.Survey_Question__r.Survey_KPI__c!=null?osr.Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c:null;
        }
        else if(osr.Survey_Question__r.Activation_Type__c!=Null){
            surActkpi=new Pick_Up_Options__c(Id=osr.Survey_Question__r.Activation_Type__c);
            surActkpi.Type__c = 'Activation Type';
            surActkpi.Applicable_Business_Role__c=osr.Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c;
        }
        return surActkpi;
    }
    
    
    //Method To check if String is Numeric
    public static Boolean isNumeric(String s){
        Boolean returnValue;
        try{
            Decimal.valueOf(s);
            returnValue = TRUE; 
        } catch (Exception e) {
            returnValue = FALSE;
        }
        return returnValue;
    }
    
    
    //Method to calculate the Achievement of KPI
    public static double calculateAchievement(KPI_Achivement__c kpiAchievement){
        double achievement = 0.0;
        //143480 Added for Activation Survey KPI & Total survey
        List<String> kpiTypeList = new List<String>{'Activation Survey KPI','Total Activation Survey'};
        if(kpiTypeList.contains(kpiAchievement.KPI_Type__c)){	//143480
            achievement = kpiAchievement.Actual_Numerator__c;
        }
        else if(kpiAchievement.Actual_Numerator__c != Null && kpiAchievement.Total_Denominator__c > 0){
            achievement = (kpiAchievement.Actual_Numerator__c/kpiAchievement.Total_Denominator__c)*100;
        }
        return achievement;    
    }
    
    
    //Method to generate Unique Key For Survey and Activation Type KPI Achievement
    public static String getUniqKPIKey(EDGE_OutletSurveyRespWrapper osrWrap){
        String key;
        if(osrWrap.surActkpi.Type__c == 'Survey KPI'){
            key = osrWrap.terr.Id + '_' + 'Survey' + '_' +osrWrap.surActkpi.Id;
        }
        else if(osrWrap.surActkpi.Type__c == 'Activation Type'){
            key = osrWrap.terr.Id + '_' + 'Activation' + '_' + osrWrap.surActkpi.Id;
        }
        return key;
    }
    
    
    //Check if KPI needs to be calculated for Activation Territory
    public static Boolean isValidActivationOsr(EDGE_OutletSurveyRespWrapper osrWrap){
        Boolean valid = false;
        if(osrWrap.terr.RecordTypeId==actTerrRecordTypeId && (osrWrap.surActkpi!=Null && osrWrap.surActkpi.Applicable_Business_Role__c == 'Activation Specialist')){
            valid = true;
        }
        return valid;
    }
    
    //ES20-13746
    //Check if OSR is latest for Survey KPI
    public static Boolean isSurveyLatestResp(Outlet_Survey_Response__c osr,List<String> outSurKPIKey){
        String key=(osr.Survey_Question__r.Survey_KPI__c!=null)?(osr.Outlet_Survey__r.Outlet__c+'_'+osr.Outlet_Survey__r.Survey__c+'_'+osr.Survey_Question__r.Survey_KPI__c):null;
        Boolean valid = false;
        if(osr.Survey_Question__r.Activation_Type__c!=Null || (osr.Survey_Question__r.Survey_KPI__c!=Null && !outSurKPIKey.contains(key))){
            valid = true;
        }
        return valid;
    }
    
    
    //Check if KPI needs to be calculated for Sales and Quality Territory
    public static Boolean isValidSalesQualityOsr(EDGE_OutletSurveyRespWrapper osrWrap){
        Boolean valid = false;
        if((osrWrap.terr.RecordTypeId==salesTerrRecordTypeId || osrWrap.terr.RecordTypeId==qualityTerrRecordTypeId) && (osrWrap.surActkpi!=Null && osrWrap.surActkpi.Applicable_Business_Role__c != 'Activation Specialist')){
            valid = true;
        }
        return valid;
    }
    
    //Add the osr key for the Survey KPI Latest Response
    public static void setLatestSurveyResponseKey(Outlet_Survey_Response__c osr,List<String> outSurKPIKey){
        String key = osr.Outlet_Survey__r.Outlet__c+'_'+osr.Outlet_Survey__r.Survey__c+'_'+osr.Survey_Question__r.Survey_KPI__c;
        if(osr.Survey_Question__r.Survey_KPI__c!=Null && !outSurKPIKey.contains(key)){
            outSurKPIKey.add(key);
        }
    }
    
	//Method to create KPI Achievement Instance
    public static KPI_Achivement__c createTotalKPIAchievement(EDGE_OutletSurveyRespWrapper osrWrap){
        KPI_Achivement__c kpiAchievement = new KPI_Achivement__c();       
        String key = '';
        //Block for populating fields common to both Survey and Activation KPI and Total
        kpiAchievement.Territory__c = osrWrap.terr.Id;
        kpiAchievement.Country__c = osrWrap.terr.country__c;
        kpiAchievement.Region__c = osrWrap.terr.region__c;
        kpiAchievement.Total_Denominator__c = osrWrap.totalNoofOutlets;
        
        //Block for populating fields relevant for Total Activation Survey KPI
        kpiAchievement.RecordTypeId = terrKPIRecordTypeId;           
        kpiAchievement.KPI_Type__c = 'Total Activation Survey';
        key = osrWrap.terr.Id + '_' + 'Total Activation Survey' ;
        kpiAchievement.Unique_Key__c = key;
        
        return kpiAchievement;
    }
}