/**

* @Description: EDGE_OrderPushNotifHelper

* @Purpose : Order Push Notification 

* @History:

* @Version     Developer		   Date			     Story/Purpose
*    1.1       Aanand		      11/05/2022		 ES20-12619(Method:outMemDetails,pushNotificationMethodforOrder)
*    1.2       Supriya			  11/05/2022          ES20-12621(Method:outMemDetails,pushNotificationMethodforOrder)
*/

public without sharing class EDGE_OrderPushNotifHelper {
    
    public static final String EDGE_Connected_App = 'Edge_SFA_2_0';
    
        /**
* @description : populateOutMemDetails method collects the OutletMember details of Account tagged to Order and PushNotification message
               for POS and Transfer Order
* @return : void
* @param : List<Order__c> , Boolean
*/
    public static void populateOutMemDetails(List<Order__c> ordersList, Boolean posOrder){
        Set<Id> accIds = new Set<Id>();
        Map<Id,String> accRecs =new Map<Id,String>();
        Map<Id,List<String>> accToUsersMap = new Map<Id,List<String>>();
        String beforeMsg =''; 
        String message='';
        Map<String,Object> custom = new Map<String,Object>();
        List<String> usersToNotifyList = new List<String>();
        if(!posOrder){
            message = System.label.EDGE_MsgForTranferOrderPushNotification;
        }
        else{
            message=System.label.EDGE_MsgForPOSOrderPushNotification;
        }
        beforeMsg=message.substringBefore('.');
        String msgAfter=message.substringAfter('.');
        
        
        for(order__c ordRec : ordersList){
            accIds.add(ordRec.Account__c);
        }
        
        for(Outlet_Member__c outMember:[SELECT ID,Name,Outlet__c,Outlet__r.name,User__c FROM Outlet_Member__c WHERE outlet__c IN :accIds]){
            accRecs.put(outMember.Outlet__c,outMember.Outlet__r.name);
            if(accToUsersMap.containsKey(outMember.Outlet__c)){
                accToUsersMap.get(outMember.Outlet__c).add(outMember.User__c);
            }
            else{
                accToUsersMap.put(outMember.Outlet__c,new List<String> {outMember.User__c});
            }
            
        }
        
        //Sending Push-Notification
        for(Order__c orderObj : ordersList)
        {         
         if(accToUsersMap!=null && accToUsersMap.size()>0)
         {                
             if(orderObj.Account__c != null)
             {   
              beforeMsg+=accRecs.get(orderObj.Account__c)+'.';
              String pushNotifMsg=beforeMsg+msgAfter;
              usersToNotifyList = accToUsersMap.get(orderObj.Account__c);
              String msgBody = pushNotifMsg.stripHtmlTags();
              custom.put('AccountID',orderObj.Account__c);
              custom.put('Type','Order');
              pushNotificationMethodforOrder(usersToNotifyList, msgBody, custom);                    
             }
         }
        }
    }
            /**
* @description : pushNotificationMethodforOrder method sends the pushnotification to FE users(outlet Members)
* @return : void
* @param : List<user> , Map<String, Object> , String
*/
    public static void pushNotificationMethodforOrder(List<String> users, String msgBody, Map<String, Object> custom){
        
        Set<String> usersList = new Set<String>();       
        if(users != null && !users.isEmpty()){
            usersList.addAll(users);
            System.debug('@@@'+users);
            Messaging.PushNotification msg = new Messaging.PushNotification();
            Map<String, Object> payload = Messaging.PushNotificationPayload.apple(msgBody,null,null,custom);
            msg.setPayload(payload);
            System.debug('@@@payload'+payload);
            if(!Test.isRunningTest()){
                msg.send(EDGE_Connected_App, usersList);  
            }
        }               
    } 
}