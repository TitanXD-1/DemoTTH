/**
* @ Name : EDGE_LineCleaningCaseTaskDltBatch
* @ Description : Deletion of Open,Pending status case tasks,related cases,calls for assets that satisfy the conditions.
* @ History  
* @ Author          Version    				Date           Detail
* @	Saranya L       Initial Development	   06/12/2021     Created for ES20-11657
* @	Prasanth T      Enhancement			   04/04/2022     Created for ES20-12397
* @ Wribhu  		User Story			   02/05/2023	  Modified for GT-26: Implementation story for adding the filter for Quality record type for the Quality Assets instances
**/


public class EDGE_LineCleaningCaseTaskDltBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode;
    List<Asset> processedAssetList = new List<Asset>();
    //ES20-12397
    Id  lineCleaningId;
    Date currentDate = Date.Today();
    boolean dateMatch = false;
    List<Line_Cleaning_Cycle__c> mCycles = new List<Line_Cleaning_Cycle__c> ();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        String activeStatus='Active';
        String queryString='';
        String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();//GT-26
       
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        //Get all future cycles (used to get the next cycle for each current cycle)
        mCycles  =  [SELECT Name, country__c, Start_Date__c, End_Date__c,Batch_Processed__c 
                     FROM Line_Cleaning_Cycle__c WHERE country__r.code__c =: countryCode AND Active__c = true AND Start_Date__c >= :currentDate
                     Order By country__c, Start_Date__c LIMIT 2];
        
        if(mCycles.size() !=null && mCycles.size() >0){
            for(Line_Cleaning_Cycle__c lc1 : mCycles){
                if(lc1.Start_Date__c == currentDate){
                    dateMatch = true;
                    lineCleaningId = lc1.Id;
                }
            }
        }
        if(dateMatch){
        queryString = 'SELECT Id, Name,Country__r.code__c,Asset_Removed__c,Offset_Day__c,Master_Asset__r.Active__c,'
            + ' Batch_Processed__c,RecordType.Name FROM Asset'
            + ' WHERE (Asset_Removed__c = True OR Offset_Day__c = 0 OR Master_Asset__r.Active__c = False)'
            + ' AND RecordTypeId =: qualityAssetRecordTypeId AND Master_Asset__r.Line_Cleaning_Asset__c = True'
            + ' AND Country__r.code__c = :countryCode AND Batch_Processed__c = False';
        }//GT-26
        else{
            queryString = 'SELECT Id FROM Asset WHERE RecordTypeId =: qualityAssetRecordTypeId LIMIT 0';
        }//GT-26
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Asset> assetList){     	
       // List<String> caseTaskStatusList = new List<String>{EDGE_Constant.OPEN_QUALITYCASE,EDGE_Constant.PENDING_QUALITYCASE};
        List<String> caseTaskStatusList = Label.Edge_LineCleaningTaskDeletionStatus.split(';');
        Set<Id> callIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        List<Call__c> callList = new List<Call__c>();
        List<Case> caseList = new List<Case>();
        List<Case_task__c> caseTaskList = new List<Case_task__c>();
        Set<Id> assetIds = new Set<Id>();
        Set<Id> lineCleaningAssetIds = new Set<Id>();
        if(assetList !=null && assetList.size()>0 ){
            for(Asset assetRec : assetList){
                assetIds.add(assetRec.Id);
            }
        }
        String soqlQuery='SELECT Id, Name, Achievement_Status__c, Call__c, Case__c, Line_Cleaning_Asset__c FROM Case_Task__c'
            + ' WHERE Line_Cleaning_Asset__c IN :assetIds AND Achievement_Status__c IN :caseTaskStatusList AND Batch_Generated__c = true'
            + ' AND Line_Cleaning_Cycle__c = :lineCleaningId'; 
        
        for(Case_Task__c caseTaskRec : Database.query(soqlQuery)){
            caseTaskList.add(caseTaskRec);
            if(caseTaskRec.Line_Cleaning_Asset__c != null){
                lineCleaningAssetIds.add(caseTaskRec.Line_Cleaning_Asset__c);
            }
            if(caseTaskRec.Call__c != null){
                callIds.add(caseTaskRec.Call__c);
            }
            if(caseTaskRec.Case__c != null){
                caseIds.add(caseTaskRec.Case__c);
            }
        }
        try{
            if(lineCleaningAssetIds != null && lineCleaningAssetIds.Size()>0){
                for(Id assetId : lineCleaningAssetIds){
                Asset assetobj = new Asset(Id = assetId);
                assetobj.Batch_Processed__c = true;
                if(!processedAssetList.contains(assetobj)){
                    processedAssetList.add(assetobj);    
                }
            }
            }
            if(callIds != null && callIds.size()>0){
                callList = [SELECT Id,Name from Call__c where Id IN :callIds];
                Database.DeleteResult[] deleteCallResults = Database.delete(callList,false);
            }
            if(caseIds != null && caseIds.size()>0){
                caseList = [SELECT Id,CaseNumber from Case where Id IN :caseIds];
                Database.DeleteResult[] deleteCaseResults = Database.delete(caseList,false);
            }
            if(caseTaskList != null && caseTaskList.size()>0){
                List<Database.DeleteResult> dResults = Database.delete(caseTaskList,false);
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_LineCleaningCaseTaskDltBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            if(processedAssetList != null && processedAssetList.size()>0 && Schema.sObjectType.Asset.isUpdateable()){
                Database.update(processedAssetList,false);
            }
        }
        //Schedule Next Batch from Batch Utility Class
        if(!test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);  
        }
    }
    
}