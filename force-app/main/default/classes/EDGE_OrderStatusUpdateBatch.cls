/**
* @Name: EDGE_OrderStatusUpdateBatch
* @Req: Sending email with order details to Delivery Partner
* @User Story : ES20-2267
* @History                                                            
* @VERSION   AUTHOR                   DATE              DETAIL
*  1.0       Anuja Chattopadhyay      11/07/2019        Sending email with order details to Delivery Partner when POS Order gets placed from Ready for Order
*  1.1       Anuja Chattopadhyay      07/10/2019        ES20-4606,Sending email with order details to Delivery Partner when for  Delivered to Shed Stock Movement Order
*  1.2       Manikant Prasad                            Added logic for file Attachment and Language Translation
*  1.3       Kapil Baliyan            30/12/2019        Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*  1.4       Ankit Das                27/01/2020        Introduction of two DateTime fields (ES20-6910)
*  1.5		  Amardeep				   12/06/2020		 ES20-8022
*  1.6		  Rubeena	               2/12/2020         [CR-2178] Included two new fields Legacy Front Office Number and Territory Name of Rep for POS Order Email Attachment
*  1.7 		 Rajarshi Lahiri	  	  22/06/2022	     ES20-12606
*  1.8       Anamika Shukla           23/06/2022         [ES20-12954]-Added Field SAP Ship To in the Attached Order CSV.
*  1.9       Monalisa Halder          05/08/2022         [ES20-13180]-Separate CSV Mails for Delivery Partners
*  2.0       Wribhu Bose              07/11/2022         [ES20-13023] Added Parent Order field in Attached Order CSV
*/

public class EDGE_OrderStatusUpdateBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    //implements Database.Batchable<AggregateResult>, Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode = '';
    String languageName = '';
    Id marketBatchJobId; //Update ES20-6594
    Market_Setting__c mrktSetting;
    
    
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
        
        List<Market_Setting__c> marketSettingRecords = [SELECT Attachment_Format__c,language__c from Market_Setting__c WHERE Geography__r.Code__c = :countryCode LIMIT 1] ;
        if(marketSettingRecords != null && marketSettingRecords.size() > 0){
            mrktSetting = marketSettingRecords[0];
        }
        
        queryString = 'SELECT Name , Batch_Notification__c, Country__c from Delivery_Partner__c where Country__r.Code__c = \'' + countryCode + '\' and Batch_Notification__c = True';
        //System.debug('queryString = '+ queryString); //query on delivery partner instead
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<sObject> scope){     
        //Variables
        String countryName = '';
        
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();
        Set<Id> allOrderSet = new Set<Id>();
        List<order__c> orderListToUpdate  = new List<order__c>();
        List<Order_item__c> ordItemListToUpdate = new List<Order_item__c>();
        Map<String,List<Order_Item__c>> orderListOrderMap = new Map<String,List<Order_Item__c>>();
        
        String posOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        String stockmovmntOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        List<Order__c> orderList = new List<Order__c>();
        Map<Id,String> delivryPartnrEmailMap = new Map<Id,String>();
        Map<Id,Set<Order__c>> delivryPartnrOrderIdsMap = new Map<Id,Set<Order__c>>();
        
        List<Delivery_Partner__c> delivryPartnrList = new List<Delivery_Partner__c>();
        delivryPartnrList = (List<Delivery_Partner__c>)scope;
        
        try{
            
            if(delivryPartnrList != null){
                //Added Alternate_Delivery_Address__r as part of ES20-12606
                //Added SAP_Ship_To__c as part of ES20-12954
                //Added Parent_Order__c as part of ES20-13023
                orderList = [Select Id,RecordTypeId,Status__c,Delivery_End_Date__c,Delivery_Start_Date__c,Order_Header_Notes__c,Alternate_Delivery_Address__r.Address,Delivery_Location__c,Order_Group__c,Delivery_Partner__r.Email__c,Delivery_Partner__c,Account__c,
                             Account__r.name,Sales_Representative__r.TimeZoneSidKey,Sales_Representative__r.name,Sales_Representative__r.MobilePhone,Sales_Representative__r.Email,Name,Parent_Order__c,
                             Account__r.BillingStreet,Account__r.BillingState,Account__r.BillingCity,Account__r.BillingCountry,Account__r.BillingPostalCode,Account__r.RecordTypeId,Account__r.Country__c,Account__r.Country__r.Name,
                             Account__r.Legacy_Front_Office_Account_No__c,Account__r.Primary_Sales_Territory__r.Name,Account__r.SAP_Ship_to__c,Sales_Representative__r.Street,Sales_Representative__r.City,Sales_Representative__r.State,Sales_Representative__r.PostalCode,Sales_Representative__r.Country,Contact__c,Contact__r.Name,Contact__r.Phone from order__c //included territory and legacy front office fields
                             where Delivery_Partner__c in : delivryPartnrList and ( RecordTypeId =:posOrderRecordTypeId or RecordTypeId =:stockmovmntOrderRecordTypeId ) and Status__c = 'Ready for Order'];                
                for(Order__c ordObj : orderList){
                    allOrderSet.add(ordObj.Id);
                } 
                if(orderList!=null && orderList.size()>0){                
                    orderItemList = [Select Id,Product__c,RecordTypeId,Product__r.Product_Code__c,Order__c,Quantity__c,Note__C,Text_to_Print__c,Product_Variant__r.Size__c,Product_Variant__r.Gender__c,
                                     toLabel(Product_Variant__r.Colour__c),Product_Variant__r.Paper_Finish__c from Order_Item__c where Order__c in :orderList];
                }
                
                delivryPartnrOrderIdsMap = EDGE_POSStockMvmtEmailHelper.getDlvryPartnerOrderMap(orderList, delivryPartnrEmailMap);
                String emailAttachmentFormat = mrktSetting.Attachment_Format__c;
                String languageName = mrktSetting.language__c;
               // System.debug('emailAttachmentFormat = '+ emailAttachmentFormat);
                //System.debug('languageName = '+ languageName);
                //Added Custom Label EDGE_SAPShipTo for ES20-12954
                //Added Custom Label EDGE_IsReplacementOrder for ES20-13023
                Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_ClientCode', 'EDGE_OutletID','EDGE_OutletName','EDGE_SAPShipTo','EDGE_LegacyFrontOfficeNmbr','EDGE_TerritoryName','EDGE_SalesRepName','EDGE_SalesRepMobile','EDGE_SalesRepEmail','EDGE_ToDelivery',
                    'EDGE_Address','EDGE_City','EDGE_State','EDGE_PostalCode','EDGE_Country','EDGE_OrderNumber','EDGE_ProductCode','EDGE_Quantity','EDGE_Notes','EDGE_IsReplacementOrder',  //included EDGE_TerritoryName & EDGE_LegacyFrontOfficeNmbr custom label for translation as a part of CR-2178
                    'EDGE_TextToPrint','EDGE_Size','EDGE_Gender','EDGE_Colour','EDGE_PaperFinish','EDGE_DeliveryStartDate','EDGE_DeliveryEndDate', 'EDGE_POS_Email_Subject','EDGE_POS_Attachment_Name','EDGE_OrderHeaderNotes','EDGE_OutletContactName','EDGE_OutletContactPhoneNumber'}, languageName);
                
                for(Id delPartnerId : delivryPartnrOrderIdsMap.keySet()){      
                    String emailAdd = delivryPartnrEmailMap.get(delPartnerId);
                    //System.debug('emailAdd = '+ emailAdd);
                    if(emailAttachmentFormat != null && emailAttachmentFormat.equalsIgnoreCase('CSV')){
                        Set<Order__c> ordersForDeliveryPartnerSet=delivryPartnrOrderIdsMap.get(delPartnerId);//ES20-13180 
                        if(ordersForDeliveryPartnerSet!=null && ordersForDeliveryPartnerSet.size()>0)
                        {
                            List<Order__c> ordersForDeliveryPartnerList=new List<Order__c>(ordersForDeliveryPartnerSet);//ES20-13180
                            EDGE_POSStockMvmtEmailHelper.sendCsvAttachment(ordersForDeliveryPartnerList, new List<String>{emailAdd}, labelToTranslatedStrMap, countryCode);//ES20-13180   
                        } 
                    }else if(emailAttachmentFormat != null && emailAttachmentFormat.equalsIgnoreCase('Excel')){
                        EDGE_POSStockMvmtEmailHelper.sendExcelBodyEmail(null, new List<String>{emailAdd}, languageName, countryCode, true, delPartnerId, labelToTranslatedStrMap);
                    }
                }
                
                
                //Updating Order Item
                if(orderItemList!=null && orderItemList.size()>0){
                    for(Order_Item__c ordItemObj : orderItemList){
                        ordItemObj.Status__c = 'Order Placed';
                        ordItemListToUpdate.add(ordItemObj);
                    }
                }
                
                //Updating Order 
                if(allOrderSet!=null){
                    for(Id ordObjId : allOrderSet){
                        Order__c ordObj = new Order__c(Id=ordObjId);
                        ordObj.Status__c ='Order Placed';
                        ordObj.Order_Placed_Date__c = Date.today();
                        orderListToUpdate.add(ordObj);
                    }
                }
                
                //System.debug('orderListToUpdate = '+ orderListToUpdate);
                //System.debug('ordItemListToUpdate = '+ ordItemListToUpdate);
                
                //Update both POS orders and POS order line item
                if(Schema.sObjectType.Order__c.isUpdateable() && orderListToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
                    update orderListToUpdate;
                    update ordItemListToUpdate;
                }
            }
        } 
        catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
            
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
            System.debug('exceptionMsg = '+ exceptionMsg);
        }
    }
    
    //Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OrderStatusUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}