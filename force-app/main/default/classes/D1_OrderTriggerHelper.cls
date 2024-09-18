/**
 * @name D1_OrderTriggerHelper
 * @purpose Trigger Helper Class for OrderTriggerHandler
 * @history                                                                                                                       
 * VERSION   AUTHOR             DATE              DETAIL
 * 1.0       Rubeena Naaz       26/07/2021        NCP-3874,NCP-3826,NCP-3818
 * 2.0       Rubeena Naaz       25/10/2021        NCP-5085
 * 3.0       Rubeena Naaz       09/11/2021        NCP-5117
 * 4.0       Rubeena Naaz       07/06/2022        NCP-6835
**/
public without sharing class D1_OrderTriggerHelper {
    /**
     *  @description Method to send notification to contacts if POS orders gets Approved/Rejected
     *  @param {Map<Id, sObject>} newItems 
     *  @param {Map<Id, sObject>} oldItems
     **/
    public static void posOrderNotification(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        Map<Id,Order__c> newItemMap = (Map<Id,Order__c>) newItems;
        Map<Id,Order__c> oldItemMap;
        Id posOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        Set<String> contactIds =new Set<String>();
        String body;
        String title = 'D1_POS_Order_Title';
        String targetPageRef = 'my-orders?selectedPOSOrderId='; //NCP-5117
        String notificationName='D1_Nozzle_and_Glassware_Status_Update';
        //List<String> customLabelValue = new List<String>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Set<String>> accountContactsMap = new  Map<Id,Set<String>>();
        List<Order__c> orderList = new List<Order__c>();
        
        if(oldItems!=null){
            oldItemMap = (Map<Id,Order__c>) oldItems;
        }
        
        for(Order__c newOrder : newItemMap.values()){
            Order__c oldOrder;
            if(oldItemMap != null){
                oldOrder = oldItemMap.get(newOrder.Id); 
            }
            if(oldOrder!=null && newOrder.Status__c != oldOrder.Status__c && (newOrder.Status__c=='Approved' || newOrder.Status__c=='Rejected')
                && newOrder.Source_Application__c == 'Diageo One' && newOrder.RecordTypeId == posOrderRecTypeId)
            {
                accountIds.add(newOrder.Account__c); //NCP-5117
                orderList.add(newOrder); //NCP-5117
            }
            
        }

        if(accountIds!=null){
            for(AccountContactRelation acrRecord : [SELECT Id,ContactId,AccountId  FROM AccountContactRelation 
                                                    WHERE AccountId IN :accountIds
                                                    AND D1_Active__c = true AND D1_Roles__c INCLUDES ('POS & Equipment Ordering')])
            {
                if(accountContactsMap.containsKey(acrRecord.AccountId)){
                    accountContactsMap.get(acrRecord.AccountId).add(acrRecord.ContactId); 
                }
                else{
                    accountContactsMap.put(acrRecord.AccountId, new Set<String>{acrRecord.ContactId});
                }
            }
        }

        if(accountContactsMap.size()>0 && orderList.size()>0){
            for(Order__c orderRec: orderList){
                List<String> customLabelValue = new List<String>(); //NCP-5117
                if(accountContactsMap.get(orderRec.Account__c)!=null && accountContactsMap.get(orderRec.Account__c).size()>0){
                    contactIds = accountContactsMap.get(orderRec.Account__c);
                    body = (orderRec.Request_Type__c=='Equipment') ? 'D1_Nozzle_Body' : 'D1_Glassware_Body'; //NCP-5487
                    customLabelValue.add(orderRec.Name);
                    if(orderRec.Status__c =='Approved'){//NCP-5633
                         customLabelValue.add('D1_Order_Status_Approved');
                        }
                    else{//NCP-5633
                        customLabelValue.add('D1_Order_Status_Rejected');
                    }
                    if(!Test.isRunningTest()){
                        D1_CustomNotificationUtility.notifyUsers(contactIds, notificationName, title, body, null, targetPageRef+orderRec.Id, customLabelValue, customLabelValue); //NCP-5117
                    }
                }     
            }                              
        }
    }
    
    /**
     *  @description Method to send notification to contacts for tracking Transfer Order was delivered or not.
     *  @param {List<Order__c>} orderList
     **/
    @InvocableMethod(label='Transfer Order Delivery')
    public static void transferOrderNotification(List<Order__c> orderList){
        Set<String> contactIds =new Set<String>();
        String body='D1_Transfer_Order_Delivery_Body';
        String title='D1_Transfer_Order_Delivery_Title';
        String targetPageRef = 'my-orders?selectedOrderId=';
        String notificationName='D1_Transfer_Order_Delivery_Update';
        Map<Id,List<Order__c>> accountOrderMap = new Map<Id,List<Order__c>>();
        Map<Id,Set<String>> accountContactsMap = new  Map<Id,Set<String>>();
        
        
        //NCP-5085
        Map<Id,List<Order__c>> orderContactMap = new Map<Id,List<Order__c>>();
        Map<Id,User> contactUserMap = new Map<Id,User>();
        List<Order__c> newOrderList = new List<Order__c>();
        List<Messaging.SingleEmailMessage> mailsToSend = new list<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemp =[SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName ='D1_Transfer_Order_Delivery_Acknowledgement_Emails'];
        String redirectLink = System.Label.D1_Community_Link +'/'+ targetPageRef;
        
        if(orderList!=null){
            for(Order__c order : orderList){
                //NCP-5085
                if(order.Status__c != 'Order Delivered'){
                    
                    if(accountOrderMap.containsKey(order.Account__c)){
                        accountOrderMap.get(order.Account__c).add(order);
                    }
                    else{
                        accountOrderMap.put(order.Account__c, new List<Order__c>{order});
                    }
                    newOrderList.add(order);
                }
            }
        }
        
        if(accountOrderMap.size()>0){
            for(AccountContactRelation acrRecord : [SELECT Id, ContactId, AccountId FROM AccountContactRelation 
                                                    WHERE AccountId IN :accountOrderMap.keyset()
                                                    AND D1_Active__c = true 
                                                    AND D1_Roles__c INCLUDES ('Transfer Orders')])
            {
                if(accountContactsMap.containsKey(acrRecord.AccountId)){
                    accountContactsMap.get(acrRecord.AccountId).add(acrRecord.ContactId);
                }
                else{
                    accountContactsMap.put(acrRecord.AccountId, new Set<String>{acrRecord.ContactId});
                }
                
                //creating Contact and order map 
                //NCP-5085
                List<Order__c> ords = accountOrderMap.get(acrRecord.AccountId);
                orderContactMap.put(acrRecord.ContactId,ords);
            }
        }
        if(accountContactsMap.size()>0 && accountOrderMap.size()>0 ){
            for(Order__c orderRcd : newOrderList){ 
                if(accountContactsMap.get(orderRcd.Account__c).size()>0){
                    contactIds = accountContactsMap.get(orderRcd.Account__c);
                    if(!Test.isRunningTest()){
                        D1_CustomNotificationUtility.notifyUsers(contactIds, notificationName, title, body, null, targetPageRef+orderRcd.Id, null, null); //Gaurav Change
                    }
                }
            }
        }
        
        //NCP-5085
        if(orderContactMap.size()>0){
            
            for(User user : [SELECT Id,IsActive,ContactId,LanguageLocaleKey FROM User WHERE ContactId IN :orderContactMap.keyset() AND IsActive = true]){
                contactUserMap.put(user.ContactId,user);
            }
      
            for(Contact cont : [Select Id,Email,FirstName,  D1_User_Type__r.Customer_Service_Group__c  from Contact where Id IN : orderContactMap.keyset()]){
                
                String userLang = contactUserMap.get(cont.Id).LanguageLocaleKey;
                
                Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'D1_Hi', 'D1_Any_Questions_text','D1_Transfer_Order_Delivery_1',
                'D1_Transfer_Order_Delivery_2','D1_Transfer_Order_Delivery_3','D1_Transfer_Order_Email_Body_8','D1_Transfer_Order_Email_Body_7','D1_Transfer_Order_Footer',
                'D1_Transfer_Order_Footer_2','D1_Transfer_Order','D1_Transfer_Order_Delivery_4','D1_Transfer_Order_Footer_1','D1_Copyright_2020_All_rights_reserved_Diageo_PLC','D1_Transfer_Order_Acknowledgement'},userLang);
                
                List<Order__c> orders = orderContactMap.get(cont.Id);
                if(orders.size()>0){
                    for(Order__c orderRcd : orders){
                        String emailBody  = emailTemp.HtmlValue;
                        
                        emailBody  = emailBody.replace('{!Receiving_User.FirstName}', cont.FirstName);
                        emailBody  = emailBody.replace('{!OrderNumber}', orderRcd.Name);
                        emailbody  = emailBody.replace('{!Community_Url}',redirectLink+orderRcd.Id);
                        String csgMail = cont.D1_User_Type__r.Customer_Service_Group__c != null ? cont.D1_User_Type__r.Customer_Service_Group__c : '';
                        emailbody  = emailBody.replace('{!Receiving_User.D1_UserType_CSG_Email__c}',csgMail);
                        
                        emailbody   = emailBody.replace('{!$Label.D1_Hi}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Hi')));
                        emailbody   = emailBody.replace('{!$Label.D1_Any_Questions_text}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Any_Questions_text')));
                        emailbody   = emailBody.replace('{!$Label.D1_Transfer_Order_Delivery_1}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Delivery_1')));
                        emailbody   = emailBody.replace('{!$Label.D1_Transfer_Order_Delivery_2}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Delivery_2')));
                        emailbody   = emailBody.replace('{!$Label.D1_Transfer_Order_Delivery_3}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Delivery_3')));
                        emailBody  = emailBody.replace('{!$Label.D1_Transfer_Order_Email_Body_8}', returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Transfer_Order_Email_Body_8')));
                        emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Email_Body_7}', returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Transfer_Order_Email_Body_7')));
                        emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Footer')));
                        emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_1}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Footer_1')));
                        emailbody  = emailBody.replace('{!$Label.D1_Transfer_Order_Footer_2}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Footer_2')));
                        emailbody  = emailBody.replace('{!$Label.D1_Copyright_2020_All_rights_reserved_Diageo_PLC}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Copyright_2020_All_rights_reserved_Diageo_PLC')));
                        emailbody   = emailBody.replace('{!$Label.D1_Transfer_Order}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order')));
                        emailbody   = emailBody.replace('{!$Label.D1_Transfer_Order_Delivery_4}', returnDefaultIfBlank( labelToTranslatedStrMap.get('D1_Transfer_Order_Delivery_4')));
            
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTemp.Id);
                        mail.setSubject(returnDefaultIfBlank(labelToTranslatedStrMap.get('D1_Transfer_Order_Acknowledgement')));
                        mail.setToAddresses(new String[] {cont.Email});
                        mail.setHtmlBody(emailBody);
                        mailsToSend.add(mail);
                    }
                }   
            }
            
            if(!mailsToSend.isEmpty()){
                Messaging.sendEmail(mailsToSend);
            }
        }
    }
    
    private static String returnDefaultIfBlank(String value){
        return String.isEmpty(value) ? ' ' : value;
    }
    
     /**
     * @userStory : NCP-6835
     * @description : Updates POS Order date on related ACR and Account 
     * @param newItems 
     * @param oldItems 
     */
    public static void updatePOSOrderDate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id,Order__c> newOrderMap = (Map<Id,Order__c>) newItems;
        
        List<Account> toUpdateAccount = new List<Account>();
        List<AccountContactRelation> toUpdateACR = new List<AccountContactRelation>();
        
        Set<id> accountIdSet = new Set<Id>();

        Map<Id,Order__c> oldOrderMap;
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order__c>) oldItems;
        }

        for(Order__c newOrderItem : newOrderMap.values()){
            Order__c oldOrderItems;
            if(oldOrderMap != null){
                oldOrderItems = oldOrderMap.get(newOrderItem.Id); 
            }
            if(newOrderItem !=null &&  newOrderItem.Source_Application__c == 'Diageo One' && newOrderItem.Record_Type_Name__c == 'POS Order'){
                accountIdSet.add(newOrderItem.Account__c);

                Account acc = new Account(Id=newOrderItem.Account__c);
                acc.Last_POS_Order_Date__c = System.now();
                toUpdateAccount.add(acc);
                
            }
            
        }

        //Update Order approved Date on Account and related ACR
        if(!accountIdSet.isEmpty()){
            for(AccountContactRelation acr : [SELECT Id,Last_POS_Order_Date__c,D1_Roles__c,AccountId  
                                              FROM AccountContactRelation 
                                              WHERE AccountID IN : accountIdSet AND D1_Roles__c INCLUDES('POS & Equipment Ordering') AND D1_Active__c = True
                                              ORDER BY AccountID ]){
                acr.Last_POS_Order_Date__c = System.now();
                toUpdateACR.add(acr);
            }
        }

        if(!toUpdateAccount.isEmpty()){
            update toUpdateAccount;
        }

        if(!toUpdateACR.isEmpty()){
            update toUpdateACR;
        }
    }
}