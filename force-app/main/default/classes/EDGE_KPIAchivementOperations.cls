/**
* @Name: EDGE_KPIAchivementOperations 
* @ES20-5482 - Batch KPI Calculation 
* @History                                                            
* 	@VERSION     AUTHOR              DATE              DETAIL
*	1.0         Dipanjan D          31/10/2019        ES20-5482
*	2.0			Dipanjan D          31/10/2019        ES20-6945
*	3.0			Dipanjan D          19/04/2020        ES20-7638
*	4.0			Prasanth T			29/10/2021		  ES20-10838(calculateAssetKPIAchivements)
*	5.0			Saranya L			19/11/2021		  ES20-11036(getKPIWithValuesMap,calculateAccountValues,getOutlets,getOutletsCountAgainstTerritory)
*	6.0			Subhodeep Sarkar	10/02/2022		  ES20-11839(Calculating Target number value according to MS at Territory Level)
*	7.0			Rajarshi Lahiri		23/02/2022		  ES20-10999(getTerrHierMap,getOutletsCountAgainstActivTerritory,getkpiAchievementMapAT)
*   8.0			Saranya/Anand		10/02/2022		  ES20-12220(calculateKPIAchivements-included activation territory)
*   9.0         Uppalapati Anand    11/03/2022        ES20-12305
*   10.0		Saranya L			22/02/2022		  ES20-12222(calculateKPIAchivements-using label for Volume Target Performance KPI countries)
*	11.0		Supriya G			22/03/2022		  ES20-12224(Calculation of Planned Call, Virtual Call, Outlet Visit Compliance)
*   12.0        Joshraj Sen         20/05/2022        ES20-12734(Calculation of OES,MPA KPIs for Temporarily Closed)
*   13.0        Joshraj Sen         08/06/2022        ES20-12763(Calculation of Distribution KPIs for Temporarily Closed)
*   14.0        Aparajita           09/06/2022        ES20-12821(Restricting KPI calculation for Planned & Virtual calls at Territory level) 
*   15.0        Joshraj Sen         15/06/2022        ES20-13002(The MPA,OES and Distribution KPI of Activation Territory have their Total Denominator Blank)  
*   16.0        Joshraj Sen         16/06/2022        ES20-13004(Calculation of OES,MPA,Distribution KPIs for Temporarily Closed Outlets Present in Activation Territories)
*	17.0		Rajarshi Lahiri		07/07/2022		  ES20-13053(Updated MAS calculation to include 'Activated' Outlets in numerator and denominator)
*   17.1        Rajarshi Lahiri     05/08/2022        ES20-13205(UAT_EDGE_PrimaryTerritoryOutletCalcBatch failing for PT)
*   17.2        Joshraj Sen         04/01/2023        ES20-13672
*/
public with sharing class EDGE_KPIAchivementOperations 
{
    
    public static String territoryRecType = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
    public static String salesTerritoryRecType = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    public static String qualityTerritoryRecType = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
    public static String allowTemporarilyClosedOutletKPIs=Label.EDGE_AllowTemporarilyClosed_Outlets_KPI;
   
    public static Map<Id,Integer> totalNoOfActiveTempClosedOutlets=new Map<Id,Integer>();
    public static Map<Id,Integer> totalNoOfActiveTempClosedActivatedOutlets=new Map<Id,Integer>();
    //public static Map<String, Id> kpiAchivementMap = new Map<String, Id>();
    public static final String activeString='Active';
    public static final String temporarilyClosedString='Temporarily Closed';
    public static final String oesString='OES';
    public static final String masString='MAS';
    public static final String mpaString='MPA';
    public static final String distributionString='Distribution';
    public static final String npdString='NPD';
    public static final String outletVisitsComplianceString='Outlet Visits Compliance';
    public static final String volumeTargetPerformanceString='Volume Target Performance';
    
    private static KPI_Achivement__c formKPIAchievementRecordProgressive(EDGE_KPIAchievementWrapper kpiAchvWrapper)
    {
        String territoryId=(Id)kpiAchvWrapper.aggResult.get('TerritoryID');
        String keyString=territoryId+'_'+ kpiAchvWrapper.kpiType;
        KPI_Achivement__c kpi=new KPI_Achivement__c(Id = kpiAchvWrapper.kpiAchivementMap.containsKey(keyString) ? kpiAchvWrapper.kpiAchivementMap.get(keyString) : null); 
        kpi.Total_Denominator__c= kpiAchvWrapper.aggResult.get('Den')!=null ? (Decimal)kpiAchvWrapper.aggResult.get('Den'):0;  
        kpi.Actual_Numerator__c=kpiAchvWrapper.aggResult.get('Num')!=null ? (Decimal)kpiAchvWrapper.aggResult.get('Num'):0;
        kpi.Region__c=kpiAchvWrapper.territoryMap.containsKey(territoryId)?kpiAchvWrapper.territoryMap.get(territoryId).Region__c:null;
        kpi.KPI_Type__c = kpiAchvWrapper.kpiType;
        kpi.RecordTypeId=territoryRecType;
        kpi.Territory__c=territoryId;
        kpi.Target__c=kpiAchvWrapper.territoryMap.get(territoryId).get(kpiAchvWrapper.targetFieldName)!=null?(Decimal)kpiAchvWrapper.territoryMap.get(territoryId).get(kpiAchvWrapper.targetFieldName):0;             
        kpi.Country__c=kpiAchvWrapper.marketSettingList!=null && kpiAchvWrapper.marketSettingList.size()>0 ? ((kpiAchvWrapper.marketSettingList[0]).Geography__c):null;
        kpi.Achievement__c= kpi.Total_Denominator__c!=0 && kpi.Actual_Numerator__c!=0 ?  (kpi.Actual_Numerator__c/kpi.Total_Denominator__c)*100:0;
        return kpi;
    }
    
    private static KPI_Achivement__c formKPIAchievementRecord(EDGE_KPIAchievementWrapper kpiAchvWrapper)
    {
        String territoryId=(Id)kpiAchvWrapper.aggResult.get('TerritoryID');
        String keyString=territoryId+'_'+ kpiAchvWrapper.kpiType;
        KPI_Achivement__c kpi=new KPI_Achivement__c(Id = kpiAchvWrapper.kpiAchivementMap.containsKey(keyString) ? kpiAchvWrapper.kpiAchivementMap.get(keyString) : null); 
        kpi.Total_Denominator__c=kpiAchvWrapper.terrToOutletsCountMap.get(territoryId)!=null ? kpiAchvWrapper.terrToOutletsCountMap.get(territoryId):0;
        kpi.Actual_Numerator__c=kpiAchvWrapper.aggResult.get('Num')!=null? (Decimal)kpiAchvWrapper.aggResult.get('Num'):0;
        kpi.Region__c=kpiAchvWrapper.territoryMap.containsKey(territoryId)?kpiAchvWrapper.territoryMap.get(territoryId).Region__c:null;
        kpi.KPI_Type__c = kpiAchvWrapper.kpiType;
        kpi.RecordTypeId=territoryRecType;
        kpi.Territory__c=territoryId;
        //kpi.Target__c=territoryMap.get(territoryId).OES_Target__c!=null?territoryMap.get(territoryId).OES_Target__c:0;
        kpi.Target__c=kpiAchvWrapper.territoryMap.get(territoryId).get(kpiAchvWrapper.targetFieldName)!=null?(Decimal)kpiAchvWrapper.territoryMap.get(territoryId).get(kpiAchvWrapper.targetFieldName):0;
        kpi.Country__c=kpiAchvWrapper.marketSettingList!=null && kpiAchvWrapper.marketSettingList.size()>0 ? ((kpiAchvWrapper.marketSettingList[0]).Geography__c):null;
        kpi.Achievement__c= kpi.Total_Denominator__c!=0 && kpi.Actual_Numerator__c!=0 ?  kpi.Actual_Numerator__c/kpi.Total_Denominator__c:0;
        return kpi;
    }
    
    public static  List<KPI_Achivement__c> calculateKPIAchivements(Map<Id, Territory__c> territoryMap, Map<Id, Territory_Cycle__c> territoryWithCycleMap, String countryCode, String territoryTypeStr){
        Set<Id> territoryIdSet = new Set<Id>();   
        territoryIdSet.addAll(territoryMap.keySet());
        Map<Id,Decimal> totalNoOfActiveOutlets=getOutletsCountAgainstTerritory(territoryIdSet,'active');
        Map<Id,Decimal> totalNoOfActiveTempClosedOutlets=getOutletsCountAgainstTerritory(territoryIdSet,'active_temp');
        Map<Id,Decimal> totalNoOfActiveTempClosedActivatedOutlets=getOutletsCountAgainstTerritory(territoryIdSet,'active_temp_flag');
        Map<String, Id> kpiAchivementMap  = getkpiAchievementMap(territoryIdSet);
        //Map<Id,decimal> territoryToOutletMap = new map<Id,decimal>();
        List<String> excludedKPIFromRegionList = Label.EDGE_ExcludedKPIFromMetadata.split(';'); //ES20-12821
        List<String> countryList = new List<String>(); // added by saranya for ES20-12222
        String countriesStr = Label.EDGE_Volume_Target_Performance_Country;    
        if(countriesStr != null){
            countryList = countriesStr.split(',');
        }
        String queryForOES='';
        String queryForMPA='';
        String queryForMAS='';
        String queryForDistributionBinary='';
        String queryForDistributionProgressive='';
        String queryForNPDBinary='';
        String queryForOutletVisitsCompliance='';
        String queryForVolumeTargetAU='';
        String  queryForVolumeTargetIENIRCOMXTW='';
        String queryForNPDProgressive='';
        boolean activatedOutlets=true;
        activatedOutlets=true;
        String progressiveString='Progressive';
        //String binaryString='Binary';
        Integer centPercent=100;
        centPercent=100;
        List<Market_Setting__c> marketSettingList = fetchMarketSetting(countryCode);
        List<KPI_Achivement__c> kpiAchivementsToUpsert=new List<KPI_Achivement__c>();
        Map<String, Sales_Area_KPI_Fields_Mapping__mdt> kpiTypeToKPIMtRecMap = new Map<String, Sales_Area_KPI_Fields_Mapping__mdt>(); 

        //System.debug(territoryTypeStr + ' : ');
        //EDGE_UtilityClass.printGovLimits(295);
        if(Schema.SObjectType.Sales_Area_KPI_Fields_Mapping__mdt.isAccessible())
        {
            for(Sales_Area_KPI_Fields_Mapping__mdt kpiMetadataRec : [SELECT MasterLabel, Account_KPI_Field__c, Operation_Type__c, Calculation_Type__c, Relationship__c,
                                                             Market_Settings_Reference__c, Check_for_Null__c, KPI_Achievement_Type__c, Dependent_Field__c, Fraction_Variant__c, 
                                                             Territory_Target_Fields__c, Territory_Cycle_Target_Field__c FROM Sales_Area_KPI_Fields_Mapping__mdt 
                                                             WHERE KPI_Achievement_Type__c != null AND Active__c = True AND KPI_Achievement_Type__c NOT IN : excludedKPIFromRegionList])
            {//ES20-12821
                //Mapping Account KPI fields with KPI Mapping instance
                if(kpiMetadataRec.Account_KPI_Field__c != null){
                    kpiTypeToKPIMtRecMap.put(kpiMetadataRec.KPI_Achievement_Type__c, kpiMetadataRec);
                }
                
            }
        }
        if(territoryTypeStr=='Sales'){
            
            queryForOES='SELECT sum(Outlet_Execution_Score__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet and Status__c in (:activeString,:temporarilyClosedString) and Outlet_Execution_Score__c=:centPercent group by Primary_Sales_Territory__c';  
            queryForMPA='SELECT sum(Minimum_Product_Assortment__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString,:temporarilyClosedString)  and Minimum_Product_Assortment__c=:centPercent  group by Primary_Sales_Territory__c';  
            queryForDistributionBinary='SELECT sum(Distribution__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString,:temporarilyClosedString) and  Distribution__c=:centPercent  group by Primary_Sales_Territory__c'; 

            queryForMAS='SELECT sum(Minimum_Activation_Standards__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet and Status__c in (:activeString,:temporarilyClosedString) and Activated_Outlet__c=:activatedOutlets and Minimum_Activation_Standards__c=:centPercent   group by Primary_Sales_Territory__c '; 
            
            queryForOutletVisitsCompliance='SELECT sum(Expected_Visits__c) Den,sum(Capped_Visits__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString)  group by Primary_Sales_Territory__c';
            queryForDistributionProgressive='SELECT sum(Distribution_Denominator__c) Den,sum(Distribution_Numerator__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString,:temporarilyClosedString)  group by Primary_Sales_Territory__c'; 
            queryForNPDProgressive='SELECT sum(New_Product_Distribution_Denominator__c) Den,sum(New_Product_Distribution_Numerator__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString)  group by Primary_Sales_Territory__c'; 
            queryForNPDBinary='SELECT sum(New_Product_Distribution__c) Num,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString) and  New_Product_Distribution__c=:centPercent  group by Primary_Sales_Territory__c'; 
            
             
            queryForVolumeTargetAU='SELECT sum(Volume_Actual_Points__c) volNum,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString)  group by Primary_Sales_Territory__c'; 
            queryForVolumeTargetIENIRCOMXTW='SELECT sum(Volume_Number_Current_FY__c) achv ,sum(Volume_Number_Last_FY__c) prevAchv,Primary_Sales_Territory__c TerritoryID from Account where Primary_Sales_Territory__c in :territoryIdSet  and Status__c in (:activeString)  group by Primary_Sales_Territory__c'; 
        
        }else if(territoryTypeStr=='Activation'){ 
            
            queryForOES='SELECT sum(Outlet_Execution_Score__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet and Status__c in (:activeString,:temporarilyClosedString) and Outlet_Execution_Score__c=:centPercent group by Activation_Territory_LT__c';   
            queryForMPA='SELECT sum(Minimum_Product_Assortment__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString,:temporarilyClosedString)  and Minimum_Product_Assortment__c=:centPercent  group by Activation_Territory_LT__c';   
            queryForDistributionBinary='SELECT sum(Distribution__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString,:temporarilyClosedString) and  Distribution__c=:centPercent  group by Activation_Territory_LT__c';  

            queryForMAS='SELECT sum(Minimum_Activation_Standards__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet and Status__c in (:activeString,:temporarilyClosedString) and Activated_Outlet__c=:activatedOutlets and Minimum_Activation_Standards__c=:centPercent   group by Activation_Territory_LT__c ';  

            queryForOutletVisitsCompliance='SELECT sum(Expected_Visits__c) Den,sum(Capped_Visits__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString)  group by Activation_Territory_LT__c';  
            queryForDistributionProgressive='SELECT sum(Distribution_Denominator__c) Den,sum(Distribution_Numerator__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString,:temporarilyClosedString)  group by Activation_Territory_LT__c';  
            queryForNPDProgressive='SELECT sum(New_Product_Distribution_Denominator__c) Den,sum(New_Product_Distribution_Numerator__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString)  group by Activation_Territory_LT__c';  
            queryForNPDBinary='SELECT sum(New_Product_Distribution__c) Num,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString) and  New_Product_Distribution__c=:centPercent  group by Activation_Territory_LT__c';  

            queryForVolumeTargetIENIRCOMXTW='SELECT sum(Volume_Number_Current_FY__c) achv ,sum(Volume_Number_Last_FY__c) prevAchv,Activation_Territory_LT__c TerritoryID from Account where Activation_Territory_LT__c in :territoryIdSet  and Status__c in (:activeString)  group by Activation_Territory_LT__c';
            
        }else{
            
            queryForOES='SELECT sum(Outlet__r.Outlet_Execution_Score__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet and Outlet_Status__c in (:activeString,:temporarilyClosedString) and Outlet__r.Outlet_Execution_Score__c=:centPercent group by Territory__c'; 
            queryForMPA='SELECT sum(Outlet__r.Minimum_Product_Assortment__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet and Outlet_Status__c in (:activeString,:temporarilyClosedString) and Outlet__r.Minimum_Product_Assortment__c=:centPercent group by Territory__c'; 
            queryForDistributionBinary='SELECT sum(Outlet__r.Distribution__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet  and Outlet_Status__c in (:activeString,:temporarilyClosedString) and  Outlet__r.Distribution__c=:centPercent  group by Territory__c';   

            queryForMAS='SELECT sum(Outlet__r.Minimum_Activation_Standards__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet and Outlet_Status__c in (:activeString,:temporarilyClosedString) and Outlet__r.Activated_Outlet__c=:activatedOutlets and Outlet__r.Minimum_Activation_Standards__c=:centPercent group by Territory__c'; 

            queryForOutletVisitsCompliance='SELECT sum(Outlet__r.Expected_Visits__c) Den,sum(Outlet__r.Capped_Visits__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet  and Outlet_Status__c in (:activeString)  group by Territory__c';               
            queryForDistributionProgressive='SELECT sum(Outlet__r.Distribution_Denominator__c) Den,sum(Outlet__r.Distribution_Numerator__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet  and Outlet_Status__c in (:activeString,:temporarilyClosedString)  group by Territory__c'; 
            queryForNPDProgressive='SELECT sum(Outlet__r.New_Product_Distribution_Denominator__c) Den,sum(Outlet__r.New_Product_Distribution_Numerator__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet  and Outlet_Status__c in (:activeString)  group by Territory__c';   
            queryForNPDBinary='SELECT sum(Outlet__r.New_Product_Distribution__c) Num,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet  and Outlet_Status__c in (:activeString) and  Outlet__r.New_Product_Distribution__c=:centPercent  group by Territory__c';   
            
            queryForVolumeTargetIENIRCOMXTW='SELECT sum(Outlet__r.Volume_Number_Current_FY__c) achv ,sum(Outlet__r.Volume_Number_Last_FY__c) prevAchv,Territory__c TerritoryID from Outlet_Territory__c where Territory__c in :territoryIdSet  and Outlet_Status__c in (:activeString)  group by Territory__c';  
        }
        //System.debug('@@@ OES Size '+Database.query(queryForOES).size());
        
        for (AggregateResult aggResult :Database.query(queryForOES))               
        {	
            
            EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
            kpiAchvWrapper.kpiType = 'OES';
            String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'OES_Target__c';
            kpiAchvWrapper.aggResult = aggResult;
            kpiAchvWrapper.territoryMap = territoryMap;
            kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveTempClosedOutlets;
            kpiAchvWrapper.marketSettingList = marketSettingList;
            kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
            kpiAchvWrapper.targetFieldName = targetFieldName;
            KPI_Achivement__c kpi = formKPIAchievementRecord(kpiAchvWrapper);
            kpiAchivementsToUpsert.add(kpi);
        }
        //System.debug('Here ' + territoryTypeStr + '--> ');
        //EDGE_UtilityClass.printGovLimits(365);
        for (AggregateResult aggResult :Database.query(queryForMPA)){
            EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
            kpiAchvWrapper.kpiType = 'MPA';
            String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'MPA_Target__c';
            kpiAchvWrapper.aggResult = aggResult;
            kpiAchvWrapper.territoryMap = territoryMap;
            kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveTempClosedOutlets;
            kpiAchvWrapper.marketSettingList = marketSettingList;
            kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
            kpiAchvWrapper.targetFieldName = targetFieldName;
            KPI_Achivement__c kpi = formKPIAchievementRecord(kpiAchvWrapper);
            kpiAchivementsToUpsert.add(kpi);            
        }
        //System.debug(territoryTypeStr + '--> ');
        //EDGE_UtilityClass.printGovLimits(383);
        for (AggregateResult aggResult :Database.query(queryForMAS)){
            EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
            kpiAchvWrapper.kpiType = 'MAS';
            String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'MAS_Target__c';
            kpiAchvWrapper.aggResult = aggResult;
            kpiAchvWrapper.territoryMap = territoryMap;
            kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveTempClosedActivatedOutlets;
            kpiAchvWrapper.marketSettingList = marketSettingList;
            kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
            kpiAchvWrapper.targetFieldName = targetFieldName;
            KPI_Achivement__c kpi = formKPIAchievementRecord(kpiAchvWrapper);
            kpiAchivementsToUpsert.add(kpi);
        }
        //System.debug(territoryTypeStr + '--> ');
        //EDGE_UtilityClass.printGovLimits(401);      
        for (AggregateResult aggResult :Database.query(queryForNPDBinary)){
            EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
            kpiAchvWrapper.kpiType = 'NPD';
            String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'NPD_Target__c';           
            kpiAchvWrapper.aggResult = aggResult;
            kpiAchvWrapper.territoryMap = territoryMap;
            kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveOutlets;
            kpiAchvWrapper.marketSettingList = marketSettingList;
            kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
            kpiAchvWrapper.targetFieldName = targetFieldName;
            KPI_Achivement__c kpi = formKPIAchievementRecord(kpiAchvWrapper);
            kpiAchivementsToUpsert.add(kpi);
        }
        //System.debug(territoryTypeStr + '--> ');
        //EDGE_UtilityClass.printGovLimits(440);
        
        if(marketSettingList!=null && marketSettingList.size()>0 && marketSettingList[0].Distribution__c==progressiveString){
            //Distribution - Progressive
            for (AggregateResult aggResult :Database.query(queryForDistributionProgressive)){
                EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
                kpiAchvWrapper.kpiType = 'Distribution';
            	String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'Distribution_Target__c';           
                kpiAchvWrapper.aggResult = aggResult;
                kpiAchvWrapper.territoryMap = territoryMap;
                //kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveOutlets;
                kpiAchvWrapper.marketSettingList = marketSettingList;
                kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
                kpiAchvWrapper.targetFieldName = targetFieldName;
                KPI_Achivement__c kpi = formKPIAchievementRecordProgressive(kpiAchvWrapper);
                kpiAchivementsToUpsert.add(kpi);
            }
            //System.debug(territoryTypeStr + '--> ');
            //EDGE_UtilityClass.printGovLimits(479);
        }else{//Distribution - Binary
            for (AggregateResult aggResult :Database.query(queryForDistributionBinary))               
            {
                EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
                kpiAchvWrapper.kpiType = 'Distribution';
            	String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'Distribution_Target__c';           
                kpiAchvWrapper.aggResult = aggResult;
                kpiAchvWrapper.territoryMap = territoryMap;
                kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveTempClosedOutlets;
                kpiAchvWrapper.marketSettingList = marketSettingList;
                kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
                kpiAchvWrapper.targetFieldName = targetFieldName;
                KPI_Achivement__c kpi = formKPIAchievementRecord(kpiAchvWrapper);
                kpiAchivementsToUpsert.add(kpi);
            }
            //System.debug(territoryTypeStr + '--> ');
            //EDGE_UtilityClass.printGovLimits(500);
        }
        
        for (AggregateResult aggResult :Database.query(queryForOutletVisitsCompliance))               
        {

            EDGE_KPIAchievementWrapper kpiAchvWrapper = new EDGE_KPIAchievementWrapper();
            kpiAchvWrapper.kpiType = 'Outlet Visits Compliance';
            String targetFieldName = kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType) != null ? kpiTypeToKPIMtRecMap.get(kpiAchvWrapper.kpiType).Territory_Target_Fields__c : 'Outlet_Visit_Compliance_Target__c';
            kpiAchvWrapper.aggResult = aggResult;
            kpiAchvWrapper.territoryMap = territoryMap;
            //kpiAchvWrapper.terrToOutletsCountMap = totalNoOfActiveOutlets;
            kpiAchvWrapper.marketSettingList = marketSettingList;
            kpiAchvWrapper.kpiAchivementMap = kpiAchivementMap;
            kpiAchvWrapper.targetFieldName = targetFieldName;
            KPI_Achivement__c kpi = formKPIAchievementRecordProgressive(kpiAchvWrapper);
            kpiAchivementsToUpsert.add(kpi);
        }
        //System.debug(territoryTypeStr + '--> ');
        //EDGE_UtilityClass.printGovLimits(459);
        
        String countryCodeAU='AU';
        //System.debug('@@@ Reaches Record Type '+territoryTypeStr);
        if(countryCode==countryCodeAU && queryForVolumeTargetAU!=''){
            //System.debug('@@@ Reaches Here Before Query');
            for (AggregateResult aggResult :Database.query(queryForVolumeTargetAU)){
                String territoryId=(Id)aggResult.get('TerritoryID');
                String keyString=territoryId+'_'+volumeTargetPerformanceString;
                //System.debug('@@@ key String '+keyString);
                KPI_Achivement__c kpi=new KPI_Achivement__c(Id = kpiAchivementMap.containsKey(keyString) ? kpiAchivementMap.get(keyString) : null); 
                kpi.Total_Denominator__c= totalNoOfActiveOutlets.get(territoryId)!=null? totalNoOfActiveOutlets.get(territoryId):0;  
                kpi.Achievement__c=aggResult.get('volNum')!=null ? (Double)aggResult.get('volNum'):0;
                kpi.Actual_Numerator__c=aggResult.get('volNum')!=null ? (Double)aggResult.get('volNum'):0;
                kpi.Region__c=territoryMap.containsKey(territoryId)?territoryMap.get(territoryId).Region__c:null;                   
                kpi.KPI_Type__c = volumeTargetPerformanceString;
                kpi.RecordTypeId=territoryRecType;
                kpi.Territory__c=territoryId;
                kpi.Target__c=territoryWithCycleMap.get(territoryId)!=null ?territoryWithCycleMap.get(territoryId).Volume_Target_Value__c:0;
                kpi.Country__c=marketSettingList!=null && marketSettingList.size()>0 ? ((marketSettingList[0]).Geography__c):null;
                //kpi.Achievement__c= kpi.Total_Denominator__c!=0 && kpi.Actual_Numerator__c!=0 ?  kpi.Actual_Numerator__c/kpi.Total_Denominator__c:0;
                kpiAchivementsToUpsert.add(kpi);
            }  
            //System.debug(territoryTypeStr + '--> ');
            //EDGE_UtilityClass.printGovLimits(526);
        }
        else if(countryList.contains(countryCode)){
            //System.debug('@@@ Reaches Here');
            //System.debug('@@@ Reaches Here Volume Target Performance');
            for (AggregateResult aggResult :Database.query(queryForVolumeTargetIENIRCOMXTW))  
            {
                String territoryId=(Id)aggResult.get('TerritoryID');
                String keyString=territoryId+'_'+volumeTargetPerformanceString;
                KPI_Achivement__c kpi=new KPI_Achivement__c(Id = kpiAchivementMap.containsKey(keyString) ? kpiAchivementMap.get(keyString) : null);                
                //kpi.Actual_Numerator__c=aggResult.get('achv')!=null ? (Double)aggResult.get('achv'):0;
                kpi.Achievement__c=aggResult.get('achv')!=null ? (Decimal)aggResult.get('achv'):0;
                kpi.Previous_Achievement__c=aggResult.get('prevAchv')!=null ? (Decimal)aggResult.get('prevAchv'):0;
                kpi.Region__c=territoryMap.containsKey(territoryId)?territoryMap.get(territoryId).Region__c:null;
                kpi.KPI_Type__c = volumeTargetPerformanceString;
                kpi.RecordTypeId=territoryRecType;
                kpi.Territory__c=territoryId;
                kpi.Country__c=marketSettingList!=null && marketSettingList.size()>0 ? ((marketSettingList[0]).Geography__c):null;
                //kpi.Achievement__c= kpi.Total_Denominator__c!=0 && kpi.Actual_Numerator__c!=0 ?  kpi.Actual_Numerator__c/kpi.Total_Denominator__c:0;
                kpiAchivementsToUpsert.add(kpi);
            }
            //System.debug(territoryTypeStr + '--> ');
            //EDGE_UtilityClass.printGovLimits(549);
        }
        //System.debug('@@@ KPIs size '+kpiAchivementsToUpsert==null);
        return  kpiAchivementsToUpsert;
    }
    
    public static map<Id,decimal> getOutletsCountAgainstTerritory(Set<Id> territoryIds,String activeTemporaryFlagCheck){
        String queryString='';
        String active='Active';
        active='Active';                                                     
        String temporarilyClosed='Temporarily Closed';
        temporarilyClosed='Temporarily Closed';
        Boolean activatedOutlet=true;
        activatedOutlet=true;
        if(activeTemporaryFlagCheck == 'active_temp'){// consider active,temporary closed status outlets 
            queryString='SELECT Territory__c territoryId, Count(Outlet__c) outletCount  from Outlet_Territory__c '+ 
                +'WHERE Territory__r.Id IN :territoryIds AND Outlet__r.Status__c in (:active,:temporarilyClosed) AND Active__c = :EDGE_Constant.ACTIVE group by Territory__c';
        }else if(activeTemporaryFlagCheck == 'active'){//consider active status outlets
            queryString='SELECT Territory__c territoryId, Count(Outlet__c) outletCount from Outlet_Territory__c '+
            +'WHERE Territory__r.Id IN :territoryIds AND Outlet__r.Status__c in (:active) AND Active__c = :EDGE_Constant.ACTIVE group by Territory__c';
        }else if(activeTemporaryFlagCheck == 'active_temp_flag'){// consider active,temporary closed status outlets with activated outlet falg as true ES20-13053
            queryString='SELECT Territory__c territoryId, Count(Outlet__c) outletCount  from Outlet_Territory__c '+ 
            +'WHERE Territory__r.Id IN :territoryIds AND Outlet__r.Status__c in (:active,:temporarilyClosed) AND Outlet__r.Activated_Outlet__c =:activatedOutlet AND Active__c = :EDGE_Constant.ACTIVE  group by Territory__c';//ES20-13053
        }
        EDGE_UtilityClass.printGovLimits(574);
        //System.debug('queryString with type'+queryString);
        Map<Id,decimal> territoryToOutletCountMap = new map<Id,decimal>();
        if(territoryIds!=null && territoryIds.size()>0){
            for(AggregateResult aggResObj :Database.query(queryString))
            {
                String terrId = (String)aggResObj.get('territoryId');
                decimal outletCount = (decimal)aggResObj.get('outletCount');
                //System.debug('Active outlet '+outletCount);
                if(!territoryToOutletCountMap.containsKey(terrId)){
                    territoryToOutletCountMap.put(terrId, outletCount);
                }
            }
            
        }
        EDGE_UtilityClass.printGovLimits(589);
        return territoryToOutletCountMap;
    }  
    
    public static List<KPI_Achivement__c> calculateSOSandVolumeCategoryKPIAchivements(Map<Id, Territory__c> territoryMap, Map<Id, Territory_Cycle__c> territoryWithCycleMap, List<Outlet_KPI_Achievement__c> outletKpiAchievementList,String countryCode, Set<Id> revisedOutletIds){ 
        List<KPI_Achivement__c> kpiAchivementsToUpsert = new List<KPI_Achivement__c>();
        Set<Id> territoryIdSet = new Set<Id>();   
        territoryIdSet.addAll(territoryMap.keySet());
        Map<String, Id> kpiAchivementMap  = getkpiAchievementMap(territoryIdSet);
        List<Market_Setting__c> marketSettingList = new List<Market_Setting__c>();
        Map<String, String> volumeKpiWithTargetFieldsMap = new Map<String, String> {'Premium Core' => 'Volume_Category_Premium_Core_Target__c' , 'Super Deluxe' => 'Volume_Category_Super_Deluxe_Target__c', 'RTD' => 'Volume_Category_RTD_Target__c', 'Reserve' => 'Volume_Category_Reserve_Target__c', 'Deluxe' => 'Volume_Category_Deluxe_Target__c'};
            Map<String, Map<String, Decimal>> territoryKPIWithValuesMap = new Map<String, Map<String, Decimal>>();
        //List<KPI_Achivement__c> kpideleteList = new List<KPI_Achivement__c>();
        
        marketSettingList = fetchMarketSetting(countryCode);
        Id territoryId;
        Map<Id,List<Territory__c>> accountToTerrMap = new map<Id, List<Territory__c>>();
        accountToTerrMap = getOutlets(territoryMap.keySet(), revisedOutletIds);
        List<Territory__c> outletTerrList = new List<Territory__c>();
        
        for(Outlet_KPI_Achievement__c outletKPIAchieve : outletKpiAchievementList){
            outletTerrList = accountToTerrMap.get(outletKPIAchieve.Outlet__c);
            if(outletTerrList != null && outletTerrList.size() == 1){// Sales,Quality,Activation Oulet with one Territory
                territoryId = outletTerrList[0].Id;
                String key = territoryId + '_' + outletKPIAchieve.KPI_Type__c + '_' + (outletKPIAchieve.KPI_Type__c != 'Volume' ? outletKPIAchieve.Category__c : outletKPIAchieve.Volume_Category__c);
                getKPIWithValuesMap(outletKPIAchieve, key,territoryKPIWithValuesMap, marketSettingList);
            }
            else{//Outlet with multiple territories
                for(Territory__c terRec : outletTerrList){ 
                    territoryId = terRec.Id;
                    String key = territoryId + '_' + outletKPIAchieve.KPI_Type__c + '_' + (outletKPIAchieve.KPI_Type__c != 'Volume' ? outletKPIAchieve.Category__c : outletKPIAchieve.Volume_Category__c);
                    getKPIWithValuesMap(outletKPIAchieve, key,territoryKPIWithValuesMap, marketSettingList);
                }
            }
            
        }//end of for loop
        Map<String, KPI_Achivement__c> uniqueKeyKPImap = new Map<String, KPI_Achivement__c>();
        for(KPI_Achivement__c kpi : [Select Id,Unique_Key__c ,Total_Outlets__c,Territory__c,Target__c, Target_Number__c,
                                     Achievement__c,Actual_Numerator__c,Total_Denominator__c,
                                     Previous_Achievement__c
                                     from KPI_Achivement__c where Unique_Key__c  
                                     IN :territoryKPIWithValuesMap.keySet()])
        {
            uniqueKeyKPImap.put(kpi.Unique_Key__c, kpi);
        }
        
        
        for(String keyString : territoryKPIWithValuesMap.keySet()){
            if(uniqueKeyKPImap.containsKey(keyString)){//Existing KPI Achivement values
                
                KPI_Achivement__c kpiAchive = uniqueKeyKPImap.get(keyString);
                String kpiType = keyString.substringAfter(kpiAchive.Territory__c + '_').substringBefore('_');
                Decimal totalOutlets = kpiAchive.Total_Outlets__c != null ?kpiAchive.Total_Outlets__c + territoryKPIWithValuesMap.get(keyString).get('Total'):0;
                kpiAchive.Actual_Numerator__c += territoryKPIWithValuesMap.get(keyString).get('Actual_Numerator__c');
                kpiAchive.Total_Denominator__c += territoryKPIWithValuesMap.get(keyString).get('Total_Denominator__c');
                
                kpiAchive = populateSOSAndVolume( kpiType,  keyString,  kpiAchive, 
                                                 marketSettingList[0],  territoryWithCycleMap,
                                                 territoryKPIWithValuesMap,
                                                 totalOutlets,
                                                 volumeKpiWithTargetFieldsMap,true);
                
                kpiAchive.Total_Outlets__c = totalOutlets;
                kpiAchivementsToUpsert.add(kpiAchive);
            }
            
            else{ // CReation of new KPI Achivement values
                
                KPI_Achivement__c kpiAchive = new KPI_Achivement__c(Id = kpiAchivementMap.containsKey(keyString) ? kpiAchivementMap.get(keyString) : null);
                Decimal totalOutlets = territoryKPIWithValuesMap.get(keyString).get('Total');
                kpiAchive.RecordTypeId = territoryRecType;
                kpiAchive.Territory__c = keyString.substringBefore('_');
                if(marketSettingList != null && marketSettingList.size() > 0){
                    kpiAchive.Country__c = marketSettingList[0].Geography__c;
                }
                kpiAchive.Region__c = territoryMap.get(kpiAchive.Territory__c).Region__c;
                kpiAchive.Actual_Numerator__c = territoryKPIWithValuesMap.get(keyString).get('Actual_Numerator__c');
                kpiAchive.Total_Denominator__c = territoryKPIWithValuesMap.get(keyString).get('Total_Denominator__c');
                String kpiType = keyString.substringAfter(kpiAchive.Territory__c + '_').substringBefore('_');
                kpiAchive = populateSOSAndVolume( kpiType,  keyString,  kpiAchive, 
                                                 marketSettingList[0],  territoryWithCycleMap,
                                                 territoryKPIWithValuesMap,
                                                 totalOutlets,
                                                 volumeKpiWithTargetFieldsMap, false);
                
                kpiAchive.Total_Outlets__c = totalOutlets;
                kpiAchivementsToUpsert.add(kpiAchive);
            }
        }//end of territoryKPIWithValuesMap iteration
        //loop through the KPI achivements to round off - kpiAchivementsToUpsert
        for(KPI_Achivement__c kpiAchievement: kpiAchivementsToUpsert ){
            if(kpiAchievement.KPI_Type__c=='SOS'&& kpiAchievement.Target_Number__c!=null){
                kpiAchievement.Target_Number__c = kpiAchievement.Target_Number__c.round();
            }
        }
        
        return kpiAchivementsToUpsert;
    }
    
    private static KPI_Achivement__c populateSOSAndVolume(String kpiType, string keyString, KPI_Achivement__c kpiAchive, 
                                                          Market_Setting__c marketSetting, Map<Id, Territory_Cycle__c> territoryWithCycleMap,
                                                          Map<String, Map<String, Decimal>> territoryKPIWithValuesMap,
                                                          Decimal totalOutlets, Map<String, String> volumeKpiWithTargetFieldsMap, 
                                                          Boolean isExisting)
    {
        if(kpiType == 'SoS'){//SOS type of KPI
            kpiAchive.KPI_Type__c = kpiType;
            kpiAchive.Category__c = keyString.substringAfter(kpiAchive.Territory__c + '_' + kpiType + '_');
            if(marketSetting.Share_of_Space_facings__c  == 'Facings in %' ){
                Decimal target = kpiAchive.Target__c == null? 0: (kpiAchive.Target__c* kpiAchive.Total_Outlets__c);
                    if(totalOutlets != 0 ){
                        kpiAchive.Target_Number__c = null;
                        if(isExisting){
                            
                            kpiAchive.Target__c = (target + territoryKPIWithValuesMap.get(keyString).get('Target__c')) / totalOutlets;
                            Decimal achievement = kpiAchive.Achievement__c * kpiAchive.Total_Outlets__c;
                            kpiAchive.Achievement__c = (achievement + territoryKPIWithValuesMap.get(keyString).get('Achievement__c')) / totalOutlets;
                        }else{
                            kpiAchive.Target__c = territoryKPIWithValuesMap.get(keyString).get('Target__c') / totalOutlets;
                            kpiAchive.Achievement__c = territoryKPIWithValuesMap.get(keyString).get('Achievement__c') / totalOutlets;
                            kpiAchive.Unique_Key__c = kpiAchive.Territory__c + '_' + 'SoS' + '_' + kpiAchive.Category__c;
                        }
                    }
            }
            
            else if(marketSetting.Share_of_Space_facings__c  == 'Facings in number' ){
                if(totalOutlets != 0 ){
                    kpiAchive.Target__c= null;
                    if(kpiAchive.Target_Number__c!=null){
                        kpiAchive.Target_Number__c += territoryKPIWithValuesMap.get(keyString).get('Target_Number__c');
                        Decimal achievement = kpiAchive.Achievement__c * kpiAchive.Total_Outlets__c;
                        kpiAchive.Achievement__c = (achievement + territoryKPIWithValuesMap.get(keyString).get('Achievement__c')) / totalOutlets;
                    }
                    else{
                        kpiAchive.Target_Number__c = territoryKPIWithValuesMap.get(keyString).get('Target_Number__c');
                        kpiAchive.Achievement__c = territoryKPIWithValuesMap.get(keyString).get('Achievement__c') / totalOutlets;
                        kpiAchive.Unique_Key__c = kpiAchive.Territory__c + '_' + 'SoS' + '_' + kpiAchive.Category__c;
                    }
                }
                
            }
            
        }//end of SOS KPI Block
        if(kpiType == 'Volume'){
            if(isExisting){
                if(territoryWithCycleMap.containsKey(kpiAchive.Territory__c) && volumeKpiWithTargetFieldsMap.containsKey(kpiAchive.Volume_Category__c)){
                    kpiAchive.Target__c = (Decimal)territoryWithCycleMap.get(kpiAchive.Territory__c).get(volumeKpiWithTargetFieldsMap.get(kpiAchive.Volume_Category__c));
                }
                kpiAchive.Achievement__c += territoryKPIWithValuesMap.get(keyString).get('Achievement__c');
                kpiAchive.Previous_Achievement__c = (kpiAchive.Previous_Achievement__c != null) ? kpiAchive.Previous_Achievement__c : 0;
                kpiAchive.Previous_Achievement__c += territoryKPIWithValuesMap.get(keyString).get('Previous_Achievement__c') != null ?territoryKPIWithValuesMap.get(keyString).get('Previous_Achievement__c') : 0;
            }
            else{
                kpiAchive.KPI_Type__c = 'Volume Category Performance';
                kpiAchive.Volume_Category__c = keyString.substringAfter(kpiAchive.Territory__c + '_' + kpiType + '_');
                if(territoryWithCycleMap.containsKey(kpiAchive.Territory__c) && volumeKpiWithTargetFieldsMap.containsKey(kpiAchive.Volume_Category__c)){
                    kpiAchive.Target__c = (Decimal)territoryWithCycleMap.get(kpiAchive.Territory__c).get(volumeKpiWithTargetFieldsMap.get(kpiAchive.Volume_Category__c));
                }					
                kpiAchive.Achievement__c = territoryKPIWithValuesMap.get(keyString).get('Achievement__c');
                kpiAchive.Previous_Achievement__c = territoryKPIWithValuesMap.get(keyString).get('Previous_Achievement__c');
                kpiAchive.Unique_Key__c = kpiAchive.Territory__c + '_' + 'Volume' + '_' + kpiAchive.Volume_Category__c;
            }
        }
        return kpiAchive;
    }
    
    public static Map<String, Id> getkpiAchievementMap(Set<Id>territoryIdSet){ 
       Map<String, Id> kpiAchivementMap  = new Map<String, Id> ();
        EDGE_UtilityClass.printGovLimits(758);
        //Quering on KPI Achievement object for Upserting Records
        for(KPI_Achivement__c kpiAchive : [SELECT Id, Territory__c, Category__c, Volume_Category__c, KPI_Type__c,Master_Asset__c,Region__c,Actual_Numerator__c,Total_Denominator__c,Achievement__c FROM KPI_Achivement__c WHERE Territory__c IN :territoryIdSet AND recordType.developerName = 'Territory_KPI']){
            if(kpiAchive.KPI_Type__c == 'SoS'){
                kpiAchivementMap.put(kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c + '_' + kpiAchive.Category__c, kpiAchive.Id);                    
            }else if(kpiAchive.KPI_Type__c == 'Volume Category Performance'){
                kpiAchivementMap.put(kpiAchive.Territory__c + '_' + 'Volume' + '_' + kpiAchive.Volume_Category__c, kpiAchive.Id);
            }else if(kpiAchive.KPI_Type__c == 'Asset'){
                kpiAchivementMap.put(kpiAchive.Territory__c + '_' + 'Asset' + '_' + kpiAchive.Master_Asset__c, kpiAchive.Id);
            }else{
                kpiAchivementMap.put(kpiAchive.Territory__c + '_' + kpiAchive.KPI_Type__c, kpiAchive.Id);
            }
        }
        EDGE_UtilityClass.printGovLimits(771);
        return kpiAchivementMap;
    }
    
    
    
    public static List<Market_Setting__c> fetchMarketSetting(String countryCode){
        //EDGE_UtilityClass.printGovLimits(778);
        List<Market_Setting__c>  marketSettingList = [Select Id, Geography__c,Outlet_Execution_Score__c, Minimum_Activation_Standards__c, Minimum_Product_Assortment__c, Distribution__c, 
                                                      Share_Of_Space__c, New_Product_Distribution__c, Share_of_Space_facings__c from Market_Setting__c 
                                                      WHERE Geography__r.Code__c = :countryCode LIMIT 1];
        //EDGE_UtilityClass.printGovLimits(782);
        return marketSettingList;
    }
    
    public static Map<Id, List<Territory__c>> getOutlets(Set<Id> territoryIds, Set<Id> revisedOutletIds){
        Map<Id, List<Territory__c>> outletToTerritoryMap = new Map<Id, List<Territory__c>>();
        EDGE_UtilityClass.printGovLimits(788);
        if(territoryIds!=null && territoryIds.size()>0){
            for(Outlet_Territory__c outletTerr : [SELECT Id, Territory__c, Outlet__c,Outlet__r.Name from Outlet_Territory__c 
                                                  WHERE Territory__r.Id IN : territoryIds 
                                                  AND Outlet__c in :revisedOutletIds
                                                  AND Outlet__r.Status__c = :EDGE_Constant.ACTIVE
                                                  AND Active__c = :EDGE_Constant.ACTIVE])
            {
                Territory__c terr = new Territory__c(Id=outletTerr.Territory__c);
                if(outletToTerritoryMap.containsKey(outletTerr.outlet__c)){
                    outletToTerritoryMap.get(outletTerr.outlet__c).add(terr);
                }
                else{
                    outletToTerritoryMap.put(outletTerr.outlet__c, new List<Territory__c>{terr});
                }
            } 
        }
        EDGE_UtilityClass.printGovLimits(805);
        return outletToTerritoryMap;
    }
    
    /*public static Map<Id, List<Territory__c>> getOutlets(Set<Id> territoryIds){
        Map<Id, List<Territory__c>> outletToTerritoryMap = new Map<Id, List<Territory__c>>();
        EDGE_UtilityClass.printGovLimits(811);
        if(territoryIds!=null && territoryIds.size()>0){
            for(Territory__c territoryRec : [SELECT ID,Pending_For_Batch__c,
                                             (Select Outlet__c,Territory__c from Territory_Outlets__r) 
                                             from Territory__c 
                                             WHERE Id IN : territoryIds])
            {
                //Territory__c terr = new Territory__c(Id=outletTerr.Territory__c);
                for(Outlet_Territory__c outletTerr : territoryRec.Territory_Outlets__r){
                    Id outletId = outletTerr.outlet__c;
                    if(outletToTerritoryMap.containsKey(outletId)){
                        outletToTerritoryMap.get(outletId).add(territoryRec);
                    }
                    else{
                        outletToTerritoryMap.put(outletId, new List<Territory__c>{territoryRec});
                    }
                }
                
            } 
        }
        EDGE_UtilityClass.printGovLimits(831);
        return outletToTerritoryMap;
    }*/
    
    
    //Get Number of Outlets against a Territory
    //ES20-13053- Changed parameter type from Boolean to string activeTemporaryFlagCheck
    
    
    // to check the method process
    public static Decimal checkValue(Decimal kpiValue, String calcType){
        if(kpiValue != null){
            if(calcType == 'Binary'){
                if(kpiValue == 100){
                    return 100;
                }else{
                    return 0;
                }               
            }else if(calcType == 'Progressive' || calcType == 'Calculative'){
                return kpiValue;
            }else{
                return 0;
            }
        }else{
            return 0;
        }  
        
    }
    
    
    public static Map<String, Map<String, Decimal>> getKPIWithValuesMap(Outlet_KPI_Achievement__c outletKPIAchieve,
                                                                        String key, 
                                                                        Map<String, Map<String, Decimal>> territoryKPIWithValuesMap,
                                                                        List<Market_Setting__c> marketSettingList)
    {
        //Map<String, Map<String, Decimal>> territoryKPIWithValuesMap = new Map<String, Map<String, Decimal>>();
        
        if((outletKPIAchieve.KPI_Type__c == 'SoS' && (outletKPIAchieve.Target__c != null || outletKPIAchieve.Target_Number__c!=null)) || outletKPIAchieve.KPI_Type__c == 'Volume'){
            if(territoryKPIWithValuesMap.containsKey(key)){
                territoryKPIWithValuesMap.get(key).put('Actual_Numerator__c' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Actual_Numerator__c')) + EDGE_UtilityClass.checkForNull(outletKPIAchieve.Actual_Numerator__c));
                territoryKPIWithValuesMap.get(key).put('Total_Denominator__c' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Total_Denominator__c')) + EDGE_UtilityClass.checkForNull(outletKPIAchieve.Total_Denominator__c));
                territoryKPIWithValuesMap.get(key).put('Achievement__c' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Achievement__c')) + EDGE_UtilityClass.checkForNull(outletKPIAchieve.Achievement__c));
                territoryKPIWithValuesMap.get(key).put('Previous_Achievement__c' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Previous_Achievement__c')) + EDGE_UtilityClass.checkForNull(outletKPIAchieve.Previous_Achievement__c));
                territoryKPIWithValuesMap.get(key).put('Total' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Total')) + 1);
                //added as part of ES20-11839
                if(outletKPIAchieve.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_facings__c  == 'Facings in number' ){ 
                    territoryKPIWithValuesMap.get(key).put('Target_Number__c' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Target_Number__c')) + EDGE_UtilityClass.checkForNull(outletKPIAchieve.Target_Number__c));
                }
                else if((outletKPIAchieve.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_facings__c  == 'Facings in %' )|| outletKPIAchieve.KPI_Type__c == 'Volume' ){
                    territoryKPIWithValuesMap.get(key).put('Target__c' , EDGE_UtilityClass.checkForNull(territoryKPIWithValuesMap.get(key).get('Target__c')) + EDGE_UtilityClass.checkForNull(outletKPIAchieve.Target__c));
                    
                }
            }else{
                if(outletKPIAchieve.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_facings__c  == 'Facings in number' ){ 
                    territoryKPIWithValuesMap.put(key, new Map<String, Decimal> { 'Actual_Numerator__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Actual_Numerator__c) , 'Total_Denominator__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Total_Denominator__c) , 'Achievement__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Achievement__c), 'Target_Number__c' =>EDGE_UtilityClass.checkForNull(outletKPIAchieve.Target_Number__c), 'Previous_Achievement__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Previous_Achievement__c), 'Total' => 1});
                }
                else if((outletKPIAchieve.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_facings__c  == 'Facings in %' )|| outletKPIAchieve.KPI_Type__c == 'Volume' ){
                    territoryKPIWithValuesMap.put(key, new Map<String, Decimal> { 'Actual_Numerator__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Actual_Numerator__c) , 'Total_Denominator__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Total_Denominator__c) , 'Achievement__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Achievement__c), 'Target__c' =>EDGE_UtilityClass.checkForNull(outletKPIAchieve.Target__c), 'Previous_Achievement__c' => EDGE_UtilityClass.checkForNull(outletKPIAchieve.Previous_Achievement__c), 'Total' => 1});
                }
                
            }					
        }
        return territoryKPIWithValuesMap;
    }
  
}