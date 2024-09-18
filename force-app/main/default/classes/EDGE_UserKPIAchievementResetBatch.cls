/**
* @description : EDGE_UserKPIAchievementResetBatch
* @purpose : Reseting KPIAchivement related fields on User KPI as 0 when new market cycle is starting for a particular market
User Story : ES20-11092
* @history
* Version   Developer         Date             User Story	          			  Purpose
*  1.0      Mayank Singh      11/10/2021       Initial Development(ES20-11092)    Reseting KPIAchivement related fields on User KPI as 0 when new market cycle is starting for a particular market

*  2.0      Debolina Saha     10/02/2022       ES20-11557						  Market Cycle_Case Task vs SLA/Total_Refresh logic for Quality KPIs_SFDC_KPIs for Quality
*  3.0      Anamika Shukla    22/02/2022       ES20-12094		                  Base Achievement Refresh for User KPIs

*/
public class EDGE_UserKPIAchievementResetBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    public Market_Batch_Setting__mdt batchSetting;
    string countryCode = '';
    List<Market_Cycle__c> marketCycleRecord;
    Date actvMarketCycleStartDate;
    Date actvMarketCycleEndtDate;
    Date todayDate;
    public boolean isMarketCycleStart = false;
    Id marketBatchJobId;
    boolean hasError = false ;
    public boolean firstDayOfMonthMatch = false;
    string exceptionMsg = '';
    List<String> profileList = new List<String>();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());     
        countryCode = batchSetting.Country_Code__c;
        todayDate = Date.today();
        String queryString = '';
        marketCycleRecord = [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,
                             End_Date__c,Geography__r.Code__c from Market_Cycle__c 
                             WHERE Geography__r.Code__c =: countryCode AND Active__c= True LIMIT 1] ;
        
        String profilesStr = Label.EDGE_User_KPI_Reset_Batch_Profiles;      
        if(profilesStr != null)
            profileList = profilesStr.split(',');
        
        if(marketCycleRecord!=null && marketCycleRecord.size()>0){
            actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
            actvMarketCycleEndtDate = marketCycleRecord[0].End_Date__c; 
        }
        
        if(actvMarketCycleStartDate == todayDate){
            isMarketCycleStart = true;  
        }
        
        if(isMarketCycleStart){
            list<String> kpiTypes = Label.EDGE_KPIType.split(',');
            
            
            queryString = 'SELECT Id,Actual_Achievement__c,Actual_Numerator__c,KPI_Type__c,RecordTypeId,Achievement__c,Base_Achievement__c,' +
                
                ' Target_Number__c,Total_Denominator__c, User__c FROM KPI_Achivement__c WHERE RecordType.name =\'User KPI\' AND'+ 
                ' Country__r.Code__c = \'' + countryCode + '\' AND KPI_Type__c in :kpiTypes AND  '+
                ' User__r.Profile.Name in :profileList'; 
        }else{
            queryString = 'SELECT Id FROM KPI_Achivement__c Limit 0';  //Adding dummy query to run the batch with 0 data.
        }
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<KPI_Achivement__c> kpiAchivementList){ 
        List<KPI_Achivement__c> kpiAchievmentUpdatedList = new List<KPI_Achivement__c>();
        Set<Id> userAssignIds = new Set<Id>();
        Map<String,Integer> userAssignCountMap =  new Map<String,Integer>();
        try{
            if(kpiAchivementList!=null){
                for(KPI_Achivement__c kpiAchivementObj : kpiAchivementList){
                    if(kpiAchivementObj.KPI_Type__c == 'Case Task vs Total' || kpiAchivementObj.KPI_Type__c == 'Case Task vs SLA'){
                        if(kpiAchivementObj.User__c != null){
                            userAssignIds.add(kpiAchivementObj.User__c);  
                        }
                    }
                }
                System.debug('User List : ' + userAssignIds);
            }
            for(sobject cstList : [SELECT user_Assigned_To__c, count(Id) countOfOpenCTs FROM Case_Task__c WHERE Achievement_Status__c IN ('Open','Pending') AND user_Assigned_To__c IN:userAssignIds group by user_Assigned_To__c]){
                userAssignCountMap.put((String) cstList.get('user_Assigned_To__c'), (Integer)cstList.get('countOfOpenCTs'));
                //mapping the users and the count of open or pending casetasks assigned to the users
            }
            if(kpiAchivementList!=null){
                for(KPI_Achivement__c kpiAchivementObj : kpiAchivementList){
                    if(isMarketCycleStart){
                        kpiAchivementObj.Actual_Numerator__c = 0;               
                        
                        
                        kpiAchivementObj.Previous_Achievement__c = 0;
                        kpiAchivementObj.Total_Outlets__c = 0;
                        kpiAchivementObj.Target__c = 0;
                        kpiAchivementObj.Target_Number__c = 0;
                        
                        kpiAchivementObj.Base_Achievement__c=kpiAchivementObj.Achievement__c;
                        kpiAchivementObj.Achievement__c = 0;
                        
                        if(kpiAchivementObj.KPI_Type__c == 'Case Task vs Total' || kpiAchivementObj.KPI_Type__c == 'Case Task vs SLA'){    //ES20-11557
                            Id kpiAchvUserId = kpiAchivementObj.User__c;      
                            kpiAchivementObj.Total_Denominator__c = userAssignCountMap.containsKey(kpiAchvUserId) && userAssignCountMap.get(kpiAchvUserId)!= null ? userAssignCountMap.get(kpiAchvUserId) :0;
                        }
                        else{
                            kpiAchivementObj.Total_Denominator__c = 0;
                            
                        }
                        kpiAchievmentUpdatedList.add(kpiAchivementObj);
                    }
                    
                }//end of for loop
                System.debug('KPI List'+ kpiAchievmentUpdatedList);
                //Update KPI_Achivement record
                if(!kpiAchievmentUpdatedList.isEmpty()){
                    //update kpiAchievmentUpdatedList; 
                    database.update(kpiAchievmentUpdatedList,false);
                }
            }
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UserVisitsKPIBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}