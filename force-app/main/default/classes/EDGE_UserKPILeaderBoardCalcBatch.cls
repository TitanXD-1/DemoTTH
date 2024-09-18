/**
* 	Class Name: EDGE_UserKPILeaderBoardCalcBatch
*   History  
* 	Author          Version    Date           Detail
* 	Saranya L       V1.0	   15/11/2021     Created for ES20-11206 && ES20-11306
**/

public class EDGE_UserKPILeaderBoardCalcBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String rankingCalculationType;
    String countryCode;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        List<string> profileList = new List<String>();
        String queryString='';
        String activeStatus='Active'; 
        String profilesStr = Label.EDGE_UserKPILeaderBoardCalcBatchProfile;    
        if(profilesStr != null){
           profileList = profilesStr.split(','); 
        }
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594   
        countryCode = batchSetting.Country_Code__c;
        List<Market_Setting__c> marketSettingRecords = [SELECT Ranking_Calculation__c from Market_Setting__c WHERE Geography__r.Code__c =:countryCode LIMIT 1] ;
        if(marketSettingRecords != null && marketSettingRecords.size() > 0){
        	rankingCalculationType = marketSettingRecords[0].Ranking_Calculation__c;
        }
        queryString = 'SELECT Available_Countries__c, Default_Country__c'
            		  +' FROM User'
            		  +' WHERE (Available_Countries__c INCLUDES (\''
            		  +countryCode+'\') OR Default_Country__c = \''
            		  +countryCode +'\') AND IsActive = true'
                      +' AND Available_Countries__c != null'
            		  +' AND Profile.Name IN : profileList';
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<User> scope){
        Set<Id> userIds = new Set<Id>();
        if(scope!= null && !scope.isEmpty()){
            for(User userObj : scope){
                if(String.isNotBlank(userObj.Available_Countries__c)  
                   &&((userObj.Available_Countries__c.contains(';') && String.isNotBlank(userObj.Default_Country__c) && userObj.Default_Country__c.equals(countryCode) )
                   ||(!userObj.Available_Countries__c.contains(';') && userObj.Available_Countries__c.equals(countryCode)))){
                    userIds.add(userObj.Id);
                }
            }
        }
        if(!userIds.isEmpty()){
            EDGE_LeaderboardOperations.calculateKPIRankings(userIds, rankingCalculationType);
        }
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UserKPILeaderBoardCalcBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
    }
}