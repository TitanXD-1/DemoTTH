/*
Name: EDGE_FreeGoodsOrderBatch

Req: Sending email with order details to Wholesaler/Delivery Partner
User Story : ES20-5056

History                                                            
                                                        
VERSION   AUTHOR                   DATE              DETAIL
1.0       Shahbaz Khan         22/11/2019     Sending email with order details to Wholesaler/Delivery Partner when Free Goods Order gets placed from Ready for Order
1.1       Kapil Baliyan        30/12/2019     Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
1.2       Rajarshi Lahiri	   10/05/2022	  ES20-12641
1.3       Rajarshi Lahiri	   13/05/2022     ES20-12728
1.4		  Rajarshi/Aparajita   17/08/2022	  ES20-13244
1.5       Mayukh S Roy         23/06/2023     291561 - Added Subject to Label for Translations
1.6       Doman/Mayukh         14/07/2023     301950 - Changed label for Sales Rep
1.7       Suvendu Roy          10/07/2024     152723 - Send automated email with attached Free Goods csv file to robot email address
*/

public class EDGE_FreeGoodsOrderBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode = '';
    String languageName = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        String queryString = '';
        System.debug(logginglevel.Debug,'countryCode'+countryCode);
        queryString = 'SELECT Id,Sales_Representative__c,Sales_Representative__r.Name,RecordTypeId,Status__c,Delivery_Location__c,Delivery_instructions__c, Wholesaler__c,Wholesaler__r.Outlet_Email_Address__c,Delivery_Partner__c,Delivery_Partner__r.Email__c,Account__c,Account__r.name,Name,Account__r.BillingStreet,Account__r.BillingState,Account__r.BillingCity,Account__r.BillingCountry,Account__r.Country__c,Account__r.Country__r.Name,Account__r.BillingPostalCode,Account__r.RecordTypeId,Account__r.PhonePrefix__c,Account__r.Phone__c,Preferred_Delivery_Date__c'+
            +' FROM Order__c WHERE Status__c =\'Ready for Order\' AND RecordType.Name=\'Free Goods\' AND (Wholesaler__c !=null OR Delivery_Partner__c!=null) AND Account__r.Country__r.Code__c =:countryCode'; 
        System.debug(logginglevel.Debug,'queryString'+queryString);
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Order__c> orderList){
        String countryName = '';
        List<Delivery_Partner__c> deliveryPartnerList = new List<Delivery_Partner__c>();
        Set<Account> wholesalerSet = new Set<Account>(); //ES20-13244: replaced list with set to avoid duplicates
        //List<Order__c> orderList = new List<Order__c>();
        //List<Order_Item__c> orderItemList = new List<Order_Item__c>();
        Map<Id,String> wholesalerMailMap = new Map<Id,String>();
        Map<Id,String> deliveryPartnerMailMap = new Map<Id,String>();
        Map<String,List<Order__c>> wholesalerOrderMap = new Map<String,List<Order__c>>();
        Map<String,List<Order__c>> deliveryPartnerOrderMap = new Map<String,List<Order__c>>();
        Map<String,List<Order_Item__c>> orderListOrderItemMap = new Map<String,List<Order_Item__c>>();
        List<Order__c> orderListToUpdate = new List<Order__c>();
        List<Order_item__c> ordItemListToUpdate = new List<Order_item__c>();
        List<Messaging.SingleEmailMessage> orderEmail = new List<Messaging.SingleEmailMessage>();
        List<Market_Setting__c> marketSetList = new List<Market_Setting__c>();//152327
        Map<Id,Order__c> orderListWithDeliveryPartnersMap = new Map<Id,Order__c>();
        //String freeGoodsOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        System.debug(logginglevel.Debug,'orderList'+orderList);
        try{
            if(orderList!=null){
                for(Order__c sObj: orderList){
                    Account wholesaler = new Account();
                    Delivery_Partner__c deliveryPartner = new Delivery_Partner__c();
                    if(sObj.get('Wholesaler__c')!=null){
                        wholesaler.Id = (Id) sObj.get('Wholesaler__c');
                        wholesalerSet.add(wholesaler);
                    }
                    else if(sObj.get('Delivery_Partner__c')!=null){
                        deliveryPartner.Id = (id)  sObj.get('Delivery_Partner__c');
                        deliveryPartnerList.add(deliveryPartner);
                        orderListWithDeliveryPartnersMap.put(sObj.Id, sObj);
                    }
                }  
            }
            
            List<Geography__c> countryList = [Select Id,name,Code__c from Geography__c where Code__c =: countryCode LIMIT 1 ];
            if(countryList.size()>0){
                countryName=countryList[0].Id;
            }
            System.debug(logginglevel.Debug,'orderListWithDeliveryPartners : '+orderListWithDeliveryPartnersMap);
            if(countryName != null){
                marketSetList = [Select Id, language__c,Free_Goods_SAP_Automation__c,Free_Goods_Robot_Email_Address__c from Market_setting__c where Geography__c =: countryName LIMIT 1];
                if(marketSetList.size()>0){
                    languageName = marketSetList[0].language__c;
                }  
                //152327
                if(marketSetList.size()>0&& marketSetList[0].Free_Goods_SAP_Automation__c =='Robot CSV Upload to SAP' && marketSetList[0].Free_Goods_Robot_Email_Address__c!='' && !orderListWithDeliveryPartnersMap.isEmpty()){
                    sendRoboMailToDeliveryPartners(orderListWithDeliveryPartnersMap, marketSetList[0].Free_Goods_Robot_Email_Address__c);
                }
            }
            //System.debug('orderList :'+ orderList);
            if(orderList!=null && orderlist.size()>0){
                for(Order__c ordObj : orderList){
                    ordObj.Status__c = 'Order Placed';
                    ordObj.Order_Placed_Date__c = Date.today();
                    orderListToUpdate.add(ordObj);
                    if(ordObj.Wholesaler__c!=null){
                        wholesalerMailMap.put(ordObj.Wholesaler__c,ordObj.Wholesaler__r.Outlet_Email_Address__c);            
                        if(wholesalerOrderMap.containsKey(ordObj.Wholesaler__c)){
                            List<Order__c> relatedOrderList =  wholesalerOrderMap.get(ordObj.Wholesaler__c);
                            relatedOrderList.add(ordObj);
                            wholesalerOrderMap.put(ordObj.Wholesaler__c,relatedOrderList);
                        }
                        else{
                            wholesalerOrderMap.put(ordObj.Wholesaler__c,new List<Order__c> {ordObj});
                        }
                    } 
                    else if(ordObj.Delivery_Partner__c!=null){
                        deliveryPartnerMailMap.put(ordObj.Delivery_Partner__c,ordObj.Delivery_Partner__r.Email__c);
                        if(deliveryPartnerOrderMap.containsKey(ordObj.Delivery_Partner__c)){
                            List<Order__c> relatedOrderList =  deliveryPartnerOrderMap.get(ordObj.Delivery_Partner__c);
                            relatedOrderList.add(ordObj);
                            deliveryPartnerOrderMap.put(ordObj.Delivery_Partner__c,relatedOrderList);
                        }
                        else{
                            deliveryPartnerOrderMap.put(ordObj.Delivery_Partner__c,new List<Order__c> {ordObj});
                        }            
                    }
                }
            }
            //System.debug('deliveryPartnerOrderMap :'+ deliveryPartnerOrderMap);
            if(orderList!=null && orderlist.size()>0){ //aligning order items with order
                //Added Product Name of MAP and Customer Facing Description as part of ES20-12641
                //Added SAP SKU Code as part of ES20-12728
                for(Order_Item__c ordItemObj: [select Id,Product__c,RecordTypeId,Note__c,Product__r.Name,Product__r.Product_Code__c,Product__r.Description__c,Order__c,Quantity__c,Reason__c,Selected_UoM__c,Reason_Code__c,Reason_Code__r.Name,Market_Assortment_Product__r.Product__r.Name,Market_Assortment_Product__r.D1_Product_Name__c,Product__r.SAP_SKU_Code__c
                                               from Order_Item__c where Order__c IN :orderList])
                {
                    ordItemObj.Status__c = 'Order Placed';
                    ordItemListToUpdate.add(ordItemObj);
                    
                    if(orderListOrderItemMap.containsKey(ordItemObj.Order__c)){
                        List<Order_Item__c> relatedOrderItemList = orderListOrderItemMap.get(ordItemObj.Order__c);
                        relatedOrderItemList.add(ordItemObj);
                        orderListOrderItemMap.put(ordItemObj.Order__c,relatedOrderItemList);
                    }
                    else{
                        orderListOrderItemMap.put(ordItemObj.Order__c,new List<Order_Item__c> {ordItemObj});
                    }
                }
            }
			//System.debug('orderListOrderItemMap :'+ orderListOrderItemMap);
            // Added label EDGE_ProductSKUId as part of ES20-12728 //Changed label for Sales Rep - 301950
            Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_Free_Goods_Email_Subject','EDGE_AccountName', 'EDGE_AccountAdress', 'EDGE_EmailBody','EDGE_AccountPhone','EDGE_SalesRepresentative','EDGE_ExpectedDeliveryDate','EDGE_Reason','EDGE_ProductCode','EDGE_DeliveryInstructions','EDGE_ProductDescription', 'EDGE_PrefOderDate','EGDE_ProductName','EDGE_ProductQuantity','EDGE_UOM','EDGE_OrderedProducts','EDGE_SubjectTO','EDGE_BatchSubjectTO','EDGE_ProductSKUId'}, languageName);
            
            if(wholesalerSet!=null){
                for(Account wholesaler: wholesalerSet){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<Messaging.Emailfileattachment> fileAttachments = EDGE_UtilityClass.getAttachment(wholesalerOrderMap.get(wholesaler.Id));
                    String body = EDGE_UtilityClass.getFreeGoodsMail(wholesalerOrderMap.get(wholesaler.Id), orderListOrderItemMap,languageName,labelToTranslatedStrMap);
                    mail=EDGE_UtilityClass.setEmailBody(fileAttachments,wholesaler,null,body);
                    String emailAdd = wholesalerMailMap.get(wholesaler.Id);
                    mail.setToAddresses(new String[] {emailAdd});
                    //291561 - Added Subject to Label for Translations
                    String todayDate = date.today().format();
                    if(languageName !=null && languageName != ''){
                        mail.setSubject(labelToTranslatedStrMap.get('EDGE_Free_Goods_Email_Subject') + todayDate);
                    }
                    orderEmail.add(mail); 
                }
            }
            if(deliveryPartnerList!=null){
                for(Delivery_Partner__c deliverPartner: deliveryPartnerList){
                    Messaging.SingleEmailMessage delPartMail = new Messaging.SingleEmailMessage(); 
                    List<Messaging.Emailfileattachment> fileAttachments = EDGE_UtilityClass.getAttachment(deliveryPartnerOrderMap.get(deliverPartner.Id));
                    String body = EDGE_UtilityClass.getFreeGoodsMail(deliveryPartnerOrderMap.get(deliverPartner.Id), orderListOrderItemMap,languageName,labelToTranslatedStrMap);
                    delPartMail=EDGE_UtilityClass.setEmailBody(fileAttachments,null,deliverPartner,body);
                    String emailAdd = deliveryPartnerMailMap.get(deliverPartner.Id);
                    delPartMail.setToAddresses(new String[] {emailAdd});
                    //291561 - Added Subject to Label for Translations
                    String todayDate = date.today().format();
                    if(languageName !=null && languageName != ''){
                        delPartMail.setSubject(labelToTranslatedStrMap.get('EDGE_Free_Goods_Email_Subject') + todayDate);
                    }
                    orderEmail.add(delPartMail); 
                }    
            }
            //System.debug('orderEmail :'+ orderEmail);
            Messaging.sendEmail(orderEmail, false);
            
            if(Schema.sObjectType.Order__c.isUpdateable() && orderListToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
                Database.update(orderListToUpdate);
                Database.update(ordItemListToUpdate);    
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
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_FreeGoodsOrderBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    /**
     * @ADO Number : 152327
     * @Name : getCustomLabel
	 * @description : This method send automated email with attached Free Goods csv file to robot email address
	 */
    public static void sendRoboMailToDeliveryPartners(Map<Id, Order__c> orderMap, String roboMail){
        Map<Id, String> deliveryPartnerEmailMap = new Map<Id, String>();
        Map<Id, String> deliveryPartnerCSVMap = new Map<Id, String>();
        Map<Id, Set<Id>> deliveryPartnerOrderMap = new Map<Id, Set<Id>>();
        Set<Id> orderIdsSet = new Set<Id>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Order__c order : orderMap.values()){
            orderIdsSet.add(order.id);
            if(!deliveryPartnerOrderMap.containsKey(order.Delivery_Partner__c)){
                deliveryPartnerEmailMap.put(order.Delivery_Partner__c, order.Delivery_Partner__r.Email__c);
                deliveryPartnerOrderMap.put(order.Delivery_Partner__c, new Set<ID>());
            }
            deliveryPartnerOrderMap.get(order.Delivery_Partner__c).add(order.Id);
        }
        deliveryPartnerCSVMap = EDGE_OrderFreeGoodsRoboExcelController.processOrders(orderIdsSet);
        for(Id recId : deliveryPartnerOrderMap.keyset()){ //{Order_id, CSV DATA}
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {roboMail});
            email.setCcAddresses(new String[] {deliveryPartnerEmailMap.get(recId)});
            email.setSubject('Free Goods');
            email.setPlainTextBody('');
            List<Messaging.EmailFileAttachment> mailAttachmentList = new List<Messaging.EmailFileAttachment>();
            //Getting CSV body
            for(Id orderId: deliveryPartnerOrderMap.get(recId)){
                if(deliveryPartnerCSVMap.containsKey(orderId) && deliveryPartnerCSVMap.get(orderId)!= '' ){
                    String csvName = 'FreeIssue Template - '+orderMap.get(orderId).Sales_Representative__r.Name+ ' '+ EDGE_OrderFreeGoodsRoboExcelHelper.dateFormatter(Date.today());
                    Blob csvBlob = Blob.valueOf(deliveryPartnerCSVMap.get(orderId));
                    // Create the attachment
                    Messaging.EmailFileAttachment mailAttachment = new Messaging.EmailFileAttachment();
                    mailAttachment.setFileName(csvName+'.csv');
                    mailAttachment.setBody(csvBlob);
                    mailAttachment.setContentType('text/csv');
                    mailAttachmentList.add(mailAttachment);
                }
            }
            // Attach the file to the email
            email.setFileAttachments(mailAttachmentList);
            emailList.add(email);
        }
        System.debug('emailList :' + emailList);
        if(!emailList.isEmpty()){
            // Send the email
        	Messaging.SendEmailResult[] mailResults = Messaging.sendEmail(emailList);
            System.debug('emailList sent :' + mailResults);
        }
        
    }
    /**
     * @ADO Number : 152327
     * @Name : dateFormatter
	 * @description : This method returns formated date value eg: 20.07.2024
	 */
   /* public static String dateFormatter(Date dt){
        DateTime dtTime = DateTime.newInstance(dt.year(), dt.month(),dt.day());
        return dtTime.format('DD.MM.YYYY');
    }*/
}