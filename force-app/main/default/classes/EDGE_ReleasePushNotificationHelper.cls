/**
* @Name: EDGE_ReleasePushNotificationHelper
* @Test class: EDGE_PushNotifPriorReleaseBatch_Test
* @Req: Sending push notification prior and post release
* @User Story : ES20-13542, ES20-13708, ES20-13744
* @History                                                            
* @VERSION   AUTHOR                   DATE              DETAIL
*  1.0       Wribhu Bose              10/01/2023        Initial development for ES20-13542: created prior-release notification method
*  1.1       Shivam Chauhan           10/01/2023        ES20-13708: added post-release notification method
*  1.2       Mayukh SRoy			  30/01/2023        Sending push notification to android device-ES20-13744
*  1.3       Mayukh S Roy             02/03/2023		ES20-13877: Sanity_defect: Push notifications are received for both prior and post release notification.
*/

public with sharing class EDGE_ReleasePushNotificationHelper {
    
    /**
     * @Description: Sends notifications prior to release, recalculates next batch run date
     * @Returns: void
     * @Param: List<User> (list of users to send notification, passed from batch), Notification__c (the notification record), Date (current date)
     */
    public static void sendPriorReleaseNotification(List<User> users, Notification__c notifRecord, Date currentDay) {
        sendIosNotificationToUsers(users, notifRecord.Short_Description__c);
        EDGE_ReleasePushNotifExtendedHelper.sendAndroidNotificationToUsers(users, notifRecord.Short_Description__c); //ES20-13744
    }

    /**
     * @Description: Sends notifications post release
     * @Returns: void
     * @Param: List<User> (list of users to send notification, passed from batch), Notification__c (the notification record)
     */
    public static void sendPostReleaseNotification(List<User> users, Notification__c notifRecord) {
        sendIosNotificationToUsers(users, notifRecord.Post_Release__c);
        EDGE_ReleasePushNotifExtendedHelper.sendAndroidNotificationToUsers(users, notifRecord.Post_Release__c); //ES20-13744

    }

    /**
     * @Description: Sends notifications to users one by one
     * @Returns: void
     * @Param: List<User> (list of users to send notification), String (text to be passed in notification body)
     */
    public static void sendIosNotificationToUsers(List<User> users, String notifText) {
        Set<String> usersToNotify = new Set<String>();
        final String edgeConnectedApp = System.Label.EDGE_ConnectedApp; // 'Edge_SFA_2_0'
        Messaging.PushNotification msg = new Messaging.PushNotification();
        Map<String,Object> custom = new Map<String,Object>();
        
        if(!users.isEmpty()) {
            for(User individual: users) {
                usersToNotify.add(individual.Id);
            }
        }
        
        custom.put('Type',String.valueOf(Label.EDGE_ReleaseNotificationRecordType));
        Map<String, Object> payload = Messaging.PushNotificationPayload.apple(notifText,null,null,custom);
        msg.setPayload(payload);
        
        System.debug(Logginglevel.INFO,'release notif users '+usersToNotify);
        System.debug(Logginglevel.INFO,'release notif msg '+msg);

        if(!Test.isRunningTest() && usersToNotify != null && usersToNotify.size()>0){
            msg.send(edgeConnectedApp, usersToNotify);
        }
    }

    /**
     * @Description: Checks if a date is a weekend
     * @Returns: Boolean
     * @Param: Date (date to be checked)
     */
    public static Boolean isWeekend(Date passedDate) {
        Boolean isWeekend = false;
        Date startingDate = Date.newInstance(1900, 1, 7); // Sunday
        Integer dayOfWeek = Math.abs(Math.mod((startingDate.daysBetween(passedDate)),7));

        // 0 - Sun, 1 - Mon, 2 - Tue, 3 - Wed, 4 - Thu, 5 - Fri, 6 - Sat
        isWeekend = (dayOfWeek == 0 || dayOfWeek == 6) ? true : false;
        return isWeekend;
    }
    
    
    /**
     * @Description: Updates the Next Batch Run Date in Notification Record
     * @Returns: void
     * @Param: Notification__c (the notification record to be update), Date (current date)
     */
    public static void setNextBatchRunDate(Notification__c notifRecord,Date currentDay){
        Date nextBatchRunDate = currentDay;
        Integer interval = Integer.valueOf(notifRecord.Duration_Interval__c);
        
        // 1. The batch will next be run on the date coming after the number of days specified in the Duration_Interval__c field of the record
        // If that date goes beyond the end date specified, then the actual next date to run it is the day before the end date
        // NB: Once it reaches the date before end date, it always reverts to this date by the below condition.
        // There is no recursion as the date passes by the next time - and the end date condition finishes the checks for the record.
        
        if(currentDay.addDays(interval) >= notifRecord.End_Date__c) {
            nextBatchRunDate = notifRecord.End_Date__c.addDays(-1);
        } else {
            nextBatchRunDate = currentDay.addDays(interval);
        }
        
        // 2. Unless it is the day before the end date, for each weekend-day we will move forward by one day
        while (isWeekend(nextBatchRunDate) && nextBatchRunDate.addDays(1) != notifRecord.End_Date__c) {
            nextBatchRunDate = nextBatchRunDate.addDays(1);
        }
        
        // 3. The part of sending the notification ON the end day is handled in the query (always send), 
        // as is the scenario of next batch date appearing after a completed release (filtered out via checkbox check)
        if(notifRecord != null){
        	notifRecord.Next_Batch_Run_Date__c = nextBatchRunDate;
            Database.update(notifRecord,false);
        }
    }
}