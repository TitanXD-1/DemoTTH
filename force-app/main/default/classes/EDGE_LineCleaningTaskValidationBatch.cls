/**
@name EDGE_LineCleaningTaskValidationBatch
@description EDGE_LineCleaningTaskValidationBatch case task,case,call record validation from 1st day of cycle.
@history
VERSION     AUTHOR           DATE           DETAIL
1.0          Prasanth          12/03/2021
1.1 		Sudipta Nandy	09/12/2022		US-3247363 - We have added 'order by Exclusion_Date__c' in the query
**/
public class EDGE_LineCleaningTaskValidationBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    string countryCode = '';
    
    //Map between location and cycle                     
    Map<Id,Line_Cleaning_Cycle__c> mCycles = new Map<Id,Line_Cleaning_Cycle__c>();
    Map<Id,List<Line_Cleaning_Holiday__c>> lineCycleHolidaysMap = new Map<Id,List<Line_Cleaning_Holiday__c>>();
    Map<Id,Line_Cleaning_Cycle__c> finalCycleMap = new Map<Id,Line_Cleaning_Cycle__c>();
    Map<Id,Date> caseTaskDueDateMap = new Map<Id,Date>();
    public static List<String> caseTaskStatus = new List<String> {'Open','Pending'};
        
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  
        countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        Date todaysDate = Date.today();
        
        //Get all future cycles (used to get the next cycle for each current cycle)
        for(Line_Cleaning_Cycle__c lineCycle : [SELECT Id,Name, country__c, Start_Date__c, End_Date__c 
                                                FROM Line_Cleaning_Cycle__c
                                                WHERE country__r.Code__c =: countryCode 
                                                AND Active__c = true 
                                                AND End_Date__c >= :todaysDate 
                                                AND (Change_in_Holidays__c = true 
                                                     OR Change_in_Start_Date__c = true)]){
                                                         mCycles.put(lineCycle.Id,lineCycle);
                                                     }
      // We have added 'order by Exclusion_Date__c' in the below query.  
        for(Line_Cleaning_Holiday__c lineHolidayObj: [SELECT Id,Name,Active__c,Exclusion_Date__c,Line_Cleaning_Cycle__c,
                                                      Line_Cleaning_Cycle__r.Start_Date__c,Line_Cleaning_Cycle__r.End_Date__c
                                                      FROM Line_Cleaning_Holiday__c 
                                                      WHERE Line_Cleaning_Cycle__c IN: mCycles.keyset() 
                                                      AND Active__c = true order by Exclusion_Date__c]){
                                                          if(lineHolidayObj.Exclusion_Date__c >= lineHolidayObj.Line_Cleaning_Cycle__r.Start_Date__c && lineHolidayObj.Exclusion_Date__c <= lineHolidayObj.Line_Cleaning_Cycle__r.End_Date__c){ 
                                                              if(!lineCycleHolidaysMap.containsKey(lineHolidayObj.Line_Cleaning_Cycle__c)){
                                                                  lineCycleHolidaysMap.put(lineHolidayObj.Line_Cleaning_Cycle__c, new List<Line_Cleaning_Holiday__c> {lineHolidayObj});
                                                              }
                                                              else{
                                                                  lineCycleHolidaysMap.get(lineHolidayObj.Line_Cleaning_Cycle__c).add(lineHolidayObj);
                                                              }
                                                          }
                                                      }
        
        
       // if(mCycles !=null && mCycles.size() > 0){
            set<Id> lineCleanIds = new set<Id>();
            lineCleanIds.addAll(mCycles.keySet());
            
            String queryString = 'SELECT Id,Account__c,Achievement_Status__c,Call__c,Call__r.Plan_Start_Date__c,'
                +' Case_Task_Type__c,Case__c,Case__r.Due_Date_Time__c,Country__c,'
                +' Line_Cleaning_Asset__c,Line_Cleaning_Asset__r.Offset_Day__c,Line_Cleaning_Cycle__c,'
                +' Line_Cleaning_Cycle__r.Start_Date__c,Line_Cleaning_Cycle__r.End_Date__c,'
                +' Line_Cleaning_Due_Date__c,Name,Quantity_Cleaned__c,'
                +' User_Assigned_To__c,Quantity__c,Product__c FROM Case_Task__c'
                +' WHERE Batch_Generated__c = true'
                +' AND Line_Cleaning_Cycle__c IN : lineCleanIds'
                +' AND Achievement_Status__c IN : caseTaskStatus';
            
            return Database.getQueryLocator(queryString);
       // }
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Case_Task__c> scope){       
        try{
            if (scope != null && !scope.isEmpty()){
                for(Case_Task__c caseTaskRec : scope){
                    Date cycleStartDate = caseTaskRec.Line_Cleaning_Cycle__r.Start_Date__c;
                    Decimal assetOffsetDay = caseTaskRec.Line_Cleaning_Asset__r.Offset_Day__c;
                    List<Line_Cleaning_Holiday__c> holidayList = lineCycleHolidaysMap.get(caseTaskRec.Line_Cleaning_Cycle__c);
                    Date lineDueDate = EDGE_LineCLeaningCaseTaskCreationHelper.calculateDueDate(cycleStartDate,assetOffsetDay,holidayList);
                    caseTaskDueDateMap.put(caseTaskRec.Id,lineDueDate);
                }
                if(caseTaskDueDateMap != null  && caseTaskDueDateMap.size()>0){
                    EDGE_LineCLeaningCaseTaskCreationHelper.updateLineDueDate(scope, caseTaskDueDateMap);
                }
                
                for(Line_Cleaning_Cycle__c lineCycle: mCycles.values()){
                    lineCycle.Change_in_Holidays__c = false; 
                    lineCycle.Change_in_Start_Date__c = false;
                    if(!finalCycleMap.containsKey(lineCycle.Id)){
                        finalCycleMap.put(lineCycle.Id,lineCycle);
                    }
                }
            }
            if(finalCycleMap!= null && finalCycleMap.size()>0){
                Database.upsert(finalCycleMap.values(),false);
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
    
    public void finish(Database.BatchableContext bc){ 
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_LineCleaningTaskValidationBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}