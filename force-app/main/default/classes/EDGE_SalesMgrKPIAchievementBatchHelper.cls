/**
* @Name: EDGE_SalesMgrKPIAchievementBatchHelper

* @History                                                            

* @VERSION     AUTHOR              DATE            DETAIL
*  1.0         Juned Khan          01/12/2020      ES20-8787  
*  2.0 		   Juned Khan		   08/01/2021	   ES20-9359 UAT_For Total Activation Survey KPI at AT level , total denominator is considering inactive outlets also
*  3.0         Dinesh Sharma       07/05/2021      ES20-10210 Bug for Binary Calculation
*  4.0         Anand Uppalapati    02/11/2021      ES20-11187
*  5.0         Anamika Shukla      02/11/2021      ES20-11202
*  6.0         Anand Uppalapati    11/29/2021      ES20-11203
*  7.0		   Subhodeep Sarkar    23/02/2022      ES20-11840 (Territory Heirarchy_SOS batch logic change for targets_SFDC_SOS Enhancements)
*  8.0         Monalisa Halder     22/03/2022      ES20-12221
*  9.0 		   Aparajita		   25/03/2022	   ES20-12223 
*  10.0		   Prasanth T		   25/03/2022	   ES20-12218
*  11.0		   Aparajita		   09/06/2022      ES20-12821(Restricting KPI calculation for Planned & Virtual calls at Region level)		   
*  12.0        Joshraj Sen         06/07/2022      ES20-13098(To consider the calculation of Territory Hierarchy KPIs for KPI Type Distribution,OES,MPA,MAS,NPD,Asset,Outlet Visit Compliance,Asset)

**/
public class EDGE_SalesMgrKPIAchievementBatchHelper {
    
    //Get Record Type ID
    static Id territoryRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Territory_KPI').getRecordTypeId();
    static Id territoryHierarchyRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Territory_Hierarchy_KPI').getRecordTypeId();
    static Id surveyRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Survey_KPI').getRecordTypeId();// added by juned
    //static Id activationRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Activation_Territory').getRecordTypeId();//ES20-ES20-12223,ES20-12221
    
    public static void calculateTerrHierarchyKPIs(List<Territory_Hierarchy__c> lstTerritoryHierarchy,boolean isRegion, String regionType){
        string queryFieldsString = '';
        Id countryId = lstTerritoryHierarchy[0].Geography__c;
        Map<Id, Territory_Hierarchy__c> terrHierMap = new Map<Id, Territory_Hierarchy__c>(lstTerritoryHierarchy);
        Set<Id> terrHierSetIds = terrHierMap.keySet(); //contains act terr hie ids
        Set<Id> territorySetIds = new Set<Id>();
        Map<Id, Set<Id>> hierarchyWithTerritoryMap = new Map<Id, Set<Id>>();
        Map<String, Decimal> regionKPIsNumMap = new Map<String, Decimal>();
        Map<String, Decimal> regionKPIsDenomMap = new Map<String, Decimal>(); 
        Map<String, Decimal> regionKPIsActualMap = new Map<String, Decimal>();
        Map<String, Decimal> regionKPIsPrevActualMap = new Map<String, Decimal>();
        Map<String, Decimal> regionKPIsTargetMap =  new Map<String, Decimal>();
        Map<String, Id> hierarchyKPIAchievements = new Map<String, Id>();
        Map<String, String> kpisWithTargetFieldsMap = new Map<String, String>();    
        List<KPI_Achivement__c> kpiAchieveHierList = new List<KPI_Achivement__c>();
        Set<String> categoryKPIs = new Set<String> {'SoS','Volume Category Performance'};
        Set<String> surveyKPIs = new Set<String> {'Survey', 'Activation Survey KPI'}; 
        Map<Id,Set<Id>> existingUserManagermap = new Map<Id,Set<Id>>();//ES20-8415 change
        Set<String> recordTypeNameSet = new Set<String>{'Territory_Hierarchy_KPI'};
        String virtualCallComp = 'Virtual Call Compliance';
        Map<String, Decimal> activationKPIsNumMap = new Map<String, Decimal>();// added by juned
        Map<String, Decimal> surveyKPIsNumMap = new Map<String, Decimal>();// added by juned
        Map<String, Decimal> activationKPIsDenomMap = new Map<String, Decimal>();// added by juned
        Map<String, Decimal> surveyKPIsDenomMap = new Map<String, Decimal>();// added by juned
        Map<String, Decimal> activationKPIsActualMap = new Map<String, Decimal>();// added by juned
        Map<String, Decimal> surveyKPIsActualMap = new Map<String, Decimal>();// added by juned
        Set<String> recordTypeASNameSet = new Set<String>{'Survey_KPI','Territory_KPI','Territory_Hierarchy_KPI'};// added by juned
        //Set<String> TotalandVirtualKPIs = new Set<String> {'Virtual Call Compliance','Total Activation Survey','Asset'}; //added by juned->'Total Activation Survey' //ES20-12821->Removed un-used variable
        Map<String, Id> existinghierarchyKPIAchievements = new Map<String, Id>();  // added by juned
        Map<String, KPI_Achivement__c> totalActivationKPIMap = new Map<String, KPI_Achivement__c>();
        Map<Id, Id> existingTotalActKPiAchvsMap = new Map<Id, Id> ();
        Map<String, Id> pickUpOptionMap= new Map<String, Id>();
        Map<Id, Boolean> surveyPickUpOptionMap= new Map<Id, Boolean>();
        Id surveyPickUpOptionId;//added by juned
        Id activationPickUpOptionId;//added by juned
        //Map<String, Decimal> actTerritoryToNoOfOutlets= new Map<String, Decimal>(); //ES20-ES20-12223,ES20-12221
        //Map<Id, Decimal> regionToOutletsCountMap = new Map<Id, Decimal>(); //ES20-ES20-12223,ES20-12221
        Map<Id, Decimal> regionToOutletsCountQueryMap = new Map<Id, Decimal>();
        Map<String, List<String>> kpiAchivementFieldsMap = new Map<String, List<String>>();
        Map<String, Sales_Area_KPI_Fields_Mapping__mdt> kpiFieldsMap = new Map<String, Sales_Area_KPI_Fields_Mapping__mdt>();
        Map<String,String> kpiTypeToCalcTypeMap = new Map<String,String>();
        List<Market_Setting__c> marketSettingList = new List<Market_Setting__c>();
        //Map<Id, Decimal> regionToOutletsCountQueryMap = new Map<Id, Decimal>();
        
        List<String> excludedKPIFromRegionList = Label.EDGE_ExcludedKPIFromMetadata.split(';'); //ES20-12821
        
        //Fetching Market Settings for Country ES20-10210
        if(Schema.SObjectType.Market_Setting__c.isAccessible() && Schema.SObjectType.Geography__c.isAccessible() ){
            
            
            marketSettingList = [Select Id, Geography__c,Outlet_Execution_Score__c, Minimum_Activation_Standards__c, Minimum_Product_Assortment__c, Distribution__c, 
                                                         Share_Of_Space__c,Share_of_Space_Facings__c, New_Product_Distribution__c from Market_Setting__c 
                                                         WHERE Geography__c = :countryId LIMIT 1];
            
            //Iterating over Sales Area KPI Fields Mapping ES20-10210
            if(Schema.SObjectType.Sales_Area_KPI_Fields_Mapping__mdt.isAccessible()){
                for(Sales_Area_KPI_Fields_Mapping__mdt kpiMap : [SELECT MasterLabel, Account_KPI_Field__c, Operation_Type__c, Calculation_Type__c, 
                                                                 Relationship__c, Market_Settings_Reference__c, Check_for_Null__c, KPI_Achievement_Type__c, 
                                                                 Dependent_Field__c, Fraction_Variant__c, Territory_Target_Fields__c, Territory_Cycle_Target_Field__c 
                                                                 FROM Sales_Area_KPI_Fields_Mapping__mdt WHERE KPI_Achievement_Type__c != null AND Active__c = True
                                                                 AND KPI_Achievement_Type__c NOT IN : excludedKPIFromRegionList]){ //ES20-12821

                    //Mapping Account KPI fields with KPI Mapping instance
                    kpiFieldsMap.put(kpiMap.Account_KPI_Field__c, kpiMap); // kpiFieldsMap={Volume_Actual_Points__c:kpiMap} for VTP; no data for SOS and VCP
                    
                }
            }
            
            // Get Calculation Type ES20-10210
            for(String fieldName : kpiFieldsMap.keySet()){
                String calcType = '';
                Sales_Area_KPI_Fields_Mapping__mdt kpiMapItem = kpiFieldsMap.get(fieldName); 
                if(kpiMapItem.Market_Settings_Reference__c != null){
                    calcType = string.valueOf(marketSettingList[0].get(kpiMapItem.Market_Settings_Reference__c));
                    kpiTypeToCalcTypeMap.put(kpiMapItem.KPI_Achievement_Type__c,calcType);
                }else{
                    kpiTypeToCalcTypeMap.put(kpiMapItem.KPI_Achievement_Type__c,kpiMapItem.Calculation_Type__c); //Comes here and kpiTypeToCalcTypeMap={Volume Target Performance:Progressive}; no data for SOS and VCP
                }                
            }
        }
        
        //Region level metadata
        //Get Custom Metadata to get KPI Target Fields API Name
        if(isRegion){//Target from metadata required for Region
            if(Schema.SObjectType.Region_KPI_Mapping__mdt.isAccessible()){
                for(Region_KPI_Mapping__mdt regionKPIs : [SELECT MasterLabel, Hierarchy_Target_Field__c FROM Region_KPI_Mapping__mdt WHERE Active__c = True
                                                          AND MasterLabel NOT IN : excludedKPIFromRegionList]){ //ES20-12821
                    kpisWithTargetFieldsMap.put(regionKPIs.MasterLabel, regionKPIs.Hierarchy_Target_Field__c); //kpisWithTargetFieldsMap={SoS,NULL}; no data for VTP/VCP
                }
            }
        }


        /*
        if(!isRegion){// Only required for Activation Territory and 'Total Activation Survey' kpi type


            for(KPI_Achivement__c existingTotalActKPiAchv : [Select Id,Region__c from KPI_Achivement__c where 
                                                             Region__r.RecordType.Name = 'Activation Territory' AND 
                                                             KPI_Type__c != null and KPI_Type__c in ('Total Activation Survey')
                                                             AND Region__c in :terrHierSetIds])
            {
                existingTotalActKPiAchvsMap.put(existingTotalActKPiAchv.Region__c, existingTotalActKPiAchv.Id);                                  
            }
            //ES20-9359 UAT_For Total Activation Survey KPI at AT level , total denominator is considering inactive outlets also
            for(Account outlet : [Select Id,Activation_Territory__c,Status__c,Primary_Sales_Territory__r.Activation_Territory__c from Account where 
                                  Primary_Sales_Territory__r.Activation_Territory__c in :terrHierSetIds and RecordType.Name = 'Outlet' and Status__c ='Active'])
            {//AT Level
                if(!regionToOutletsCountQueryMap.containsKey(outlet.Primary_Sales_Territory__r.Activation_Territory__c)){
                    regionToOutletsCountQueryMap.put(outlet.Primary_Sales_Territory__r.Activation_Territory__c, 1);
                }else{
                    Decimal tempCount = regionToOutletsCountQueryMap.get(outlet.Primary_Sales_Territory__r.Activation_Territory__c);
                    tempCount++;
                    regionToOutletsCountQueryMap.put(outlet.Primary_Sales_Territory__r.Activation_Territory__c, tempCount);
                }                         
            }
        }
        */
        String queryString = 'SELECT Id, RecordType.DeveloperName, Territory__c,Territory__r.Activation_Territory__c, Region__c, Achievement__c, Previous_Achievement__c, Target__c, Target_Number__c, Target_Derived__c, Actual_Numerator__c, Total_Denominator__c, Country__c, KPI_Type__c, Category__c, Volume_Category__c, Survey_KPI__r.Applicable_Business_Role__c, Activation_Type__r.Applicable_Business_Role__c, Region__r.RecordTypeId, Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c ,Master_Asset__c '+
            + ' FROM KPI_Achivement__c WHERE (RecordType.DeveloperName IN';
        if(isRegion){//Sales & Quality
            queryString += ' :recordTypeNameSet OR (RecordType.DeveloperName=\'Territory_KPI\' AND Territory__r.Status__c=\'Active\')) AND Region__c IN :terrHierSetIds AND  KPI_Type__c NOT IN :surveyKPIs';
        }
        
        //ES20-12223 -> Commented the below code 
        /*else{// Activation Territory Level
            queryString += ' :recordTypeASNameSet) AND (Territory__r.Activation_Territory__c IN :terrHierSetIds OR Region__c IN :terrHierSetIds ) AND KPI_Type__c NOT IN :TotalandVirtualKPIs'; //+
            //+' AND (Survey_KPI__r.Applicable_Business_Role__c =\'Activation Specialist\' OR Activation_Type__r.Applicable_Business_Role__c =\'Activation Specialist\')'; //added by juned
        }*/ //replaced with dynamic query by Shahbaz & Juned
        
        //Process KPI Achievement Records
        for(KPI_Achivement__c kpiAchieve : Database.query(queryString))
        {
            String regionIdWithKPI = '';
            
            if(isRegion){//Sales & Quality //conditional based unique key generation
                //System.debug('kpi Achievement '+kpiAchieve);
                if(kpiAchieve.KPI_Type__c == 'SoS'){//conditional based unique key generation
                    regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c + '_' + kpiAchieve.Category__c;  
                }else if(kpiAchieve.KPI_Type__c == 'Volume Category Performance'){
                    regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c + '_' + kpiAchieve.Volume_Category__c;
                }else if(kpiAchieve.KPI_Type__c == 'Asset'){//ES20-11202
                    regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c + '_' + kpiAchieve.Master_Asset__c;
                }else{
                    regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c;
                    //System.debug('@165Coverage'+regionIdWithKPI);
                }
            }  
            
            //ES20-12223 -> Commented the below code
            /*
            else{//AT Level
                String regionTerrKey = kpiAchieve.Territory__r.Activation_Territory__c + '_' + kpiAchieve.Territory__c; 
                
                 //ES20-12223 -> Commented the below code
                /*if(kpiAchieve.KPI_Type__c == 'SoS'){
                    if(kpiAchieve.RecordType.DeveloperName == 'Territory_KPI'){
                        regionIdWithKPI = kpiAchieve.Territory__r.Activation_Territory__c + '_' + kpiAchieve.KPI_Type__c + '_' + kpiAchieve.Category__c;
                    }else{//for existing Activation Territory KPI achievement records
                        regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c + '_' + kpiAchieve.Category__c;
                    }
                }
                //ES20-12218 -> Commented the below code
                if(kpiAchieve.RecordType.DeveloperName == 'Survey_KPI'){/*12218
                    surveyPickUpOptionMap.put(kpiAchieve.Survey_KPI__c,kpiAchieve.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c);
                    //added by juned
                    if(kpiAchieve.Territory__c!=null && kpiAchieve.Territory__r.Activation_Territory__c!=null && kpiAchieve.Survey_KPI__c!=null){
                        if(!actTerritoryToNoOfOutlets.containsKey(regionTerrKey)){
                            actTerritoryToNoOfOutlets.put(regionTerrKey,kpiAchieve.Total_Denominator__c);
                        }
                        //Territory level Survey KPI type KPI Achievement record 
                        regionIdWithKPI = kpiAchieve.Territory__r.Activation_Territory__c + '_' + kpiAchieve.KPI_Type__c+'_'+kpiAchieve.Survey_KPI__c;
                    }
                    else{// Existing Survey KPI record at AT level
                        regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c+'_'+kpiAchieve.Survey_KPI__c;
                    }
                }
                else{//MAS, MPA, Distribution, OES, Activation Survey KPI, Asset
                    if(kpiAchieve.RecordType.DeveloperName == 'Territory_KPI'){// territory level
                        //Activation Survey KPI
                        if(!actTerritoryToNoOfOutlets.containsKey(regionTerrKey)){// added by juned
                            Id terrId=regionTerrKey.substringAfter('_');
                            
                            actTerritoryToNoOfOutlets.put(regionTerrKey,kpiAchieve.Total_Denominator__c);
                        }
                        if(kpiAchieve.KPI_Type__c =='Activation Survey KPI' && kpiAchieve.Activation_Type__c !=null ){
                            /* //ES20-12218
                            regionIdWithKPI = kpiAchieve.Territory__r.Activation_Territory__c + '_'+ kpiAchieve.KPI_Type__c+ '_' + kpiAchieve.Activation_Type__c;
                        }else if(kpiAchieve.KPI_Type__c=='Asset'){
                            regionIdWithKPI = kpiAchieve.Territory__r.Activation_Territory__c + '_'+ kpiAchieve.KPI_Type__c + '_'+kpiAchieve.Master_Asset__c;
                        } 
                        //commented for ES20-12221
                       /* else{//MAS, MPA, Distribution, OES
                            regionIdWithKPI = kpiAchieve.Territory__r.Activation_Territory__c + '_'+ kpiAchieve.KPI_Type__c;
                        }
                    }else{//AT level, for existing Activation Territory KPI achievement records
                        //Activation Survey KPI
                        if(kpiAchieve.KPI_Type__c =='Activation Survey KPI' && kpiAchieve.Activation_Type__c !=null ){
                            /* //ES20-12218
                            regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c+ '_' + kpiAchieve.Activation_Type__c;  
                        }
                        else{//MAS, MPA, Distribution, OES
                            regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c;
                        }
                    }
                }
            }
            */
            //String regionIdWithKPI = kpiAchieve.Region__c + '_' + kpiAchieve.KPI_Type__c + (kpiAchieve.KPI_Type__c != 'SoS'? '' : '_' + kpiAchieve.Category__c);
            
            //Process Territory KPI Record to calculate Territory Hierarchy KPI
            if(kpiAchieve.RecordType.DeveloperName == 'Territory_KPI'){
                
                if(kpiAchieve.KPI_Type__c != 'Activation Survey KPI' 
                   
                   //ES20-12218 -> Commented the below code 
                   /*|| (kpiAchieve.KPI_Type__c == 'Activation Survey KPI' &&  kpiAchieve.Activation_Type__r.Applicable_Business_Role__c == 'Activation Specialist')*/){
                    
                    //Calculate Numerator for KPI
                    populateKPIMaps(regionKPIsNumMap, regionIdWithKPI, kpiAchieve.Actual_Numerator__c);
                    //Calculate Denominator for KPI
                    populateKPIMaps(regionKPIsDenomMap, regionIdWithKPI, kpiAchieve.Total_Denominator__c);
                    //Calculate Actual for KPI
                    populateKPIMaps(regionKPIsActualMap, regionIdWithKPI, kpiAchieve.Achievement__c);
    
                    //ES20-12218 -> Commented the below code 
                    /*if(kpiAchieve.Activation_Type__r.Applicable_Business_Role__c == 'Activation Specialist'){
                         
                        //activationPickUpOptionId=kpiAchieve.Activation_Type__c;
                        pickUpOptionMap.put(kpiAchieve.Territory__r.Activation_Territory__c+'_'+kpiAchieve.Activation_Type__c,kpiAchieve.Activation_Type__c);
                    }*/
                }	
                
                //Calculate Previous Actual for KPI
                if(isRegion){//previous is required only for Region level
                    if(regionKPIsPrevActualMap.containsKey(regionIdWithKPI)){
                        regionKPIsPrevActualMap.put(regionIdWithKPI, regionKPIsPrevActualMap.get(regionIdWithKPI) + checkValue(kpiAchieve.Previous_Achievement__c));
                    }else{
                        regionKPIsPrevActualMap.put(regionIdWithKPI, checkValue(kpiAchieve.Previous_Achievement__c));
                    }				
                }
                //Calculate Target for KPI -- Why are we iterating multiple times to get MAS/MPA Target ?
                if(kpisWithTargetFieldsMap.containsKey(kpiAchieve.KPI_Type__c) && kpisWithTargetFieldsMap.get(kpiAchieve.KPI_Type__c) != null ){             
                    regionKPIsTargetMap.put(regionIdWithKPI, (Decimal)terrHierMap.get(kpiAchieve.Region__c).get(kpisWithTargetFieldsMap.get(kpiAchieve.KPI_Type__c)));
                }else{ 
                    Decimal target = (kpiAchieve.KPI_Type__c == 'Total Activation Survey' || kpiAchieve.KPI_Type__c == 'Activation Survey KPI') ? checkValue(kpiAchieve.Target_Number__c)  : checkValue(kpiAchieve.Target__c);
                    if(regionKPIsTargetMap.containsKey(regionIdWithKPI)){//existing kpi achievement
                        if(kpiAchieve.KPI_Type__c =='SOS'){
                            Decimal value = (marketSettingList[0].Share_of_Space_Facings__c == 'Facings in %')?(regionKPIsTargetMap.get(regionIdWithKPI) + target) : (regionKPIsTargetMap.get(regionIdWithKPI) + checkValue(kpiAchieve.Target_Number__c));
                            regionKPIsTargetMap.put(regionIdWithKPI, value);
                        }
                        else{
                            regionKPIsTargetMap.put(regionIdWithKPI, regionKPIsTargetMap.get(regionIdWithKPI) + target);
                        }
                        
                    }else{//new kpi achievement
                        if(kpiAchieve.KPI_Type__c =='SOS'){
                            Decimal value = (marketSettingList[0].Share_of_Space_Facings__c == 'Facings in %')? target : checkValue(kpiAchieve.Target_Number__c);
                            regionKPIsTargetMap.put(regionIdWithKPI, value);
                        }
                        else{
                            regionKPIsTargetMap.put(regionIdWithKPI, target); 




                        } 
                    }
                }               
                
                //Get Territory Id's Set related to Territory Hierarchy
                if(isRegion){//split for both types of hierarchy
                    if(hierarchyWithTerritoryMap.containsKey(kpiAchieve.Region__c)){
                        hierarchyWithTerritoryMap.get(kpiAchieve.Region__c).add(kpiAchieve.Territory__c);
                    }else{
                        hierarchyWithTerritoryMap.put(kpiAchieve.Region__c, new Set<Id> { kpiAchieve.Territory__c } );
                    }
                }
                
                //ES20-12223 -> Commented the below code
                /*else{
                    if(hierarchyWithTerritoryMap.containsKey(kpiAchieve.Territory__r.Activation_Territory__c)){
                        hierarchyWithTerritoryMap.get(kpiAchieve.Territory__r.Activation_Territory__c).add(kpiAchieve.Territory__c);
                    }else{
                        hierarchyWithTerritoryMap.put(kpiAchieve.Territory__r.Activation_Territory__c, new Set<Id> { kpiAchieve.Territory__c } );
                    }
                }*/
            }
            
            //Process Survey KPI Record to calculate Territory Hierachy KPI
            // ES20-12218 -> Commented the below code
            /*if(kpiAchieve.RecordType.DeveloperName == 'Survey_KPI' && kpiAchieve.KPI_Type__c == 'Survey'){
                if(!isRegion){
                    
                      // Survey KPI calculation At Territory level only for Activation Territory added by juned
                    if(kpiAchieve.Survey_KPI__r.Applicable_Business_Role__c == 'Activation Specialist' 
                       && kpiAchieve.Territory__c!=null && kpiAchieve.Territory__r.Activation_Territory__c!=null)
                    {
                        // surveyPickUpOptionId=kpiAchieve.Survey_KPI__c;
                        pickUpOptionMap.put(kpiAchieve.Territory__r.Activation_Territory__c+'_'+kpiAchieve.Survey_KPI__c,kpiAchieve.Survey_KPI__c);
                        //Calculate Numerator for KPI
                        populateKPIMaps(regionKPIsNumMap, regionIdWithKPI, kpiAchieve.Actual_Numerator__c);
                        //Calculate Denominator for KPI
                        populateKPIMaps(regionKPIsDenomMap, regionIdWithKPI, kpiAchieve.Total_Denominator__c);
                        //Calculate Actual for KPI
                        populateKPIMaps(regionKPIsActualMap, regionIdWithKPI, kpiAchieve.Achievement__c);
                        //target calculation for survey kpi
                        Decimal target = (kpiAchieve.KPI_Type__c == 'Survey') ? checkValue(kpiAchieve.Target__c) : checkValue(kpiAchieve.Target_Number__c);
                        
                        populateKPIMaps(regionKPIsTargetMap, regionIdWithKPI, target);
                        
                    }else{ //Existing Activation Survey KPI calculation at AT level
                        if(kpiAchieve.Region__r.RecordTypeId == activationRecTypeId){
                            hierarchyKPIAchievements.put(regionIdWithKPI, kpiAchieve.Id);
                        }
                    }
                    
                }
            }*/
            
            //Get Existing Territory Hierarchy KPI Record Id
            if(kpiAchieve.RecordType.DeveloperName == 'Territory_Hierarchy_KPI'){
                hierarchyKPIAchievements.put(regionIdWithKPI, kpiAchieve.Id);
            }
        }
        

        
       //ES20-ES20-12223,ES20-12221 -> Commented below code
       /*for(String regionTerrKey : actTerritoryToNoOfOutlets.keySet()){


            String regionStr = regionTerrKey.substringBefore('_');
            if(!regionToOutletsCountMap.containsKey(regionStr)){
                regionToOutletsCountMap.put(regionStr, actTerritoryToNoOfOutlets.get(regionTerrKey));
            }else{
                if((actTerritoryToNoOfOutlets.get(regionTerrKey))!=null && regionToOutletsCountMap.get(regionStr)!=null){
                    Decimal tempOutletCount = regionToOutletsCountMap.get(regionStr);
                    tempOutletCount += actTerritoryToNoOfOutlets.get(regionTerrKey);
                    regionToOutletsCountMap.put(regionStr, tempOutletCount);
                }
            }
        }*/
        
        //ES20-11023
        Date currentDate = Date.today();
        Date yesterdayDate = currentDate.addDays(-1);    
        for(Territory_Member__c terrMem : [Select Id,User__c,Territory__r.Region__r.Name from Territory_Member__c 
                                           where Territory__r.Region__c in :hierarchyWithTerritoryMap.keySet() AND Start_Date__c <= :currentDate 
                                           AND (End_Date__c >= :yesterdayDate OR End_Date__c=null) order by Territory__r.Region__r.Name])
        {
            Id regionId = terrMem.Territory__r.Region__c;
            if(existingUserManagermap.containsKey(regionId)){
                existingUserManagermap.get(regionId).add(terrMem.User__c);
            }else{
                existingUserManagermap.put(regionId, new Set<Id>{terrMem.User__c});
            }
        }
        
        //Create KPI Achievement Records for upsert
        for(String regionIdWithKPI : regionKPIsNumMap.keySet()){
            KPI_Achivement__c kpiAchieveHier = new KPI_Achivement__c(Id = hierarchyKPIAchievements.containsKey(regionIdWithKPI) ? hierarchyKPIAchievements.get(regionIdWithKPI) : null);
     
            kpiAchieveHier.RecordTypeId = territoryHierarchyRTId;
            kpiAchieveHier.Region__c = regionIdWithKPI.substringBefore('_');
            //System.debug('@383kpiAchieveHier.Region__c'+kpiAchieveHier.Region__c);
            kpiAchieveHier.Country__c = countryId;
            if(categoryKPIs.contains(regionIdWithKPI.substringAfter('_').substringBefore('_'))){
                kpiAchieveHier.KPI_Type__c = regionIdWithKPI.substringAfter('_').substringBefore('_');
            }else if(regionIdWithKPI.substringAfter('_').substringBefore('_') =='Survey' 
                     || regionIdWithKPI.substringAfter('_').substringBefore('_') =='Activation Survey KPI'
                     || regionIdWithKPI.substringAfter('_').substringBefore('_') =='Asset'){
                         kpiAchieveHier.KPI_Type__c = regionIdWithKPI.substringAfter('_').substringBefore('_');
                     }else{
                         kpiAchieveHier.KPI_Type__c=  regionIdWithKPI.substringAfter('_');
                         //System.debug('@393kpiAchieveHier.KPI_Type__c'+kpiAchieveHier.KPI_Type__c);
                     }
            //kpiAchieveHier.KPI_Type__c = regionIdWithKPI.substringAfter('_').startsWith('SoS') ? regionIdWithKPI.substringAfter('_').substringBefore('_') : regionIdWithKPI.substringAfter('_');
            if(kpiAchieveHier.KPI_Type__c == 'SoS'){
                kpiAchieveHier.Category__c = regionIdWithKPI.substringAfter('_').substringAfter('_');  
            }else if(kpiAchieveHier.KPI_Type__c == 'Volume Category Performance'){
                kpiAchieveHier.Volume_Category__c = regionIdWithKPI.substringAfter('_').substringAfter('_');
            }else if(kpiAchieveHier.KPI_Type__c == 'Asset'){
                kpiAchieveHier.Master_Asset__c = regionIdWithKPI.substringAfter('_').substringAfter('_');
            }
            
            //ES20-12218 -> Commented the below code 
             /*else{
                //MAS,MPA,Distribution,OES,Survey,Activation KPI, Total Activation Survey
                if(!isRegion && kpiAchieveHier.KPI_Type__c == 'Survey'){//added by juned && !pickUpOptionMap.isEmpty()
                    kpiAchieveHier.RecordTypeId = surveyRTId;
                    for(String pickup: pickUpOptionMap.keySet()){
                        if(regionIdWithKPI.substringBefore('_') == pickup.substringBefore('_') && regionIdWithKPI.substringAfter('_').substringAfter('_')==pickup.substringAfter('_')){
                            kpiAchieveHier.Survey_KPI__c=pickUpOptionMap.get(pickup);
                        }
                    } 
                }
                if(!isRegion && kpiAchieveHier.KPI_Type__c == 'Activation Survey KPI' ){
                    //added by juned
                    for(String pickup: pickUpOptionMap.keySet()){
                        if(regionIdWithKPI.substringBefore('_') == pickup.substringBefore('_') && regionIdWithKPI.substringAfter('_').substringAfter('_')==pickup.substringAfter('_')){
                            kpiAchieveHier.Activation_Type__c=pickUpOptionMap.get(pickup);
                        }
                    }
                } 
                kpiAchieveHier.Category__c = '';
            }*/   
            
            kpiAchieveHier.Actual_Numerator__c = regionKPIsNumMap.get(regionIdWithKPI);
            kpiAchieveHier.Total_Denominator__c = regionKPIsDenomMap.get(regionIdWithKPI); 
            if(kpiAchieveHier.KPI_Type__c == 'Total Activation Survey'){               
                kpiAchieveHier.Target_Number__c = regionKPIsTargetMap.get(regionIdWithKPI);
            }else{
                if(regionKPIsTargetMap.get(regionIdWithKPI) != null && hierarchyWithTerritoryMap.get(kpiAchieveHier.Region__c) != null){                   
                    if(kpisWithTargetFieldsMap.containsKey(kpiAchieveHier.KPI_Type__c) && kpisWithTargetFieldsMap.get(kpiAchieveHier.KPI_Type__c) != null){
                        kpiAchieveHier.Target__c = regionKPIsTargetMap.get(regionIdWithKPI);                       
                    }else{
                        /*if(kpiAchieveHier.KPI_Type__c == 'Activation Survey KPI' ){ //kpiAchieveHier.KPI_Type__c == 'Total Activation Survey' ||
kpiAchieveHier.Target_Number__c = regionKPIsTargetMap.get(regionIdWithKPI);
}else{//Survey KPI*/
                        if(kpiAchieveHier.KPI_Type__c != 'Survey' && kpiAchieveHier.KPI_Type__c != 'SOS'){
                            kpiAchieveHier.Target__c = regionKPIsTargetMap.get(regionIdWithKPI)/ hierarchyWithTerritoryMap.get(kpiAchieveHier.Region__c).size();
                        }//added as part of ES20-11840 upto Line 412
                        else if(kpiAchieveHier.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_Facings__c=='Facings in %'){
                            kpiAchieveHier.Target_Number__c = null;
                            kpiAchieveHier.Target__c = regionKPIsTargetMap.get(regionIdWithKPI)/ hierarchyWithTerritoryMap.get(kpiAchieveHier.Region__c).size();
                        }
                        else if(kpiAchieveHier.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_Facings__c=='Facings in number'){
                            kpiAchieveHier.Target__c= null;
                            kpiAchieveHier.Target_Number__c = regionKPIsTargetMap.get(regionIdWithKPI);       


                        }                      


                    }
                }
            }
            if((isRegion && kpiAchieveHier.KPI_Type__c == 'Volume Category Performance' || kpiAchieveHier.KPI_Type__c == 'Volume Target Performance')){
                kpiAchieveHier.Achievement__c = regionKPIsActualMap.get(regionIdWithKPI);
            }else if(isRegion && kpiAchieveHier.KPI_Type__c == 'Total Activation Survey'){// Only Region Level
                kpiAchieveHier.Achievement__c = regionKPIsActualMap.get(regionIdWithKPI);
            }
            /*else if(kpiAchieveHier.KPI_Type__c == 'Virtual Call Compliance'){ //ES20-12821
                //ES20-8415 change
                kpiAchieveHier.Total_Denominator__c = (existingUserManagermap.get(kpiAchieveHier.Region__c) != null) ? ((existingUserManagermap.get(kpiAchieveHier.Region__c)).size()) : 0;
                kpiAchieveHier.Achievement__c = (existingUserManagermap.get(kpiAchieveHier.Region__c) != null) ? ((regionKPIsNumMap.get(regionIdWithKPI))/((existingUserManagermap.get(kpiAchieveHier.Region__c)).size())) : 0;
            }*/
            /* //Start:Changes as  surveyPickUpOptionMap value is set to null for activation territory on 06/14/2022.
			else if((kpiAchieveHier.KPI_Type__c == 'Survey' && kpiAchieveHier.Survey_KPI__c != null 
                      && surveyPickUpOptionMap.containsKey(kpiAchieveHier.Survey_KPI__c)
                      && surveyPickUpOptionMap.get(kpiAchieveHier.Survey_KPI__c)) || kpiAchieveHier.KPI_Type__c == 'Activation Survey KPI'){
                          if(kpiAchieveHier.KPI_Type__c == 'Survey'){
                              kpiAchieveHier.Achievement__c = regionKPIsDenomMap.get(regionIdWithKPI) > 0 ? ((regionKPIsNumMap.get(regionIdWithKPI)/regionKPIsDenomMap.get(regionIdWithKPI))).setscale(2) : 0;
                          }else{
                              kpiAchieveHier.Achievement__c = regionKPIsDenomMap.get(regionIdWithKPI) > 0 ? (regionKPIsNumMap.get(regionIdWithKPI)) : 0;                    
                              System.debug('@472'+kpiAchieveHier.Achievement__c+'____'+kpiAchieveHier.KPI_Type__c);
                          }
                          //Decimal target = (kpiAchieveHier.KPI_Type__c != 'Activation Survey KPI') ? checkValue(kpiAchieveHier.Target_Derived__c) : checkValue(kpiAchieveHier.Target_Number__c);
                          if(!totalActivationKPIMap.containsKey(kpiAchieveHier.Region__c)){
                              String regionIdWithTotalKPI = kpiAchieveHier.Region__c + '_' + 'Total Activation Survey';
                              //KPI_Achivement__c totalKpiAchieveHier = new KPI_Achivement__c(Id = hierarchyKPIAchievements.containsKey(regionIdWithTotalKPI) ? hierarchyKPIAchievements.get(regionIdWithTotalKPI) : null);
                              KPI_Achivement__c totalKpiAchieveHier = new KPI_Achivement__c(Id = existingTotalActKPiAchvsMap.containsKey(kpiAchieveHier.Region__c) ? existingTotalActKPiAchvsMap.get(kpiAchieveHier.Region__c) : null);
                              totalKpiAchieveHier.Region__c = kpiAchieveHier.Region__c;
                              totalKpiAchieveHier.Actual_Numerator__c = kpiAchieveHier.Actual_Numerator__c;
                              totalKpiAchieveHier.Total_Denominator__c = regionToOutletsCountQueryMap.get(kpiAchieveHier.Region__c); //regionToOutletsCountMap.get(kpiAchieveHier.Region__c);//kpiAchieveHier.Total_Denominator__c;
                              totalKpiAchieveHier.Achievement__c = kpiAchieveHier.Actual_Numerator__c; //kpiAchieveHier.Achievement__c;
                              totalKpiAchieveHier.RecordTypeId = territoryHierarchyRTId;
                              totalKpiAchieveHier.KPI_Type__c = 'Total Activation Survey';
                              totalKpiAchieveHier.Country__c = countryId;//added country for total
                              totalKpiAchieveHier.Target_Number__c = 0;
                              //totalKpiAchieveHier.Target_Number__c = target;
                              totalActivationKPIMap.put(kpiAchieveHier.Region__c,totalKpiAchieveHier);
                          }else{
                              KPI_Achivement__c totalKpiAchieveHier = totalActivationKPIMap.get(kpiAchieveHier.Region__c);
                              totalKpiAchieveHier.Actual_Numerator__c += kpiAchieveHier.Actual_Numerator__c;
                              //totalKpiAchieveHier.Total_Denominator__c += kpiAchieveHier.Total_Denominator__c;
                              totalKpiAchieveHier.Achievement__c += kpiAchieveHier.Actual_Numerator__c; //kpiAchieveHier.Achievement__c;
                              //totalKpiAchieveHier.Target_Number__c += target;
                          }
                      }*/
            else{//SOS,MAS,MPA,Distribution,OES
                          kpiAchieveHier.Achievement__c = regionKPIsDenomMap.get(regionIdWithKPI) > 0 ? ((regionKPIsNumMap.get(regionIdWithKPI)/regionKPIsDenomMap.get(regionIdWithKPI))).setscale(2) : 0;	
                          //System.debug('kpiAchieveHier.Achievement__c 446'+kpiAchieveHier.Achievement__c);
                      }
            
            //ES20-10210
            if(kpiTypeToCalcTypeMap.get(kpiAchieveHier.KPI_Type__c) != 'Binary'){
                kpiAchieveHier.Achievement__c = kpiAchieveHier.Achievement__c <= 1 ? kpiAchieveHier.Achievement__c * 100 : kpiAchieveHier.Achievement__c;
            }
            if(isRegion){//previous is required only for Region level
                kpiAchieveHier.Previous_Achievement__c = regionKPIsPrevActualMap.get(regionIdWithKPI);
            }
            //kpiAchieveHierList.add(kpiAchieveHier);
            
            //ES20-12223, ES20-12218 -> Commented the below code 
            if( /*(!isRegion && (kpiAchieveHier.KPI_Type__c == 'MAS' || kpiAchieveHier.KPI_Type__c == 'MPA'
                               || kpiAchieveHier.KPI_Type__c == 'Distribution' || kpiAchieveHier.KPI_Type__c == 'OES'
                               || kpiAchieveHier.KPI_Type__c == 'SOS' || (kpiAchieveHier.KPI_Type__c == 'Survey')
                               || kpiAchieveHier.KPI_Type__c == 'Activation Survey KPI' || kpiAchieveHier.KPI_Type__c == 'Total Activation Survey'))
               || */(isRegion && (kpiAchieveHier.KPI_Type__c != 'Survey'|| kpiAchieveHier.KPI_Type__c != 'Activation Survey KPI')))
            {   
                kpiAchieveHierList.add(kpiAchieveHier);
            }
        }
        
        if(!totalActivationKPIMap.isEmpty()){
            for(KPI_Achivement__c surveyOrActivationKPI : [Select Id,Target_Derived__c,KPI_Type__c,Region__c from KPI_Achivement__c where KPI_Type__c in ('Survey','Activation Survey KPI')
                                                           AND Region__c in : totalActivationKPIMap.keySet()])
            {
                if(totalActivationKPIMap.containsKey(surveyOrActivationKPI.Region__c))  {
                    KPI_Achivement__c totalSurvKPI = totalActivationKPIMap.get(surveyOrActivationKPI.Region__c);
                    totalSurvKPI.Target_Number__c += surveyOrActivationKPI.Target_Derived__c;
                    totalActivationKPIMap.put(surveyOrActivationKPI.Region__c,totalSurvKPI);
                }  
            }
            
        }
        
        for(String totalKpiAchvRegionId : totalActivationKPIMap.keySet()){
            KPI_Achivement__c kpiAchievement = totalActivationKPIMap.get(totalKpiAchvRegionId);
            kpiAchieveHierList.add(kpiAchievement);
        }
        
        for(KPI_Achivement__c kpiAchievement : kpiAchieveHierList){
            if(kpiAchievement.KPI_Type__c=='SOS' && kpiAchievement.Target_Number__c!=null){
                kpiAchievement.Target_Number__c = kpiAchievement.Target_Number__c.round();
            }
        }
        //Upsert KPI Achievment Territory Hierarchy data
        if(kpiAchieveHierList != null && kpiAchieveHierList.size()>0){
            Database.upsert(kpiAchieveHierList, false);
        }
    }
    
    //Method to check null value
    public static Decimal checkValue(Decimal kpiValue){
        if(kpiValue != null){
            return kpiValue;
        }else{
            return 0;
        }       
    }
    
    //Method to populate Numerator,Denominator and Actual maps
    private static void populateKPIMaps(Map<String, Decimal> regionKPIsCompMap, String regionIdWithKPI, Decimal kpiComponent){
        if(regionKPIsCompMap.containsKey(regionIdWithKPI)){
            regionKPIsCompMap.put(regionIdWithKPI, regionKPIsCompMap.get(regionIdWithKPI) + checkValue(kpiComponent));
        }else{
            regionKPIsCompMap.put(regionIdWithKPI, checkValue(kpiComponent));
        }
    }
}