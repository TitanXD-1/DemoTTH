/**
* Name: EDGE_LeaderboardOperations
* Req: ES20-4026 - Custom Leaderboard- Ranking at three levels-Team Level Ranking 
* History                                                            
* VERSION     AUTHOR              DATE              DETAIL
* 1.0         Dipanjan D          12/11/2019        Contains Generic Methods for National, Region and BU Level Leaderboard Calculation
* 2.0		  Sandip Ghosh		  15/06/2020		[ES20-6238]Perform calculation based on the Ranking Calculation field on the Market Settigs object
* 3.0         Saranya L           11/11/2021        Modified for ES20-11206 && ES20-11306
* 4.0		  Rajarshi Lahiri	  07/10/2022		ES20-13337
* 5.0		  Doman Murmu		  17/07/2023		142822
**/
public with sharing class EDGE_LeaderboardOperations {
    
    static Map<Id, KPI_Achivement__c> kpiMap = new Map<Id, KPI_Achivement__c>();
    //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
    static String RANKING_AS_PER_KPI_ACHIEVEMENT = 'Ranking as per KPI Achievement';
    static String RANKING_AS_PER_KPI_TARGET_FULFILLLMENT = 'Ranking as per KPI Target Fulfilment';
    //ES20-13337
    final static String SalesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String ActivationRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
    
    public static void calculateKPIRankings(Set<Id> territoyIdSet, String rankingCalculationType, Id defaultPickupOptionId){
        Set<String> kpiTypes = new Set<String>();        
        Map<Id, KPI_Achivement__c> kpiRegionMap = new Map<Id, KPI_Achivement__c>(); //NOPMD
        Map<Id, KPI_Achivement__c> kpiBUMap = new Map<Id, KPI_Achivement__c>(); //NOPMD
        
        //Iterating over Sales Area KPI Fields Mapping
        for(Sales_Area_KPI_Fields_Mapping__mdt kpiMeta : [SELECT KPI_Achievement_Type__c FROM Sales_Area_KPI_Fields_Mapping__mdt 
                                                          WHERE Leaderboard_KPI__c = True AND KPI_Achievement_Type__c != null])
        {            
            //Getting the KPIs included for Leaderboard Calculation
            kpiTypes.add(kpiMeta.KPI_Achievement_Type__c);
        }
        
        if(territoyIdSet != null && territoyIdSet.size() > 0){
            //kpiNationalMap = calcNationalRankings(territoyIdSet, kpiTypes);
            calcNationalRankings(territoyIdSet, kpiTypes, rankingCalculationType,defaultPickupOptionId);
            calculateRegionKPIRankings(territoyIdSet, kpiTypes, rankingCalculationType,defaultPickupOptionId);
            calculateBUKPIRankings(territoyIdSet, kpiTypes, rankingCalculationType,defaultPickupOptionId);
        }
        
        if(kpiMap != null && !kpiMap.isEmpty()){
            database.update(kpiMap.values());
        }
    }
    
    //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
    private static String returnDynQueryBasedOnRankingType(String soqlQuery, String rankingCalculationType){       
        if(rankingCalculationType != null){
            if(rankingCalculationType.equalsIgnoreCase(RANKING_AS_PER_KPI_ACHIEVEMENT)){
                soqlQuery = 'SELECT Achievement__c, '+ soqlQuery +', Achievement__c DESC';
            }else if(rankingCalculationType.equalsIgnoreCase(RANKING_AS_PER_KPI_TARGET_FULFILLLMENT)){
                soqlQuery = 'SELECT KPI_Target_Fulfillment__c, '+ soqlQuery +', KPI_Target_Fulfillment__c DESC';
            }
        }
        return soqlQuery;
    }
    //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
    // This method returns the field value to be used for comparison for ranking calculation
    private static Decimal returnCmpValBasedOnRankingType(KPI_Achivement__c kpiAchive, String rankingCalculationType){
        
        Decimal compareToValue;
        
        if(rankingCalculationType != null){
            if(rankingCalculationType.equalsIgnoreCase(RANKING_AS_PER_KPI_ACHIEVEMENT)){
                compareToValue = kpiAchive.Achievement__c;
            }else if(rankingCalculationType.equalsIgnoreCase(RANKING_AS_PER_KPI_TARGET_FULFILLLMENT)){
                compareToValue = kpiAchive.KPI_Target_Fulfillment__c;
            }
        }
        return compareToValue;
    }
    //Method to calculate National Ranking
    public static Map<Id, KPI_Achivement__c> calcNationalRankings(Set<Id> territoyIdSet, Set<String> kpiTypes, String rankingCalculationType,Id defaultPickupOptionId){
        
        Map<String,Integer> kpiTypeToRankMap = new Map<String,Integer>();
        Map<String,Decimal> prevRankTrackerMap = new Map<String,Decimal>();
        List<Id> allowedTerrTypes;
        allowedTerrTypes=new List<Id>{SalesRecordTypeId,ActivationRecordTypeId};//ES20-13337
        
        //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        String soqlQuery = ' Id, KPI_Type__c, Territory__c, Territory__r.Region__c,' 
            +' Territory__r.Business_Unit__c, Current_BU_Ranking__c, Current_Region_Ranking__c,'
            +' Current_National_Ranking__c,Territory__r.Leaderboard_Grouping__c FROM KPI_Achivement__c'
            +' WHERE Territory__c IN :territoyIdSet AND KPI_Type__c IN :kpiTypes AND Territory__r.RecordTypeId IN:allowedTerrTypes'
            +' ORDER By  KPI_Type__c'; //removed Territory__r.Leaderboard_Grouping__c,
        
        soqlQuery = returnDynQueryBasedOnRankingType(soqlQuery, rankingCalculationType);
        for(KPI_Achivement__c kpiAchive : Database.query(String.escapeSingleQuotes(soqlQuery)))		//142822 added String.escapeSingleQuotes
        {
            //added Territory__r.Leaderboard_Grouping__c to categorise on Leaderboard Group basis for ES20-8067
            kpiAchive.Previous_National_Ranking__c = checkForNull(kpiAchive.Current_National_Ranking__c);
            
            String kpiTypeGroupId = kpiAchive.KPI_Type__c + '_' + (kpiAchive.Territory__r.Leaderboard_Grouping__c!=null?kpiAchive.Territory__r.Leaderboard_Grouping__c:defaultPickupOptionId);//changed kpiType to kpiTypeGroupId and included + '_' + kpiAchive.Territory__r.Leaderboard_Grouping__c for ES20-8067            
            
            //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        	Decimal achvToBeComparedWith = returnCmpValBasedOnRankingType(kpiAchive, rankingCalculationType);
            
            if(kpiTypeToRankMap.containsKey(kpiTypeGroupId)){
                Integer nationalRank = kpiTypeToRankMap.get(kpiTypeGroupId);
                Decimal lastEntryScore = prevRankTrackerMap.get(kpiTypeGroupId);
				            	
                //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
                if(lastEntryScore == achvToBeComparedWith){ //kpiAchive.Achievement__c
                    kpiAchive.Current_National_Ranking__c = nationalRank; 
                }else{
                    kpiAchive.Current_National_Ranking__c = ++nationalRank;
                    kpiTypeToRankMap.put(kpiTypeGroupId, nationalRank); 
                }                                                  
            }else{
                kpiTypeToRankMap.put(kpiTypeGroupId, 1);
                kpiAchive.Current_National_Ranking__c = 1;
            }
            //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
            prevRankTrackerMap.put(kpiTypeGroupId, achvToBeComparedWith); //kpiAchive.Achievement__c
            kpiMap.put(kpiAchive.Id, kpiAchive);       
        }
        return kpiMap;
    }   
    
    //Method to calculate Region Ranking
    public static Map<Id, KPI_Achivement__c> calculateRegionKPIRankings(Set<Id> territoyIdSet , Set<String> kpiTypes, String rankingCalculationType,Id defaultPickupOptionId){
        
        Map<String, KPI_Achivement__c> rankKPIIdToKPIAchvMAP = new Map<String, KPI_Achivement__c>();
        Map<String,Integer> regToMaxRankCtrMap = new Map<String,Integer>();
        Map<String,Decimal> prevRankTrackerMap = new Map<String,Decimal>();
        List<Id> allowedTerrTypes;
        allowedTerrTypes=new List<Id>{SalesRecordTypeId};//ES20-13337
        //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        String soqlQuery = ' Id, KPI_Type__c, Territory__c,Territory__r.Leaderboard_Grouping__c, Territory__r.Region__c,' 
                                          +' Territory__r.Business_Unit__c, Current_BU_Ranking__c, Current_Region_Ranking__c,'
                                          +' Current_National_Ranking__c FROM KPI_Achivement__c '
                                          +' WHERE Territory__c IN :territoyIdSet AND KPI_Type__c IN :kpiTypes AND Territory__r.RecordTypeId IN:allowedTerrTypes' 
                                          +' ORDER By  Territory__r.Region__c DESC, KPI_Type__c';//removed Territory__r.Leaderboard_Grouping__c,
        
        soqlQuery = returnDynQueryBasedOnRankingType(soqlQuery, rankingCalculationType);        
        
        for(KPI_Achivement__c kpiAchive : Database.query(String.escapeSingleQuotes(soqlQuery)))		//142822 added String.escapeSingleQuotes
        {
            //added Territory__r.Leaderboard_Grouping__c to categorise on Leaderboard Group basis for ES20-8067            
            KPI_Achivement__c tempKPIAchieve = kpiMap.get(kpiAchive.Id);
            //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        	Decimal achvToBeComparedWith = returnCmpValBasedOnRankingType(kpiAchive, rankingCalculationType);
            if(tempKPIAchieve != null){
                tempKPIAchieve.Previous_Region_Ranking__c = checkForNull(kpiAchive.Current_Region_Ranking__c);
                
                String hierarchyId = kpiAchive.KPI_Type__c+ '_' +kpiAchive.Territory__r.Region__c+ '_'+ (kpiAchive.Territory__r.Leaderboard_Grouping__c!=null?kpiAchive.Territory__r.Leaderboard_Grouping__c:defaultPickupOptionId);//included + '_' + kpiAchive.Territory__r.Leaderboard_Grouping__c for ES20-8067
                
                if(regToMaxRankCtrMap.containsKey(hierarchyId)){
                    Integer hierarchyRank = regToMaxRankCtrMap.get(hierarchyId);
                    Decimal lastEntryScore = prevRankTrackerMap.get(hierarchyId);
                    
                    //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
                    if(lastEntryScore == achvToBeComparedWith){ //kpiAchive.Achievement__c
                        tempKPIAchieve.Current_Region_Ranking__c = hierarchyRank; 
                    }else{
                        tempKPIAchieve.Current_Region_Ranking__c = ++hierarchyRank;
                        regToMaxRankCtrMap.put(hierarchyId, hierarchyRank);
                    } 
                }else{
                    regToMaxRankCtrMap.put(hierarchyId, 1);
                    tempKPIAchieve.Current_Region_Ranking__c = 1;
                }
                //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
                prevRankTrackerMap.put(hierarchyId, achvToBeComparedWith); // kpiAchive.Achievement__c
            }
        }
        return kpiMap;
    }
    
    //Method to calculate BU Ranking
    public static Map<Id, KPI_Achivement__c> calculateBUKPIRankings(Set<Id> territoyIdSet , Set<String> kpiTypes, String rankingCalculationType,Id defaultPickupOptionId){
        Map<String, KPI_Achivement__c> rankKPIIdToKPIAchvMAP = new Map<String, KPI_Achivement__c>();    //NOPMD
        Map<String,Integer> regToMaxRankCtrMap = new Map<String,Integer>();
        Map<String,Decimal> prevRankTrackerMap = new Map<String,Decimal>();            
        List<Id> allowedTerrTypes;
        allowedTerrTypes=new List<Id>{SalesRecordTypeId};//ES20-13337
        //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        String soqlQuery = ' Id, KPI_Type__c, Territory__c,Territory__r.Leaderboard_Grouping__c,'
                                           +' Territory__r.Region__c, Territory__r.Business_Unit__c, Current_BU_Ranking__c, Current_Region_Ranking__c,'
                                           +' Current_National_Ranking__c FROM KPI_Achivement__c'
                                           +' WHERE Territory__c IN :territoyIdSet AND KPI_Type__c IN :kpiTypes AND Territory__r.RecordTypeId IN:allowedTerrTypes' 
                                           +' ORDER By Territory__r.Business_Unit__c DESC, KPI_Type__c';//removed Territory__r.Leaderboard_Grouping__c,
        
        soqlQuery = returnDynQueryBasedOnRankingType(soqlQuery, rankingCalculationType);
        
        for(KPI_Achivement__c kpiAchive : Database.query(String.escapeSingleQuotes(soqlQuery)))		//142822 added String.escapeSingleQuotes
        {
            //added Territory__r.Leaderboard_Grouping__c to categorise on Leaderboard Group basis for ES20-8067
            KPI_Achivement__c tempKPIAchieve = kpiMap.get(kpiAchive.Id);
            //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        	Decimal achvToBeComparedWith = returnCmpValBasedOnRankingType(kpiAchive, rankingCalculationType);
            if(tempKPIAchieve != null){
                tempKPIAchieve.Previous_BU_Ranking__c = checkForNull(kpiAchive.Current_BU_Ranking__c);
                String hierarchyId = kpiAchive.KPI_Type__c+ '_' +kpiAchive.Territory__r.Business_Unit__c+ '_' + (kpiAchive.Territory__r.Leaderboard_Grouping__c!=null?kpiAchive.Territory__r.Leaderboard_Grouping__c:defaultPickupOptionId);//included + '_' + kpiAchive.Territory__r.Leaderboard_Grouping__c for ES20-8067
                Decimal lastEntryScore = prevRankTrackerMap.get(hierarchyId);
                if(regToMaxRankCtrMap.containsKey(hierarchyId)){
                    Integer hierarchyRank = regToMaxRankCtrMap.get(hierarchyId);
                    //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
                    if(lastEntryScore == achvToBeComparedWith){ //kpiAchive.Achievement__c
                        tempKPIAchieve.Current_BU_Ranking__c = hierarchyRank; 
                    }else{
                        tempKPIAchieve.Current_BU_Ranking__c = ++hierarchyRank;
                        regToMaxRankCtrMap.put(hierarchyId, hierarchyRank);
                    }
                }else{
                    regToMaxRankCtrMap.put(hierarchyId, 1);
                    tempKPIAchieve.Current_BU_Ranking__c = 1;
                }
                //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
                prevRankTrackerMap.put(hierarchyId, achvToBeComparedWith); //kpiAchive.Achievement__c
            }
        }        
        return kpiMap;
    }    
    
    public static Decimal checkForNull(Decimal daysValue){
        return EDGE_UtilityClass.checkForNull(daysValue);
    }   
    public static void calculateKPIRankings(Set<Id> userIdset, String rankingCalculationType){
        //Variables
        Set<String> kpiTypes = new Set<String>();        //NOPMD
        Map<Id, KPI_Achivement__c> kpiRegionMap = new Map<Id, KPI_Achivement__c>(); //NOPMD
        Map<Id, KPI_Achivement__c> kpiBUMap = new Map<Id, KPI_Achivement__c>(); //NOPMD
        
        //Iterating over Quality Area KPI Fields Mapping
        for(Quality_KPI_Fields_Mapping__mdt qualityKpiMeta : [SELECT KPI_Achievement_Type__c 
                                                              FROM Quality_KPI_Fields_Mapping__mdt
                                                              WHERE Leaderboard_KPI__c = true 
                                                              AND KPI_Achievement_Type__c != null]){
            kpiTypes.add(qualityKpiMeta.KPI_Achievement_Type__c);    
        }
        if(userIdset != null && userIdset.size() > 0){
            calcNationalRankings(userIdset, kpiTypes, rankingCalculationType);
            calculateRegionKPIRankings(userIdset, kpiTypes, rankingCalculationType);
        }
        
        if(kpiMap != null && !kpiMap.isEmpty()){
            database.update(kpiMap.values());
        }
    }
    public static Map<Id, KPI_Achivement__c> calcNationalRankings(Set<Id> userIdSet, Set<String> kpiTypes, String rankingCalculationType){
        //Variables
        Map<String,Integer> kpiTypeToRankMap = new Map<String,Integer>();
        Map<String,Decimal> prevRankTrackerMap = new Map<String,Decimal>();
        List<string> profileList = new List<String>();
        List<string> recTypeList = new List<String>();
        String profilesStr = Label.EDGE_UserKPILeaderBoardCalcBatchProfile;    
        if(profilesStr != null){
           profileList = profilesStr.split(','); 
        }
        String recTypeStr = Label.KPI_Achievement_RecType;    
        if(recTypeStr != null){
           recTypeList = recTypeStr.split(','); 
        }
        String soqlQuery = ' Id, KPI_Type__c, User__c,' 
            +'  Current_BU_Ranking__c, Current_Region_Ranking__c,'
            +' Current_National_Ranking__c FROM KPI_Achivement__c'
            +' WHERE User__c IN :userIdSet AND KPI_Type__c IN :kpiTypes'
            +'  AND User__r.Profile.Name IN : profileList'
           	+' AND RecordType.Name IN :recTypeList'                   
            +' ORDER BY  KPI_Type__c'; 
        
        soqlQuery = returnDynQueryBasedOnRankingType(soqlQuery, rankingCalculationType);
        for(KPI_Achivement__c kpiAchive : Database.query(String.escapeSingleQuotes(soqlQuery))){	//142822 added String.escapeSingleQuotes
            kpiAchive.Previous_National_Ranking__c = checkForNull(kpiAchive.Current_National_Ranking__c);
            String kpiTypeGroupId = kpiAchive.KPI_Type__c;
            Decimal achvToBeComparedWith = returnCmpValBasedOnRankingType(kpiAchive, rankingCalculationType);
            if(kpiTypeToRankMap.containsKey(kpiTypeGroupId)){
                Integer nationalRank = kpiTypeToRankMap.get(kpiTypeGroupId);
                Decimal lastEntryScore = prevRankTrackerMap.get(kpiTypeGroupId);
				if(lastEntryScore == achvToBeComparedWith){ //kpiAchive.Achievement__c
                    kpiAchive.Current_National_Ranking__c = nationalRank; 
                }else{
                    kpiAchive.Current_National_Ranking__c = ++nationalRank;
                    kpiTypeToRankMap.put(kpiTypeGroupId, nationalRank); 
                }                                                  
            }else{
                kpiTypeToRankMap.put(kpiTypeGroupId, 1);
                kpiAchive.Current_National_Ranking__c = 1;
            }
            prevRankTrackerMap.put(kpiTypeGroupId, achvToBeComparedWith); //kpiAchive.Achievement__c
            kpiMap.put(kpiAchive.Id, kpiAchive);       
        }
        return kpiMap;
    }
    //Method to calculate Region Ranking for USerKPI Achievement
    public static Map<Id, KPI_Achivement__c> calculateRegionKPIRankings(Set<Id> userIdSet , Set<String> kpiTypes, String rankingCalculationType){
        //Variables
        Map<String, KPI_Achivement__c> rankKPIIdToKPIAchvMAP = new Map<String, KPI_Achivement__c>();    //NOPMD
        Map<String,Integer> regToMaxRankCtrMap = new Map<String,Integer>();
        Map<String,Decimal> prevRankTrackerMap = new Map<String,Decimal>();
        List<string> recTypeList = new List<String>();
        List<string> profileList = new List<String>();
        String profilesStr = Label.EDGE_UserKPILeaderBoardCalcBatchProfile;    
        if(profilesStr != null){
           profileList = profilesStr.split(','); 
        }
        String recTypeStr = Label.KPI_Achievement_RecType;    
        if(recTypeStr != null){
           recTypeList = recTypeStr.split(','); 
        }
        String soqlQuery = ' Id, KPI_Type__c, User__c,User__r.ManagerId,' 
           				 +' Current_BU_Ranking__c, Current_Region_Ranking__c,'
           				 +' Current_National_Ranking__c FROM KPI_Achivement__c '
           				 +' WHERE User__c IN :userIdSet AND KPI_Type__c IN :kpiTypes'
           				 +' AND User__r.Profile.Name IN : profileList'
           				 +' AND RecordType.Name IN :recTypeList'                   
            			 +' ORDER BY  User__r.ManagerId DESC, KPI_Type__c';
        
        soqlQuery = returnDynQueryBasedOnRankingType(soqlQuery, rankingCalculationType);        
        for(KPI_Achivement__c kpiAchive : Database.query(String.escapeSingleQuotes(soqlQuery))){	//142822 added String.escapeSingleQuotes
            KPI_Achivement__c tempKPIAchieve = kpiMap.get(kpiAchive.Id);
            Decimal achvToBeComparedWith = returnCmpValBasedOnRankingType(kpiAchive, rankingCalculationType);
            if(tempKPIAchieve != null){
                tempKPIAchieve.Previous_Region_Ranking__c = checkForNull(kpiAchive.Current_Region_Ranking__c);
                String hierarchyId = kpiAchive.KPI_Type__c+ '_' +kpiAchive.User__r.ManagerId;
                if(regToMaxRankCtrMap.containsKey(hierarchyId)){
                    Integer hierarchyRank = regToMaxRankCtrMap.get(hierarchyId);
                    Decimal lastEntryScore = prevRankTrackerMap.get(hierarchyId);
                    if(lastEntryScore == achvToBeComparedWith){ //kpiAchive.Achievement__c
                        tempKPIAchieve.Current_Region_Ranking__c = hierarchyRank; 
                    }else{
                        tempKPIAchieve.Current_Region_Ranking__c = ++hierarchyRank;
                        regToMaxRankCtrMap.put(hierarchyId, hierarchyRank);
                    } 
                }else{
                    regToMaxRankCtrMap.put(hierarchyId, 1);
                    tempKPIAchieve.Current_Region_Ranking__c = 1;
                }
                prevRankTrackerMap.put(hierarchyId, achvToBeComparedWith); // kpiAchive.Achievement__c
            }
        }
        return kpiMap;
    }
}