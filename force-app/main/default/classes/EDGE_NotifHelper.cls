/**
* @Name: EDGE_NotifHelper
* @Test class: EDGE_ReleasePushNotifExtendedHelperTest
* @Req: Sending push notification for Android and IOS
* @History                                                            
* @VERSION   AUTHOR                   DATE              DETAIL
*  1.0       Shivam Chauhan           31/05/2023        ES20-13851
*/
public with sharing class EDGE_NotifHelper {
    /*
* Method  : sendAndroidNotificationToUsers
* Purpose : This method will send push notification to Android Users
*/
    public static void sendAndroidNotificationToUsers(Map<String,Map<String,Object>> idCustomMsg){
        Set<String> usersToNotify = new Set<String>();
        final String edgeConnectedApp = System.Label.EDGE_ConnectedAppAndroid;  //'Edge_365_Android'
        Messaging.PushNotification msg = new Messaging.PushNotification();
        Map<String,Object> custom = new Map<String,Object>();
        
        if(!idCustomMsg.isEmpty()) {
            for(String individual: idCustomMsg.keyset()) {
                usersToNotify.add(individual);
            }
        }
        
        for(string key: idCustomMsg.keyset()){
            custom=idCustomMsg.get(key);
            msg.setPayload(custom);
        }
        
        if(!Test.isRunningTest() && usersToNotify != null && usersToNotify.size()>0){
            msg.send(edgeConnectedApp, usersToNotify);
        }
    }
    
    /*
* Method  : sendIosNotificationToUsers
* Purpose : This method will send push notification to IOS Users
*/
    public static void sendIosNotificationToUsers(Map<String,String> idCustomMsgIosBody,Map<String,Map<String,Object>> idCustomMsgIosType) {
        Set<String> usersToNotify = new Set<String>();
        final String edgeConnectedApp = System.Label.EDGE_ConnectedApp; // 'Edge_SFA_2_0'
        Messaging.PushNotification msg = new Messaging.PushNotification();
        Map<String,Object> customType = new Map<String,Object>();
        
        if(!idCustomMsgIosType.isEmpty()) {
            for(String individual: idCustomMsgIosType.keyset()) {
                usersToNotify.add(individual);
            }
        }
        
        for(string key: idCustomMsgIosType.keyset()){
            customType =idCustomMsgIosType.get(key);
            
            Map<String, Object> payload = Messaging.PushNotificationPayload.apple(idCustomMsgIosBody.get(key),null,null,customType);
            msg.setPayload(payload);
        }
        
        if(!Test.isRunningTest() && usersToNotify != null && usersToNotify.size()>0){
            msg.send(edgeConnectedApp, usersToNotify);
        }
    }
    
}