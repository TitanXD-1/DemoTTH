/********************************************************************************************
Class Name: EDGE_PrimaryTerritoryKPICalcBatch

Author          Version    Date           Detail
Sandip Ghosh    V1.0       25/02/2019     This batch is used to calculate Leaderboard Ranking
Kapil Baliyan	V2.0	   30/12/2019	  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
Kapil Baliyan	V3.0	   14/05/2020	  ES20-7835
Rajarshi Lahiri	v4.0	   07/10/2022     ES20-13337 
*********************************************************************************************/

public class EDGE_PrimaryTerritoryKPICalcBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    String territoryRecTypeId = '';
    Id marketBatchJobId; //Update ES20-6594
    //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
    String rankingCalculationType;
    Id defaultCatPickupOption;
    final String categoryName = 'Diageo';
    
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594   
        String queryString='';
        String activeStatus='Active'; 
        String countryCode = batchSetting.Country_Code__c;
        //String territoryType='Sales';
        boolean excludeLeaderBoard = False;
        //ES20-13337
        String TerritoryRecordTypes = System.Label.EDGE_AllowedTerrRecordTypesLeaderboard;
    	String[] TerritoryRecordTypesList = TerritoryRecordTypes.split(',');
        
        String defaultCategoryName = categoryName + '[' + countryCode + ']';
        List<Pick_Up_Options__c> pickupRecords = [SELECT Name,Id from Pick_Up_Options__c WHERE Geography__r.Code__c=:countryCode AND Type__c='Leaderboard Grouping'] ;
        if(pickupRecords != null && pickupRecords.size() > 0){
            for(Pick_Up_Options__c pickOption : pickupRecords){
                String pickOptionName = pickOption.Name;
                if(defaultCategoryName.equalsIgnoreCase(pickOptionName.remove(' '))){
                    defaultCatPickupOption = pickOption.Id;
                    break;
                }
            }       
        }
        
        //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic
        List<Market_Setting__c> marketSettingRecords = [SELECT Ranking_Calculation__c from Market_Setting__c WHERE Geography__r.Code__c =:countryCode LIMIT 1] ;
        if(marketSettingRecords != null && marketSettingRecords.size() > 0){
        	rankingCalculationType = marketSettingRecords[0].Ranking_Calculation__c;
        }
        //ES20-13337 Added record type check instead of territory type check
        queryString='SELECT Id,Exclude_from_Leaderboard_ranking__c FROM Territory__c WHERE RecordType.Name IN:TerritoryRecordTypesList'+
            ' AND Country__r.Code__c =:countryCode AND Status__c = :activeStatus AND Exclude_from_Leaderboard_ranking__c =:excludeLeaderBoard';
        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Territory__c> scope){
        Set<Id> territoryIds = new Set<Id>();
        territoryIds = (new Map<Id, Territory__c>(scope)).keyset();
        
        //ES20-6238 : SFDC_Ranking based on Target Fulfillment calculation logic, passing a paramter - rankingCalculationType
        EDGE_LeaderboardOperations.calculateKPIRankings(territoryIds, rankingCalculationType, defaultCatPickupOption);
        /*
        System.debug('Limits.getHeapSize()= '+ Limits.getHeapSize());
        System.debug('Limits.getLimitHeapSize()= '+ Limits.getLimitHeapSize());
        System.debug('Limits.getCpuTime() = '+ Limits.getCpuTime());
        System.debug('Limits.getLimitCpuTime() = '+ Limits.getLimitCpuTime());
        System.debug('Limits.getQueries() = '+ Limits.getQueries());
        System.debug('Limits.getDmlStatements() = '+ Limits.getDmlStatements());*/
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_PrimaryTerritoryKPICalcBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
    }
}