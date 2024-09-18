/**
* Class Name: EDGE_OutletSurveyKPIRollupBatch

*  Version      Developer       Date           Detail

*    1.0       Sandip Ghosh    20/01/2020    [ES20-4595]This batch is used to roll up Survey KPI results to KPI Achievement object at the Territory level
*    1.1       Aparajita       26/10/2021	 [ES20-11188]Modified to include both sales and quality territory
*	 1.2	   Rajarshi Lahiri 22/03/2022    [ES20-12217]Modified to include activation territory
*    1.3       Rajarshi Lahiri 12/01/2023    [ES20-13499]Survey KPI Calculation Batch Optimization- Changed the start query
*    1.4       Rajarshi/Mayukh 27/02/2023    [ES20-13746]
*/

public class EDGE_OutletSurveyKPIRollupBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    String territoryRecTypeId = '';
    Id marketBatchJobId;
    
    String countryCode = '';
    List<Market_Cycle__c> marketCycleRecord = new List<Market_Cycle__c>();
	
    List<String> outSurKPIKey=new List<String>();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
  
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String queryString='';
        Date startDate;
        Date endDate;
        this.countryCode = batchSetting.Country_Code__c;
        marketCycleRecord = [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,End_Date__c,Geography__r.Code__c from Market_Cycle__c WHERE Geography__r.Code__c =:countryCode AND Active__c= True LIMIT 1] ;
        if(marketCycleRecord != Null && marketCycleRecord.size()>0){
            startDate = marketCycleRecord[0].Start_Date__c;
            endDate = marketCycleRecord[0].End_Date__c;

            queryString='SELECT Id, Outlet_Survey__c, Response__c, Survey_Question__c, Survey_Question__r.Survey_KPI__c, Outlet_Survey__r.Outlet__c,Outlet_Survey__r.Outlet__r.Primary_Sales_Territory__c,'+ 
                +' Outlet_Survey__r.Outlet__r.Activation_Territory_LT__c,Outlet_Survey__r.Survey__c, Outlet_Survey__r.Completion_Date__c, Survey_Question__r.Activation_Type__c, Survey_Question__r.Survey_KPI__r.Include_in_Total_Activation_Survey_KPI__c,'+
                +' Survey_Question__r.Activation_Type__r.Applicable_Business_Role__c, Survey_Question__r.Survey_KPI__r.Applicable_Business_Role__c FROM Outlet_Survey_Response__c'+ 
                +' WHERE (Survey_Question__r.Survey_KPI__c != NULL OR Survey_Question__r.Activation_Type__c != NULL) AND Outlet_Survey__r.Achievement_status__c = \'Complete\''+
                +' AND Outlet_Survey__r.Completion_Date__c >= :startDate AND Outlet_Survey__r.Completion_Date__c <= :endDate AND Outlet_Survey__r.Outlet__r.Country__r.Code__c =:countryCode'+
                +' ORDER BY Outlet_Survey__r.Survey__c,Outlet_Survey__r.Completion_Date__c DESC, Outlet_Survey__r.Outlet__c, Survey_Question__r.Survey_KPI__c,CreatedDate DESC';
         }
        else{
            queryString='SELECT Id FROM Outlet_Survey_Response__c LIMIT 0';
        }
        return Database.getQueryLocator(queryString);
    }

    //execute method
    public void execute(Database.BatchableContext bc, List<Outlet_Survey_Response__c> scope){
        Set<Id> outletIds = new Set<Id>();

        for(Outlet_Survey_Response__c osrRec : scope){
            outletIds.add(osrRec.Outlet_Survey__r.Outlet__c);
        }

        //ES20-13746
        if(scope.size()>0){
            try{
                outSurKPIKey = EDGE_OutletSurveyKPIRollupHelper.populateSurveyKPI(outletIds,scope,outSurKPIKey);
            }
            catch(Exception ex){
                system.debug(LoggingLevel.DEBUG,'@@Exception' + ex.getMessage());
                hasError = true;
                exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
            }
        }
    }
   

    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        System.debug(LoggingLevel.DEBUG,'@@Heap Size'+Limits.getHeapSize());
        System.debug(LoggingLevel.DEBUG,'@@Heap Limit Size'+Limits.getLimitHeapSize());
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletSurveyKPIRollupBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
        
    }
}