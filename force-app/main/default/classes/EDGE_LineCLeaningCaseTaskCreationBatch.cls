/**
@name EDGE_LineCLeaningCaseTaskCreationBatch
@description Edge_LineCLeaningCaseTaskCreationBatch case task,case,call record Creation from 1st day of cycle.
@history
VERSION     AUTHOR           DATE           DETAIL
1.0          Anand          12/03/2021      ES20-10426
1.1         Mayukh          18/05/2022      US-3032317
1.2        Sudipta Nandy 	09/12/2022		We have added 'order by Exclusion_Date__c' in the query.
1.3        Wribhu           02/05/2023      GT-26: Implementation story for adding the filter for Quality record type for the Quality Assets instances
**/
public class EDGE_LineCLeaningCaseTaskCreationBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    string countryCode = '';
    Date todaysDate = Date.today();
    Boolean batchProcess = false; //US-3032317
    //Map between location and cycle                     
    List<Line_Cleaning_Cycle__c> mCycles = new List<Line_Cleaning_Cycle__c> ();
    Map<Id,List<Line_Cleaning_Holiday__c>> lcToLHoliday = new Map<Id,List<Line_Cleaning_Holiday__c>>();
    List<Case_Task__c> caseTaskList =new List<Case_Task__c>();
    Map<Id,Line_Cleaning_Cycle__c> finalCycleMap = new Map<Id,Line_Cleaning_Cycle__c>();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  
        countryCode = batchSetting.Country_Code__c;
        list<String> outletStatus = Label.Edge_LineCleaningOutletStatus.split(';');
        String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();//GT-26
        //String activeStatus='Active';
        
        System.debug(LoggingLevel.DEBUG, 'outletStatus@@'+outletStatus);
        
        //Get all future cycles (used to get the next cycle for each current cycle)
        mCycles  =  [SELECT Name, country__c, Start_Date__c, End_Date__c,Batch_Processed__c 
                     FROM Line_Cleaning_Cycle__c WHERE country__r.code__c =: countryCode AND Active__c = true AND Start_Date__c >= :todaysDate
                     Order By country__c, Start_Date__c limit 2];
         //US-3032317
         for(Line_Cleaning_Cycle__c lCycle : mCycles){
       		 if(lCycle.Start_Date__c  == todaysDate && lCycle.End_Date__c > todaysDate){
            	batchProcess = true;
       		 }
         }
// We have added 'order by Exclusion_Date__c' in the query
        System.debug(LoggingLevel.DEBUG, 'mCycles:'+mCycles);
        for(Line_Cleaning_Holiday__c lholiday:[SELECT id,Exclusion_Date__c,Line_Cleaning_Cycle__c,name FROM Line_Cleaning_Holiday__c WHERE Active__c=true AND Line_Cleaning_Cycle__r.Id IN:mCycles order by Exclusion_Date__c]){
            
            if(lcToLHoliday.containsKey(lholiday.Line_Cleaning_Cycle__c)){
                lcToLHoliday.get(lholiday.Line_Cleaning_Cycle__c).add(lholiday);
            }
            else{
                lcToLHoliday.put(lholiday.Line_Cleaning_Cycle__c,new List<Line_Cleaning_Holiday__c>{lholiday});
            }
            
        }
        //Get the outlets    
        String queryString='SELECT Name, Id FROM Account WHERE Id IN (SELECT AccountId From Asset WHERE Line_Cleaning_Asset__c = true AND Master_Asset__r.Active__c=true AND RecordTypeId =:qualityAssetRecordTypeId)'+
            ' AND Status__c IN :outletStatus AND Country__r.Code__c =:countryCode';//GT-26
        
        return Database.getQueryLocator(queryString);
        
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> scope){  
        
        try{
            if (!scope.isEmpty() && mCycles !=null && mCycles.size() >1){
                EDGE_LineCLeaningCaseTaskCreationHelper.processLineCaseTask(mCycles,scope,lcToLHoliday,countryCode,todaysDate);
            }
            
        }
        
        catch(Exception ex) {
            System.debug(LoggingLevel.DEBUG, 'ex :'+ ex.getStackTraceString());
            System.debug(LoggingLevel.DEBUG, 'ex :'+ ex.getCause());
            System.debug(LoggingLevel.DEBUG, 'ex :'+ ex.getMessage());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    public void finish(Database.BatchableContext bc){ 
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_LineCLeaningCaseTaskCreationBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            if(mCycles !=null && mCycles.size() >0 && batchProcess){
                for(Line_Cleaning_Cycle__c lineCycle: mCycles){
                    lineCycle.Batch_Processed__c = true; 
                    if(!finalCycleMap.containsKey(lineCycle.Id)){
                        finalCycleMap.put(lineCycle.Id,lineCycle);
                    }
                }
            }
            if(finalCycleMap!= null && finalCycleMap.size()>0){
                Database.upsert(finalCycleMap.values(),false);
            }  
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
           EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); 
        }
    }
}