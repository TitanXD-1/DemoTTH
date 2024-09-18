/*
 * Class Name : EDGE_PushNotificationHelper
 * @description: Helper Class for Push Notification
 * @history
 * VERSION    	AUTHOR              DATE              DETAIL
 * 1.0 -    	Amar Deep 	      	11/02/2021        ES20-9704 
 * 1.1 -    	Sayan Mullick 	    28/07/2021        ECM-4570 & ECM-4620
*/
public class EDGE_PushNotificationHelper {
    public static void pushNotificationMethod(List<ConnectApi.MessageSegment> messageSegments,string chatterBody,Map<String, Object> custom){
        
        Set<String> users = new Set<String>();
        String targetUserId = '';
        
        System.debug('custom' +custom);
        System.debug('messageSegments'+messageSegments);
        if(messageSegments != null && !messageSegments.isEmpty()){
            
            for (ConnectApi.MessageSegment messageSegment : messageSegments) {
                if (messageSegment instanceof ConnectApi.MentionSegment) {
                    ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                    targetUserId = mentionSegment.record.Id;
                    //System.debug('Mentioned user name: ' + mentionSegment.name);
                    //System.debug('Mentioned user id: ' + mentionSegment.record.Id);
                } 
                
                users.add(targetUserId);
            } 
        }
        
        //ECM-4570 & ECM-4620
        else if(messageSegments == null && !custom.isEmpty() && custom.containsKey('OwnerId')){            
            users.add(String.valueOf(custom.get('OwnerId')));
            System.debug('User from Push Notification'+users);
        }
        
        // Instantiating a notification
        Messaging.PushNotification msg = new Messaging.PushNotification();
        String chatterMessage = '';
        String userName = '';
        Map<String, Object> payload = Messaging.PushNotificationPayload.apple(chatterBody, '', null, custom);
        // Adding the assembled payload to the notification
        msg.setPayload(payload);
        
        // Adding recipient users to list
        System.debug('users = '+ users);
        if(!Test.isRunningTest() && !users.isEmpty()){
            msg.send('Edge_SFA_2_0', users);
        }
        
    }

}