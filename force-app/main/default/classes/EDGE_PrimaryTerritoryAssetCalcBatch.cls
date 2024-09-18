/**
* @Name: EDGE_PrimaryTerritoryAssetCalcBatch
* @Description: Calculate the Terrritory level KPIs Count for Asset
* @History
* @VERSION   @AUTHOR            @DATE              @DETAIL
*	1.0      Joshraj     03/01/2022     Initial Development(ES20-13672)
*   1.1      Wribhu      02/05/2023     GT-26: Implementation story for adding the filter for Quality record type for the Quality Assets instances
*/
public class EDGE_PrimaryTerritoryAssetCalcBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
	
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Set<Id> territoryIdSet;
    Id marketBatchJobId; //Update ES20-6594
    String countryCode ='';
    static Map<String,Integer> terrIdPriorityAssetsOutletsCountMap = new Map<String,Integer>();
    static Map<Id,Integer> terrToOutletsCountInContextMap = new Map<Id,Integer>();
    static String activeStatus='Active';
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
		this.batchSetting = batchSetting;
	}
    
    // start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        activeStatus='Active';
        Boolean batchPending = true;
        batchPending=true;
        
        // start query to fetch OT for the market
        String queryString='Select Id,Outlet__c,Territory__c, Territory__r.Region__c FROM Outlet_Territory__c WHERE (Territory__r.RecordType.Name in '+
            ' (\'Sales Territory\', \'Quality Territory\', \'Activation Territory\') '+
            ' AND Territory__r.Pending_For_Batch__c =:batchPending) AND Territory__r.Country__r.Code__c =:countryCode '+
            '  AND Outlet__r.Status__c =:activeStatus Order by Territory__c';
        
        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Outlet_Territory__c> scope){
        
        Set<Id> territoryIdSet = new Set<Id>();
        Map<Id,Integer> terrToOutletsCountInDBMap = new Map<Id,Integer>();
        Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>();
        Map<String, KPI_Achivement__c> kpiAchvMap = new Map<String, KPI_Achivement__c>();
        List<Market_Setting__c> marketSettingList = EDGE_KPIAchivementOperations.fetchMarketSetting(countryCode);
        Map<Id,Master_Asset__c> idtoMasterAssetMap = new Map<Id,Master_Asset__c>();
        Map<String,Boolean> outletIdPriorityAssetsCountMap = new Map<String,Boolean>();
        Map<String, Id> kpiAchivementMap  = new Map<String, Id>();
        Map<Id,Decimal> totalNoOfActiveOutlets= new Map<Id,Decimal>();
        Set<Id> outletIds=new Set<Id>();
        String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        try{
            System.debug(LoggingLevel.DEBUG, 'scope : '+ scope.size());
            EDGE_UtilityClass.printGovLimits(59);
            for(Outlet_Territory__c outletTerritory : scope){
                Id territoryId = outletTerritory.Territory__c;
                territoryIdSet.add(territoryId); //set of all territory ids in scope
                Territory__c territoryRec = new Territory__c(Id=territoryId, Region__c = outletTerritory.Territory__r.Region__c);
                territoryMap.put(territoryId, territoryRec); //Map of all territory id, territory rec in scope
                if(terrToOutletsCountInContextMap.containsKey(territoryId)){
                    Integer count = terrToOutletsCountInContextMap.get(territoryId);
                    terrToOutletsCountInContextMap.put(territoryId, ++count);//Stores Number of Outlets against terr id in context
                }else{
                    terrToOutletsCountInContextMap.put(territoryId, 1);
                }
                if(!outletIds.contains(outletTerritory.Outlet__c))
                {
                outletIds.add(outletTerritory.Outlet__c);
                }
            }
            //EDGE_UtilityClass.printGovLimits(72);
            kpiAchivementMap  = EDGE_KPIAchivementOperations.getkpiAchievementMap(territoryIdSet);
            totalNoOfActiveOutlets= EDGE_KPIAchivementOperations.getOutletsCountAgainstTerritory(territoryIdSet,'active');
            
            for (Master_Asset__c masterAssetRec  : [Select Id, Country__r.Code__c from Master_Asset__c 
                                                    where Priority_Assets__c = true 
                                                    and Country__r.Code__c = :countryCode])
            {
                idtoMasterAssetMap.put(masterAssetRec.Id, masterAssetRec); //Stores Master Asset Id and respective master asset rec
            }
            
            if(territoryIdSet!=null && territoryIdSet.size() > 0){
                //GT-26
                for(AggregateResult aggrResult : [Select AccountId outletId, Master_Asset__c masterAssetId
                                                  from Asset where Asset_Removed__c = false and Master_Asset__c!=null 
                                                  and Master_Asset__r.Priority_Assets__c= true  and AccountId in :outletIds and RecordTypeId =:qualityAssetRecordTypeId
                                                  group by AccountId, Master_Asset__c])
                {
                    outletIdPriorityAssetsCountMap.put((Id)aggrResult.get('outletId') + '_' + (String)aggrResult.get('masterAssetId'), true); 
                }
                                
                for(String outletMasterAssetKey : outletIdPriorityAssetsCountMap.keySet()){
                    for(Outlet_Territory__c outletTerritory : scope){
                        Id outletId = outletTerritory.Outlet__c;
                        Id territoryId = outletTerritory.Territory__c;
                        if(outletMasterAssetKey.contains(outletId)){
                            String masterAssetId = outletMasterAssetKey.substringAfter('_');
                            String mapKey = territoryId+'_'+masterAssetId;
                            if(terrIdPriorityAssetsOutletsCountMap.containsKey(mapKey)){
                                Integer count = terrIdPriorityAssetsOutletsCountMap.get(mapKey);
                                terrIdPriorityAssetsOutletsCountMap.put(mapKey, ++count);//Stores Number of Outlets against terr id in context
                            }else{
                                terrIdPriorityAssetsOutletsCountMap.put(mapKey, 1);
                            }
                            
                        }
                    }
                }
            }
            //EDGE_UtilityClass.printGovLimits(111);
            System.debug(LoggingLevel.DEBUG, 'IdtoMasterAssetMap : '+ idtoMasterAssetMap);
            
            for (Master_Asset__c masterAssetRec  : idtoMasterAssetMap.values())
            {
                
                for(Territory__c territory : territoryMap.values()){
                    
                    Decimal noOfOutlets = totalNoOfActiveOutlets.get(territory.Id) !=null ? totalNoOfActiveOutlets.get(territory.Id):0;
                    if(noOfOutlets != null && noOfOutlets > 0){//If a territory has outlets under it
                        String mapKey = territory.Id + '_' + masterAssetRec.Id;
                        String keyString = territory.Id + '_' + 'Asset' + '_' + masterAssetRec.Id;
                        
                        if(!kpiAchvMap.containskey(mapKey)){
                            KPI_Achivement__c kpiAchive = new KPI_Achivement__c(Id = kpiAchivementMap.get(keyString)!=null ? kpiAchivementMap.get(keyString) : null);
                            kpiAchive.RecordTypeId = EDGE_KPIAchivementOperations.territoryRecType;
                            kpiAchive.Territory__c = territory.Id;
                            if(marketSettingList !=null && marketSettingList.Size()>0){
                                kpiAchive.Country__c = marketSettingList[0].Geography__c;
                            }
                            kpiAchive.KPI_Type__c = EDGE_Constant.ASSET;
                            kpiAchive.Region__c = territory.Region__c;
                            kpiAchive.Master_Asset__c = masterAssetRec.Id;        
                            kpiAchive.Actual_Numerator__c = 0;
                            kpiAchive.Total_Denominator__c = noOfOutlets;
                            kpiAchive.Achievement__c = 0;
                            kpiAchvMap.put(mapKey,kpiAchive);
                        }
                    }
                }     
            }
            
            
            for(AggregateResult aggrResult : [Select Count(Outlet__c) outletCount, territory__c terrId 
                                              from Outlet_Territory__c Where Outlet__r.Status__c = :activeStatus
                                              AND Territory__c in :territoryIdSet group by territory__c])
            {
                //Get Count of Outlets against territory Id as per Salesforce Database
                terrToOutletsCountInDBMap.put((Id)aggrResult.get('terrId'), (Integer)aggrResult.get('outletCount')); 
            }
            //EDGE_UtilityClass.printGovLimits(151);
            System.debug(LoggingLevel.DEBUG, 'terrToOutletsCountInDBMap : '+ terrToOutletsCountInDBMap);
            
            for(Id terrId : terrToOutletsCountInContextMap.keySet()){
                if(terrToOutletsCountInContextMap.containsKey(terrId) 
                   && terrToOutletsCountInContextMap.get(terrId) == terrToOutletsCountInDBMap.get(terrId))
                {	//Time to populate the KPI Achievement records
                    for (Master_Asset__c masterAssetRec  : idtoMasterAssetMap.values()){
                        String mapKey = terrId + '_' + masterAssetRec.Id;
                        if(terrIdPriorityAssetsOutletsCountMap.containsKey(mapKey)){
                            KPI_Achivement__c kpiAchive = kpiAchvMap.get(mapKey);
                            if(kpiAchive != null){
                                kpiAchive.Actual_Numerator__c = terrIdPriorityAssetsOutletsCountMap.get(mapKey);
                                if(kpiAchive.Total_Denominator__c != null && kpiAchive.Total_Denominator__c >0){
                                    kpiAchive.Achievement__c = (kpiAchive.Actual_Numerator__c*100)/kpiAchive.Total_Denominator__c;
                                }
                                kpiAchvMap.put(mapKey,kpiAchive);
                            }
                        }
                        
                    }
                 terrToOutletsCountInContextMap.remove(terrId);   
                }
            }
            
            /*for(KPI_Achivement__c kpiAchive : kpiAchvMap.values()){
            	System.debug(LoggingLevel.DEBUG, '2. kpiAchive : '+ kpiAchive);
            }*/
            Database.upsert(kpiAchvMap.values(), false);
            EDGE_UtilityClass.printGovLimits(180);
            
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }catch(DmlException de){
            System.debug(LoggingLevel.DEBUG,de.getStackTraceString());
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }catch(Exception ex) {
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