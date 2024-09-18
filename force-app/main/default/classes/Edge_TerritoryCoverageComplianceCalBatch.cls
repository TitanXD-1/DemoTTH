/**
* @Name: Edge_TerritoryCoverageComplianceCalBatch 
* @ES20-11060 - Batch KPI Calculation for Coverage Compliance from Outlet Kpi Acievement records(Territory Level and Activation Territory Level)
* @History                                                            
* 	@VERSION     AUTHOR              DATE              DETAIL
*	1.0         Sudipta Nandi        11/26/2021        ES20-11060
*	2.0			Rajarshi Lahiri		 02/23/2022		   ES20-10999(KPI Achievement Calculation where OKA is aggregated for Territory or Activation Territory based on KPI Type)

*	3.0			Subhodeep Sarkar	 24/03/2022        ES20-12232(Removing Activation territory calculation at Territory Hierarchy level and calculation at Territory Level)
*   4.0         Joshraj Sen          31/05/2022        ES20-12891(Batch Failing for GB Market) 
*	5.0			Swaraj Samanta		 20/05/2022		   ES20-12675(Including temporary closed outlets)
*	6.0			Rajarshi Lahiri		 07/07/2022		   ES20-13053(Changed getOutletsCountAgainstTerritory method signature)
*/

public class Edge_TerritoryCoverageComplianceCalBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    List<Territory__c> processedTerrLst = new List<Territory__c>();
    //Set<Territory__c> processedTerrSet = new Set<Territory__c>();
    Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>();
    
    Map<Id,Territory_Hierarchy__c> activationTerrMap=new Map<Id,Territory_Hierarchy__c>();


    List<Territory__c> territoryList = new List<Territory__c>();
    Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
    
    public final String coverageForSalesKPI = 'Coverage for Sales';
    public final String coverageForQualityKPI = 'Coverage for Quality';
    public final String coverageForActivSpecKPI = 'Coverage for Activation Specialist';
    public final String coverageComplianceKPI = 'Coverage Compliance';
    public final String coverageComplianceTargetFieldName = 'Coverage_Compliance_Target__c';
    
    public Map<String, Decimal> territoryWithOutletComplianceMap = new Map<String, Decimal>();
    public static String territoryRecType = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
    public static String territoryHierRecType = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory Hierarchy KPI').getRecordTypeId();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  
        String territoryType='Sales';
        String countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        List<String> outletStatus = new List<String>{EDGE_Constant.ACTIVE,EDGE_Constant.TEMPORARILYCLOSED};//ES20-12675
        Boolean batchPending = true;   //filter added to process those territories only whose Pending_For_Batch__c is true 
        String coverageForSalesKPI = 'Coverage for Sales';
        String coverageForQualityKPI = 'Coverage for Quality';
        String coverageForActivSpecKPI = 'Coverage for Activation Specialist';
     //   Set<Id> territorySetIds = new Set<Id>(); //ES20-12675
        Set<Id> salesTerritorySetIds = new Set<Id>();
        Set<Id> qualityTerritorySetIds = new Set<Id>();
        Set<Id> activationTerritorySetIds = new Set<Id>();
        
        territoryList = [SELECT ID,Pending_For_Batch__c,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c,
                         Distribution_Target__c, Activation_Territory__c,Activation_Territory__r.Pending_For_Batch__c, Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c,RecordType.Name

                         FROM Territory__c WHERE (RecordType.Name = 'Sales Territory' OR RecordType.Name =  'Quality Territory' OR RecordType.Name = 'Activation Territory') AND Country__r.Code__c =:countryCode AND Pending_For_Batch__c =:batchPending AND Status__c =:activeStatus];

        if(territoryList != null && territoryList.size()>0){
            for(Territory__c territory : territoryList){
                territoryMap.put(territory.Id, territory);
                //Get a set of ATs related to Territory

                /*if(territory.Activation_Territory__c!=null && territory.Activation_Territory__r.Pending_For_Batch__c==batchPending){//ES20-12232 dont need this map anymore
                	activationTerrSet.add(territory.Activation_Territory__c);
                }*/
                if (territory.RecordType.Name == 'Sales Territory') {
                    salesTerritorySetIds.add(territory.Id);
                }else if (territory.RecordType.Name == 'Activation Territory') {
                    activationTerritorySetIds.add(territory.Id);
                }else{
                    qualityTerritorySetIds.add(territory.Id);
                }

            }
        }
     //   if(territoryMap != null && territoryMap.size() > 0) //ES20-12675
     //   	territorySetIds = territoryMap.keySet();
        
			/*'SELECT Outlet__r.Primary_Sales_Territory__c, KPI_Type__c, Category__c, Volume_Category__c, Total_Denominator__c,' +
            + ' Actual_Numerator__c, Achievement__c, Previous_Achievement__c, Target__c,Last_Compliant_Call_Date__c,Valid__c,Territory__c FROM Outlet_KPI_Achievement__c' +
            + ' WHERE Territory__c IN: territorySetIds AND (KPI_Type__c =:coverageForSalesKPI OR KPI_Type__c =:coverageForQualityKPI OR KPI_Type__c=:coverageForActivSpecKPI)' +
            + ' AND Outlet__r.Status__c IN:outletStatus ORDER BY Territory__c DESC';*/
        System.debug('qualityTerritorySetIds '+qualityTerritorySetIds);
        //Get sales territories        
        String queryString='SELECT Outlet__r.Primary_Sales_Territory__c, KPI_Type__c, Category__c, Volume_Category__c, Total_Denominator__c,' +
            + ' Actual_Numerator__c, Achievement__c, Previous_Achievement__c, Target__c,Last_Compliant_Call_Date__c,Valid__c,Territory__c FROM Outlet_KPI_Achievement__c' +
            + ' WHERE ((Territory__c IN: salesTerritorySetIds AND KPI_Type__c =:coverageForSalesKPI) OR (Territory__c IN: qualityTerritorySetIds AND KPI_Type__c =:coverageForQualityKPI)'+
            + ' OR (Territory__c IN: activationTerritorySetIds AND KPI_Type__c=:coverageForActivSpecKPI))' +
            + ' AND Outlet__r.Status__c IN:outletStatus ORDER BY Territory__c DESC';//ES20-12675
        System.debug('queryString '+queryString);
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Outlet_KPI_Achievement__c> outletKPIAchievementList){     	
        try{
            List<KPI_Achivement__c> kpiAchvmntList = new List<KPI_Achivement__c>();
            Set<KPI_Achivement__c> kpiAchvmntSet=new Set<KPI_Achivement__c>();
            List<KPI_Achivement__c> kpiAchivListUpsert =new List<KPI_Achivement__c>();
            Map<String, Market_Cycle__c> marketCycleMap = new Map<String, Market_Cycle__c>();
            Set<Id> territoryIdSet = new Set<Id>();
            Map<String, Id> territoryWithOutletKPIAchv = new Map<String, Id>();
            List<Market_Setting__c> marketSettingList = new List<Market_Setting__c>();
            String territoryId;
            Map<Id,decimal> territoryToOutletCountMap = new map<Id,decimal>();
            
            if(territoryMap != null && territoryMap.size() > 0 ){
                String countryCode = batchSetting.Country_Code__c;
                territoryIdSet.addAll(territoryMap.keySet());
                //Mapping Market Cycle with Country Code
                if(Schema.SObjectType.Market_Cycle__c.isAccessible()){
                    for(Market_Cycle__c marketCycle : [Select Id, Geography__r.Code__c, Start_Date__c, End_Date__c FROM Market_Cycle__c WHERE Geography__r.Code__c =:countryCode and Active__c = TRUE]){
                        marketCycleMap.put(marketCycle.Geography__r.Code__c, marketCycle);
                    }
                }
                
                //Get existing KPI Achievement records
                Map<String, Id> kpiAchivementMap  = EDGE_KPIAchivementOperations.getkpiAchievementMap(territoryIdSet);
                
                marketSettingList = EDGE_KPIAchivementOperations.fetchMarketSetting(countryCode);
                //ES20-13053-Changed getOutletsCountAgainstTerritory method signature
                territoryToOutletCountMap = EDGE_KPIAchivementOperations.getOutletsCountAgainstTerritory(territoryMap.keySet(),'active_temp');//ES20-12734
                System.debug('territoryToOutletCountMap '+territoryToOutletCountMap);
                
                //Activation Territory Level KPI Calculation
                //Map<Id,decimal> activTerrToOutletCountMap=EDGE_KPIAchivementOperations.getOutletsCountAgainstActivTerritory(activationTerrSet);//ES20-12232 do we need activation terr to # of outlet map??
                //Append Map to original Map to use later
                //territoryToOutletCountMap.putAll(activTerrToOutletCountMap);
                
				//Map<String, Id> kpiAchivementMapAT = EDGE_KPIAchivementOperations.getkpiAchievementMapAT(activationTerrSet);//ES20-12232 we don't need activation terr hie anymore
                //kpiAchivementMap.putAll(kpiAchivementMapAT);
                //Get Territory Hierarchy detaisls for Ats that will be used in KPI calculation
                //Map<Id,Territory_Hierarchy__c> activationTerrMap=EDGE_KPIAchivementOperations.getTerrHierMap(activationTerrSet,countryCode);//ES20-12232 we don't need activation terr hie anymore
                
                    

                if(outletKpiAchievementList !=null && outletKpiAchievementList.size()>0){    
               
                    for(Outlet_KPI_Achievement__c outletKPIAchieve : outletKpiAchievementList){
                        if(outletKPIAchieve.Territory__c !=null){
                            String key;
							//Create key based on KPI type

                            if(outletKPIAchieve.KPI_Type__c == coverageForSalesKPI 
                               || outletKPIAchieve.KPI_Type__c == coverageForQualityKPI 
                               || outletKPIAchieve.KPI_Type__c==coverageForActivSpecKPI 
                               /*&& territoryMap.get(outletKPIAchieve.Territory__c).Activation_Territory__c!=null*/)
                            {//ES20-  removed null check as we dont need to check activation terr field anymore of OKA
                                //added all kpi check type check, although there is no need, but maybe later new kpis can be added
                                /*key = territoryMap.get(outletKPIAchieve.Territory__c).Activation_Territory__c + '_' + outletKPIAchieve.KPI_Type__c;                              
                                }
                                else{*/
                                key = outletKPIAchieve.Territory__c + '_' + outletKPIAchieve.KPI_Type__c;
                            }
     
                            Date lastCompliantCallDate = (Date)outletKPIAchieve.Last_Compliant_Call_Date__c;

                            if(marketCycleMap != null && marketCycleMap.size() > 0 
                               && lastCompliantCallDate != null 
                               && lastCompliantCallDate >= marketCycleMap.get(countryCode).Start_Date__c 
                               && lastCompliantCallDate <= marketCycleMap.get(countryCode).End_Date__c
                               && outletKPIAchieve.Valid__c ==true )
                            {
                               
                               

                                if(territoryWithOutletComplianceMap.containsKey(key)){
                                    territoryWithOutletComplianceMap.put(key, territoryWithOutletComplianceMap.get(key) + 1);
                                }else{
                                    territoryWithOutletComplianceMap.put(key, 1);
                                }					
                                      
                            }
                            System.debug('territoryWithOutletComplianceMap'+territoryWithOutletComplianceMap);
                            System.debug('key'+key);
                            //to get the all the outlet KPI acievement territories which does not meet the criteria.
                            //Keeping a track of which territories were considered in the current batch run
                            if(!territoryWithOutletKPIAchv.containsKey(key)){
                                territoryWithOutletKPIAchv.put(key, outletKPIAchieve.Territory__c);
                            }
                        }
                    }
                }
                if(territoryWithOutletKPIAchv !=null){
                     System.debug('territoryWithOutletKPIAchv '+territoryWithOutletKPIAchv);
                    //Iterating over Territory Ids and KPI Achievement Types to Create KPI Achivement Records
                    for(String key : territoryWithOutletKPIAchv.keySet()){
                        //territoryId is either Territory Id or Activation Terriroty Id
                        territoryId = key.split('_')[0];
                        String cmpKey = territoryId + '_' + coverageComplianceKPI;
                        KPI_Achivement__c kpiAchive = new KPI_Achivement__c(Id = kpiAchivementMap.containsKey(cmpKey) ? kpiAchivementMap.get(cmpKey):null);

                       //Set record type and other fields based on KPI type
                        /**if(key.split('_')[1].equals(coverageForActivSpecKPI)){//Coverage for AT

                            //kpiAchive.RecordTypeId=territoryHierRecType;//ES20-12232 no terr hie for activation specialist kpi
                            kpiAchive.RecordTypeId=territoryRecType;//ES20-12232 populating rectype as territory kpi

                            if(activationTerrMap.get(territoryId).get(coverageComplianceTargetFieldName) != null){
                                if(activationTerrMap.get(territoryId) != null){
                                    kpiAchive.Target__c =   (Decimal)activationTerrMap.get(territoryId).get(coverageComplianceTargetFieldName);
                                }
                        	}

                            //kpiAchive.Region__c =territoryId ;//ES20-12232 
                        }
                        else{**/
							//Coverage for Sales or Quality

                            kpiAchive.RecordTypeId = territoryRecType;
                            kpiAchive.Territory__c = territoryId;
                            if(territoryMap.get(territoryId).get(coverageComplianceTargetFieldName) != null){
                                 if(territoryMap.get(territoryId) != null){
                                     kpiAchive.Target__c =   (Decimal)territoryMap.get(territoryId).get(coverageComplianceTargetFieldName);
                                 }
                             }

                        if(!key.split('_')[1].equals(coverageForActivSpecKPI)){//ES20-12232 populate region only if kpitype is not activation spcialist
                        

                            kpiAchive.Region__c = territoryMap.get(territoryId).Region__c;
                        }

                        
                        if(marketSettingList !=null && marketSettingList.Size()>0){
                            kpiAchive.Country__c = marketSettingList[0].Geography__c;
                        }
                        kpiAchive.KPI_Type__c = coverageComplianceKPI;
                        kpiAchive.Total_Denominator__c =  territoryToOutletCountMap.get(territoryId); 
                        kpiAchive.Actual_Numerator__c =  (territoryWithOutletComplianceMap.containsKey(key)) ? territoryWithOutletComplianceMap.get(key): 0;
                        kpiAchive.Achievement__c = kpiAchive.Total_Denominator__c > 0 ? (kpiAchive.Actual_Numerator__c / kpiAchive.Total_Denominator__c) * 100 :0;
                        
                        
                        kpiAchvmntSet.add(kpiAchive);
                        System.debug('kpiAchvmntList '+kpiAchvmntSet);
                    }
                }            
            }




            if(kpiAchvmntSet != null && kpiAchvmntSet.size() > 0){
                kpiAchvmntList.addAll(kpiAchvmntSet);
                List<Database.upsertResult> uResults = Database.upsert(kpiAchvmntList,false);
                for(Database.upsertResult result :uResults) {
                    if (!result.isSuccess()) {
                        System.debug('failure : result.getId() : '+ result.getId());
                        System.debug('failure : result : '+ result);
                    }
                }
            }
            
        }
        catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    //Update ES20-6594
    public void finish(Database.BatchableContext bc){ 
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','Edge_TerritoryCoverageComplianceCalBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}