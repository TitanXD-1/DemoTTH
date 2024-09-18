/**
* @ Name : EDGE_LineCleaningDateOutletUpdateBatch
* @ Description : Batch Job that will Load and Update the Next Line Cleaning Date corresponding to an outlet.
* @ History  
* @ Author                   Version    			 Date           Detail
* @	Rajarshi Lahiri       Initial Development	   30/01/2023     ES20-13471
**/


public class EDGE_LineCleaningDateOutletUpdateBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode;

    Date currentDate = Date.Today();
    boolean dateMatch = false;
    List<Line_Cleaning_Cycle__c> lcCycles = new List<Line_Cleaning_Cycle__c> ();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method
    public Database.QueryLocator start(Database.BatchableContext bc){

        String queryString='';
       
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        //Get all future cycles (used to get the next cycle for each current cycle)
        lcCycles  =  [SELECT Name, country__c, Start_Date__c, End_Date__c,Batch_Processed__c 
                     FROM Line_Cleaning_Cycle__c WHERE country__r.code__c =: countryCode AND Active__c = true AND Start_Date__c >= :currentDate
                     Order By country__c, Start_Date__c LIMIT 2];

        if(lcCycles.size() !=null && lcCycles.size() >0){
            queryString = 'SELECT Id,Next_Line_Cleaning_Date__c FROM Account'
                            + ' WHERE RecordType.Name = \'Outlet\''
                            + ' AND Country__r.code__c = :countryCode';
           }
        else{
            queryString = 'SELECT Id FROM Account LIMIT 0';
        }
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> accList){     	

        Set<Id> accIds = new Set<Id>();
        Set<Id> accSet=new Set<Id>();
        Map<Id,Account> accMap=new Map<Id,Account>();
        list<String> caseTaskStatus = Label.Edge_LCDueDateUpdateStatus.split(';');
        for(Account acc : accList){
            accIds.add(acc.Id);
        }
        try{

            for(Case_Task__c caseTask:[SELECT Id, Name,Account__c,Account__r.Next_Line_Cleaning_Date__c,Line_Cleaning_Due_Date__c, Line_Cleaning_Asset__c FROM Case_Task__c WHERE 
                                       Account__c IN :accIds 
                                       AND Achievement_Status__c IN :caseTaskStatus 
                                       AND Batch_Generated__c = true 
                                       AND Line_Cleaning_Cycle__c IN :lcCycles ORDER BY Line_Cleaning_Due_Date__c DESC]){
               
                    EDGE_LineCleaningDateOutletUpdateHelper.setAccMap(caseTask,accMap);
                    accSet.add(caseTask.Account__c);
               }
            
            for(Account accRec : accList){
                EDGE_LineCleaningDateOutletUpdateHelper.setLCDateBlank(accRec,accSet,accMap);
            }
            
            if(accMap.values().size()>0){
				Database.update(accMap.values(),false);
            }
           
            if(Test.isRunningTest()){
                
                throw (new EDGE_GenericException());
            }
        }
        catch(Exception ex) {
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_LineCleaningDateOutletUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
    }
    
}