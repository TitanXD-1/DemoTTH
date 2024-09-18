/**
* @Name: EDGE_PrimaryTerritoryOutletCalcBatch
* @Description: Calculate the Terrritory level Actual Volume and Target
* @History
* @VERSION   @AUTHOR            @DATE              @DETAIL
*	1.0      Sandeep Sahoo     07/04/2019     Initial Development
*	1.1      Sagar Barman      08/04/2019     Added Territory Volume Actual and Target population logic.
*	1.2      Anuja Chatterjee  11/11/2019     EDGE_TerritoryHistoricUpdate method added,Update Territory KPIs in Territory Historic object from Territory (KPI Achievement)
*	1.3	     Shahbaz Khan	   24/12/2019	  Added one filter in scope query for ES20-6588
*	1.4		 Dipanjan D		   26/12/2019 	  ES20-6359 : Upserting KPI Achievements (Change of Architechture)
*	1.5	     Kapil Baliyan	   30/12/2019	  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*	1.6		 Prasanth T		   29/10/2021	  Introducted new condition to create records for territory kpi record type with Kpi type as Asset. ES20-10838
*	1.7		 Saranya L		   29/11/2021	  Extending the batch for Quality(ES20-11036)
*   1.8		 Saranya/Anand	   09/03/2022	  Included the Activation Territory for KPI Calculation(ES20-12220)
*	1.9		 Wribhu Bose	   21/03/2022	  ES20-12298; edited query string to include Activation Territory under 'pending for batch'
*   2.0      Joshraj Sen       27/05/2022     ES20-12734; Removal Loop
*   2.1      Joshraj Sen       04/01/2023     ES20-13672
 
*/
public class EDGE_PrimaryTerritoryOutletCalcBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Set<Id> territoryIdSet;
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  //Update ES20-6594
        //String territoryType='Sales';
        String countryCode='';
        countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        activeStatus='Active';
        Boolean batchPending = true;
        batchPending=true;   //filter added to process those territories only whose Pending_For_Batch__c is true
        // added activation territories in the query: ES20-12220
        String queryString='SELECT ID,Pending_For_Batch__c,Total_Number_Of_Active_Outlets__c,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c,' +
            + ' Distribution_Target__c, Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c,RecordType.Name,' +
            + ' (SELECT Id, Volume_Category_Premium_Core_Target__c, Volume_Category_Deluxe_Target__c, Volume_Category_Reserve_Target__c, Volume_Category_RTD_Target__c, Volume_Category_Super_Deluxe_Target__c, Volume_Target_Value__c FROM Territory_Cycles__r WHERE Market_Cycle__r.Active__c = TRUE)' +

            + ' FROM Territory__c WHERE (RecordType.Name in (\'Sales Territory\', \'Quality Territory\', \'Activation Territory\') AND Pending_For_Batch__c =:batchPending) AND Country__r.Code__c =:countryCode  AND Status__c =:activeStatus';

        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Territory__c> scope){
        
        Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
        Map<Id, Territory_Cycle__c> territoryWithCycleSalesMap = new Map<Id, Territory_Cycle__c>();
        Map<Id, Territory_Cycle__c> territoryWithCycleQualityMap = new Map<Id, Territory_Cycle__c>();
        Map<Id, Territory_Cycle__c> territoryWithCycleATMap = new Map<Id, Territory_Cycle__c>();//ES20-12220
        Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>();
        Map<Id, Territory__c> salesTerritoryMap = new Map<Id, Territory__c>();
        Map<Id, Territory__c> activationTerritoryMap = new Map<Id, Territory__c>();//ES20-12220
        Map<Id, Territory__c> qualityTerritoryMap = new Map<Id, Territory__c>();
        List<KPI_Achivement__c> kpiAchvmntList = new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> kpiAchvmntQualityList = new List<KPI_Achivement__c>();
        List<KPI_Achivement__c> kpiAchvmntATList = new List<KPI_Achivement__c>();
		List<KPI_Achivement__c> masterkpiAchvmntDMLList = new List<KPI_Achivement__c>();
        for(Territory__c territory : scope){
            territoryMap.put(territory.Id, territory);
            if(territory.Territory_Cycles__r != null && territory.Territory_Cycles__r.size() > 0){
                territoryWithCycleMap.put(territory.Id, territory.Territory_Cycles__r[0]);
            }
        }
        for(Territory__c territory : scope){
            if((territory.RecordType.Name =='Sales Territory')) //included the activation territory- ES20-12220
            {
                salesTerritoryMap.put(territory.Id, territory);
            }
            else if(territory.RecordType.Name =='Activation Territory') //included the activation territory- ES20-12220
            {
                activationTerritoryMap.put(territory.Id, territory);
            }
            else if(territory.RecordType.Name.equals('Quality Territory'))
            {
                qualityTerritoryMap.put(territory.Id, territory);
            }
            if(territory.Territory_Cycles__r != null && territory.Territory_Cycles__r.size() > 0){
                if(territory.RecordType.Name.equals('Sales Territory')){
                    territoryWithCycleSalesMap.put(territory.Id, territory.Territory_Cycles__r[0]);
                }
                if(territory.RecordType.Name.equals('Quality Territory')){
                    territoryWithCycleQualityMap.put(territory.Id, territory.Territory_Cycles__r[0]);
                }
                if(territory.RecordType.Name.equals('Activation Territory')){//included the activation territory- ES20-12220
                    territoryWithCycleATMap.put(territory.Id, territory.Territory_Cycles__r[0]);
                }
            }
            
        }
        try{
            //update the territoryList with Actual volume and Target volume
            if(territoryMap != null && territoryMap.size() > 0){
                //Sales Calculation
                kpiAchvmntList = EDGE_KPIAchivementOperations.calculateKPIAchivements(salesTerritoryMap, territoryWithCycleSalesMap, batchSetting.Country_Code__c,'Sales');
                //Activation Territory
                kpiAchvmntATList = EDGE_KPIAchivementOperations.calculateKPIAchivements(activationTerritoryMap, territoryWithCycleATMap, batchSetting.Country_Code__c,'Activation');
                //Quality Calculation
                kpiAchvmntQualityList = EDGE_KPIAchivementOperations.calculateKPIAchivements(qualityTerritoryMap, territoryWithCycleQualityMap, batchSetting.Country_Code__c,'Quality');
            }
            if(kpiAchvmntList != null && kpiAchvmntList.size() > 0){
                masterkpiAchvmntDMLList.addAll(kpiAchvmntList);
            }
            if(kpiAchvmntQualityList != null && kpiAchvmntQualityList.size() > 0){
                masterkpiAchvmntDMLList.addAll(kpiAchvmntQualityList);
            }
            if(kpiAchvmntATList != null && kpiAchvmntATList.size() > 0){
                masterkpiAchvmntDMLList.addAll(kpiAchvmntATList);
            }
            /*if(territoryMap != null && territoryMap.size() > 0){
                kpiAchievementAssetList = EDGE_KPIAchivementOperations.calculateAssetKPIAchivements(territoryMap, territoryWithCycleMap, batchSetting.Country_Code__c);
            }
            if(kpiAchievementAssetList != null && kpiAchievementAssetList.size() > 0){
                masterkpiAchvmntDMLList.addAll(kpiAchievementAssetList);
            }*/
            
            
            
            if(masterkpiAchvmntDMLList != null && masterkpiAchvmntDMLList.size()>0){
               upsert masterkpiAchvmntDMLList;
            }
            
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }
        catch(DmlException de){
            System.debug(LoggingLevel.DEBUG,de.getStackTraceString());
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex) {
            System.debug(LoggingLevel.DEBUG,ex.getStackTraceString());
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_PrimaryTerritoryOutletCalcBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
           
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}