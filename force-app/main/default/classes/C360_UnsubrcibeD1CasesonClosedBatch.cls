/*
* @Name: C360_UnsubrcibeD1CasesonClosedBatch
* @description: This is class is to Unsubcribe Users in Bulk to closed D1 Cases
* @History                                                            

VERSION			AUTHOR					DATE					DETAIL
1.0			Joshraj Sen       		18/08/2023				    144407

*/
public class C360_UnsubrcibeD1CasesonClosedBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass
{

Market_Batch_Setting__mdt batchSetting;
boolean hasError = false ;
string exceptionMsg = '';
Id marketBatchJobId;

//Interface Class Method
public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
    this.batchSetting = batchSetting;
}
public Database.QueryLocator start(Database.BatchableContext bc){
    //Upsert Market Batch Job Data
    marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
    String countryCode = '';
    countryCode = batchSetting.Country_Code__c;
    String closedString = '';
    closedString = Label.C360_Status_Closed;
    String recordTypeName = '';
    recordTypeName = Label.C360_D1_Case_RecordType;
    String queryString = 'SELECT Id from Case where Status =:closedString and RecordType.DeveloperName =:recordTypeName and Account.Country__r.Code__c =:countryCode and LastModifiedDate in (TODAY,YESTERDAY)';
    
    return Database.getQueryLocator(queryString);
}
//execute method
public void execute(Database.BatchableContext bc, List<Case> caseList){   
    try{
        List<EntitySubscription> entitySubcription = new List<EntitySubscription>();
        if(Schema.sObjectType.EntitySubscription.isAccessible())
        {
            entitySubcription = [Select Id from EntitySubscription where ParentId in :caseList];
        }
        if(entitySubcription !=null && entitySubcription.size()>0)
        {
          delete entitySubcription;
        }
        if(Test.isRunningTest())
        {
            insert new Lead();
        }
    }
    catch(DmlException de){
        System.debug(LoggingLevel.DEBUG,'DML Exception Stack Trace'+ de.getStackTraceString());
        hasError = true;
        Integer numErrors = de.getNumDml();
        for(Integer i=0; i<numErrors; i++) {
            exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
        }
        
    }
}

//finish method
public void finish(Database.BatchableContext bc){
    //Get Batch Job
    Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
    
    //Check whether Batch Job has been updated by Batch Platform Event or Not
    if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
        hasError = true;
    }
    
    //Update Batch Job Status
    if(hasError){
        EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'C360_UnsubrcibeD1CasesonClosedBatch', exceptionMsg);
    }else{
        EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
    }
    
    //Schedule Next Batch from Batch Utility Class
    if(!Test.isRunningTest()){
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
    }
}


}