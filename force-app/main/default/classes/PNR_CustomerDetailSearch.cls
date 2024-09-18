/**********************************************************************
Name: PNR_CustomerDetailSearch
=======================================================================
Req:  
User Story : PION-11-Search In SalesForce for Customer 360 Records - Detailed Search by Document / by Customer
User Story : PION-88-Search In SalesForce for Customer 360 Records - Detailed Search by Delivery Document Number
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Juned Khan       11/06/2019      Initial Development
1.1 Tanmoy Bardhan   13/06/2019      Modified 
1.2 Juned Khan       14/06/2019      Added PNR_SAP_Order_Number__c field to track order number 
2.0 Saurav Paul      25/07/2019      Invoice and Order Fetch Related code Added
3.0 Tanmoy Bardhan   30/08/2019      UAT bug(enhancement) PION-880 - search for only wave 1 sales orgs
3.1 Saurav Paul      16/12/2019      Invoice Line Item 'Real_Time_Fetch_from_SAP__c' value added
3.2 Anamika Shukla   29/02/2024      EDGE Global: Mulesoft OAuth2 migration-358242
***********************************************************************/
public without sharing class PNR_CustomerDetailSearch {
      public static final String PIONEER_MULESOFT_ORDFETCH = 'Pioneer_Mulesoft_Order_Fetch';//358242
      public static final String PIONEER_MULESOFT_INVFETCH = 'Poineer_Mulesoft_Invoice_Fetch';//358242
    
    @AuraEnabled
    public static List<PNR_Partner_Function__c> getPartnerFunctionList() {
        Set<Id> accountSet = new Set<Id>();
        List<PNR_Partner_Function__c> pfList = new List<PNR_Partner_Function__c>();
        List<PNR_Diageo_Contact__c> diageoContacts = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c FROM PNR_Diageo_Contact__c];
        system.debug('diageoContacts:' + diageoContacts);
        for(PNR_Diageo_Contact__c diageoContact : diageoContacts) {
            accountSet.add(diageoContact.PNR_Customer__c);    
        }
        system.debug('accountSet:' + accountSet);
        pfList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber,PNR_Sold_To__r.Name,PNR_Customer_No__r.Name
                  FROM PNR_Partner_Function__c where PNR_Sold_To__c IN : accountSet AND (PNR_Type__c = 'Sold-To' OR PNR_Type__c = 'Payer') AND PNR_Customer_No__r.Sort__c !='staff' AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE 
                  AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE ORDER BY PNR_Customer_No__c ASC NULLS LAST];
        system.debug('PFList:' + pfList);
        return pfList;
        
    }
    
    @AuraEnabled
    public static List<PNR_Partner_Function__c> filterPartnerFunctionList(String searchBy, String searchValue) {
        system.debug('searchBy-->'+searchBy);
        system.debug('searchValue-->'+searchValue);
        List<PNR_Partner_Function__c> finalPFList = new List <PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> sortedPFList = new List <PNR_Partner_Function__c>();
        List<PNR_Partner_Function__c> uniqueFinalPFList = new List <PNR_Partner_Function__c>();
        List<PNR_Diageo_Contact__c> diageoContacts = new List<PNR_Diageo_Contact__c>();
        PNR_MyCustomersController customerController = new PNR_MyCustomersController();
        Set<Id> accountSet = new Set<Id>();
        
        if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
            diageoContacts = [SELECT PNR_Contact_Type__c,PNR_Customer__c,PNR_Diageo_Rep__c FROM PNR_Diageo_Contact__c];  
        }
        system.debug('diageoContacts:' + diageoContacts);
        for(PNR_Diageo_Contact__c diageoContact : diageoContacts) {
            accountSet.add(diageoContact.PNR_Customer__c);    
        }
        system.debug('accountSet:' + accountSet);
        if(searchBy == 'Customer Number') {
            List<PNR_Partner_Function__c> accessiblePFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> soldToPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> unSoldToPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> payerPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> unPayerPFList = new List<PNR_Partner_Function__c>();
            List<PNR_Partner_Function__c> billShiptoPFList = new List<PNR_Partner_Function__c>();
            List<String> salesOrg = new List<String>();
            Set<String> uniqueSetOfSalesOrgCustomers = new Set<String>();
            
            if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
                
                /*List<PNR_Partner_Function__c> sOrg = [SELECT ID,PNR_Sales_Org__c FROM PNR_Partner_Function__c WHERE PNR_Customer_No__r.AccountNumber =: searchValue];
                for(PNR_Partner_Function__c pfSl : sOrg){
                    salesOrg.add(pfSl.PNR_Sales_Org__c);
                }
                */
                Set<String> soldToNumberSet = new Set<String>();
                 Set<String> soldToNumberSetToPass = new Set<String>();
                for(PNR_Partner_Function__c pfRec : [SELECT Id,PNR_Sold_To__r.AccountNumber,PNR_Type__c from PNR_Partner_Function__c WHERE PNR_Customer_No__r.AccountNumber=:searchValue]){
                    soldToNumberSet.add(pfRec.PNR_Sold_To__r.AccountNumber); 
                }
                for(PNR_Partner_Function__c pfRec : [SELECT Id,PNR_Sold_To__r.AccountNumber,PNR_Type__c from PNR_Partner_Function__c WHERE PNR_Customer_No__r.AccountNumber IN : soldToNumberSet]){
                    soldToNumberSetToPass.add(pfRec.PNR_Sold_To__r.AccountNumber); 
                }
                
                
                accessiblePFList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber,PNR_Customer_No__r.Name,
                                    PNR_Sold_To__r.AccountNumber
                                    //FROM PNR_Partner_Function__c where PNR_Sold_To__c IN : accountSet AND PNR_Customer_No__r.Sort__c !='staff' AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c =FALSE];
                                    FROM PNR_Partner_Function__c where PNR_Customer_No__r.Sort__c !='staff' AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c =FALSE
                                    AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE AND /* PNR_Sales_Org__c IN: salesOrg*/ (PNR_Customer_No__r.AccountNumber IN : soldToNumberSetToPass OR PNR_Customer_No__r.AccountNumber=:searchValue
                                                                                                                             OR PNR_Sold_To__r.AccountNumber =:searchValue OR PNR_Sold_To__r.AccountNumber =:soldToNumberSetToPass) ];
            }
            
            system.debug('accessiblePFList:' + accessiblePFList.size());
            for(PNR_Partner_Function__c pfRecord : accessiblePFList) {
                System.debug('AccountNumber:'+ pfRecord.PNR_Customer_No__r.AccountNumber + ':' + 'Type:' + pfRecord.PNR_Type__c +':');
                if(pfRecord.PNR_Type__c == 'Sold-To' && pfRecord.PNR_Customer_No__r.AccountNumber == searchValue) {//changed here
                    soldToPFList.add(pfRecord);    
                }
                else {
                    unSoldToPFList.add(pfRecord);
                }
                
            }
            system.debug('soldToPFList:' + soldToPFList);
            system.debug('unSoldToPFList:' + unSoldToPFList);
            for(PNR_Partner_Function__c pfRecord : unSoldToPFList) {
                if(pfRecord.PNR_Type__c == 'Payer' && pfRecord.PNR_Customer_No__r.AccountNumber == searchValue) { //changed here
                    payerPFList.add(pfRecord);    
                }
                else {
                    unPayerPFList.add(pfRecord);
                    system.debug('unPayerPFList***:' + pfRecord);
                }
                
            }
            system.debug('payerPFList:' + payerPFList);
            system.debug('unPayerPFList:' + unPayerPFList);
            for(PNR_Partner_Function__c pfRecord : unPayerPFList) {
                if((pfRecord.PNR_Type__c == 'Bill-To' || pfRecord.PNR_Type__c == 'Ship-To') && pfRecord.PNR_Customer_No__r.AccountNumber == searchValue)  {
                    uniqueSetOfSalesOrgCustomers.add(pfRecord.PNR_Sold_To__r.AccountNumber + '_' + pfRecord.PNR_Sales_Org__c);
                }
            }
            system.debug('uniqueSetOfSalesOrgCustomers:' + uniqueSetOfSalesOrgCustomers);
            for(PNR_Partner_Function__c pfRecord : unPayerPFList) {
                for(String uniquestring : uniqueSetOfSalesOrgCustomers) {
                    if(uniquestring.substringBefore('_') == pfRecord.PNR_Sold_To__r.AccountNumber && uniquestring.substringAfter('_') == pfRecord.PNR_Sales_Org__c) {
                        if(pfRecord.PNR_Type__c == 'Sold-To' || pfRecord.PNR_Type__c == 'Payer') {
                            billShiptoPFList.add(pfRecord);  
                        }
                    }
                    
                }
            } 
            system.debug('billShiptoPFList:' + billShiptoPFList);
            finalPFList.addAll(soldToPFList);
            finalPFList.addAll(payerPFList);
            finalPFList.addAll(billShiptoPFList);
            system.debug('finalPFList:' + finalPFList);
            uniqueFinalPFList = customerController.uniqueRecords(finalPFList);
            sortedPFList = customerController.sortRecords(uniqueFinalPFList);
            return sortedPFList;
        }
        else if(searchBy == 'Customer Name') {
            String searchText = '%' + searchValue + '%';
            if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
                finalPFList = [SELECT Id, PNR_Customer_No__c, PNR_Sales_Org__c, PNR_Sold_To__c, PNR_Type__c, PNR_Customer_No__r.AccountNumber,
                               PNR_Customer_No__r.Name  
                               FROM PNR_Partner_Function__c
                               //WHERE PNR_Sold_To__c IN : accountSet AND
                               WHERE (PNR_Customer_No__r.Name LIKE :searchText)
                               AND (PNR_Type__c = 'Sold-To' OR PNR_Type__c = 'Payer')
                               AND PNR_Customer_No__r.Sort__c !='staff'
                               AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c != TRUE
                               AND PNR_Deletion_Flag_for_Sales_Level__c != TRUE     
                               ORDER BY PNR_Customer_No__c ASC NULLS LAST];
            }
            system.debug('finalPFList:' + finalPFList);
            uniqueFinalPFList = customerController.uniqueRecords(finalPFList);
            sortedPFList = customerController.sortRecords(uniqueFinalPFList);
            return sortedPFList;
        }
        return sortedPFList;    
    }
    @AuraEnabled
    public static String getCustomerId(String customerName) {
        Account customer = new Account();
        if(Schema.sObjectType.Account.isAccessible()){
            customer = [Select Id, AccountNumber FROM Account WHERE AccountNumber = :customerName];
        }
        
        if(customer != null) {
            return customer.Id;
        }
        return null;
    }
    /*******************************************************************
    Method  : getOrderList
    Purpose : This method is used to get the sales and purchase order list.
    ***********************************************************************/
    @AuraEnabled
    public static List<Order__c> getOrderList(String orgName,String salesOrderNumber,String purchaseOrderNumber,String deliveryNumber) {
        String queryToQuery = '';
        String conditionQuery = '';
        List<Order__c> orderlist= new List<Order__c>();
        
        queryToQuery = 'SELECT Id,Name,SAP_Order_Number__c,SAP_Order_Type__c,Sales_Org__c,PO_Number__c,Account__r.AccountNumber, '+
            'Account__r.Name,Payer_Number__r.AccountNumber,Payer_Number__r.Name,Requested_Delivery_Date__c, '+
            'Net_Value__c,CurrencyIsoCode,Credit_Held__c,Delivery_Document__c '+
            'FROM Order__c '+
            'WHERE Account__r.Sort__c !=\'staff\' AND Payer_Number__r.Sort__c != \'staff\' '+
            'AND Payer_Number__r.Deletion_Flag_from_SAP__c = False '+
            'AND Account__r.Deletion_Flag_from_SAP__c =FALSE '+
            'AND Sales_Org__c = \'' + orgName +  '\' ';
        
        if(salesOrderNumber != null && !(String.isBlank(salesOrderNumber))){
            conditionQuery+= ' AND SAP_Order_Number__c = \'' + salesOrderNumber +  '\'  ';
        }else if(purchaseOrderNumber != null && !(String.isBlank(purchaseOrderNumber))){
            conditionQuery+= ' AND PO_Number__c = \'' + purchaseOrderNumber +  '\'  ';
        }else if(deliveryNumber != Null && !(String.isBlank(deliveryNumber))){
            conditionQuery+= ' AND Delivery_Document__c = \'' + deliveryNumber +  '\'  ';
        }
        
        queryToQuery += conditionQuery;
        system.debug('@@ Dynamic Query @@'+queryToQuery);
        orderlist = Database.query(queryToQuery);
        system.debug('orderlist-->'+orderlist);
        
        return orderlist;
        
    }
    
    /*******************************************************************
    Method  : getInvoiceList
    Purpose : This method is used to get the Invoice list.
    ***********************************************************************/
    @AuraEnabled
    public static List<Invoice__c> getInvoiceList(String Invoice,String orgName) {
        List<Invoice__c> invoicelist= new List<Invoice__c>();
        List<Invoice__c> invoicesearchlist = new List<Invoice__c>();
        
        if(Invoice != null && !(String.isBlank(Invoice)) && Schema.SObjectType.Invoice__c.isAccessible() 
           && Schema.SObjectType.Account.isAccessible() && Schema.SObjectType.Order__c.isAccessible()) {
               invoicelist =[SELECT Id,Name,Sales_Org__c, CurrencyIsoCode, Document_Type__c,
                             Due_Date__c, Order__c, Due_Type__c, Payer_Number__c, SAP_Invoice_Number__c,
                             Payment_Term__c, Account__c,Account__r.AccountNumber,
                             Net_Value__c,Payer_Number__r.AccountNumber,
                             Order__r.SAP_Order_Number__c,Payer_Number__r.Name,Account__r.Name,Payment_Status__c
                             FROM Invoice__c
                             WHERE SAP_Invoice_Number__c = :Invoice
                             AND Sales_Org__c = :orgName
                             AND Payer_Number__r.Sort__c !='staff'
                             AND Account__r.Sort__c !='staff'
                             AND Account__r.Deletion_Flag_from_SAP__c =FALSE
                             AND Payer_Number__r.Deletion_Flag_from_SAP__c =FALSE];
           } 
        return invoicelist;
    }
    
    /*******************************************************************
    Method  : validateWave1SalesOrg
    Purpose : This method is used to validate the sales orgs entered by user
    ***********************************************************************/
    @AuraEnabled
    public static Boolean validateWave1SalesOrg(String salesOrg){
        List<String> salesOrgList = new List<String>();
        String salesOrgMdt = [SELECT Sales_Org_Name__c FROM PNR_SalesOrg_Mapping__mdt WHERE DeveloperName = 'Wave1'].Sales_Org_Name__c;
        salesOrgList.addAll(salesOrgMdt.split(','));
        Boolean isValidSalesOrg = salesOrgList.contains(salesOrg);
        return isValidSalesOrg;
    }
    
    /*******************************************************************
    Class : OrderWrapper
    Purpose : This is a wrapper class used to create JSON body
    ***********************************************************************/
    public class OrderWrapper{
        String salesOrganization,salesOrderNumber,purchaseOrderNumber,deliveryNumber;
        public OrderWrapper(String salesOrganization, String salesOrderNumber,
                            String purchaseOrderNumber, String deliveryNumber){
            this.salesOrganization = salesOrganization;
            this.salesOrderNumber = salesOrderNumber;
            this.purchaseOrderNumber = purchaseOrderNumber;
            this.deliveryNumber = deliveryNumber;                    
        }
    }
    /*******************************************************************
    Method  : sendReq
    Purpose : This method is used to Create Order record
    ***********************************************************************/
    @AuraEnabled
    public static String sendReq(String salesOrg, String salesOrder,
                                 String purOrderNum, String deliveryNum, String invoiceNum){
        String msgString = '';                            
        
        if(String.isNotEmpty(invoiceNum)){
            msgString = PNR_CustomerDetailSearch.getInvoiceData(salesOrg,invoiceNum);
        }else{
            msgString =  PNR_CustomerDetailSearch.getOrderData(salesOrg,salesOrder,purOrderNum,deliveryNum);   
        } 
        return msgString;
    }
    /*******************************************************************
    Method  : getOrderData
    Purpose : This method is used to get order data 
    ***********************************************************************/
    public static String getOrderData(String salesOrg, String salesOrder,String purOrderNum, String deliveryNum){
        String msgString = '';                            
        OrderWrapper wrapData = new OrderWrapper(salesOrg,salesOrder,purOrderNum,deliveryNum);
        String jsonPayload = JSON.serialize(wrapData);
        String endPoint = PIONEER_MULESOFT_ORDFETCH;
        String jsonBody = PNR_CustomerDetailSearch.getResponse(jsonPayload,endPoint,'Order Fetch');
        if(jsonBody!= null && jsonBody != ''){
            try{
                PNR_OrderWrapper wrapObj = PNR_OrderWrapper.parse(jsonBody);
                if(wrapObj.status.equalsIgnoreCase('s') && Integer.valueOf(wrapObj.recordCount) >0){
                    Order__c orderRec = PNR_CustomerDetailSearch.createOrder(wrapObj.Orders.order);
                    if(orderRec!= null){
                        if(Schema.SObjectType.Order__c.isUpdateable() && Schema.SObjectType.Order__c.isCreateable()){
                            Schema.SObjectField extFld = Order__c.Fields.SAP_Order_Number__c;
                            Database.UpsertResult upsrtRes = Database.upsert(orderRec, extFld, false);
                            if(upsrtRes.isSuccess()){
                                msgString = Label.Data_Import_Success;
                                msgString = msgString.replace('&&&&', 'Order');
                            }else{
                                msgString = Label.Data_Import_Error + ' '+upsrtRes.getErrors();
                                PNR_CustomerDetailSearch.createLog(String.valueOf(upsrtRes.getErrors()), 'Order Fetch', null, 'Failure', 'Order');
                            }
                        }
                    } 
                }else if (wrapObj.status.equalsIgnoreCase('e')){
                    msgString = wrapObj.statusDescription;
                }else{
                    msgString = Label.Data_Import_Warning;
                }
            }catch(Exception ex){
                msgString = Label.Data_Import_Warning;
            }
        }else{
            msgString = Label.No_Connection;
        }
        return msgString;
    }
    /*******************************************************************
    Method  : getResponse
    Purpose : This method is used to Call-Out
    ***********************************************************************/
    public static String getResponse(String jsonPayload,String endPoint, String reqstType){
        String jsonBody = '';
        //String clientId = Label.X_IBM_Client_Id;
        //String clientSecret = Label.X_IBM_Client_Secret;
        HttpRequest request = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        request.setEndpoint('callout:' +endPoint);
        request.setMethod('POST');
        //request.setHeader('client_id',clientId);
        //request.setHeader('client_secret',clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setBody(jsonPayload);
        request.setTimeout(120000);
        try {
            res = http.send(request);
            if(res.getStatusCode() == 200){
                jsonBody = res.getBody();
                System.debug('&&&&&jsonBody in customerdetailsearch '+ jsonBody);
            }else{
                PNR_CustomerDetailSearch.createLog('Response Status code is : '+String.valueOf(res.getStatusCode()),
                                                   reqstType, jsonPayload, 'Failure', reqstType.split(' ')[0]);
                jsonBody ='';
            }
        }catch(Exception ex){
            PNR_CustomerDetailSearch.createLog(ex.getMessage(), reqstType, jsonPayload, 'Failure', reqstType.split(' ')[0]);
        }
        return jsonBody;
    }
    /*******************************************************************
    Method  : createOrder
    Purpose : This method is used to populate fields values for Order
    ***********************************************************************/
    public static Order__c createOrder(PNR_OrderWrapper.Order orderWrapData){
        Order__c orderObj = new Order__c();
        try{
            Id ordrRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Direct Order').getRecordTypeId();
            
            orderObj.RecordTypeId = ordrRecTypeId;
            orderObj.SAP_Order_Number__c = orderWrapData.salesDocumentNumber;
            orderObj.SAP_Order_Type__c = orderWrapData.salesDocumentType;
            orderObj.Sales_Org__c = orderWrapData.salesOrganization;
            orderObj.Distribution_Channel__c = orderWrapData.distributionChannel;
            orderObj.Division__c = orderWrapData.division;
            orderObj.PO_Number__c = orderWrapData.purchaseOrderNumber;
            if(String.isNotBlank(orderWrapData.soldToParty)){
                Account soldToAccRef = new Account(KUNNR__c  = orderWrapData.soldToParty );
                orderObj.Account__r = soldToAccRef;
            }
            if(String.isNotBlank(orderWrapData.payer)){
                Account payerAccRef = new Account(KUNNR__c  = orderWrapData.payer );
                orderObj.Payer_Number__r = payerAccRef;
            }
            orderObj.Ship_To_Number__c = orderWrapData.shipToParty;
            orderObj.Requested_Delivery_Date__c = PNR_CustomerDetailSearch.conDate(orderWrapData.requestedDeliveryDate) ;
            orderObj.Net_Value__c = Decimal.valueOf(orderWrapData.netValueInDocumentCurrency);
            orderObj.CurrencyIsoCode = orderWrapData.sdDocumentCurrency;
            orderObj.Reason_Code__c = orderWrapData.orderReason;
            orderObj.Name_of_Person__c = orderWrapData.nameOfPersonCreatedObject;
            orderObj.Delivery_Block__c = orderWrapData.deliveryBlock;
            orderObj.Central_Billing_Block__c = orderWrapData.billingBlockInSDDocument;
            orderObj.Credit_Held__c = orderWrapData.overallStatusOfCreditChecks;
            orderObj.Blocked__c = String.isNotEmpty(orderWrapData.overallBlockedStatus) ? orderWrapData.overallBlockedStatus : 'Not blocked';
            orderObj.Plant__c = orderWrapData.plant;
            orderObj.Pricing_Date__c = PNR_CustomerDetailSearch.conDate(orderWrapData.dateForPricingAndExchangeRate);
            orderObj.Incoterms1__c = orderWrapData.incotermsPart1;
            orderObj.Incoterms2__c = orderWrapData.incotermsPart2;
            orderObj.Delivery_Document__c = orderWrapData.deliveryDocument;
            orderObj.Planned_Goods_Movement_Date__c =  PNR_CustomerDetailSearch.conDate(orderWrapData.plannedGoodsMovementDate);
            orderObj.Billing_Document__c = orderWrapData.billingDocument;
            orderObj.Is_Deletion_Indicator_Flag__c = orderWrapData.deletionIndicatorFlag;
            orderObj.Real_Time_Fetch_from_SAP__c = true;
        }catch(Exception ex){
            PNR_CustomerDetailSearch.createLog(ex.getMessage(), 'Order Realtime Fetch', null, 'Failure', 'Order');        
        }
        
        return orderObj;
    }
    /*******************************************************************
    Method  : createLog
    Purpose : This method is used to Create Integration log record
    ***********************************************************************/
    public static void createLog(String errMsg, String interfcName,
                                 String res, String status, String objType){
        Integration_Log__c logObj = new Integration_Log__c();
        logObj.Error_Message__c = errMsg;
        logObj.Interface_Name__c = interfcName;
        logObj.Response__c = res;
        logObj.Status__c = status;
        logObj.Type_of_Object__c = objType;
        if(Schema.SObjectType.Integration_Log__c.isCreateable()
           && Schema.SObjectType.Integration_Log__c.isAccessible()){
               insert logObj;                             
           }                             
    }
    /*******************************************************************
    Class : InvoiceWrapper
    Purpose : This is a wrapper class used to create JSON body
    ***********************************************************************/
    public class InvoiceWrapper{
        String salesOrg,invoice;
        public InvoiceWrapper(String salesOrg, String invoice){
            this.salesOrg = salesOrg;
            this.invoice = invoice;
        }
    }
    /*******************************************************************
    Class : getInvoiceData
    Purpose : This method is used to get Invoice Info
    ***********************************************************************/
    public static String getInvoiceData(String salesOrg,String invoiceNum){
        Boolean isInvoicePresent = false;
        Id existngInvId;
        String msgString = '';  
        String invoiceId = '';
        String billingDoc = '';
        String billingType = '';
        String dueType = '';//added for PION-1649 Change
        Invoice__c invoiceRec;
        List<Invoice_Line_Item__c> lineItemList = new List<Invoice_Line_Item__c> ();
        Set<String>accExtIdSet = new Set<String>();
        List<Account> accList = new List<Account>();
        Map<String,Id> accMap  = new Map<String,Id>();
        Map<String,Id> orderMap = new Map<String,Id> ();
        List<Invoice_Line_Item__c> invLneItmLst = new List<Invoice_Line_Item__c>();
        /*//invLneItmLst = PNR_fetchInvoiceFromSAP.getInvoiceList(invoiceNum,salesOrg);
        if(invLneItmLst!= null && !invLneItmLst.isEmpty()){
          msgString = Label.PNR_InvoicePresentInSF;
       }else{*/
            InvoiceWrapper invWrapData = new InvoiceWrapper(salesOrg,invoiceNum);
            String jsonPayload = JSON.serialize(invWrapData);
            String endPoint = PIONEER_MULESOFT_INVFETCH;
            System.debug('jsonPayLoad '+ jsonPayload);
            String jsonResponse = PNR_CustomerDetailSearch.getResponse(jsonPayload,endPoint,'Invoice Fetch');
            if(String.isNotBlank(jsonResponse)){
                try{
                    PNR_InvoiceWrapper wrapData = PNR_InvoiceWrapper.parse(jsonResponse);
                    //PION-1649 change; added String.isBlank(wrapData.status) && wrapData.invoices.invoice.billingType == 'YF2' )
                    if( ( wrapData.status.equalsIgnoreCase('s')) && Integer.valueOf(wrapData.recordCount)>0 ){
                            PNR_InvoiceWrapper.Invoice invoiceData = wrapData.invoices.invoice;
                            billingDoc = invoiceData.billingDocument;
                            billingType = invoiceData.billingType;//added for PION - 1649 change; used for validation check for displaying warning toast message
                        	dueType = invoiceData.dueType;//added for PION-1649 change; used for validation check for displaying warning toast message
                        	System.debug('dueType '+ dueType);
                        
                        
                        List<Invoice__c> invPresentList = [SELECT Id,SAP_Invoice_Number__c 
                                                           FROM Invoice__c 
                                                           WHERE SAP_Invoice_Number__c =: billingDoc];
                        if(!invPresentList.isEmpty()){
                            isInvoicePresent = true; 
                            existngInvId = invPresentList[0].Id;
                            
                        }//else{
                            accExtIdSet.add(invoiceData.soldToParty);
                            accExtIdSet.add(invoiceData.payer);
                            if(!accExtIdSet.isEmpty() && Schema.SObjectType.Account.isAccessible()){
                                accList = [SELECT Id,KUNNR__c 
                                           FROM Account 
                                           WHERE KUNNR__c IN : accExtIdSet];
                                if(!accList.isEmpty()){
                                    for(Account accObj : accList){
                                        accMap.put(accObj.KUNNR__c, accObj.Id);
                                    }
                                }
                            }
                            if(String.isNotBlank(invoiceData.salesOrderDocument) && Schema.SObjectType.Order__c.isAccessible() ){
                                List<Order__c> orderRecList = [SELECT Id,SAP_Order_Number__c 
                                                               FROM Order__c 
                                                               WHERE SAP_Order_Number__c =: invoiceData.salesOrderDocument];
                                if(orderRecList!= null && !orderRecList.isEmpty()){
                                    orderMap.put(orderRecList[0].SAP_Order_Number__c,orderRecList[0].Id);
                                }
                                
                            }  
                            System.debug('accMap&&&&&&&&&&& '+ accMap);
                            invoiceRec = PNR_CustomerDetailSearch.insertInvoice(invoiceData,orderMap,accMap);
                        //}
                        
                        if(isInvoicePresent || (invoiceRec != null && Schema.SObjectType.Invoice__c.isUpdateable() && Schema.SObjectType.Invoice__c.isCreateable())){
                            try{
                                Boolean createLineItems = false;
                               // if(isInvoicePresent){
                                 //   invoiceId = existngInvId;
                                //    createLineItems = true;
                               // }else{
                               		PNR_CustomerDetailSearch.byPassValidation(false);//PION-2188 change
                                    Schema.SObjectField extFld = Invoice__c.Fields.SAP_Invoice_Number__c;
                                    Database.UpsertResult upsrtRes = Database.upsert(invoiceRec, extFld, false);
                                    createLineItems = upsrtRes.isSuccess();
                                    if(upsrtRes.isSuccess()){
                                        invoiceId = upsrtRes.getId();
                                    }else{
                                        msgString = Label.Data_Import_Error + ' '+upsrtRes.getErrors();
                                        PNR_CustomerDetailSearch.createLog(String.valueOf(upsrtRes.getErrors()), 'Invoice Line Item Fetch', jsonPayload, 'Failure', 'Invoice');
                                    }
                               // }
                                if(createLineItems){
                                    PNR_CustomerDetailSearch.deleteInvoiceLineItem(invoiceId);//PION-2188 change
                                    if(!invoiceData.InvoiceLines.invoiceLine.isEmpty()){
                                        for(PNR_InvoiceWrapper.InvoiceLine lineObj : invoiceData.InvoiceLines.invoiceLine){
                                            Invoice_Line_Item__c itemObj = PNR_CustomerDetailSearch.createLineItem(invoiceId, lineObj, billingDoc);
                                            itemObj.CurrencyIsoCode = invoiceData.sdDocumentCurrency;
                                            lineItemList.add(itemObj);
                                        }
                                        if(!lineItemList.isEmpty() && Schema.SObjectType.Invoice_Line_Item__c.isUpdateable() && Schema.SObjectType.Invoice_Line_Item__c.isCreateable()){
                                            Schema.SObjectField extFldItem = Invoice_Line_Item__c.Fields.External_Id__c;
                                            Database.UpsertResult[] upsrtResItemList = Database.upsert(lineItemList, extFldItem, false);
                                            Boolean isSuccess = true;
                                            for(Database.UpsertResult upsrtObj :upsrtResItemList){
                                                if(!upsrtObj.isSuccess()){
                                                    isSuccess = false;
                                                    msgString = Label.Data_Import_Error + ' '+upsrtObj.getErrors();
                                                    PNR_CustomerDetailSearch.createLog(String.valueOf(upsrtObj.getErrors()), 'Invoice Line Item Fetch', jsonPayload, 'Failure', 'Invoice Line Item');
                                                    break;
                                                }
                                            }
                                            PNR_CustomerDetailSearch.byPassValidation(true);//PION-2188 Change
                                            //PION-1649 change; added if block from 539 to 541
                                            if(dueType.equalsIgnoreCase('cancelled') || !billingType.equalsIgnoreCase('YF2')){
                                                isSuccess = false;
                                                msgString = Label.Invalid_Invoice_Type;
                                            }
                                            if(isSuccess){
                                                msgString = Label.Data_Import_Success_Invoice;
                                                msgString = msgString.replace('&&&&', 'Invoice and Invoice Line Item');
                                            }
                                             
                                        }
                                    }
                                }
                            }catch(Exception ex){
                                system.debug('*********update'+ex.getMessage() );
                                PNR_CustomerDetailSearch.createLog(ex.getMessage(), 'Invoice Realtime Fetch', jsonPayload, 'Failure', 'Invoice');
                            }
                        }
                    }else if (wrapData.status.equalsIgnoreCase('e')){
                        msgString = wrapData.statusDescription;
                    }else{
                        msgString = Label.Data_Import_Warning;
                    }
                }catch(Exception ex){
                    msgString = Label.Data_Import_Warning;
                    PNR_CustomerDetailSearch.createLog(ex.getMessage(), 'Invoice Realtime Fetch', jsonPayload, 'Failure', 'Invoice');
                }
            }
        	else{
                msgString = Label.No_Connection;
            	}
      // }
        
        return msgString;
    }
    /*******************************************************************
    Class : insertInvoice
    Purpose : This method is used to create Invoice inst
    ***********************************************************************/
    public static Invoice__c insertInvoice(PNR_InvoiceWrapper.Invoice invoiceData, Map<String,Id> orderMap,Map<String,Id> accMap){
        Invoice__c invoiceObj = new Invoice__c();
      
        try{
            System.debug('invoiceData&&&&&&&& '+ invoiceData.soldToParty);
            Id invcRecTypId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('Direct Invoice').getRecordTypeId(); 
            
            invoiceObj.Name = invoiceData.billingDocument;
            invoiceObj.Sales_Org__c = invoiceData.salesOrganization;
            invoiceObj.recordtypeId  = invcRecTypId;
            invoiceObj.Distribution_Channel__c = invoiceData.distributionChannel;
            invoiceObj.Division__c = invoiceData.division;
            invoiceObj.Document_Type__c = invoiceData.billingType;
            invoiceObj.SAP_Invoice_Number__c = invoiceData.billingDocument;
            invoiceObj.Net_Value__c = Decimal.valueOf(invoiceData.grossValueInDocumentCurrency);
            invoiceObj.CurrencyIsoCode = invoiceData.sdDocumentCurrency;
            invoiceObj.Payment_Term__c = invoiceData.termsOfPaymentKey;
            invoiceObj.Due_Type__c = invoiceData.dueType;
            invoiceObj.Due_Date__c = PNR_CustomerDetailSearch.conDate(invoiceData.dueDate);
            invoiceObj.Bill_To_Number__c = invoiceData.billToParty;
            invoiceObj.Ship_To_Number__c = invoiceData.shipToParty;
            invoiceObj.Real_Time_Fetch_from_SAP__c = true;
            invoiceObj.PNR_PO_Number__c = invoiceData.poNumber;
            
            if((String.isNotBlank(invoiceData.salesOrganization)) && invoiceData.salesOrganization== label.PNR_SalesorgforIT01){                
            invoiceObj.Delivery_External_Number__c=invoiceData.ExternalIdentificationofDelivery;
            invoiceObj.SAP_Delivery_Number__c=Decimal.valueOf(invoiceData.Delivery);
            invoiceObj.Invoice_external_number__c=Decimal.valueOf(invoiceData.ReferenceDocumentNumber);
            invoiceObj.Invoice_Billing_Date__c=PNR_CustomerDetailSearch.conDate(invoiceData.BillingDate);
            
            }  
      
            
            if(String.isNotBlank(invoiceData.soldToParty)){
                if(!accMap.isEmpty() && accMap.containsKey(invoiceData.soldToParty)){
                    invoiceObj.Account__c = accMap.get(invoiceData.soldToParty);
                }
            }
            if(String.isNotBlank(invoiceData.payer)){
                if(!accMap.isEmpty() && accMap.containsKey(invoiceData.payer)){
                    invoiceObj.Payer_Number__c = accMap.get(invoiceData.payer);
                }
            }
            if(String.isNotBlank(invoiceData.salesOrderDocument)){
                if(!orderMap.isEmpty() && orderMap.containsKey(invoiceData.salesOrderDocument)){
                    invoiceObj.Order__c = orderMap.get(invoiceData.salesOrderDocument);
                }
            }
            
        }catch(Exception ex){
            PNR_CustomerDetailSearch.createLog(ex.getMessage(), 'Invoice Realtime Fetch', null, 'Failure', 'Invoice');
        }
        return invoiceObj;
    }
  
    /*******************************************************************
    Class : createLineItem
    Purpose : This method is used to create Line Item Inst
    ***********************************************************************/
    public static Invoice_Line_Item__c createLineItem(Id invoieId, PNR_InvoiceWrapper.InvoiceLine lineItemData, String invcBillingDoc){
        Invoice_Line_Item__c lineItemObj  = new Invoice_Line_Item__c();
        String extFieldVal = invcBillingDoc+lineItemData.materialNumber+lineItemData.lineItemNumber;
        Id itemRecTypId = Schema.SObjectType.Invoice_Line_Item__c.getRecordTypeInfosByName().get('Direct SAP Invoice Line Item').getRecordTypeId();
        lineItemObj.RecordTypeId = itemRecTypId;
        lineItemObj.SAP_Line_Item_Number__c = lineItemData.lineItemNumber;
        lineItemObj.Product_Number__c = lineItemData.materialNumber;
        lineItemObj.Product_Description__c = lineItemData.materialDescription;
        lineItemObj.Invoice_Quantity__c = Decimal.valueOf(lineItemData.actualInvoicedQuantity);
        lineItemObj.Invoice_Unit_of_Measure__c = lineItemData.salesUnit;
        lineItemObj.Invoice_Net_Price_Item__c = Decimal.valueOf(lineItemData.netPriceItem);
        lineItemObj.Invoice_Net_Price_Unit__c = Decimal.valueOf(lineItemData.netPriceUnit);
        lineItemObj.Plant__c = lineItemData.plant;
        lineItemObj.Batch__c = lineItemData.batchNumber;
        lineItemObj.Invoice__c = invoieId;
        lineItemObj.External_Id__c = extFieldVal;
        lineItemObj.Real_Time_Fetch_from_SAP__c = true;
        return lineItemObj;
    }
    //PION-2188 change start
    private static void deleteInvoiceLineItem(string InvId){
       list<Invoice_Line_Item__c> lineItemList = [select id from Invoice_Line_Item__c where Invoice__c =:InvId];      
        if(lineItemList.size()>0){
            delete lineItemList;
        }
    }
    //PION-2188 change end
    //PION-2188 change start
    private static void byPassValidation(boolean byPass){
        InvandInvLineItembyPassValidation__c validationByPass = [select id,By_Pass__c from InvandInvLineItembyPassValidation__c limit 1];
        validationByPass.By_Pass__c = byPass;
        update validationByPass;
    }//PION-2188 change end
    /*******************************************************************
    Method  : conDate
    Purpose : This method is converting a String 'yyyy-mm-dd' or 'yyyymmdd' into a Date
    ***********************************************************************/
    public static Date conDate(String dateString){
        if(dateString.contains('-')){
            Date myDate = Date.valueOf(dateString);
            return myDate;
        }else if(dateString.length()>=8){
            String yearVal = dateString.substring(0, 4);
            String monthVal = dateString.substring(4, 6);
            String dayVal = dateString.substring(6, 8);
            string stringDate = yearVal + '-' + monthVal+ '-' + dayVal;
            Date myDate = Date.valueOf(stringDate);
            return myDate;
        }else{
            return null;
        }
    }
     
    
}