/********************************************************************************************
Class Name: EDGE_TravelLogBookGeneratorBatch

Author          Version    Date           Detail
Sandip Ghosh    V1.0       17/02/2020     [ES20-6936]This batch is used to generate travel 
log book records
*********************************************************************************************/

public class EDGE_TravelLogBookGeneratorBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
	//Set<Id> allTravelLogBookIds = new Set<Id>();//global set for handling territory hierarchy ids
	Set<Id> successEmailsTravelLogBooks = new Set<Id>();
    Set<Id> failureEmailsTravelLogBooks = new Set<Id>();
    //List<Market_Setting__c> marketSettingRecords;
    Market_Setting__c mrktSetting;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
  
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String queryString='';
        String activeStatus='Active'; 
        String countryCode = batchSetting.Country_Code__c;
        
        System.debug('countryCode = '+ countryCode);
        List<Market_Setting__c> marketSettingRecords = [SELECT Id,Last_Travel_Log_Date__c from Market_Setting__c WHERE Geography__r.Code__c =:countryCode LIMIT 1] ;
        if(marketSettingRecords != null && marketSettingRecords.size() > 0){
        	mrktSetting = marketSettingRecords[0];
        }
        
        System.debug('@@batchSetting.Frequency__c = '+ batchSetting);
        if(countryCode != null){
           queryString='SELECT Id, Business_Percentage__c, Max_Created_Date__c, Total_Business_Distance__c, Total_Distance__c, Total_Personal_Distance__c, Geography__c, User__r.Available_Countries__c, Min_Start_Date__c, Registration_Number__c from Personal_Information__c WHERE User__r.Available_Countries__c includes (:countryCode)';
        }
        
        System.debug('countryCode = '+ countryCode);
        System.debug('queryString = '+ queryString);
        return Database.getQueryLocator(queryString);
    }

    //execute method
    public void execute(Database.BatchableContext bc, List<Personal_Information__c> scope){
        System.debug('scope = '+ scope);
        EDGE_TravelLogBookGenBatchHelper.batchFreQuency = batchSetting.Frequency__c;
        //EDGE_TravelLogBookGenBatchHelper.batchFreQuency = mrktSetting.Logbook_Frequency__c;
        Map<Id, Boolean> travelLogBookIdsMap = EDGE_TravelLogBookGenBatchHelper.generateTravelLogBook(scope,false);
        System.debug('travelLogBookIdsMap = '+ travelLogBookIdsMap);
        
        if(travelLogBookIdsMap != null && travelLogBookIdsMap.keySet().size() > 0){
            for(Id travelLogBookId : travelLogBookIdsMap.keySet()){
                if(travelLogBookIdsMap.get(travelLogBookId)){
                    failureEmailsTravelLogBooks.add(travelLogBookId);
                }else{
                    successEmailsTravelLogBooks.add(travelLogBookId);
                }
            }
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
        
        System.debug('successEmailsTravelLogBooks = '+ successEmailsTravelLogBooks);
        System.debug('failureEmailsTravelLogBooks = '+ failureEmailsTravelLogBooks);
        
        if(!hasError && failureEmailsTravelLogBooks != null && failureEmailsTravelLogBooks.size() > 0){
            hasError = true;
            exceptionMsg += 'Mail could not be sent for the below travel log Ids : ';
            for(Id failedTravelLogBookId : failureEmailsTravelLogBooks){
                exceptionMsg += '\t' + failedTravelLogBookId;
            }
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_PrimaryTerritoryKPICalcBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        
        if(!hasError && successEmailsTravelLogBooks != null && successEmailsTravelLogBooks.size() > 0){
            EDGE_TravelLogBookGenBatchHelper.markTravelLogBooksEmailSent(successEmailsTravelLogBooks);
        }

		system.debug('orgSetting++ ' + [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]);        
        
        System.debug('mrktSetting = '+ mrktSetting);
        //Last Travel Log Date
        if(mrktSetting != null){
            mrktSetting.Last_Travel_Log_Date__c = Date.today();
            Database.update(mrktSetting, false);
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}