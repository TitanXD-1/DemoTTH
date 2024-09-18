/**********************************************************************
Name: PNR_CorrDocuTriggerHelper
***********************************************************************
Purpose: Trigger Helper Class for Correction Document
***********************************************************************
History                                                            
********                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0      	Saurav Paul    	  11/08/2019        Send Correction Document and Line Items to SAP
2.0 	    Jayashree R		  26/11/2021		Modified
3.0			Sai Kiran		  18/01/2022
4.0         Kumar Gaurav      27/05/2022        Modified as of PION-2529(introducing 'Greek Reason Code' for Sales Org GR01)
5.0         Anamika Shukla     29/02/2024       EDGE Global: Mulesoft OAuth2 migration-358242
***********************************************************************/
public with sharing class PNR_CorrDocuTriggerHelper {
    public static final String PIONEER_MULESOFT_COMMENT = 'Pioneer_Mulesoft_Credit_Debit_Return';//358242
    /*******************************************************************
Method  : getInvoiceData
Purpose : This method is used to get Correction Doc record
***********************************************************************/
    public static void getInvoiceData(List<Correction_Document__c> corrDocList, Map<Id,sObject> oldMap,Boolean isUpdate){
        Map <Id,Correction_Document__c> oldCorrDocMap;
        Set<Id> corrDocIdSet = new Set<Id>();
        List<Correction_Document__c> corrDocUpdateList = new List<Correction_Document__c>(); //PION-1647 : creating CD list for update 
        List<Case> caseUpdateList = new List<Case>(); //PION-1647 : creating case list for update
        try{ //PION-1647 : Exception handling
            if(oldMap!= null){
                oldCorrDocMap = (Map<Id,Correction_Document__c>)oldMap;
            }
            Id corDocRecTypId = Schema.SObjectType.Correction_Document__c.getRecordTypeInfosByName().get('Direct Correction Document').getRecordTypeId();
            
            for(Correction_Document__c corrDocObj : corrDocList){
                if(String.isNotBlank(corrDocObj.RecordTypeId) && corrDocObj.RecordTypeId.equals(corDocRecTypId) && !corrDocObj.Data_Send_to_SAP__c && !corrDocObj.SAP_Request_Sent__c
                   && ((isUpdate && oldCorrDocMap!= null && oldCorrDocMap.containsKey(corrDocObj.Id) 
                        && oldCorrDocMap.get(corrDocObj.Id).Status__c != corrDocObj.Status__c 
                        && (corrDocObj.Status__c.equalsIgnoreCase('Approved') ||corrDocObj.Status__c.equalsIgnoreCase('Externally Approved')))
                       ||(!isUpdate && (corrDocObj.Status__c.equalsIgnoreCase('Approved')||corrDocObj.Status__c.equalsIgnoreCase('Externally Approved'))))){
                           corrDocIdSet.add(corrDocObj.Id);
                           Correction_Document__c cd = new Correction_Document__c(Id = corrDocObj.Id);
                           cd.SAP_Request_Sent__c = true;
                           corrDocUpdateList.add(cd);
                       }
                //PION-1647 : updating Case and CD based on the billing details
                else if(isUpdate && String.isNotBlank(corrDocObj.RecordTypeId) && corrDocObj.RecordTypeId.equals(corDocRecTypId) 
                        && corrDocObj.Data_Send_to_SAP__c && corrDocObj.Case__c != null){
                            Case c = new Case(Id = corrDocObj.Case__c);
                            Correction_Document__c cd = new Correction_Document__c(Id = corrDocObj.Id);
                            Decimal existingResReceivedCount;
                            if(corrDocObj.PNR_SAP_Billing_Response_Received__c == null){
                                existingResReceivedCount = 0;
                            }else{
                                existingResReceivedCount = corrDocObj.PNR_SAP_Billing_Response_Received__c;
                            }
                            if(oldCorrDocMap.get(corrDocObj.Id).PNR_Billing_Document_Number__c != corrDocObj.PNR_Billing_Document_Number__c &&
                               String.isNotBlank(corrDocObj.PNR_Billing_Document_Number__c)){
                                   cd.PNR_Billing_Acknowledgement__c = 'X';
                                   cd.PNR_Billing_Document_Status__c = 'O'; //PION-1987 : Setting billing doc status to order invoiced when the billing doc number is received
                                   cd.PNR_SAP_Billing_Response_Received__c = existingResReceivedCount + 1;
                                   corrDocUpdateList.add(cd);
                                   if(String.isNotBlank(corrDocObj.PNR_Case_Dispute_Subtype__c)){ //PION-1994 : checking dispute subtype for closing case
                                       c.Status = 'Closed';
                                   }
                                   c.PNR_Correction_Billing_Document_Number__c = corrDocObj.PNR_Billing_Document_Number__c;
                                   c.PNR_Billing_Date__c = corrDocObj.PNR_Billing_Date__c;
                                   caseUpdateList.add(c);
                               }
                            else if(String.isBlank(corrDocObj.PNR_Billing_Document_Number__c) &&
                                    oldCorrDocMap.get(corrDocObj.Id).PNR_Billing_Document_Status__c != corrDocObj.PNR_Billing_Document_Status__c
                                    && String.isNotBlank(corrDocObj.PNR_Billing_Document_Status__c)){
                                        cd.PNR_Order_Acknowledgement__c = 'X';
                                        cd.PNR_SAP_Billing_Response_Received__c = existingResReceivedCount + 1;
                                        cd.PNR_Billing_Date__c = null; //PION-1731 : storing null value in billing date if we receive order status 
                                        corrDocUpdateList.add(cd);
                                        if(corrDocObj.PNR_Billing_Document_Status__c == 'C' || corrDocObj.PNR_Billing_Document_Status__c == 'D'){
                                            if(String.isNotBlank(corrDocObj.PNR_Case_Dispute_Subtype__c)){ //PION-1994 : checking dispute subtype for closing case
                                                c.Status = 'Closed';
                                            }
                                            c.Rejection_Reason__c = 'Order Rejected';
                                            caseUpdateList.add(c);
                                        }
                                        /*else if(corrDocObj.PNR_Billing_Document_Status__c == 'D'){
if(String.isNotBlank(corrDocObj.PNR_Case_Dispute_Subtype__c)){ //PION-1994 : checking dispute subtype for closing case
c.Status = 'Closed';
}
c.Rejection_Reason__c = 'Order Rejected';
caseUpdateList.add(c);
}*/
                                    }
                            //added this for sending acknowledgement to SAP for an update happening on CD
                            else if(isUpdate && corrDocObj.LastModifiedById == label.PNR_Integration_User_Id && oldCorrDocMap.get(corrDocObj.Id).PNR_SAP_Billing_Response_Received__c == corrDocObj.PNR_SAP_Billing_Response_Received__c){
                                
                                cd.PNR_SAP_Billing_Response_Received__c = corrDocObj.PNR_SAP_Billing_Response_Received__c==null?1:corrDocObj.PNR_SAP_Billing_Response_Received__c+1;
                                corrDocUpdateList.add(cd);
                                
                            }
                        }
            }
            if(!corrDocIdSet.isEmpty()){
                PNR_CorrDocuTriggerHelper.getCorDocLineItems(corrDocIdSet);//PION-1645 Change
                PNR_CorrDocuTriggerHelper.createLog(String.valueOf(corrDocIdSet), 'Credit/Debit Return', 'Credit/Debit Checkbox request', 'Success', 'Credit/Debit Return',String.valueOf(corrDocIdSet));
                
                
            }
            //PION-1647 : Updating CD and Case
            if(!corrDocUpdateList.isEmpty()){
                Update corrDocUpdateList;
            }
            if(!caseUpdateList.isEmpty()){
                Update caseUpdateList;
            }
        }
        catch(Exception ex){ //PION-1647 : Exception handling
            System.debug('Exception:: '+ex.getStackTraceString());
            System.debug('Exception msg:: '+ex.getMessage());
        }
    }
    //PION-1645 change
    @future(callout = true)
    public static void getCorDocLineItems(Set<Id> corDocIdSet){
        PNR_CorrDocuTriggerHelper.getDocLineItems(corDocIdSet);
    }
    /*******************************************************************
Method  : getDocLineItems
Purpose : This method is used to get Correction Documents and Corresponding Line Items
***********************************************************************/
    public static void getDocLineItems(Set<Id> corDocIdSet){
        //variables
        List<Correction_Document__c> corDocSet = new List<Correction_Document__c>();
        Set<String> invItmNameSet = new Set<String>();
        Map<String,PNR_CreditDebitRetWrapper> wrapDataMap= new Map<String,PNR_CreditDebitRetWrapper>();
        Map<String,List<String>> corrDocMap = new Map<String,List<String>>();
        List<PNR_CorrectionDocumentMapping__c> lineItmList = new List<PNR_CorrectionDocumentMapping__c>();
        Map<String,WrapResponseClass> respMap = new Map<String,WrapResponseClass>();
        List<Correction_Document__c> corrDocUpdte = new List<Correction_Document__c>();
        List<Integration_Log__c> errLogList = new List<Integration_Log__c>();
        Map<String,Correction_Document__c> caseCorrDocMap = new Map<String,Correction_Document__c>();
        Map<String,Case> caseUpdateMap = new Map<String,Case> ();
        PNR_CreditDebitRetWrapper  parentWrap;	
        if(!corDocIdSet.isEmpty() && Schema.sObjectType.Correction_Document__c.isAccessible()){
            Map<String,PNR_CorrectionDocumentMapping__c> lineItmMap = new Map<String,PNR_CorrectionDocumentMapping__c>();
            corDocSet = [SELECT Id, Document_Type__c,Reference_invoice__r.SAP_Invoice_Number__c,Sales_Org__c,Claimed_Invoice_Line_Items__c,PNR_Greek_Reason_Code__c,// PION-2529
                         Distribution_Channel__c,Division__c,PO_Number__c,Sold_To__r.KUNNR__c,Ship_To__c,Case__c,Case__r.Dispute_Sub_type__c,
                         Case__r.Status,Bill_To__c,Payer__r.KUNNR__c,Reason_Code__c,Billing_notes_for_printing__c,Reference_invoice__c,Case__r.Owner.Email,
                         PNR_Re_Trial_Count__c,PNR_Shipping_instructions__c,PNR_USO_CFDI__c,PNR_Reference_documents__c,PNR_Requested_Delivery_date__c// SKS
                         FROM Correction_Document__c
                         WHERE Id IN : corDocIdSet];
            if(!corDocSet.isEmpty()){
                for(Correction_Document__c corrDocObj : corDocSet){
                    if(String.isNotBlank(corrDocObj.Claimed_Invoice_Line_Items__c)){
                        String claimedItem = corrDocObj.Claimed_Invoice_Line_Items__c;
                        List<String> sapItem = claimedItem.split(';');
                        corrDocMap.put(corrDocObj.Id,new List<String>{});
                        corrDocMap.get(corrDocObj.Id).addAll(sapItem);
                        invItmNameSet.addAll(sapItem);
                        caseCorrDocMap.put(corrDocObj.Id,corrDocObj);
                    }
                }
                if(!invItmNameSet.isEmpty() && Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
                    lineItmList = [SELECT Id,Name,Product_Number__c,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c,Invoice_Quantity__c,
                                   Claimed_Net_Amount__c,CurrencyIsoCode,Pricing_Condition__c, Pricing_Condition_Code__c, Plant__c,Batch__c,Invoice_Unit_of_Measure__c, PNR_Recharge_Material__c
                                   FROM PNR_CorrectionDocumentMapping__c
                                   WHERE Name IN : invItmNameSet];
                    if(!lineItmList.isEmpty()){
                        for(PNR_CorrectionDocumentMapping__c itemObj : lineItmList){
                            lineItmMap.put(itemObj.Name,itemObj);
                        }
                    }
                }
                for(Correction_Document__c corrDoc : corDocSet){
                    String resnCode = String.valueOf(corrDoc.Reason_Code__c);
                    String resnCodeVal = '';
                    if(String.isNotBlank(resnCode)){
                        resnCodeVal = resnCode.length()>3 ? resnCode.substring(0, 3) : resnCode;
                    }
                    String reqDeliveryDate = '';// PION-2371
                    if(corrDoc.PNR_Requested_Delivery_date__c !=null){// PION-2371
                        reqDeliveryDate = string.valueOf(corrDoc.PNR_Requested_Delivery_date__c).replace('-','');
                        system.debug('+++++++++'+reqDeliveryDate);
                    }//PION-2371 Change ends
                    
                    
                    if(corrDoc.Sales_Org__c=='GR01'){
                        //PION-2529 : included new parameter Greek reason code to send in the request
                        String greekReasCode = String.ValueOf(corrDoc.PNR_Greek_Reason_Code__c.substringBefore('-')); 
                        String greekReasonCode = greekReasCode.deleteWhitespace();
                        
                        parentWrap = new PNR_CreditDebitRetWrapper(String.valueOf(corrDoc.Document_Type__c),
                                                                   String.valueOf(corrDoc.Reference_invoice__r.SAP_Invoice_Number__c),
                                                                   String.valueOf(corrDoc.Sales_Org__c),
                                                                   String.valueOf(corrDoc.Distribution_Channel__c),
                                                                   String.valueOf(corrDoc.Division__c),
                                                                   String.valueOf(corrDoc.PO_Number__c),
                                                                   String.valueOf(corrDoc.Sold_To__r.KUNNR__c),
                                                                   String.valueOf(corrDoc.Ship_To__c),
                                                                   Integer.valueOf(corrDoc.Bill_To__c),
                                                                   String.valueOf(corrDoc.Payer__r.KUNNR__c),
                                                                   resnCodeVal, 
                                                                   String.valueOf(corrDoc.Billing_notes_for_printing__c),
                                                                   String.valueOf(corrDoc.Id),
                                                                   String.valueOf(corrDoc.PNR_Shipping_instructions__c),// PION-2371
                                                                   String.valueOf(corrDoc.PNR_USO_CFDI__c),//PION-2371
                                                                   String.valueOf(corrDoc.PNR_Reference_documents__c),// PION-2371
                                                                   String.valueOf(reqDeliveryDate),//PION-2371
                                                                   greekReasonCode ); //PION-2529 
                        
                    }
                    else{
                        parentWrap = new PNR_CreditDebitRetWrapper(String.valueOf(corrDoc.Document_Type__c),
                                                                   String.valueOf(corrDoc.Reference_invoice__r.SAP_Invoice_Number__c),
                                                                   String.valueOf(corrDoc.Sales_Org__c),
                                                                   String.valueOf(corrDoc.Distribution_Channel__c),
                                                                   String.valueOf(corrDoc.Division__c),
                                                                   String.valueOf(corrDoc.PO_Number__c),
                                                                   String.valueOf(corrDoc.Sold_To__r.KUNNR__c),
                                                                   String.valueOf(corrDoc.Ship_To__c),
                                                                   Integer.valueOf(corrDoc.Bill_To__c),
                                                                   String.valueOf(corrDoc.Payer__r.KUNNR__c),
                                                                   resnCodeVal,
                                                                   String.valueOf(corrDoc.Billing_notes_for_printing__c),
                                                                   String.valueOf(corrDoc.Id),
                                                                   String.valueOf(corrDoc.PNR_Shipping_instructions__c),// PION-2371
                                                                   String.valueOf(corrDoc.PNR_USO_CFDI__c),//PION-2371
                                                                   String.valueOf(corrDoc.PNR_Reference_documents__c),// PION-2371
                                                                   String.valueOf(reqDeliveryDate)//PION-2371
                                                                  ); 
                    }
                    // PION-2529 change ends
                    
                    
                    if(String.isNotBlank(corrDoc.Claimed_Invoice_Line_Items__c)){
                        /*
Map<String, String> priConMap = new Map<String, String>();
for(PNR_CorrectionOfPricingCondition__mdt prCon: [SELECT PNR_PricingCondition__c, PNR_CorrectionOf__c FROM PNR_CorrectionOfPricingCondition__mdt]){
priConMap.put(prCon.PNR_CorrectionOf__c, prCon.PNR_PricingCondition__c);
}*/
                        
                        for(String itemName : corrDoc.Claimed_Invoice_Line_Items__c.split(';')){
                            if(!lineItmMap.isEmpty() && lineItmMap.containsKey(itemName)){
                                PNR_CorrectionDocumentMapping__c lineItem  = lineItmMap.get(itemName);
                                if(corrDoc.Document_Type__c.equalsIgnoreCase('YVCR') || 
                                   corrDoc.Document_Type__c.equalsIgnoreCase('YVDR') ||
                                   corrDoc.Document_Type__c.equalsIgnoreCase('YRET')){
                                       //This is for dispute return We are passing Claimed Quantity 
                                       //and Claimed UOM to do Calculation in SAP
                                       //PION:2412 - including recharge material number in the request, if its exists, for PE01 and CE01 sales orgs
                                       parentWrap.item.add(new PNR_CreditDebitRetWrapper.ChildRecord(String.valueOf(lineItem.Product_Number__c), 
                                                                                                     Integer.valueOf(lineItem.Claimed_Volume__c), 
                                                                                                     String.valueOf(lineItem.Unit_of_Measure_of_Claimed_QTY__c),
                                                                                                     null,
                                                                                                     null,
                                                                                                     String.valueOf(lineItem.Plant__c),
                                                                                                     String.valueOf(lineItem.Batch__c),
                                                                                                     null));
                                   }
                                //PION-2203 : Payload for DGT1 and CE01 salesorgs for YCR and YDR report types
                                else if(corrDoc.Sales_Org__c == 'DGT1' || corrDoc.Sales_Org__c == 'CE01'){
                                    //PION:2412 - including recharge material number in the request, if its exists, for PE01 and CE01 sales orgs
                                    parentWrap.item.add(new PNR_CreditDebitRetWrapper.ChildRecord( corrDoc.Sales_Org__c == 'CE01' && String.isNotBlank(lineItem.PNR_Recharge_Material__c) ? lineItem.PNR_Recharge_Material__c.substringAfterLast('-') : String.valueOf(lineItem.Product_Number__c), 
                                                                                                  Integer.valueOf(lineItem.Claimed_Volume__c), 
                                                                                                  String.valueOf(lineItem.Unit_of_Measure_of_Claimed_QTY__c),
                                                                                                  String.valueOf(lineItem.CurrencyIsoCode),
                                                                                                  //priConMap.get(lineItem.Pricing_Condition__c),
                                                                                                  String.valueOf(lineItem.Pricing_Condition_Code__c),
                                                                                                  //PION-2599 : changes made to send user selected plant value for CE01
                                                                                                  corrDoc.Sales_Org__c == 'CE01' ? String.valueOf(lineItem.Plant__c).substringBefore('-').trim() : String.valueOf(lineItem.Plant__c), 
                                                                                                  String.valueOf(lineItem.Batch__c),
                                                                                                  String.valueOf(lineItem.Claimed_Net_Amount__c)));
                                }else {
                                    //This is for dispute Pricing, We are passing Invoice Quantity 
                                    //and Invoice UOM to populate in SAP since Claimed Qnty and Claimed UOM is not available
                                    
                                    //PION-2202 change
                                    
                                    String lineItemId = lineItem.Id;
                                    //PION:2412 - including recharge material number in the request, if its exists, for PE01 and CE01 sales orgs
                                    parentWrap.item.add(new PNR_CreditDebitRetWrapper.ChildRecord(corrDoc.Sales_Org__c == 'PE01' && String.isNotBlank(lineItem.PNR_Recharge_Material__c) ? lineItem.PNR_Recharge_Material__c.substringAfterLast('-') : String.valueOf(lineItem.Product_Number__c), 
                                                                                                  Integer.valueOf(lineItem.Invoice_Quantity__c), 
                                                                                                  String.valueOf(lineItem.Invoice_Unit_of_Measure__c),
                                                                                                  String.valueOf(lineItem.CurrencyIsoCode),
                                                                                                  //priConMap.get(lineItem.Pricing_Condition__c)
                                                                                                  String.valueOf(lineItem.Pricing_Condition_Code__c),
                                                                                                  String.valueOf(lineItem.Plant__c),
                                                                                                  String.valueOf(lineItem.Batch__c),
                                                                                                  String.valueOf(lineItem.Claimed_Net_Amount__c)));
                                }
                            }
                        }
                    }
                    wrapDataMap.put(corrDoc.Id,parentWrap);
                }
            }
        }
        if(!wrapDataMap.isEmpty() && wrapDataMap.values().size()<10){//This size is used only to limit callout from trigger
            for(String keyVal : wrapDataMap.keySet()){
                String conDesKey = keyVal;
                PNR_CreditDebitRetWrapper wrapObj = wrapDataMap.get(keyVal);
                String jsonPayload = JSON.serialize(wrapObj);
                String emailVal = '';
                if(!caseCorrDocMap.isEmpty() && caseCorrDocMap.containsKey(conDesKey) && 
                   String.isNotBlank(caseCorrDocMap.get(conDesKey).Case__c)){
                       emailVal = caseCorrDocMap.get(conDesKey).Case__r.Owner.Email;
                   }
                
                String respString = PNR_CorrDocuTriggerHelper.sendResponse(jsonPayload,caseCorrDocMap.get(conDesKey),emailVal);
                String respMsg = respString.remove('{');
                respMsg = respMsg.remove('}');
                respMsg = respMsg.replaceAll('"','');
                respMsg = respMsg.substringAfterLast(':');
                if(String.isNotBlank(respString) && respString.contains('ERROR')){
                    WrapResponseClass wrapRespObj = new WrapResponseClass(false,respMsg);
                    respMap.put(conDesKey,wrapRespObj);
                    Integration_Log__c logObj = new Integration_Log__c();
                    logObj.Error_Message__c = respMsg;
                    logObj.Interface_Name__c = 'Credit/Debit Return';
                    logObj.Status__c = 'Failure';
                    logObj.Type_of_Object__c = 'Credit/Debit Return';
                    logObj.Response__c = 'Error Occurred for Correction Doc Id : '+conDesKey;
                    logObj.Request__c = jsonPayload;
                    errLogList.add(logObj);
                }else if(String.isNotBlank(respString) && respString.contains('SUCCESS')){
                    Pattern pat = Pattern.compile('([0-9]+)');
                    Matcher matcher = pat.matcher(respMsg);
                    Boolean matches = matcher.find();
                    if(matches){
                        String val = matcher.group(1);
                        WrapResponseClass wrapRespObj = new WrapResponseClass(true,val);
                        respMap.put(conDesKey,wrapRespObj);
                    }else{
                        WrapResponseClass wrapRespObj = new WrapResponseClass(true,respMsg);
                        respMap.put(conDesKey,wrapRespObj);
                    }
                }
            }
        }
        
        if(!respMap.isEmpty()){
            for(String idVal : respMap.keySet()){
                Correction_Document__c corrDoc  = new Correction_Document__c(Id = idVal); 
                WrapResponseClass wrapVal  = respMap.get(idVal);
                Boolean isSuccess = wrapVal.isSuccess;
                String emailVal = '';
                
                if(isSuccess){
                    if(!caseCorrDocMap.isEmpty() && caseCorrDocMap.containsKey(idVal) && 
                       String.isNotBlank(caseCorrDocMap.get(idVal).Case__c)){
                           Case caseObj = new Case(Id = caseCorrDocMap.get(idVal).Case__c);
                           //if(String.isNotBlank(caseCorrDocMap.get(idVal).Case__r.Dispute_Sub_type__c)){
                           caseObj.Status = 'Awaiting Billing'; //PION-1668 : changing the status to new value 'Awaiting Billing'
                           //}    
                           corrDoc.PNR_Correction_Document_SAP_Number__c = wrapVal.respMsg;//PION-1676 Change
                           caseObj.Correction_Document_SAP_Number__c  = wrapVal.respMsg;
                           corrDoc.PNR_Order_Response_Status_Code__c = null;
                           corrDoc.Error_Message__c = null;
                           corrDoc.Status__c = 'Awaiting Billing';
                           caseUpdateMap.put(caseCorrDocMap.get(idVal).Case__c,caseObj);  
                       }
                }else{
                    if(!caseCorrDocMap.isEmpty() && caseCorrDocMap.containsKey(idVal) && 
                       String.isNotBlank(caseCorrDocMap.get(idVal).Case__c)){
                           emailVal = caseCorrDocMap.get(idVal).Case__r.Owner.Email;
                           //PION-1668 : Closing and adding rejection reason to the case for error response
                           Case caseObj = new Case(Id = caseCorrDocMap.get(idVal).Case__c);
                           if(String.isNotBlank(caseCorrDocMap.get(idVal).Case__r.Dispute_Sub_type__c)){ //PION-1994 : checking dispute subtype for closing case
                               caseObj.Status = 'Closed'; 
                           }
                           caseObj.Rejection_Reason__c = 'Data / System Error';
                           caseUpdateMap.put(caseCorrDocMap.get(idVal).Case__c,caseObj);
                       }
                    
                    corrDoc.Error_Message__c = wrapVal.respMsg;
                    corrDoc.PNR_Order_Response_Status_Code__c = 200;
                    if(String.isNotBlank(emailVal)){
                        PNR_CorrDocuTriggerHelper.sendMsg(emailVal,wrapVal.respMsg,idVal);
                    }
                }
                corrDoc.PNR_Order_Acknowledgement__c = 'X'; //PION-1668 : setting the order ack flag 
                corrDoc.Data_Send_to_SAP__c = isSuccess;
                corrDocUpdte.add(corrDoc);
            }
        }
        if(!corrDocUpdte.isEmpty() && Schema.sObjectType.Correction_Document__c.isUpdateable()){
            try{
                update corrDocUpdte;
            }catch(Exception ex){
                PNR_CorrDocuTriggerHelper.createLog(ex.getMessage(), 'Credit/Debit Return', 'Credit/Debit Checkbox data update Error', 'Failure', 'Credit/Debit Return',null);
                System.debug('Exception:: '+ex.getMessage());
            }
            
        }
        
        if(!caseUpdateMap.isEmpty()){
            try{
                update caseUpdateMap.values();
            }catch(Exception ex){
                
                PNR_CorrDocuTriggerHelper.createLog(ex.getMessage(), 'Credit/Debit Return', 'Case Status update Error', 'Failure', 'Credit/Debit Return',null);
            }
        }
        if(!errLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()){
            insert errLogList;
        }
    }
    
    
    /*******************************************************************
Method  : sendResponse
Purpose : This method is used to Call-Out and Send Data
***********************************************************************/
    public static String sendResponse(String jsonPayload, Correction_Document__c corrDoc, String emailVal){
        
        String jsonBody = '';
        //String endPoint = Label.EndPoint_Credit_Debit_Return;
        // String clientId = Label.X_IBM_Client_Id;
        //String clientSecret = Label.X_IBM_Client_Secret;
        HttpRequest request = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        //request.setEndpoint(endPoint);
        request.setendpoint('callout:' +PIONEER_MULESOFT_COMMENT);
        request.setMethod('POST');
        //request.setHeader('client_id',clientId);
        //request.setHeader('client_secret',clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setBody(jsonPayload);
        request.setTimeout(120000);
        System.debug('Json payload:::'+jsonPayload);
        Integer exceptionStatusCode;//PION-2144 Change: storing status code when SAP is down or connection b/w SAP and Mulesoft is lost
        string errorMsg;
        Integer maxCount = Integer.ValueOf(Label.PNR_CDBatch_MaxCount);//PION-2338 Change
        try {
            res = http.send(request);
            Integer statusCode = res.getStatusCode(); //PION-1668 : assigning the satus code to integer value
            exceptionStatusCode = res.getStatusCode();//PION-2144 change
            system.debug('------statusCode-----'+statusCode);
            if(statusCode == 200){
                jsonBody = res.getBody(); 
                system.debug('------jsonBody-----'+jsonBody);
            }
            else{
                //commented 336 line; using the corrDoc directly; PION-1645 change
                //Correction_Document__c corrDoc = new Correction_Document__c(Id = corrDocId); //PION-1668 : creating CD variable for updating CD
                corrDoc.PNR_Order_Response_Status_Code__c = statusCode; //PION-1668 : storing the status code to mark the record for resending from the scheduler job
                corrDoc.PNR_Re_Trial_Count__c = corrDoc.PNR_Re_Trial_Count__c==null?1:corrDoc.PNR_Re_Trial_Count__c+1;//PION-1645 Change
                PNR_CorrDocuTriggerHelper.createLog('Response Status code is : '+String.valueOf(res.getStatusCode()),
                                                    'Credit/Debit Return', jsonPayload, 'Failure','Credit/Debit Return',corrDoc.Id );
                
                map<string,object> resMap = (map<string,object>)json.deserializeUntyped(res.getBody());
                
                if(resMap.containskey('error')){
                    errorMsg = string.valueOf(resMap.get('error'));
                }
                else{
                    errorMsg = res.getBody(); 
                }
                Integer maxSize = 250;
                if(errorMsg.length() > maxSize ){
                    errorMsg = errorMsg.substring(0, maxSize);
                }
                corrDoc.Error_Message__c = errorMsg;
                //added 'AND' Condition for PION-1645 change
                if(String.isNotBlank(emailVal) && (corrDoc.PNR_Re_Trial_Count__c ==maxCount)){
                    PNR_CorrDocuTriggerHelper.sendMsg(emailVal,'Response Status code is : '+String.valueOf(res.getStatusCode())+'<br/>Error is: '+errorMsg,corrDoc.Id);
                    
                }
                jsonBody ='';
                update corrDoc; //PION-1668 : updating CD
            }
        }catch(Exception ex){
            String exceptionMessage = ex.getMessage();
            Integer maxSize = 240;
            if(exceptionMessage.length() > maxSize){
                exceptionMessage = exceptionMessage.subString(0, maxSize);
            }
            if(exceptionStatusCode == NULL){
                corrDoc.PNR_Order_Response_Status_Code__c = 408;
                corrDoc.Error_Message__c = exceptionMessage;
            } else if(exceptionMessage == NULL){
                corrDoc.PNR_Order_Response_Status_Code__c = exceptionStatusCode;
                corrDoc.Error_Message__c = 'Following Exception happened '+exceptionMessage;
            }
            else {
                corrDoc.PNR_Order_Response_Status_Code__c = exceptionStatusCode;
                corrDoc.Error_Message__c = errorMsg;
            }
            
            corrDoc.PNR_Re_Trial_Count__c = corrDoc.PNR_Re_Trial_Count__c==null?1:corrDoc.PNR_Re_Trial_Count__c+1;//PION-2144 change
            
            if(String.isNotBlank(emailVal) && (corrDoc.PNR_Re_Trial_Count__c ==maxCount) && (corrDoc.PNR_Order_Response_Status_Code__c != 408 && corrDoc.PNR_Order_Response_Status_Code__c != 421) ){
                PNR_CorrDocuTriggerHelper.sendMsg(emailVal,'Response Status code is : '+String.valueOf(res.getStatusCode())+'<br/>Error is: '+errorMsg,corrDoc.Id);   
            }
            if(String.isNotBlank(emailVal) && (corrDoc.PNR_Re_Trial_Count__c ==maxCount) && corrDoc.PNR_Order_Response_Status_Code__c == 408){
                PNR_CorrDocuTriggerHelper.sendMsg(emailVal,'Response Status code is : '+408+'<br/>Error is: '+exceptionMessage,corrDoc.Id);   
            }
            if(String.isNotBlank(emailVal) && (corrDoc.PNR_Re_Trial_Count__c ==maxCount) && corrDoc.Error_Message__c == 'Following Exception happened '+exceptionMessage){
                PNR_CorrDocuTriggerHelper.sendMsg(emailVal,'Response Status code is : '+String.valueOf(res.getStatusCode())+'<br/>Error is: '+'Following Exception happened '+exceptionMessage,corrDoc.Id);   
            }
            update corrDoc;//PION-2144 change
            PNR_CorrDocuTriggerHelper.createLog(ex.getMessage(), 'Credit/Debit Return', jsonPayload, 'Failure', 'Credit/Debit Return',corrDoc.Id);
        }
        return jsonBody;
    }
    
    
    /*******************************************************************
Method  : createLog
Purpose : This method is used to Create Integration log record
***********************************************************************/
    public static void createLog(String errMsg, String interfcName, 
                                 String res, String status, String objType, String corDocId){
                                     Integer maxSize = 254;
                                     if(errMsg.length() > maxSize ){
                                         errMsg = errMsg.substring(0, maxSize);
                                     }
                                     Integration_Log__c logObj = new Integration_Log__c();
                                     logObj.Error_Message__c = errMsg;
                                     logObj.Interface_Name__c = interfcName;
                                     logObj.Request__c = res;
                                     logObj.Status__c = status;
                                     logObj.Type_of_Object__c = objType;
                                     if(Status == 'Failure' && String.isNotBlank(corDocId)){
                                         logObj.Response__c = 'Error Occurred for Correction Doc Id : '+corDocId;
                                     }
                                     else if(Status == 'Success' && String.isNotBlank(corDocId))
                                     {
                                         logObj.Response__c = 'Correction Doc Id : '+corDocId;
                                     }
                                     
                                     if(Schema.SObjectType.Integration_Log__c.isCreateable() && Schema.sObjectType.Integration_Log__c.isUpdateable()){
                                         insert logObj;
                                     }
                                 }
    /*******************************************************************
Class : wrapResponseClass
Purpose : This is the Wrapper Response Class
***********************************************************************/
    public class WrapResponseClass{
        Boolean isSuccess;
        String respMsg;
        public WrapResponseClass(Boolean isSuccess, String respMsg){
            this.isSuccess = isSuccess;
            this.respMsg = respMsg;
        }
    }
    /*******************************************************************
Method : sendMsg
Purpose : This method is used to send email to case owner
***********************************************************************/
    public static void sendMsg(String emailVal, String errorMsg, String corrDocId){
        Messaging.SingleEmailMessage emailObj = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {emailVal};
            String[] ccAddresses = new String[]{};
                ccAddresses = Label.PNR_OrderErrorEmail.split(';');
        emailObj.setToAddresses(toAddress);
        emailObj.setCcAddresses(ccAddresses);
        String corrDocURL = URL.getSalesforceBaseUrl().toExternalForm() +'/' + corrDocId;
        emailObj.setSubject('Error Occurred While Sending Data to SAP for Correction Document');
        emailObj.setHtmlBody('Error message is : <br>'+errorMsg+'</br> <p>'+
                             'Please <a href='+corrDocURL+'> click here </a> to see the Correction Document in Salesforce.');
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailObj });
        }catch(exception ex){
            System.debug('Exception:: '+ex.getStackTraceString());
        }
    }
    
    
    
}