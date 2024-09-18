/***
Name: PNR_InvoiceLineItems
=====
Purpose: This is the Controller class for PNR_InvoiceLineItems
=====
History                                                            
------                                                        
VERSION    AUTHOR            DATE              DETAIL
1.0        Sudipta Nandi     15-07-2019        Initial Development
1.1        Tanmoy Bardhan    29-07-2019        Modified fetchInvoiceLineItems to update pricing condition
1.2        Juned khan		 30-07-2019	       created method to fetch InvoiceLineItem based on correction document
***/

public with sharing class PNR_InvoiceLineItems {
    /***
* Name : fetchInvoiceLineItems
* Description : This method is used to fetch Invoice Line Items 
***/
    @AuraEnabled
    public static list<PNR_CorrectionDocumentMapping__c> fetchInvoiceLineItems(String invoiceId, String recordId,String claimedInvoiceLineItems) {
        list<Invoice_Line_Item__c> invoiceLineItemInfo = new list<Invoice_Line_Item__c>();
        list<PNR_CorrectionDocumentMapping__c> mappingInvoiceLineItems = new list<PNR_CorrectionDocumentMapping__c>();
        List<Correction_Document__c> cdList = new List<Correction_Document__c>();
        
        //This method will first get the related correction document, its Correction Of and update the pricing condition in the Invoice Line Items
        // Single Reference CD - Invoice Line Item - Pricing Condition Update Start
        String correctionOf = '';
        String pricingCondition = '';
        list<Invoice_Line_Item__c> invoiceLineItemList = new list<Invoice_Line_Item__c>();
        list<Invoice_Line_Item__c> invoiceLineItemToUpdateList = new list<Invoice_Line_Item__c>();
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            cdList = [SELECT Id,Correction_Of__c, Sales_Org__c, case__r.Dispute_Breakdown__c FROM Correction_Document__c WHERE Id = :recordId];
        }
        
        if(cdList[0].Correction_Of__c != Null && cdList[0].Correction_Of__c != ''){
            //Get the Pricing condition from the correctionOf above
            correctionOf  = cdList[0].Correction_Of__c;
            if(Schema.sObjectType.PNR_CorrectionOfPricingCondition__mdt.isAccessible()){
                pricingCondition = [SELECT PNR_PricingCondition__c
                                    FROM PNR_CorrectionOfPricingCondition__mdt
                                    WHERE PNR_CorrectionOf__c = :correctionOf].PNR_PricingCondition__c;
            }
        }
        
        System.debug('claimedInvoiceLineItems==>' + claimedInvoiceLineItems);
        if(Schema.sObjectType.Invoice_Line_Item__c.isAccessible()){
            if(claimedInvoiceLineItems == null){
                invoiceLineItemInfo = [SELECT Product_Number__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c FROM Invoice_Line_Item__c WHERE Invoice__c = :invoiceId ORDER BY SAP_Line_Item_Number__c ASC];
                System.debug('invoiceLineItemInfo===>' + invoiceLineItemInfo);
                if(invoiceLineItemInfo !=null){
                    for(Invoice_Line_Item__c inv : invoiceLineItemInfo){
                        mappingInvoiceLineItems.Add(new PNR_CorrectionDocumentMapping__c(
                            Product_Number__c = inv.Product_Number__c,
                            SAP_Line_Item_Number__c  = inv.SAP_Line_Item_Number__c,
                            Product_Description__c  = inv.Product_Description__c,
                            Pricing_Condition__c  = inv.Pricing_Condition__c,
                            //PION-2599 : changes to display plant code and plant name for CE01
                            Plant__c  = cdList[0].Sales_Org__c == 'CE01' ? inv.Plant__c.toUpperCase() + ' - '+ PNR_Primary_Market_Plant__mdt.getInstance(inv.Plant__c.toUpperCase()).Plant_Name__c: inv.Plant__c,
                            Invoice_Unit_of_Measure__c  = inv.Invoice_Unit_of_Measure__c,
                            Invoice_Quantity__c  = inv.Invoice_Quantity__c,
                            Invoice_Net_Price_Unit__c  = inv.Invoice_Net_Price_Unit__c,
                            Invoice_Net_Price_Item__c  = inv.Invoice_Net_Price_Item__c,
                            Invoice__c  = inv.Invoice__c,
                            Batch__c  = inv.Batch__c,
                            Claimed_Net_Amount__c  = inv.Claimed_Net_Amount__c,
                            CurrencyIsoCode  = inv.CurrencyIsoCode,
                            Claimed_Volume__c  = inv.Claimed_Volume__c,
                            Unit_of_Measure_of_Claimed_QTY__c = inv.Unit_of_Measure_of_Claimed_QTY__c,
                            Invoice_Line_Item__c = inv.id,
                            Correction_Document__c = recordId
                        ));
                    }
                }
                Correction_Document__c disputeBreakdown = [SELECT Id, case__r.Dispute_Breakdown__c from Correction_Document__c where Id=: recordId];//PION-2202 Change
                if(cdList[0].Correction_Of__c != Null && cdList[0].Correction_Of__c != ''){
                    if(!mappingInvoiceLineItems.isEmpty() ){
                        for(PNR_CorrectionDocumentMapping__c lineItemObj : mappingInvoiceLineItems){
                            lineItemObj.Pricing_Condition__c = cdList[0].Correction_Of__c;  
                            lineItemObj.Pricing_Condition_Code__c = pricingCondition;      
                        }
                    }
                }
                else{
                    
                    if(!mappingInvoiceLineItems.isEmpty()){
                        for(PNR_CorrectionDocumentMapping__c lineItemObj : mappingInvoiceLineItems){
                            lineItemObj.Pricing_Condition__c = '';
                            lineItemObj.Pricing_Condition_Code__c = '';
                        }
                    }
                }
                
                if(!mappingInvoiceLineItems.isEmpty()){
                    List<Database.SaveResult> updateResults = database.insert(mappingInvoiceLineItems, false);
                }
            }
        } 
        
        List<PNR_CorrectionDocumentMapping__c> invoiceLineItemsRecords = new List<PNR_CorrectionDocumentMapping__c>();
        try{
            if(Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
                invoiceLineItemsRecords = [SELECT Product_Number__c,Unit_of_Measure_of_Claimed_QTY__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,Plant__c,Id,
                                           Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,
                                           Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,Claimed_Net_Amount__c,
                                           CurrencyIsoCode,Claimed_Volume__c,Correction_Document__c,Item_Number__c,PNR_Recharge_Material__c 
                                           FROM PNR_CorrectionDocumentMapping__c WHERE Correction_Document__c = :recordId
                                           ORDER BY Item_Number__c ASC];
            }
            String claimedItemName = '';
            for(PNR_CorrectionDocumentMapping__c invRec: invoiceLineItemsRecords){
                if(string.isNotEmpty(claimedItemName) || string.isNotBlank(claimedItemName)){
                    claimedItemName = claimedItemName + ';'+ invRec.Name;
                }
                else{
                    claimedItemName = invRec.Name;
                }
            }
            Correction_Document__c corDocRecord = new Correction_Document__c();
            corDocRecord.Id =recordId;
            corDocRecord.Claimed_Invoice_Line_Items__c = claimedItemName;
            System.debug('corDocRecord from updateClaimedLineItemAmount====>' + corDocRecord);
            Database.SaveResult saveRsltforCor = Database.update(corDocRecord, false);
            
        }
        
        
        catch(Exception ex){
            invoiceLineItemsRecords = null;
        }
        return invoiceLineItemsRecords;
        
    }
    @AuraEnabled
    public static Correction_Document__c fetchInvoiceNumber(String recordId) {
        //This methd is for getting Correction_Document__c info from Correction_Document__c Object based on Correction_Document__c Id
        Correction_Document__c corDoc;
        try{
            if(Schema.sObjectType.Invoice__c.isAccessible()){
                corDoc = [SELECT Name,Sales_Org__c, CurrencyIsoCode, Distribution_Channel__c,
                          Document_Type__c, Division__c, Payer__c, Payer__r.Name, Sold_To__c,
                          Sold_To__r.Name, Reason_Code__c, Ship_To__c, Type_of_Reference__c,
                          Bill_To__c, PO_Number__c, Case__c, Case__r.CaseNumber,Case__r.Type,Case__r.Dispute_Breakdown__c/**Sai***/, Approver_Email__c,
                          Previous_Approver_Email__c, Reference_invoice__c,Claimed_Invoice_Line_Items__c,Status__c
                          FROM Correction_Document__c
                          WHERE Id = :recordId];
            }
        }
        catch(Exception ex){
            corDoc = null;
        }
        return corDoc;
        
    }
    
    @AuraEnabled
    public static boolean saveClaimedLineItem(String recordInfos, String correctionDocId){
        //Udateing Correction_Document__c Object Claimed_Invoice_Line_Items__c field based on Correction_Document__c Id and Not Removed Line Items Name from Single Reference
        List<PNR_CorrectionDocumentMapping__c> corInVItems = new List<PNR_CorrectionDocumentMapping__c>();
        String[] ids = recordInfos.split(';');
        corInVItems = [SELECT Id, Name,Correction_Document__c from PNR_CorrectionDocumentMapping__c where Correction_Document__c =:correctionDocId AND Id Not IN :ids];
        System.debug('corInVItems ===>' + corInVItems);
        Database.DeleteResult[] dr = Database.delete(corInVItems);
        
        Correction_Document__c corDocRecord = new Correction_Document__c();
        corDocRecord.Id = correctionDocId;
        corDocRecord.Claimed_Invoice_Line_Items__c = recordInfos;
        Database.SaveResult sr = Database.update(corDocRecord, false);
        if(sr.isSuccess()){
            return true;
        }else{
            return false;
        }
        
    } 
    
    @AuraEnabled
    public static boolean updateClaimedLineItemAmountForMapping(list<PNR_CorrectionDocumentMapping__c> recordInfos,String recordId){
        //This methd is for updating invoice Line Item from Single Reference Component Save Button and Editable data table save button from Multiple Reference.
        
        boolean isSuccess = true;
        
        Map<String, String> priConMap = new Map<String, String>();
        for(PNR_CorrectionOfPricingCondition__mdt prCon: [SELECT PNR_PricingCondition__c, PNR_CorrectionOf__c FROM PNR_CorrectionOfPricingCondition__mdt]){
            priConMap.put(prCon.PNR_CorrectionOf__c, prCon.PNR_PricingCondition__c);
        }
        
        for(PNR_CorrectionDocumentMapping__c invitem : recordInfos){
            if(invitem.Claimed_Net_Amount__c!=null){
                invitem.Claimed_Net_Amount__c =  invitem.Claimed_Net_Amount__c.setScale(2, RoundingMode.HALF_UP);
            }
            if(invitem.Pricing_Condition__c!=null){
                invitem.Pricing_Condition_Code__c = priConMap.get(invitem.Pricing_Condition__c);
            }
        }
        Database.SaveResult[] srList = Database.update(recordInfos, false);
        
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Invoice_Line_Item__c. Invoice_Line_Item__c ID:====> ' + sr.getId());
            }
            
            else {
                for(Database.Error err : sr.getErrors()) {
                    isSuccess = false;
                    System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Invoice_Line_Item__c fields that affected this error:===> ' + err.getFields());
                }
            }
        }
        
        //saved Claimed Line Item field in Correction Document for Single Reference Save button not needed for Multiple Reference as it is saved while new create.
        String claimedItemName = '';
        for(PNR_CorrectionDocumentMapping__c invRec: recordInfos){
            if(string.isNotEmpty(claimedItemName) || string.isNotBlank(claimedItemName)){
                claimedItemName = claimedItemName + ';'+ invRec.Name;
            }
            else{
                claimedItemName = invRec.Name;
            }
        }
        Correction_Document__c corDocRecord = new Correction_Document__c();
        corDocRecord.Id =recordId;
        corDocRecord.Claimed_Invoice_Line_Items__c = claimedItemName;
        System.debug('corDocRecord from updateClaimedLineItemAmount====>' + corDocRecord);
        Database.SaveResult saveRsltforCor = Database.update(corDocRecord, false);
        
        return isSuccess;
        
    }
    @AuraEnabled
    public static List<PNR_CorrectionDocumentMapping__c> fetchLineItemForMapping(String correctionId) {
        // This Method is used from Multiple Reference doInit method.Parameter: Correction Document Id.
        String correctionOf = '';
        String pricingCondition = '';
        List<Correction_Document__c> cdList = new List<Correction_Document__c>();
        list<PNR_CorrectionDocumentMapping__c> invoiceLineItemList = new list<PNR_CorrectionDocumentMapping__c>();
        list<PNR_CorrectionDocumentMapping__c> invoiceLineItemToUpdateList = new list<PNR_CorrectionDocumentMapping__c>();
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            cdList = [SELECT Id,Correction_Of__c FROM Correction_Document__c WHERE Id = :correctionId];
        }
        
        if(cdList[0].Correction_Of__c != Null && cdList[0].Correction_Of__c != ''){
            //Get the Pricing condition from the correctionOf above
            correctionOf  = cdList[0].Correction_Of__c;
            if(Schema.sObjectType.PNR_CorrectionOfPricingCondition__mdt.isAccessible()){
                pricingCondition = [SELECT PNR_PricingCondition__c
                                    FROM PNR_CorrectionOfPricingCondition__mdt
                                    WHERE PNR_CorrectionOf__c = :correctionOf].PNR_PricingCondition__c;
            }
            if(Schema.sObjectType.Invoice_Line_Item__c.isAccessible()){
                invoiceLineItemList = [SELECT Id,Correction_Document__c,Pricing_Condition__c 
                                       FROM PNR_CorrectionDocumentMapping__c 
                                       WHERE  Correction_Document__c = :correctionId];
            }
            if(!invoiceLineItemList.isEmpty()){
                for(PNR_CorrectionDocumentMapping__c lineItemObj : invoiceLineItemList){
                    lineItemObj.Pricing_Condition__c = pricingCondition;
                    invoiceLineItemToUpdateList.add(lineItemObj);
                }
            }
            if(!invoiceLineItemToUpdateList.isEmpty()){
                List<Database.SaveResult> updateResults = database.update(invoiceLineItemToUpdateList, false);
            }
        }else{
            if(Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
                invoiceLineItemList = [SELECT Id,Correction_Document__c,Pricing_Condition__c FROM PNR_CorrectionDocumentMapping__c WHERE  Correction_Document__c = :correctionId];
            }
            if(!invoiceLineItemList.isEmpty()){
                for(PNR_CorrectionDocumentMapping__c lineItemObj : invoiceLineItemList){
                    lineItemObj.Pricing_Condition__c = '';
                    invoiceLineItemToUpdateList.add(lineItemObj);
                }
            }
            if(!invoiceLineItemToUpdateList.isEmpty()){
                List<Database.SaveResult> updateResults = database.update(invoiceLineItemToUpdateList, false);
            }
        }
        
        // Single Reference CD - Invoice Line Item - Pricing Condition Update End
        
        //This method is for getting invoicelineitems based on Correction Document Id
        List<PNR_CorrectionDocumentMapping__c> invoiceLineItemInfo = new List<PNR_CorrectionDocumentMapping__c>();
        try{
            if(Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
                invoiceLineItemInfo = [SELECT Product_Number__c,Unit_of_Measure_of_Claimed_QTY__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,
                                       Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,
                                       Invoice__c,Batch__c,Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Correction_Document__c,Item_Number__c 
                                       FROM PNR_CorrectionDocumentMapping__c 
                                       WHERE Correction_Document__c = :correctionId
                                       ORDER BY Item_Number__c ASC];
            }
        }
        catch(Exception ex){
            invoiceLineItemInfo = null;
        }
        return invoiceLineItemInfo;
    }
    
    @AuraEnabled
    public static Boolean saveInvoiceLineItemsForMapping(PNR_CorrectionDocumentMapping__c invoiceLineItems,String recordId){
        //This Method is used from Multiple Reference during Add New Line Item option.
        boolean isSuccess = false;
        string claimedLineItem ='';
        Correction_Document__c corDocRecord = new Correction_Document__c();
        PNR_CorrectionDocumentMapping__c lineItemRec = new PNR_CorrectionDocumentMapping__c();
        Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c();
        Invoice__c invRecrd = new Invoice__c();
        
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            corDocRecord = [SELECT Id, Claimed_Invoice_Line_Items__c FROM Correction_Document__c WHERE Id = :recordId];
        }
        if(Schema.sObjectType.Invoice__c.isAccessible()){
            invRecrd = [SELECT Id FROM Invoice__c WHERE Name = '00000000'];
        }
        invoiceLineItems.Correction_Document__c = recordId;
        if(invRecrd !=null){
            invoiceLineItems.Invoice__c = invRecrd.Id;
        }
        lineItem.Product_Number__c = invoiceLineItems.Product_Number__c;
        lineItem.SAP_Line_Item_Number__c  = invoiceLineItems.SAP_Line_Item_Number__c;
        lineItem.Product_Description__c  = invoiceLineItems.Product_Description__c;
        lineItem.Pricing_Condition__c  = invoiceLineItems.Pricing_Condition__c;
        lineItem.Plant__c  = invoiceLineItems.Plant__c;
        lineItem.Invoice_Unit_of_Measure__c  = invoiceLineItems.Invoice_Unit_of_Measure__c;
        lineItem.Invoice_Quantity__c  = invoiceLineItems.Invoice_Quantity__c;
        lineItem.Invoice_Net_Price_Unit__c  = invoiceLineItems.Invoice_Net_Price_Unit__c;
        lineItem.Invoice_Net_Price_Item__c  = invoiceLineItems.Invoice_Net_Price_Item__c;
        lineItem.Invoice__c  = invoiceLineItems.Invoice__c;
        lineItem.Batch__c  = invoiceLineItems.Batch__c;
        lineItem.Claimed_Net_Amount__c  = invoiceLineItems.Claimed_Net_Amount__c;
        lineItem.CurrencyIsoCode  = invoiceLineItems.CurrencyIsoCode;
        lineItem.Claimed_Volume__c  = invoiceLineItems.Claimed_Volume__c;
        lineItem.Unit_of_Measure_of_Claimed_QTY__c = invoiceLineItems.Unit_of_Measure_of_Claimed_QTY__c;
        
        Database.SaveResult saveRsltInv = Database.insert(lineItem, false);
        
        invoiceLineItems.Invoice_Line_Item__c = lineItem.id;
        Database.SaveResult saveRslt = Database.insert(invoiceLineItems, false);
        if(saveRslt.isSuccess()){
            isSuccess = true;
        }
        else{
            for(Database.Error err : saveRslt.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }
        }
        if(Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
            lineItemRec = [SELECT Id, Name FROM PNR_CorrectionDocumentMapping__c WHERE Id = :invoiceLineItems.Id];
        }
        
        
        if(string.isNotEmpty(corDocRecord.Claimed_Invoice_Line_Items__c) || string.isNotBlank(corDocRecord.Claimed_Invoice_Line_Items__c)){
            corDocRecord.Claimed_Invoice_Line_Items__c = corDocRecord.Claimed_Invoice_Line_Items__c + ';'+ lineItemRec.Name;
        } 
        else{
            corDocRecord.Claimed_Invoice_Line_Items__c = lineItemRec.Name;
        }
        Database.SaveResult saveRsltforCor = Database.update(corDocRecord, false);
        return isSuccess;
    }
    
    @AuraEnabled
    public static boolean saveItemsAndTotalAmountForMapping(list<PNR_CorrectionDocumentMapping__c> recordInfos,String totalClaimedAmount,String caseId, String currencySign){
        //This Method is used for both Single and Multiple Reference from CalculateTotal Method to save total amount.
        //For single recordInfos is null.Because it is already saved when user clicks Save option.For multiple it is saved during Calculate Total time
        
        boolean isSuccess = true;
        System.debug('recordInfos ===>'+ recordInfos);
        if(recordInfos!=null){
            for(PNR_CorrectionDocumentMapping__c invitem : recordInfos){
                if(invitem.Claimed_Net_Amount__c!=null){
                    invitem.Claimed_Net_Amount__c =  invitem.Claimed_Net_Amount__c.setScale(2, RoundingMode.HALF_UP);
                }  
            }
            //This methd is for updateing invoice Line Items amount from Single Reference Component.
            Database.SaveResult[] srList = Database.update(recordInfos, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted Invoice_Line_Item__c. Invoice_Line_Item__c ID:====> ' + sr.getId());
                }
                
                else {
                    for(Database.Error err : sr.getErrors()) {
                        isSuccess = false;
                        System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Invoice_Line_Item__c fields that affected this error:===> ' + err.getFields());
                    }
                }
            }
        }
        PNR_InvoiceLineItems.byPassValidation(false);//PION-2162 change
        Case caseRecord = new Case();
        caseRecord.Id = CaseId;
        caseRecord.Claimed_Amount__c = (Decimal.ValueOf(totalClaimedAmount)).setScale(2, RoundingMode.HALF_UP);
        if(String.isNotEmpty(currencySign) && String.isNotBlank(currencySign)){
            caseRecord.CurrencyIsoCode =currencySign;
        }
        // Code Change for UAT PION- 1035 Fix start 
        Correction_Document__c corDocRecord = new Correction_Document__c();
        if(Schema.sObjectType.Correction_Document__c.isAccessible() && caseId!= null){
            corDocRecord = [SELECT Id, CurrencyIsoCode,Claimed_Amount__c,Case__c FROM Correction_Document__c WHERE Case__c = :caseId LIMIT 1];
        }
        if(String.isNotEmpty(currencySign) && String.isNotBlank(currencySign)){
            corDocRecord.CurrencyIsoCode =currencySign;
        }
        Database.SaveResult cordoc = Database.update(corDocRecord, false);
        if(cordoc.isSuccess()){
            System.debug('Successfully updated currency for Correcction doc ====> ' + cordoc.getId());
        }else{
            isSuccess = false;
        }
        // Code Change for UAT PION- 1035 Fix end
        Database.SaveResult sr = Database.update(caseRecord, false);
        PNR_InvoiceLineItems.byPassValidation(true);//PION-2162 change
        if(sr.isSuccess()){
            System.debug('Successfully inserted Claimed_Amount__c:====> ' + sr.getId());
        }else{
            isSuccess = false;
        }
        
        return isSuccess;
    }
    @AuraEnabled
    public static List<PNR_SalesOrg_Mapping__mdt> fetchSalesOrgMapping()
    {
        List<PNR_SalesOrg_Mapping__mdt> allsalesOrg = new List<PNR_SalesOrg_Mapping__mdt>();
        if(Schema.sObjectType.PNR_SalesOrg_Mapping__mdt.isAccessible()){
            allsalesOrg= [SELECT DeveloperName,Sales_Org_Name__c FROM PNR_SalesOrg_Mapping__mdt order by DeveloperName];
        }
        return allsalesOrg;
    }
    
    @AuraEnabled
    public static Boolean removeMultipleRefLineItemForMapping(list<PNR_CorrectionDocumentMapping__c> recordInfos,String recordId){
        //This Method is used from Multiple Reference during remove Line Item option.
        boolean isSuccess = true;
        string claimedLineItem ='';
        Correction_Document__c corDocRecord = new Correction_Document__c();
        
        
        if(Schema.sObjectType.Correction_Document__c.isAccessible()){
            corDocRecord = [SELECT Id, Claimed_Invoice_Line_Items__c FROM Correction_Document__c WHERE Id = :recordId];
        }
        
        Database.DeleteResult[] deleteResults= Database.delete(recordInfos, false);
        for (Database.DeleteResult sr : deleteResults) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully deleted Invoice_Line_Item__c. Invoice_Line_Item__c ID:====> ' + sr.getId());
            }
            
            else {
                for(Database.Error err : sr.getErrors()) {
                    isSuccess = false;
                    System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Invoice_Line_Item__c fields that affected this error:===> ' + err.getFields());
                }
            }
        }
        
        List<PNR_CorrectionDocumentMapping__c> invoiceLineItemInfo = new List<PNR_CorrectionDocumentMapping__c>();
        
        if(Schema.sObjectType.PNR_CorrectionDocumentMapping__c.isAccessible()){
            invoiceLineItemInfo = [SELECT Product_Number__c,Unit_of_Measure_of_Claimed_QTY__c,SAP_Line_Item_Number__c,Product_Description__c,Pricing_Condition__c,Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Correction_Document__c FROM PNR_CorrectionDocumentMapping__c WHERE Correction_Document__c = :recordId];
        }
        System.debug('invoiceLineItemInfo====>' + invoiceLineItemInfo);
        //saved Claimed Line Item field in Correction Document for Multiple Reference Delete button.
        String claimedItemName = '';
        for(PNR_CorrectionDocumentMapping__c invRec: invoiceLineItemInfo){
            if(string.isNotEmpty(claimedItemName) || string.isNotBlank(claimedItemName)){
                claimedItemName = claimedItemName + ';'+ invRec.Name;
            }
            else{
                claimedItemName = invRec.Name;
            }
        }
        corDocRecord.Claimed_Invoice_Line_Items__c = claimedItemName;
        System.debug('corDocRecord from removeMultipleRefLineItem====>' + corDocRecord);
        Database.SaveResult saveRsltforCor = Database.update(corDocRecord, false);
        
        return isSuccess;
    }
    
    //added by Tanmoy PION - 107 - SKU list in SF - Multiple Reference Document 2
    @AuraEnabled
    public static List<Product_Sales_Area__c> fetchSKUList(String salesOrg, String distributionChannel){
        List<Product_Sales_Area__c> productList = new List<Product_Sales_Area__c>();
        if(Schema.sObjectType.Product_Sales_Area__c.isAccessible()){
            productList = [SELECT Product__r.Name, Product__r.Brand_Name__c, Product__r.Item_Code__c , Product__r.Product_Code__c, Product__r.Description__c,
                           Sales_Org__c, Distribution_Channel__c, Product__r.UPIID__c
                           FROM Product_Sales_Area__c
                           WHERE Sales_Org__c = :salesOrg
                           AND 	Distribution_Channel__c includes (:distributionChannel)  ORDER BY Product__r.Name asc];
        }
        return productList;
    }
    
    @AuraEnabled
    public static Boolean checkServiceRep(){
         //PION-2488 changes start
        List<PermissionSetAssignment> permSetAssList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =: UserInfo.getUserId() AND
                                                        PermissionSetId IN (SELECT Id FROM PermissionSet WHERE (Name='PNR_CSE_User' or Name = 'PNR_IMC_User'))];
        //PION-2488 changes End
        Id repProfileId = [SELECT Id,Name FROM Profile WHERE Name = 'PNR_CustomerServiceRep'].Id;
        return (userinfo.getProfileId() == repProfileId || permSetAssList.size()>0 );
    }
    //PION-2202 Change Start
    @AuraEnabled
    public static List<PNR_CorrectionOfPricingCondition__mdt> fetchAllPricingCondition(){
        List<PNR_CorrectionOfPricingCondition__mdt> allPricingCondition = new List<PNR_CorrectionOfPricingCondition__mdt>();
        if(Schema.sObjectType.PNR_CorrectionOfPricingCondition__mdt.isAccessible()){
            allPricingCondition= [SELECT DeveloperName, MasterLabel, PNR_PricingCondition__c, PNR_SalesOrg__c,
                                  PNR_CorrectionOf__c
                                  FROM PNR_CorrectionOfPricingCondition__mdt
                                  ORDER BY PNR_CorrectionOf__c];
        }
        return allPricingCondition;
    }
    //PION-2202 Change End
    
    @AuraEnabled
    public static List<PNR_Recharge_Material__mdt> getRechargeMaterials(){
        List<PNR_Recharge_Material__mdt> rechargeMaterialList = new List<PNR_Recharge_Material__mdt>();
        if(Schema.sObjectType.PNR_Recharge_Material__mdt.isAccessible()){
            rechargeMaterialList= [SELECT Id, DeveloperName, MasterLabel, SKU__c
                                   FROM PNR_Recharge_Material__mdt
                                  ];
        }
        return rechargeMaterialList;
    }
    
    
    
  	/* PION-1818 : Created new method 'getDeletedLineItems' to create the correction document mapping records which
  	 * are deleted by the user.
  	 */ 
    @AuraEnabled
    public static void getDeletedLineItems(Id recId, Id invId){
        try{
            Correction_Document__c cd = [Select Correction_Of__c,Sales_Org__c  from Correction_Document__c where Id =: recId];
            List<Id> existingInvLIList = new List<Id>();
            String pricingCondition = '';
            if(Schema.sObjectType.PNR_CorrectionOfPricingCondition__mdt.isAccessible() && cd.Correction_Of__c != null && cd.Correction_Of__c != ''){
                pricingCondition = [SELECT PNR_PricingCondition__c
                                    FROM PNR_CorrectionOfPricingCondition__mdt
                                    WHERE PNR_CorrectionOf__c = :cd.Correction_Of__c].PNR_PricingCondition__c;
            }
            for(PNR_CorrectionDocumentMapping__c cdMapping : [Select Invoice_Line_Item__r.Id from PNR_CorrectionDocumentMapping__c
                                                              where Correction_Document__c = :recId]){
                                                                  if(cdMapping.Invoice_Line_Item__r.Id != NULL){
                                                                      existingInvLIList.add(cdMapping.Invoice_Line_Item__r.Id);
                                                                  }
                                                              }
            List<PNR_CorrectionDocumentMapping__c> cdMappingList = new List<PNR_CorrectionDocumentMapping__c>();
            if(existingInvLIList.size() > 0){
                for( Invoice_Line_Item__c invLineItem : [Select Product_Number__c,SAP_Line_Item_Number__c,Product_Description__c,
                                                         Pricing_Condition__c,Plant__c,Id,Invoice_Unit_of_Measure__c,Invoice_Quantity__c,
                                                         Invoice_Net_Price_Unit__c,Invoice_Net_Price_Item__c,Name,Invoice__c,Batch__c,
                                                         Claimed_Net_Amount__c,CurrencyIsoCode,Claimed_Volume__c,Unit_of_Measure_of_Claimed_QTY__c from Invoice_Line_Item__c 
                                                         Where Invoice__c = : invId and Id not in : existingInvLIList]){
                                                             cdMappingList.Add(new PNR_CorrectionDocumentMapping__c(
                                                                 Product_Number__c = invLineItem.Product_Number__c,
                                                                 SAP_Line_Item_Number__c  = invLineItem.SAP_Line_Item_Number__c,
                                                                 Product_Description__c  = invLineItem.Product_Description__c,
                                                                 Pricing_Condition__c  = invLineItem.Pricing_Condition__c,
                                                                 //PION-2599 : changes to display plant code and plant name for CE01
                                                                 Plant__c  = cd.Sales_Org__c == 'CE01' ? invLineItem.Plant__c.toUpperCase() + ' - '+ PNR_Primary_Market_Plant__mdt.getInstance(invLineItem.Plant__c.toUpperCase()).Plant_Name__c: invLineItem.Plant__c,
                                                                 Invoice_Unit_of_Measure__c  = invLineItem.Invoice_Unit_of_Measure__c,
                                                                 Invoice_Quantity__c  = invLineItem.Invoice_Quantity__c,
                                                                 Invoice_Net_Price_Unit__c  = invLineItem.Invoice_Net_Price_Unit__c,
                                                                 Invoice_Net_Price_Item__c  = invLineItem.Invoice_Net_Price_Item__c,
                                                                 Invoice__c  = invLineItem.Invoice__c,
                                                                 Batch__c  = invLineItem.Batch__c,
                                                                 Claimed_Net_Amount__c  = invLineItem.Claimed_Net_Amount__c,
                                                                 CurrencyIsoCode  = invLineItem.CurrencyIsoCode,
                                                                 Claimed_Volume__c  = invLineItem.Claimed_Volume__c,
                                                                 Unit_of_Measure_of_Claimed_QTY__c = invLineItem.Unit_of_Measure_of_Claimed_QTY__c,
                                                                 Invoice_Line_Item__c = invLineItem.id,
                                                                 Correction_Document__c = recId));
                                                         }
                if(cd.Correction_Of__c != Null && cd.Correction_Of__c != ''){
                    if(!cdMappingList.isEmpty()){
                        for(PNR_CorrectionDocumentMapping__c lineItemObj : cdMappingList){
                            lineItemObj.Pricing_Condition__c = cd.Correction_Of__c;  
                            lineItemObj.Pricing_Condition_Code__c = pricingCondition;    
                        }
                    }
                }
                else{
                    
                    if(!cdMappingList.isEmpty()){
                        for(PNR_CorrectionDocumentMapping__c lineItemObj : cdMappingList){
                            lineItemObj.Pricing_Condition__c = '';
                            lineItemObj.Pricing_Condition_Code__c = '';
                        }
                    }
                }
                
                if(!cdMappingList.isEmpty()){
                    List<Database.SaveResult> updateResults = database.insert(cdMappingList, false);
                }
            }
        }catch(Exception ex){
            System.debug('Exception::: '+ex.getStackTraceString());
        }
    }
    
    //PION-2599 : Method to fetch plants
    @AuraEnabled
    public static List<PNR_Primary_Market_Plant__mdt> getPlants(){
        List<PNR_Primary_Market_Plant__mdt> plantList = new List<PNR_Primary_Market_Plant__mdt>();
        if(Schema.sObjectType.PNR_Primary_Market_Plant__mdt.isAccessible()){
        	plantList = [SELECT Id, DeveloperName, MasterLabel, Plant_Name__c
                                  FROM PNR_Primary_Market_Plant__mdt ORDER BY DeveloperName ASC
                                  ];
        }
        return plantList;
    }
    //PION-2612 Change
    private static void byPassValidation(boolean byPass){
        PNR_Case_Claimed_Amount_Validation_Bypas__c validationByPass = [select id,By_Pass__c from PNR_Case_Claimed_Amount_Validation_Bypas__c limit 1];
        validationByPass.By_Pass__c = byPass;
        update validationByPass;
    }
}