/*
* @Description: EDGE_TransferOrderStatusUpdateBatch

* @Purpose: Sending email with order details to Wholesaler - User Story : ES20-4646 

* @History:                                                         

* @VERSION   AUTHOR                   DATE              DETAIL
*	1.0       Monalisa Halder         30/10/2019        Sending email with order details to Delivery Partner when POS Order gets placed from Ready for Order
*	1.2		  Kapil Baliyan			  30/12/2019		Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*	1.3		  Preyanka Ghosh		  10/02/2019		Free Good Email need to be send in same batch (ES20-6345)
*	1.4       Amar Deep               11/05/2021        NCP-2677
*	1.5       Monalisa Halder         17/06/2021        ES20-9974 
*   1.6       Aparajita				  20/01/2022		ES20-11954
*	1.7		  Rajarshi Lahiri		  18/05/2022		ES20-12785
*   1.8		  Rajarshi Lahiri		  30/05/2022		ES20-12875
**/
public class EDGE_TransferOrderStatusUpdateBatch implements Database.Batchable<AggregateResult>,Database.AllowsCallouts,Database.RaisesPlatformEvents,Database.Stateful,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode = '';
    String languageName = '';
    Id marketBatchJobId; //Update ES20-6594
    Boolean isBatch = True;
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;   
    }
    
    //Start Method
    public Iterable<AggregateResult> start(Database.BatchableContext bc){ 
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c; 
        String queryString = '';
        
		//Added Free Goods record Type Filter as part of ES20-12785
		// Removed Free Goods record Type for ES20-12875
        queryString = 'SELECT Wholesaler__c,Wholesaler__r.Outlet_Email_Address__c,Id'+
            +' FROM Order__c WHERE Status__c =\'Ready for Order\' AND RecordType.DeveloperName =\'Transfer_Order\' AND Wholesaler__c !=null AND Wholesaler__r.Outlet_Email_Address__c != null AND Account__r.Country__r.Code__c = \'' + countryCode + '\'' + 
            + ' GROUP BY Wholesaler__c,Wholesaler__r.Outlet_Email_Address__c,Id';
        System.debug('queryString = '+ queryString);
        return new AggregateResultIterable(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        //Variables
        Set<Account> wholesalerSet = new Set<Account>();
        List<Order__c> orderList = new List<Order__c>();
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();
        Set<Id> allOrderSet = new Set<Id>();
        Map<Id,String> wholesalerEmailMap = new Map<Id,String>();  
        Map<String,List<Order__c>> wholesalerOrderMap = new Map<String,List<Order__c>>();
        List<order__c> orderListToUpdate  = new List<order__c>();
        List<Order_item__c> ordItemListToUpdate = new List<Order_item__c>();
        String freeGoodOrderRTId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        List<String> lstRecordTypeId = new List<String>();
        lstRecordTypeId.add(Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId());
        lstRecordTypeId.add(freeGoodOrderRTId);
        Map<Id,Integer> wholesalerIdAllOrderCountMap = new Map<Id, Integer>();
        Map<Id,Integer> wholesalerWithOrderCountMap = new Map<Id,Integer>();
        Map<String,Set<ID>> wholesalerOrderIDMap = new Map<String,Set<ID>>();
        Set<Id> orderIdSet = new Set<Id>();
        try{
            if(scope!=null){
                for(sObject sObj : scope) {
                    Account wholesaler = new Account();
                    wholesaler.Id = (Id) sObj.get('Wholesaler__c');

                    wholesalerSet.add(wholesaler);

                    orderIdSet.add(sObj.Id);
                }
            }
            
            languageName = [Select Id, language__c from Market_setting__c where Geography__r.code__c =: countryCode LIMIT 1].language__c;
            
            //Fetch the child records where Wholesaler is present 
            if(wholesalerSet!=null){
                orderList = [Select Id,Name, RecordTypeId,Status__c,Account__r.Outlet_Email_Address__c,Delivery_Location__c,Order_Group__c,Wholesaler__c,Wholesaler__r.Outlet_Email_Address__c,Account__c,
                             Account__r.name, Account__r.BillingStreet,Account__r.BillingState,Account__r.BillingCity,Account__r.BillingCountry,
                             Account__r.BillingPostalCode, Account__r.RecordTypeId,Account__r.Country__c,Account__r.Country__r.Name,Account__r.Country__r.Code__c, Preferred_Delivery_Date__c, Next_Delivery_Date__c, Sales_Representative__c,
                             Source_Application__c,Contact__r.MobilePrefix__c,Contact__r.Mobile__c,Contact__c,Contact__r.Email,Country_Code__c,Sales_Representative__r.Name ,Sales_Representative__r.Email,
                             Sales_Representative__r.Mobile_Number__c,Comments__c, Signature_Image_Version_Id__c  FROM Order__c

                             WHERE Wholesaler__c IN : wholesalerSet AND RecordTypeId IN :lstRecordTypeId AND Status__c = 'Ready for Order'
                             AND Id in :orderIdSet];

            }

            // updated NCP-2677 Source_Application__c,Contact__r.MobilePrefix__c,Contact__r.Mobile__c
            if(orderList !=null && orderList.size()>0){
                orderItemList = [Select Id,Product__c,RecordTypeId,Product__r.Name,Product__r.Long_Description__c,Order__c,Quantity__c,Selected_UoM__c
                                 from Order_Item__c where Order__c IN :orderList];
                
                for(Order__c ordObj : orderList){                    
                    allOrderSet.add(ordObj.Id);
                    if(ordObj.Order_Group__c!=null){
                        allOrderSet.add(ordObj.Order_Group__c);
                    }
                    if(ordObj.Wholesaler__r.Outlet_Email_Address__c != null){
                        wholesalerEmailMap.put(ordObj.Wholesaler__c,ordObj.Wholesaler__r.Outlet_Email_Address__c);    
                    }
                    
                    if(wholesalerOrderMap.containsKey(ordObj.Wholesaler__c)){
                        List<Order__c> relatedOrderList = wholesalerOrderMap.get(ordObj.Wholesaler__c);
                        relatedOrderList.add(ordObj);
                        Set<ID> relatedOrderSet = wholesalerOrderIDMap.get(ordObj.Wholesaler__c);
                        relatedOrderSet.add(ordObj.id);
                        wholesalerOrderIDMap.put(ordObj.Wholesaler__c,relatedOrderSet);
                        wholesalerOrderMap.put(ordObj.Wholesaler__c,relatedOrderList);
                    }else{
                        wholesalerOrderMap.put(ordObj.Wholesaler__c,new List<Order__c> {ordObj});
                        wholesalerOrderIDMap.put(ordObj.Wholesaler__c,new Set<Id>{ordObj.id});
                    }
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
            
            Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_BatchSubjectTO','EDGE_Transfer_Order_Body'}, languageName);
            Map<Id,List<Messaging.Emailfileattachment>> wholesalerOrderItemAttachmentList = EDGE_UtilityClass.getTOAttachments(orderList);
           
            for(Account wholesaler : wholesalerSet){
                // List<Messaging.Emailfileattachment> fileAttachments = EDGE_UtilityClass.getAttachment(wholesalerOrderMap.get(wholesaler.Id));
                Map<String,String> subjuectStringMap = new Map<String,String>{'BatchSubject'=> labelToTranslatedStrMap.get('EDGE_BatchSubjectTO'),'BatchMailBody'=>labelToTranslatedStrMap.get('EDGE_Transfer_Order_Body')};
                Map<String,List<String>> emailListString = new Map<String,List<String>>{'batchEmail'=> new List<String> {wholesalerEmailMap.get(wholesaler.Id)}};
                //EDGE_TransferOrderStatusHelper.sendPDF(wholesalerOrderIDMap.get(wholesaler.Id),true,wholesaler,fileAttachments,emailListString,subjuectStringMap,languageName); 
                List<Messaging.Emailfileattachment> emailFileAttachments = new List<Messaging.Emailfileattachment>();
                
                if(wholesalerOrderItemAttachmentList.size() > 0 && wholesalerOrderItemAttachmentList.get(wholesaler.Id) != null) {
                    emailFileAttachments =   wholesalerOrderItemAttachmentList.get(wholesaler.Id);
                }
                //POC for defect ES20-11954(Aparajita) -> Transfer order pdf mail is sent to Wholesaler in chunks. The pdf will contain atmost 5 order details(transfer order/free goods)
                Integer orderListSize = wholesalerOrderIDMap.get(wholesaler.Id).size();
                Integer chunkSize = 5;
                Set<Id> smallerOrderIdSet = new Set<Id>();
                List<Id> orderIdList = new List<Id>();
				orderIdList.addAll(wholesalerOrderIDMap.get(wholesaler.Id));
                if(orderListSize!=0 && orderListSize<=chunkSize){
                EDGE_TransferOrderStatusHelper.sendPDF(wholesalerOrderIDMap.get(wholesaler.Id),true,wholesaler,emailFileAttachments,emailListString,subjuectStringMap,languageName); 
            }
                 else if(orderListSize!=0 && orderListSize>chunkSize){
                    for(Id orderId : wholesalerOrderIDMap.get(wholesaler.Id)){
                        if(smallerOrderIdSet.size()<chunkSize){
                            smallerOrderIdSet.add(orderId);
                            orderIdList.remove(orderIdList.indexOf(orderId));
                        }
                        if(orderIdList.size()!=0 && smallerOrderIdSet.size() == chunkSize){ 
                            EDGE_TransferOrderStatusHelper.sendPDF(smallerOrderIdSet,true,wholesaler,emailFileAttachments,emailListString,subjuectStringMap,languageName); 
                            smallerOrderIdSet.clear();
                        }
                        else if(orderIdList.size()==0 && smallerOrderIdSet.size() <= chunkSize){ 
                            EDGE_TransferOrderStatusHelper.sendPDF(smallerOrderIdSet,true,wholesaler,emailFileAttachments,emailListString,subjuectStringMap,languageName); 
                            smallerOrderIdSet.clear();
                        }
                    }                    
                }
            }
            
            //Update both Transfer Orders and Transfer order line item
            
            if(Schema.sObjectType.Order__c.isUpdateable() && orderListToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
                update orderListToUpdate;
                update ordItemListToUpdate;
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TransferOrderStatusUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}