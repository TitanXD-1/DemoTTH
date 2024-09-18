/***
Name: PNR_InvoiceDetailInformation
===
Purpose: This is the Controller class for PNR_InvoiceDetailInformation
===
History                                                            
------                                                    
VERSION    AUTHOR            DATE              DETAIL
1.0        Sudipta Nandi     15-07-2019        Initial Development
2.0		   Tanmoy Bardhan	 22-07-2019		   Added fetchCorrectionDoc method
3.0        Jyothsna Nagapudi 29-07-2019        Added validation for sold to combination
4.0		   Tanmoy Bardhan	 31-08-2019		   Added method fetchShiptoBilltoId
***/
public with sharing class PNR_InvoiceDetailInformation {
    /***
* Name : PNR_InvoiceDetailInformation
* Description : This method is used to fetch Invoice Data 
***/
    @AuraEnabled
    public static Invoice__c fetchInvoiceDetailInfo(String invoiceId) {
        //This methd is for getting cases from invoice Object based on invoice Id
        system.debug('parameter invoiceId::' + invoiceId);
        Invoice__c invoiceInfo;
        try{
            if(Schema.sObjectType.Invoice__c.isAccessible()){
                //PION-2578 Change; added Invoice_external_number__c, Delivery_External_Number__c, Invoice_Billing_Date__c fields in the soql query
                //PION-2579 Change: added SAP_Delivery_Number__c field in the SOQL Query
                invoiceInfo = [SELECT SAP_Delivery_Number__c,Invoice_external_number__c, Delivery_External_Number__c, Invoice_Billing_Date__c, Bill_To_Number__c,Correction_Of__c,Distribution_Channel__c,Division__c,Document_Type__c,Id,Due_Date__c,Due_Type__c,Order__c,Payer_Number__r.AccountNumber,Sales_Org__c,SAP_Invoice_Number__c,Ship_To_Number__c ,Account__r.AccountNumber,Order__r.PO_Number__c, PNR_PO_Number__c FROM Invoice__c WHERE Id = :invoiceId];
            }
        }
        catch(Exception ex){
            system.debug('Exception Message :: ' + ex.getMessage());
            invoiceInfo = null;
        }
        system.debug('invoiceInfo::' + invoiceInfo);
        return invoiceInfo;
        
    }
    // 1583 changes start..
    @AuraEnabled
    public static Case fetchCaseDetailInfo(string recordId) {
        //This methd is for getting cases based on recordId
                Case caseInfo;
        try{
            if(Schema.sObjectType.case.isAccessible()){
                
                caseInfo = [SELECT id, Dispute_Breakdown__c,Type from case where id=: recordId];
            }
        }
        catch(Exception ex){
            system.debug('Exception Message :: ' + ex.getMessage());
            caseInfo = null;
        }
        system.debug('caseInfo::' + caseInfo);
        return caseInfo;
        
    }
    // 1583 changes end
    @AuraEnabled
    public static List<Direct_Reason_Code_Mapping__mdt> fetchAllReasonCodes()
    {
        System.debug('Inside fetchAllReasonCodes::');
        List<Direct_Reason_Code_Mapping__mdt> allReasonCodes = new List<Direct_Reason_Code_Mapping__mdt>();
        if(Schema.sObjectType.Direct_Reason_Code_Mapping__mdt.isAccessible()){
            allReasonCodes= [SELECT DeveloperName,MasterLabel,Document_Type__c, Reason_Code_Description__c,Sales_Org__c FROM Direct_Reason_Code_Mapping__mdt order by DeveloperName];
        }
        System.debug('fetchAllReasonCodes value::' +allReasonCodes);
        return allReasonCodes;
    }
    
    @AuraEnabled
    public static List<PNR_Greek_Reason_Code__mdt> getAllGreekReasonCodes(){
        Map<String, PNR_Greek_Reason_Code__mdt> grReaCodeMap = PNR_Greek_Reason_Code__mdt.getAll();
        return grReaCodeMap.values();
    }
    
    @AuraEnabled
    public static List<PNR_CorrectionOfPricingCondition__mdt> fetchAllPricingCondition(){
        List<PNR_CorrectionOfPricingCondition__mdt> allPricingCondition = new List<PNR_CorrectionOfPricingCondition__mdt>();
        if(Schema.sObjectType.PNR_CorrectionOfPricingCondition__mdt.isAccessible()){
           
            allPricingCondition = [SELECT DeveloperName, MasterLabel, PNR_PricingCondition__c, PNR_SalesOrg__c,
                                                                 PNR_CorrectionOf__c,PNR_Dispute_Breakdown__c
                                                                 FROM PNR_CorrectionOfPricingCondition__mdt
                                                                 ORDER BY PNR_CorrectionOf__c];
                                                                     
                                                                     
        } 
        
        return allPricingCondition;
    }
    
    @AuraEnabled
    public static String createCorrectionDocument(Invoice__c recordInfo, String multipleInvoiceNumber,
                                                  String reasonCode, String greekReasonCode, String billingNotes, String poNumber,
                                                  String caseId, String typeOfReference, String correctionOf,
                                                  String shippingInstructions, String uso, String referenceDocument,
                                                  Date requestDeliveryDate){
                                                      
                                                      system.debug('correctionOf::'+correctionOf);
                                                      Date dateVar = date.valueOf(date.today());
                                                      System.debug('today date value '+ dateVar);
                                                      System.debug('user entered date '+ requestDeliveryDate);
                                                      string correctionDocumentInfo =null;
                                                      Correction_Document__c correctRecord = new Correction_Document__c();
                                                      List<Account> accountInfos = new List<Account>();
                                                      Set<String> accountId = new Set<String>();
                                                      
                                                      Map <String,String> accountMap = new Map <String,String>();
                                                      
                                                     
                                                          accountId.add(recordInfo.Ship_To_Number__c);
                                                          if(Schema.sObjectType.Account.isAccessible()){
                                                              accountInfos = [Select Id, PNR_Sales_Office__c from Account where AccountNumber in:accountId];
                                                      }
                                                        
                                                      try{
                                                          if(recordInfo != null){   
                                                                  correctRecord.Bill_To__c = recordInfo.Bill_To_Number__c;
                                                                  correctRecord.Ship_To__c = recordInfo.Ship_To_Number__c;
                                                              if(accountInfos.size()>0){
                                                                  correctRecord.PNR_Sales_Office__c = accountInfos[0].PNR_Sales_Office__c;
                                                              }
                                                              
                                                              correctRecord.Sold_To__c = recordInfo.Account__c;
                                                              correctRecord.Payer__c = recordInfo.Payer_Number__c;
                                                              correctRecord.Billing_notes_for_printing__c = billingNotes;
                                                              correctRecord.Distribution_Channel__c = recordInfo.Distribution_Channel__c;
                                                              correctRecord.Division__c = recordInfo.Division__c;
                                                              if(!recordInfo.Document_Type__c.equalsIgnoreCase('Select')){
                                                                  correctRecord.Document_Type__c = recordInfo.Document_Type__c;
                                                              }
                                                              correctRecord.Reference_invoice__c = recordInfo.Id;
                                                              correctRecord.Sales_Org__c = recordInfo.Sales_Org__c;
                                                              
                                                              correctRecord.Type_of_Reference__c = typeOfReference;
                                                              if(!reasonCode.equalsIgnoreCase('Select')){
                                                                  correctRecord.Reason_Code__c = reasonCode;
                                                              }
                                                              correctRecord.PO_Number__c = poNumber;
                                                              correctRecord.Case__c = caseId;
                                                              correctRecord.Correction_Of__c = correctionOf;
                                                              //PION-2206 change start
                                                              correctRecord.PNR_Reference_documents__c = referenceDocument;
                                                              correctRecord.PNR_Shipping_instructions__c = shippingInstructions;
                                                              correctRecord.PNR_USO_CFDI__c = uso;
                                                              
                                                              correctRecord.PNR_Requested_Delivery_date__c = requestDeliveryDate;
                                                              correctRecord.PNR_Greek_Reason_Code__c = greekReasonCode;
                                                              //PION-2206 change end
                                                              
                                                              Database.SaveResult correctionRecord = Database.insert(correctRecord, False);
                                                              if(correctionRecord.isSuccess())
                                                              {
                                                                  correctionDocumentInfo = correctRecord.id;
                                                              }
                                                          }
                                                          
                                                      }
                                                      catch(Exception ex){            
                                                          system.debug('Error in method createCorrectionDocument-->'+ex.getMessage() + ' and Line Number is ->' +ex.getLineNUmber());
                                                      }
                                                      
                                                      return correctionDocumentInfo;
                                                  } 
    
    // Added by Tanmoy
    @AuraEnabled
    public static Correction_Document__c fetchCorrectionDoc(String recordId){
        Correction_Document__c corDoc;
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            corDoc = [SELECT Name,Sales_Org__c, CurrencyIsoCode, Distribution_Channel__c,
                      Document_Type__c, Division__c, Payer__c, Payer__r.Name, Payer__r.AccountNumber, Sold_To__c,
                      Sold_To__r.Name, Sold_To__r.AccountNumber, Reason_Code__c, Ship_To__c, Type_of_Reference__c,
                      Bill_To__c, PO_Number__c, Case__c, Case__r.CaseNumber,Case__r.Type, Approver_Email__c, Invoices_Affected__c,
                      Previous_Approver_Email__c, Reference_invoice__r.SAP_Invoice_Number__c,
                      Billing_notes_for_printing__c, Correction_Of__c, Status__c,PNR_Shipping_instructions__c,PNR_Requested_Delivery_date__c,
                      PNR_USO_CFDI__c,PNR_Reference_documents__c, PNR_Greek_Reason_Code__c
                      FROM Correction_Document__c
                      WHERE Id = :recordId];
        }//PION-2206 added Status__c,PNR_Shipping_instructions__c,PNR_Requested_Delivery_date__c, PNR_USO_CFDI__c,PNR_Reference_documents__c in Query
        return corDoc;
    }
    
    // Added by Tanmoy
    @AuraEnabled
    public static Boolean updateCorrectionDocument(Correction_Document__c corDoc,String recordId){
        system.debug('ship to :: '+corDoc.Ship_To__c);
        system.debug('bill to :: '+corDoc.Bill_To__c);
        String shipToNumber = '';
        String billToNumber = '';
        if(corDoc.Ship_To__c != '' && corDoc.Ship_To__c != Null){
            shipToNumber = [SELECT Name,AccountNumber FROM Account WHERE Id = :corDoc.Ship_To__c].AccountNumber;
        }
        if(corDoc.Bill_To__c != '' && corDoc.Bill_To__c != Null){
            billToNumber = [SELECT Name,AccountNumber FROM Account WHERE Id = :corDoc.Bill_To__c].AccountNumber; 
        }
        Correction_Document__c corDocRecord = new Correction_Document__c();
        corDocRecord.Id = recordId;
        corDocRecord.Sales_Org__c = corDoc.Sales_Org__c;
        corDocRecord.Distribution_Channel__c = corDoc.Distribution_Channel__c;
        corDocRecord.Document_Type__c = corDoc.Document_Type__c;
        corDocRecord.Division__c = corDoc.Division__c;
        corDocRecord.Reason_Code__c = corDoc.Reason_Code__c;
        corDocRecord.Ship_To__c = shipToNumber;
        corDocRecord.Bill_To__c = billToNumber;
        corDocRecord.PO_Number__c = corDoc.PO_Number__c;
        corDocRecord.Payer__c = corDoc.Payer__c;
        corDocRecord.Sold_To__c = corDoc.Sold_To__c;
        corDocRecord.Invoices_Affected__c = corDoc.Invoices_Affected__c;
        corDocRecord.Reason_Code__c = corDoc.Reason_Code__c;
        corDocRecord.Correction_Of__c = corDoc.Correction_Of__c;
        corDocRecord.Billing_notes_for_printing__c = corDoc.Billing_notes_for_printing__c;
        corDocRecord.PNR_Shipping_instructions__c = corDoc.PNR_Shipping_instructions__c;//PION-2206 Change
        corDocRecord.PNR_Requested_Delivery_date__c = corDoc.PNR_Requested_Delivery_date__c;//PION-2206 Change
        corDocRecord.PNR_USO_CFDI__c = corDoc.PNR_USO_CFDI__c;//PION-2206 Change
        corDocRecord.PNR_Reference_documents__c = corDoc.PNR_Reference_documents__c;//PION-2206 Change
        corDocRecord.PNR_Greek_Reason_Code__c = corDoc.PNR_Greek_Reason_Code__c;
        
        Database.SaveResult saveRslt = Database.update(corDocRecord, false);
        if(saveRslt.isSuccess()){
            return true;
        }else{
            return false;
        }
    }
    // added by Tanmoy
    @AuraEnabled
    public static Map<String,Id> fetchShiptoBilltoId(String recordId){
        Map<String,Id> accountMap = new Map<String,Id>();
        String shipTo = '';
        String shipToId = '';
        String billTo = '';
        String billToId = '';
        List<Correction_Document__c> cdList = [SELECT Id,Ship_To__c,Bill_To__c
                                               FROM Correction_Document__c
                                               WHERE Id = :recordId];
        if(cdList[0].Ship_To__c !='' && cdList[0].Ship_To__c != Null){
            shipTo = cdList[0].Ship_To__c;
            shipToId = [SELECT Id FROM Account WHERE AccountNumber = :shipTo].Id;
            accountMap.put(shipTo,shipToId);
        }
        
        if(cdList[0].Bill_To__c !='' && cdList[0].Bill_To__c != Null){
            billTo = cdList[0].Bill_To__c;
            billToId = [SELECT Id FROM Account WHERE AccountNumber = :billTo].Id;
            accountMap.put(billTo,billToId);
        }
        system.debug('accountMap::'+accountMap);
        return accountMap;
    }
    
    // Added by Jyothsna
    @AuraEnabled
    public static String validateSoldtoCombination(String salesOrg, String soldTo, String payer, String billTo,
                                                   String shipTo, String distChannel, String division){
                                                       system.debug('salesOrg::'+salesOrg);
                                                       system.debug('soldTo::'+soldTo);
                                                       system.debug('payer::'+payer);
                                                       system.debug('billTo::'+billTo);
                                                       system.debug('shipTo::'+shipTo);
                                                       system.debug('distChannel::'+distChannel);
                                                       system.debug('division::'+division);
                                                       String validateString = '';
                                                       List<PNR_Partner_Function__c> pfList = new List<PNR_Partner_Function__c>();
                                                       Set<String> payerSet = new Set<String>();
                                                       Set<String> billToSet = new Set<String>();
                                                       Set<String> shipToSet = new Set<String>();
                                                       Set<String> salesOrgSet = new Set<String>();
                                                       Set<String> distChannelDivisionSet = new Set<String>();
                                                       Boolean isPayerAvailable = false;
                                                       Boolean isBillToAvailable = false;
                                                       Boolean isShipToAvailable = false;
                                                       Boolean isSalesOrgAvailable = false;
                                                       Boolean isdistChannelDivisionAvailable = false;
                                                       if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
                                                           pfList = [SELECT Id, Name, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Customer_No__c, PNR_Distribution_Channel__c, 
                                                                     PNR_Division__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber
                                                                     FROM PNR_Partner_Function__c
                                                                     WHERE PNR_Sold_To__c = :soldTo and PNR_Deletion_Flag_for_Sales_Level__c = false and 
                                                                     PNR_Customer_No__r.Central_Billing_Block__c != 'Blocked' and PNR_Customer_No__r.Central_Order_Block__c != 'Blocked'
                                                                     and PNR_Customer_No__r.Deletion_Flag_from_SAP__c = false];
                                                       }
                                                       if(pfList != null && pfList.size() > 0) {
                                                           system.debug('pfList:' + pfList);
                                                           for(PNR_Partner_Function__c pf : pfList) {
                                                               salesOrgSet.add(pf.PNR_Sales_Org__c);
                                                               if(pf.PNR_Sales_Org__c == salesOrg) {
                                                                   isSalesOrgAvailable = true; 
                                                                   distChannelDivisionSet.add(pf.PNR_Distribution_Channel__c + '-' + pf.PNR_Division__c);
                                                                   if(pf.PNR_Distribution_Channel__c == distChannel && pf.PNR_Division__c == division) {
                                                                       isdistChannelDivisionAvailable = true; 
                                                                       if(pf.PNR_Type__c == 'Payer') {
                                                                           payerSet.add(pf.PNR_Customer_No__r.AccountNumber); 
                                                                           if(pf.PNR_Customer_No__c == payer) {
                                                                               isPayerAvailable = true;    
                                                                           }
                                                                       }
                                                                       else if(pf.PNR_Type__c == 'Bill-To') {
                                                                           billToSet.add(pf.PNR_Customer_No__r.AccountNumber);
                                                                           if(pf.PNR_Customer_No__c == billTo) {
                                                                               isBillToAvailable = true;    
                                                                           }
                                                                       }
                                                                       else if(pf.PNR_Type__c == 'Ship-To') {
                                                                           shipToSet.add(pf.PNR_Customer_No__r.AccountNumber);
                                                                           if(pf.PNR_Customer_No__c == shipTo) {
                                                                               isShipToAvailable = true;    
                                                                           }
                                                                       }
                                                                   }
                                                               }    
                                                           }
                                                       }
                                                       system.debug('payerSet:' + payerSet);
                                                       system.debug('billToSet:' + billToSet);
                                                       system.debug('shipToSet:' + shipToSet);
                                                       system.debug('salesOrgSet:' + salesOrgSet);
                                                       system.debug('distChannelDivisionSet:' + distChannelDivisionSet);
                                                       system.debug('isPayerAvailable:' + isPayerAvailable);
                                                       system.debug('isBillToAvailable:' + isBillToAvailable);
                                                       system.debug('isShipToAvailable:' + isShipToAvailable);
                                                       system.debug('isSalesOrgAvailable:' + isSalesOrgAvailable);
                                                       system.debug('isdistChannelDivisionAvailable:' + isdistChannelDivisionAvailable);
                                                       
                                                       if(!isSalesOrgAvailable) {
                                                           List<String> salesOrgList = new List<String>();
                                                           salesOrgList.addAll(salesOrgSet);
                                                           validateString = 'Selected sales org is not available. The available sales org are ' + String.join(salesOrgList, ',') + '.';
                                                       }
                                                       else if(!isdistChannelDivisionAvailable) {
                                                           List<String> distChannelDivisionList = new List<String>();
                                                           distChannelDivisionList.addAll(distChannelDivisionSet);
                                                           validateString = 'Selected Distribution Channel and Division is not available. The available are ' + String.join(distChannelDivisionList, ',') + '.';
                                                       }
                                                       else if(!isPayerAvailable || !isBillToAvailable || !isShipToAvailable) {
                                                           if(!isPayerAvailable) {
                                                               List<String> payerList = new List<String>();
                                                               payerList.addAll(payerSet);
                                                               validateString = 'Selected payer is not available. The available payer are ' + String.join(payerList, ',') + '.';
                                                           }
                                                           if(!isBillToAvailable) {
                                                               List<String> billToList = new List<String>();
                                                               billToList.addAll(billToSet);
                                                               validateString = validateString + 'Selected bill to is not available. The available bill to are ' + String.join(billToList, ',') + '.';
                                                           }
                                                           if(!isShipToAvailable) {
                                                               List<String> shipToList = new List<String>();
                                                               shipToList.addAll(shipToSet);
                                                               validateString = validateString + 'Selected ship to is not available. The available are ship to ' + String.join(shipToList, ',') + '.';
                                                           }
                                                       }
                                                       system.debug('validateString:' + validateString);
                                                       
                                                       return validateString;
                                                   }
   
}