/**
* @Name: EDGE_ReleasePushNotifExtendedHelper
* @Test class: EDGE_ReleasePushNotifExtendedHelperTest
* @Req: Sending push notification prior and post release for Android
* @User Story : ES20-13576,ES20-13744
* @History                                                            
* @VERSION   AUTHOR                   DATE              DETAIL
*  1.0       Mayukh SRoy             13/01/2023        Initial development for ES20-13576
*  1.1       Mayukh SRoy              30/01/2023        For development ES20-13744 to Enable release notifications on Android App
*/

public with sharing class EDGE_ReleasePushNotifExtendedHelper {
    
    public static void sendAndroidNotificationToUsers(List<User> users, String notifText){
        Set<String> usersToNotify = new Set<String>();
        final String edgeConnectedApp = System.Label.EDGE_ConnectedAppAndroid;  //'Edge_365_Android' //ES20-13744
        Messaging.PushNotification msg = new Messaging.PushNotification();
        Map<String,Object> custom = new Map<String,Object>();
        if(!users.isEmpty()) {
            for(User individual: users) {
                usersToNotify.add(individual.Id);
            }
        }
        
        custom.put('Type',String.valueOf(Label.EDGE_ReleaseNotificationRecordType));
        custom.put('Body',notifText);
        
        msg.setPayload(custom);
        
        System.debug(Logginglevel.INFO,'release notif users '+usersToNotify);
        System.debug(Logginglevel.INFO,'release notif msg '+msg);

        if(!Test.isRunningTest() && usersToNotify != null && usersToNotify.size()>0){
            msg.send(edgeConnectedApp, usersToNotify);
        }
    }
}