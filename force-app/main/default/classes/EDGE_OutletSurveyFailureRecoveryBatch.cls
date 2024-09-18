/*
*@Name: EDGE_OutletSurveyFailureRecoveryBatch
*@Test Class: EDGE_OutletSurveyFailBatchTest
*@Description: This class is used to update Outlet Survey Record as complete on completion of related call.
*@History                                                            
*
*VERSION		AUTHOR					DATE				DETAIL
*1.0			Shivam Chauhan			22/04/2024			Initial Development - 152835 Outlet Survey Batch_SFDC_Techdebt
*/
public class EDGE_OutletSurveyFailureRecoveryBatch implements Database.Batchable<SObject>,Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    Market_Batch_Setting__mdt batchSetting; 
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    
    /**
    * @description : start - start method for the Batch
    * @return : Database.QueryLocator
    * @param : Database.BatchableContext
    */
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        List<Market_Setting__c> marSetList = [SELECT Id,Geography__c,Outlet_survey_batch_close__c from Market_Setting__c Where Geography__r.Code__c = :countryCode ];
        
        Integer surveyBatchClose = Integer.valueOf(marSetList[0].Outlet_survey_batch_close__c);
        DateTime endDate = System.today().addDays(-surveyBatchClose);
        DateTime startDate = endDate.addDays(-14);
        endDate = endDate.addHours(23).addMinutes(59).addSeconds(59);
        
        system.debug(LoggingLevel.Debug,'endDate @'+endDate);
        system.debug(LoggingLevel.Debug,'startDate @'+startDate);
        system.debug(LoggingLevel.Debug,'countryCode @'+countryCode);
        
        
        String query = 'SELECT Id, IsDeleted, Name, Outlet__c, Outlet__r.Country__c, Achievement_status__c, Call__c, Call__r.End_Date__c, Completion_Date__c, GUID__c, ' +
                        '(SELECT Id FROM Outlet_Survey_Responses__r), Survey_Valid_From__c, Survey__c, To_be_deleted__c, Closed_via_Batch__c ' +
                        'FROM Outlet_Survey__c ' +
                        'WHERE Outlet__r.Country_Code__c =:countryCode ' +
                        'AND Achievement_status__c = \'In Progress\' ' +
                        'AND Call__r.Status__c = \'Completed\' ' +
                        'AND (Call__r.End_Date__c >= :startDate ' +
                        'AND Call__r.End_Date__c <= :endDate)';

        system.debug(LoggingLevel.DEBUG, 'query--->' + query);
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description : execute - execute method for the Batch
    * @return : void
    * @param : Database.BatchableContext, List<Outlet_Survey__c> 
    */
    public void execute(Database.BatchableContext bc, List<Outlet_Survey__c> scope){
        List<Outlet_Survey__c> outletSurveyList = new List<Outlet_Survey__c>();
        try{
                for(Outlet_Survey__c outletSurvey :scope){
                    
                        if(outletSurvey.Outlet_Survey_Responses__r.size()>0){
                            outletSurvey.Closed_via_Batch__c = System.Label.EDGE_Response_Received;
                        }
                        else{
                            outletSurvey.Closed_via_Batch__c = System.Label.EDGE_No_Response;
                        }
                        outletSurvey.Achievement_status__c = System.Label.EDGE_Status_Complete;
                        outletSurvey.Completion_Date__c = outletSurvey.Call__r.End_Date__c.date();
                        outletSurveyList.add(outletSurvey);
            	}
                if(!outletSurveyList.isEmpty()){
                        Database.update(outletSurveyList);
                }
            
            
            
        }catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    /**
    * @description : finish - Finish method for the Batch
    * @return : void
    * @param : Database.BatchableContext - Batchable Context
    */  
    public void finish(Database.BatchableContext bc){  
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        String reducedExceptionMsg = '';
        
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){ //Check whether Batch Job has been updated by Batch Platform Event or Not
            hasError = true;
        }
        if(hasError){ //Update Batch Job Status
            reducedExceptionMsg = (exceptionMsg != null  && exceptionMsg.length() >= 32768)? exceptionMsg.substring(0, 32768): exceptionMsg; 
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletSurveyFailureRecoveryBatch', reducedExceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    } 
}