/**********************************************************************
Name: EDGE_OrderItemCompliantBatch
=======================================================================
Req: Sending email with order details to Delivery Partner per territory if any defected order is reported
User Story : ES20-13055,ES20-12600
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                   DATE              DETAIL
1.0			Joshraj Sen			10/11/2022     Replacement request email sent to DP _SFDC_POS Enhancements (ES20-13055)
1.1       Swaraj Samanta        10/11/2022     Email template for replacement request email_SFDC_POS Enhancements(ES20-12600)

***********************************************************************/


public class EDGE_OrderItemComplaintBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass 
{
    String languageName = '';
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    public Map<Id,Set<Id>> territoryAccountMap=new Map<Id,Set<Id>>();
    public Map<String,List<Order_Item__c>> orderListOrderItemMap=new Map<String,List<Order_Item__c>>();
    public Map<Id,Set<EDGE_DefectedOrderWrapper>> outletOrderMap=new Map<Id,Set<EDGE_DefectedOrderWrapper>>();
    public Map<Id,String> territoryDeliveryPartnerMap=new Map<Id,String>();
    public Map<Id,Set<Id>> terrOrderMap = new Map<Id,Set<Id>>();
    public Map<Id,Set<Id>> outletOrderIdMap=new Map<Id,Set<Id>>();
    public Set<String> orderSet = new Set<String>();
    public List<Order_Item__c> allorderItemList = new List<Order_Item__c>();
    //Map<Id, Integer> terrIdOrderItemsTrack = new Map<Id, Integer>();
    //Map<Id, Integer> terrIdOrderItemsCount = new Map<Id, Integer>();
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        String[] orderItemBatchStatus=new String[]{'Item Missing','Item Expired','Item Damaged'};
        String activeString='Active';
        String queryString = 'SELECT Replacement_Mail_Sent_Date__c,Order__r.Account__r.Primary_Sales_Territory__c,Id,Status__c,Pending_Quantity__c,Delivered_Quantity__c,Quantity__c,Name,Product__r.Name,Product__r.Brand_Name__c,Product__r.Product_Full_Name__c,Order__c,Order__r.Name,Order__r.CreatedDate,'+
            'Order__r.Account__r.Name,Order__r.Sales_Representative__r.Email,Order__r.Sales_Representative__r.Name,Order__r.Account__c, Order__r.Account__r.Status__c, '+
            'Order__r.Account__r.Country_Code__c,Order__r.Delivery_Partner__r.Delivery_Partner_Email_For_Complaints__c from Order_Item__c '+
            'where Status__c in :orderItemBatchStatus and   Order__r.Delivery_Partner__r.Delivery_Partner_Email_For_Complaints__c !=null and '+
            'Order__r.Account__r.Status__c=:activeString and Order__r.Account__r.Country__r.Code__c=:countryCode and Replacement_Mail_Sent_Date__c = null';
        
        return Database.getQueryLocator(queryString);
        
    }
    public void execute(Database.BatchableContext bc, List<Order_Item__c> orderItemList){ 
        
        
       // Map<Id,EDGE_OrderIItemSalesrepWrapper> outletSalesRepMap=new Map<Id,EDGE_OrderIItemSalesrepWrapper>();
        Map<Id,String> outletDeliveryPartnerMap=new Map<Id,String>();
        Set<Id> outletIds=new Set<Id>();
        Set<String> outletOrderList=new Set<String>();
        EDGE_OrderIItemSalesrepWrapper salesrepDetails = new EDGE_OrderIItemSalesrepWrapper();
        
        
        //Language selection based on Country
        if(countryCode != null){
            List<Market_Setting__c> marketSetList = [Select Id, language__c from Market_setting__c where Geography__r.Code__c = :countryCode LIMIT 1];
            if(marketSetList!=null && marketSetList.size()>0){
                languageName = marketSetList[0].language__c;
            }  
        }
        
        for(Order_Item__c orderItem:orderItemList)
        {
            /*String terrId = orderItem.Order__r.Account__r.Primary_Sales_Territory__c;
            if(terrId != null){
                if(!terrIdOrderItemsTrack.containskey(terrId)){
                    terrIdOrderItemsTrack.put(terrId, 1);
                }else{
                    Integer count = terrIdOrderItemsTrack.get(terrId);
                    count++;
                    terrIdOrderItemsTrack.put(terrId,count);
                }
            }*/
            //Map of Order Id to List of related Order Item records
            if(orderListOrderItemMap.containsKey(orderItem.Order__c)){
                List<Order_Item__c> relatedOrderItemList = orderListOrderItemMap.get(orderItem.Order__c);
                relatedOrderItemList.add(orderItem);
                orderListOrderItemMap.put(orderItem.Order__c,relatedOrderItemList);
            }else{
                orderListOrderItemMap.put(orderItem.Order__c,new List<Order_Item__c> {orderItem});
            }
            
            if(outletOrderIdMap.containskey(orderItem.Order__r.Account__c)){
                
                if (orderSet.contains(orderItem.Order__c) == false){
                    
                    Set<EDGE_DefectedOrderWrapper> relatedOrderList = outletOrderMap.get(orderItem.Order__r.Account__c);
                    EDGE_DefectedOrderWrapper orderWrapper = new EDGE_DefectedOrderWrapper();
                    orderWrapper.id = orderItem.Order__c;
                    orderWrapper.orderNumber = orderItem.Order__r.Name;
                    orderWrapper.accountName = orderItem.Order__r.Account__r.Name;
                    orderWrapper.createdDate = orderItem.Order__r.CreatedDate;
                    relatedOrderList.add(orderWrapper);
                    //Map of Account Id to List of related Order Wrapper instances
                    outletOrderMap.put(orderItem.Order__r.Account__c,relatedOrderList); 
                    
                    orderSet.add(orderItem.Order__c);
                    
                    Set<Id> relatedOrderIdList = outletOrderIdMap.get(orderItem.Order__r.Account__c);
                    relatedOrderIdList.add(orderItem.Order__c);
                    //Map of Account Id to List of related Order Ids
                    outletOrderIdMap.put(orderItem.Order__r.Account__c, relatedOrderIdList);
                }
                
            }else{
                EDGE_DefectedOrderWrapper orderWrapper = new EDGE_DefectedOrderWrapper();
                orderWrapper.id = orderItem.Order__c;
                orderWrapper.orderNumber = orderItem.Order__r.Name;
                orderWrapper.accountName = orderItem.Order__r.Account__r.Name;
                orderWrapper.createdDate = orderItem.Order__r.CreatedDate;
                outletOrderMap.put(orderItem.Order__r.Account__c,new Set<EDGE_DefectedOrderWrapper>{orderWrapper});
                
                orderSet.add(orderItem.Order__c);
                
                outletOrderIdMap.put(orderItem.Order__r.Account__c, new Set<Id>{orderItem.Order__c});
            }

         //   salesrepDetails.salesRepName = orderItem.Order__r.Sales_Representative__r.Name;
          //  salesrepDetails.salesRepId = orderItem.Order__r.Sales_Representative__c;
          //  salesrepDetails.salesRepEmail = orderItem.Order__r.Sales_Representative__r.email;
            
            //Map of Account Id to Sales Rep Id ??? - what about secondary Rep
          //  outletSalesRepMap.put(orderItem.Order__r.Account__c,salesrepDetails);
            //Map of Account Id to Delivery Partner Complaint Email Id
            if(orderItem.Order__r.Delivery_Partner__c != null 
               && orderItem.Order__r.Delivery_Partner__r.Delivery_Partner_Email_For_Complaints__c != null)
            {
            	outletDeliveryPartnerMap.put(orderItem.Order__r.Account__c,orderItem.Order__r.Delivery_Partner__r.Delivery_Partner_Email_For_Complaints__c);
            }
            if(!outletIds.contains(orderItem.Order__r.Account__c)){
                outletIds.add(orderItem.Order__r.Account__c); //Will be used in the Outlet Territory Query
            }
            
            orderItem.Replacement_Mail_Sent_Date__c = datetime.now();
            allorderItemList.add(orderItem);
        }
        
        Set<Id> territoryIds = new Set<Id>();
        for(Outlet_Territory__c outletTerrritory:[Select Territory__c,Territory__r.Primary_Sales_rep__r.Name ,Outlet__c
                                                  from Outlet_Territory__c where Outlet__c in :outletIds and 
                                                  Active__c='Active' and Territory__r.RecordType.Name='Sales Territory'])
        {
            if(outletOrderMap.get(outletTerrritory.Outlet__c)!=null)
            {
                territoryIds.add(outletTerrritory.Territory__c);
                if(territoryAccountMap.containskey(outletTerrritory.Territory__c))
                {
                    Set<Id> relatedAccountList = territoryAccountMap.get(outletTerrritory.Territory__c);
                    relatedAccountList.add(outletTerrritory.Outlet__c);
                    territoryAccountMap.put(outletTerrritory.Territory__c,relatedAccountList);
                    Set<Id> relatedOrderIdList = terrOrderMap.get(outletTerrritory.Territory__c);
                    relatedOrderIdList.add(outletTerrritory.Outlet__c);
                    terrOrderMap.put(outletTerrritory.Territory__c, relatedOrderIdList);
                }
                else
                {
                    //Map of Territory Id to all related Outlet Ids (Set)
                    territoryAccountMap.put(outletTerrritory.Territory__c,new Set<Id>{outletTerrritory.Outlet__c});
                    //Map of Territory Id to all related Order Ids (Set)
                    terrOrderMap.put(outletTerrritory.Territory__c, outletOrderIdMap.get(outletTerrritory.Outlet__c));
                }
            }
            
          /*  if(outletSalesRepMap.containsKey(outletTerrritory.Outlet__c))
            {
                territorySalesRepMap.put(outletTerrritory.Territory__c,outletSalesRepMap.get(outletTerrritory.Outlet__c));
            }*/
            if(outletDeliveryPartnerMap.containsKey(outletTerrritory.Outlet__c))
            {
                territoryDeliveryPartnerMap.put(outletTerrritory.Territory__c,outletDeliveryPartnerMap.get(outletTerrritory.Outlet__c));
            }
            
        }
        
        
        /*for(AggregateResult aggrResult : [Select Count(Id) orderItemCount, Order__r.Account__r.Primary_Sales_Territory__c terrId from Order_Item__c 
                                          where Order__r.Account__r.Country__r.Code__c = :countryCode
                                          AND Status__c in ('Item Missing','Item Expired','Item Damaged') 
                                          group by Order__r.Account__r.Primary_Sales_Territory__c])
        {
            Integer orderItemsCount = (Integer)aggrResult.get('orderItemCount');
            String territoryId = (String)aggrResult.get('terrId');
            terrIdOrderItemsCount.put(territoryId,orderItemsCount);
        }*/
        
        
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){   
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        List<Messaging.SingleEmailMessage> mails=new List<Messaging.SingleEmailMessage>();
        String tempStr = countryCode+'_'+'MDM';//included for ES20-9247
        Map<Id,GroupMember> salesMembers = new Map<Id,GroupMember>(); 
        List<String> ccMail = new List<String>();
        String fileOwnerId='';
        Map<String,Set<Id>> fileMap=new Map<String,Set<Id>>();
        for(GroupMember sgm : [SELECT Group.Name,UserOrGroupId FROM GroupMember WHERE group.name =:tempStr and group.type='Queue' ]){   
            salesMembers.put(sgm.UserOrGroupId,sgm);
        } 
        
        for(User usr : [Select Id,email from User where Id IN : salesMembers.keySet()]){    
            ccMail.add(usr.email);  
        }
        if(!Test.isRunningTest())
        {
            List<EmailServicesAddress> serviceEmails=[SELECT Id,RunAsUserId,AuthorizedSenders,EmailDomainName,IsActive,LocalPart,Function.FunctionName FROM EmailServicesAddress where Function.FunctionName='EDGE_DeliveryPartnerEmailService' limit 1];
            String serviceEmailString='';
            if(serviceEmails!=null && serviceEmails.size()>0){
                serviceEmailString= serviceEmails[0].LocalPart+'@'+serviceEmails[0].EmailDomainName;
                ccMail.add(serviceEmailString); 
                fileOwnerId=serviceEmails[0].RunAsUserId;
            }
            
        }
             
         Map<Id,EDGE_OrderIItemSalesrepWrapper> territorySalesRepMap=new Map<Id,EDGE_OrderIItemSalesrepWrapper>();

        Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{ 'EDGE_Account_Name', 'EDGE_Order_ID', 'EDGE_OrderCreationDate','EDGE_Brand','EDGE_ItemName','EDGE_UnitsAffected','EDGE_Status','EDGE_Sender','EDGE_DefectedOrderBody','EDGE_ReplacementStatus','EDGE_DefectedOrderMailSubject'}, languageName);
        Date currentDate=System.today();
        for(Territory_Member__c terrMem: [ Select id,Territory__c,User__c,User__r.Name,User__r.email from Territory_Member__c where Territory__c IN : territoryAccountMap.keySet() AND Type__c = 'Primary' and (End_Date__c =null or End_Date__c >=:currentDate)]){
            
            EDGE_OrderIItemSalesrepWrapper salesrepDetails = new EDGE_OrderIItemSalesrepWrapper();

            salesrepDetails.salesRepName = terrMem.User__r.Name;
            salesrepDetails.salesRepId = terrMem.User__c;
            salesrepDetails.salesRepEmail = terrMem.User__r.email;
            territorySalesRepMap.put(terrMem.Territory__c,salesrepDetails);
        }
        
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        for(String territoryId:territoryAccountMap.keySet())
        {
            /*if(terrIdOrderItemsCount.get(territoryId) != null && terrIdOrderItemsTrack.get(territoryId) != null
              && terrIdOrderItemsCount.get(territoryId) == terrIdOrderItemsTrack.get(territoryId)){*/
                  String identity= EDGE_OrderItemComplaintBatch.generateId();
                  List<String> recipientList=new List<String>();
                  recipientList.add(territoryDeliveryPartnerMap.get(territoryId));
                  ccMail.add(territorySalesRepMap.get(territoryId).salesRepEmail);
                  String body = EDGE_OrderItemCompliantMailComposer.getDefectedOrderMail(territoryAccountMap.get(territoryId),outletOrderMap,orderListOrderItemMap,languageName,labelToTranslatedStrMap,territorySalesRepMap.get(territoryId).salesRepName);//(ES20-12600)
                  Messaging.SingleEmailMessage mail = EDGE_OrderItemCompliantMailComposer.setDefectedOrderEmailBody(body,recipientList,ccMail,null,languageName,labelToTranslatedStrMap,identity);//(ES20-12600)
                  mails.add(mail);
                  
                  ccMail.remove(ccMail.size()-1);
                  ContentVersion textFile =  EDGE_OrderItemComplaintBatch.createTextFile( terrOrderMap.get(territoryId),identity+'.txt',fileOwnerId);
                  contentVersionList.add(textFile);
                  fileMap.put(identity,terrOrderMap.get(territoryId));
                  //terrIdOrderItemsTrack.remove(territoryId);
            //}
        }
        System.debug('Mail Size '+mails.size());
        Messaging.SendEmailResult[] sendEmails=Messaging.sendEmail(mails);
        System.debug('contentVersionList Size '+contentVersionList.size());
        List<ContentVersion> conUpdate=new List<ContentVersion>();
        List<Id> conVerId=new List<Id>();
        if (Schema.sObjectType.ContentVersion.isAccessible() && contentVersionList.size()>0 ){
            insert contentVersionList;
            for(ContentVersion conVer:contentVersionList){
                conVerId.add(conVer.Id);
            }
            //After saved the Content Verison, get the ContentDocumentId
            List<ContentDocumentLink> conDocLinkList=new List<ContentDocumentLink>();
            Map<String,Id> conVerMap=new Map<String,Id>();
            for(ContentVersion con: [SELECT Id,ContentDocumentId,VersionData,Title FROM ContentVersion WHERE Id IN:conVerId]){
                conVerMap.put(con.Title.substringbefore('.txt'),con.ContentDocumentId);
            }
            for(String iden:fileMap.keySet()){
                Id conDocument= conVerMap.get(iden);
                for(Id ord:fileMap.get(iden)){
                    ContentDocumentLink cDocLink=EDGE_OrderItemComplaintBatch.createContentDocumentLink(conDocument,ord);
                    conDocLinkList.add(cDocLink);
                }
            }
            if(!conDocLinkList.isEmpty()){
                Database.insert(conDocLinkList,false);
            }
        }
        if (Schema.sObjectType.Order_Item__c.isAccessible() && allorderItemList.size()>0 ){
            update allorderItemList;
        }
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletExecutionMarkLatestEntryBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
        
        
    }
    
    public static String generateId()
    {
        
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,15);
        system.debug(guid);
        return guid;
    }
    public static ContentVersion createContentVersion(Blob versionData, String fileName, String recordTypeId) 
        
    { 
        ContentVersion cVersion = new ContentVersion(); 
        cVersion.RecordTypeId = recordTypeId; 
        cVersion.Content_Type__c = 'Other'; 
        cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork. 
        cVersion.PathOnClient = fileName;	//File name with extention 
        cVersion.Title = fileName;	//Name of the file 
        cVersion.VersionData = versionData; 
        return cVersion; 
    } 
    
    public static ContentVersion createTextFile(Set<Id> orderIds,String filename,String owner) 
        
    { 
        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Order').getRecordTypeId(); 
        List<Id> orderList = new List<Id>();
        orderList.addAll(orderIds);
        String orderDocContent = string.join(orderList,','); 
        Blob OrderListString = Blob.valueOf(orderDocContent); 
        ContentVersion orderTrack = createContentVersion(OrderListString,filename,recordIdContentVersion);
        return orderTrack; 
    } 
    public static ContentDocumentLink createContentDocumentLink(String contentDocumentId,String orderId)
    {
        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = contentDocumentId;	//Add ContentDocumentId
        cDocLink.LinkedEntityId = orderId;	//Add attachment parentId
        cDocLink.ShareType = 'I';	//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        cDocLink.Visibility = 'InternalUsers';	//AllUsers, InternalUsers, SharedUsers
        return cDocLink;
    }
    
    
}