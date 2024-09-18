/**
* @Name: EDGE_PushNotificationPriorReleaseBatch
* @Test class: EDGE_PushNotifPriorReleaseBatch_Test
* @Req: Sending push notification prior and post release
* @User Story : ES20-13542, ES20-13708
* @History                                                            
* @VERSION   AUTHOR                   DATE              DETAIL
*  1.0       Wribhu Bose              05/01/2023        Initial development for ES20-13542: sending push notification prior to release
*  1.1       Shivam Chauhan           10/01/2023        ES20-13708: added post-release notification logic
*  1.2       Mayukh S Roy             02/03/2023		ES20-13877: Sanity_defect: Push notifications are received for both prior and post release notification.
*/

public class EDGE_PushNotificationPriorReleaseBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    String countryCode = '';
    Id marketBatchJobId;
    Date currentDay = System.today();
    List<Notification__c> priornotifRecord = new List<Notification__c>();
    
    /**
    * @Description: Interface class method which fetches batch details for corresponding market
    * @Returns: void
    * @Param: Market_Batch_Setting__mdt (market batch setting metadata)
    */
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting) {
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    /**
    * @Description: Start method of batch
    * @Returns: Database.QueryLocator
    * @Param: Database.BatchableContext
    */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        List<String> allowedProfiles = new List<String>();
        allowedProfiles = Label.EDGE_Release_Notification_Profiles.split(';');
        String strQuery = 'SELECT Id, Name, Available_Countries__c,Default_Country__c FROM User WHERE IsActive = true AND Available_Countries__c Includes (:countryCode) AND Profile.Name IN :allowedProfiles';
        return Database.getQueryLocator(strQuery);
    }
    
    /**
    * @Description: Execute method of batch
    * @Returns: void
    * @Param: Database.BatchableContext, List<User> (all active users from the country to whom the notification will be sent)
    */
    public void execute(Database.BatchableContext bc, List<User> usersList) {
        
        List<User> users = new List<User>();
        String userCC = '';
        
        for(User individual: usersList) {
            userCC = EDGE_BatchUtilityClass.getUserCountryCode(individual.Default_Country__c,individual.Available_Countries__c);
            if(userCC == countryCode) {
                users.add(individual);
            }
        }
        
        
        String edge365ReleaseNotificationRecType = Label.EDGE_ReleaseNotificationRecordType; // 'EDGE365 Release Notifications'
        priornotifRecord = [SELECT Id, Start_Date__c, End_Date__c, Duration_Interval__c, Next_Batch_Run_Date__c, Short_Description__c, Release_Completed__c, Country__r.Code__c
                                             FROM Notification__c
                                             WHERE RecordType.Name =: edge365ReleaseNotificationRecType
                                             AND Country__r.Code__c =: countryCode AND Release_Completed__c = false 
                                             AND (Start_Date__c =: currentDay OR Next_Batch_Run_Date__c =: currentDay OR End_Date__c =: currentDay) //ES20-13877
                                             ORDER BY Start_Date__c DESC LIMIT 1];
        
        List<Notification__c> notifRecordPostRelease = [SELECT Id, Start_Date__c, End_Date__c, Duration_Interval__c, Next_Batch_Run_Date__c, Short_Description__c, Release_Completed__c,Post_Release__c, Country__r.Code__c
                                                        FROM Notification__c
                                                        WHERE RecordType.Name =: edge365ReleaseNotificationRecType
                                                        AND Country__r.Code__c =: countryCode
                                                        AND Release_Completed__c = true AND End_Date__c >= Last_N_Days:3];
        
        try{
            if(!priornotifRecord.isEmpty()) {
                EDGE_ReleasePushNotificationHelper.sendPriorReleaseNotification(users,priornotifRecord[0],currentDay);
        } else {
                System.debug(Logginglevel.DEBUG,'Error: No notification records found for prior release');
        }
        
        if(!notifRecordPostRelease.isEmpty()) {
            EDGE_ReleasePushNotificationHelper.sendPostReleaseNotification(users,notifRecordPostRelease[0]);
        } else {
                System.debug(Logginglevel.DEBUG,'Error: No notification records found for post release');
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG,'@@Exception' + ex.getMessage());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    
    /**
    * @Description: Finish method of batch
    * @Returns: void
    * @Param: Database.BatchableContext
    */
    public void finish(database.BatchableContext bc) {
        // Get batch job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        // Check whether batch job has been updated by Batch Platform Event or not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed') {
            hasError = true;
        }
        
        // Update batch job status
        if(hasError) {
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_PushNotificationPriorReleaseBatch', exceptionMsg);
        } else {
            //ES20-13877
            if(!priornotifRecord.isEmpty()){
                EDGE_ReleasePushNotificationHelper.setNextBatchRunDate(priornotifRecord[0],currentDay);
            }
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        // Schedule next batch from Batch Utility Class
        if(!Test.isRunningTest()) {
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}