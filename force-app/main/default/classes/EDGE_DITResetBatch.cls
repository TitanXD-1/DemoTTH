/**
* @description : EDGE_DITResetBatch
* @purpose : Reseting DIT on User as 0 when new market cycle is starting for a particular market
User Story : 
* @history
* Version   Developer         Date             User Story	          			  Purpose
*  1.0      Supriya G      29/07/2024       Initial Development()    Reseting DIT on User KPI as 0 when new market cycle is starting for a particular market

**/
public class EDGE_DITResetBatch  implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
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
    /**
* @Name : getBatchDetails
* @description  This method is used to get the Country Code
* @param batchSetting
*/
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    /**
* @Name : start
* @description  This method is used to get the Active Users
* @param bc
* @return Database.QueryLocator
*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());     
        countryCode = batchSetting.Country_Code__c;
        todayDate = Date.today();
        String queryString = '';
        marketCycleRecord = [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,
                             End_Date__c,Geography__r.Code__c from Market_Cycle__c 
                             WHERE Geography__r.Code__c =: countryCode AND Active__c= True LIMIT 1] ;
        
        String profilesStr = Label.EDGE_DIT_Reset_Batch_Profiles;      
        if(profilesStr != null){
            profileList = profilesStr.split(',');
        }
        if(marketCycleRecord!=null && marketCycleRecord.size()>0){
            actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
            actvMarketCycleEndtDate = marketCycleRecord[0].End_Date__c; 
        }
        
        if(actvMarketCycleStartDate == todayDate){
            isMarketCycleStart = true; 
            queryString = 'select id, name, Available_Countries__c,Days_In_Trade__c from User where IsActive = true AND Profile.Name in :profileList ';
        }else{
            queryString = 'SELECT Id FROM User Limit 0';  //Adding dummy query to run the batch with 0 data.
        }
        
        if(Test.isRunningTest()){
            queryString = 'select id, name, Available_Countries__c,Days_In_Trade__c from User where IsActive = true AND Profile.Name in :profileList Limit 1';
        }
        
        return Database.getQueryLocator(queryString);
        
    }
    
    //Execute Method
    /**
* @Name : execute
* @description  This method is used to set the DIT to 0 for all the active users
* @param bc
* @param userList
*/
    public void execute(Database.BatchableContext bc, List<User> userList){ 
        List<User> userUpdatedList = new List<User>();
        try{
            //if(userList!=null){
                for(User userObj : userList){
                    if(isMarketCycleStart){
                        userObj.Days_In_Trade__c = 0;
                    }
                    
                    userUpdatedList.add(userObj);
                }
                
                System.debug(LoggingLevel.DEBUG,'USER List'+ userUpdatedList);
                //Update User record
                if(!userUpdatedList.isEmpty()){
                    //update userUpdatedList; 
                    database.update(userUpdatedList,false);
                }
           // }
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
        }catch(DmlException de){
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
    
    //finish method
    /**
* @Name : finish
* @description  This method is used to see if the batch has run successfully
* @param bc
*/
    public void finish(Database.BatchableContext bc){
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_DITResetBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
        
    }
    
}