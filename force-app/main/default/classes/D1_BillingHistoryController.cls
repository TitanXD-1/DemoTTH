/**
 * @name D1_BillingHistoryController
 * @description Request My Financial from SAP
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0         Ajay            08/02/21    Initial Development(NCP-1476)
 * 2.0         Gaurav          09/02/21    NCP-1477
 * 3.0         Gaurav          18/05/21    NCP-2541
 * 4.0         Rubeena         24/02/22    NCP-6197
 * 5.0         Prasanth T      20/06/24    152924
 **/
@SuppressWarnings('PMD.FieldNamingConventions,PMD.FormalParameterNamingConventions')
public without sharing class D1_BillingHistoryController {
    @TestVisible private static final String DOCUMENT_STATUS_CANCELLED = 'CANCELLED';
    @TestVisible private static Map<String, D1_Billing_Type_Mapping__mdt> mapOfBillingTypeMapping;
    @TestVisible private static Map<String, D1_Financial_Document_Type__mdt> mapOfDocTypeMapping;
    public static string SALES_ORG;

    @TestVisible class BillingDetail{
        @AuraEnabled public String documentNumber{get;set;}
        @AuraEnabled public String type{get;set;}
        @AuraEnabled public String docType{get;set;}
        @AuraEnabled public String description{get;set;}
        @AuraEnabled public Date documentDate{get;set;}
        @AuraEnabled public String value{get;set;}
        @AuraEnabled public String currencyType{get;set;}
        @AuraEnabled public String dueDate{get;set;}

        @AuraEnabled public Integer slNo{get;set;}
        @AuraEnabled public List<String> documentTypes{get;set;}

    }

    @TestVisible class BillingRequest{
        public String customer;
        public String salesOrg;
        public String distributionChannel;
        public String division;
        public String partnerFunction;
        public Date startDate;
        public Date endDate; 
    }

    

    /**
     * @description Get Billing History
     * @param {String} jsonBillingRequest JSON format of BillingRequest
     * NCP-6197: Included language parameter for fetching language specific records
     */
    @AuraEnabled
    public static Object getBillingHistory(String jsonBillingRequest, String language){ 
        BillingRequest request;
        List<D1_BillingHistoryWSDL.DT_BillingHistory_Docs_D1> response;

        try {
            request = (BillingRequest) JSON.deserialize(jsonBillingRequest, BillingRequest.class);

            //Step 1: Do Callout
			response = doCallout(request);
            
            //Step 2: Parse Response
            List< BillingDetail > billingHistory = parseResponse(response,language);
            return billingHistory;
        } catch (Exception ex) {
           
            //NCP-3577
            D1_CustomLoggingUtility.logMessage('D1_BillingHistoryController', 'getBillingHistory', ex, (request != NULL? JSON.serialize(request):''), (response != NULL? JSON.serialize(response):''));
            
            List< BillingDetail > billingHistory = parseResponse(null,'');
            return billingHistory;
            
        }
    }

    /**
     * SAP Call out
     * @param {BillingRequest} request 
     */
    public static List<D1_BillingHistoryWSDL.DT_BillingHistory_Docs_D1> doCallout( BillingRequest request ){
        request = request == null ? new BillingRequest() : request;

        request.customer = request.customer == null ? '' :  String.escapeSingleQuotes(request.customer);
        request.salesOrg = request.salesOrg == null ? '' : String.escapeSingleQuotes(request.salesOrg);
        request.distributionChannel = request.distributionChannel == null ? '' :  String.escapeSingleQuotes(request.distributionChannel);
        request.division = request.division == null ? '' : String.escapeSingleQuotes(request.division);
        request.partnerFunction = request.partnerFunction == null ? '' :  String.escapeSingleQuotes(request.partnerFunction);

        SALES_ORG = request.salesOrg == null ? '' : String.escapeSingleQuotes(request.salesOrg);
        D1_BillingHistoryWSDL.HTTPS_Port billingController = new D1_BillingHistoryWSDL.HTTPS_Port();
        billingController.timeout_x = 120000;
        return billingController.SI_BillingHistory_Sync_Out_D1(
            request.customer,
            request.salesOrg,
            request.distributionChannel,
            request.division,
            request.partnerFunction,
            request.startDate,
            request.endDate
        );
    }

    /**
     * Parse SAP Response
     * @param {Array} billingHistoryResponce SAP response
     */

    
     @TestVisible private static List<BillingDetail> parseResponse(List<D1_BillingHistoryWSDL.DT_BillingHistory_Docs_D1> billingHistoryResponce, String language){
        if(billingHistoryResponce == null){
            return new List<BillingDetail>();
        }

        
        Map<String,String> documentTypeByCode = setupDocumentTypeMapping(SALES_ORG,language);
        Map<String, String> documentLabelByCode = new Map<String, String>();
        if(!documentTypeByCode.isEmpty()){
            for(String str : documentTypeByCode.keyset()){
                List<String> strs = str.split('_');
                String documentLabel = documentTypeByCode.get(str);
                documentLabelByCode.put(strs[1],documentLabel);
                
            }
        }
        
        setupBillingTypeMapping();
        Boolean displayCancelledInv = displayCancelledInvoices();

        Integer counter = 1;
        List<BillingDetail> billingHistory = new List<BillingDetail>();
        for(D1_BillingHistoryWSDL.DT_BillingHistory_Docs_D1 billingResponce : billingHistoryResponce ){
            String docLabel = documentLabelByCode.get(billingResponce.DOCTY);
            if( displayCancelledInv || billingResponce.STATUS == NULL || !billingResponce.STATUS.equalsIgnoreCase(DOCUMENT_STATUS_CANCELLED) ){
                billingHistory.add(setupBillingDetail(billingResponce, counter++, docLabel));
            }
        }
        
        
        return billingHistory;
    }
	
    /**
     * @description NCP-6197: Fetch financial document type as per market and language
     * @param salesOrg 
     * @param lang 
     * @return  `Map<String,String>`
     */
    @AuraEnabled
    public static Map<String,String> setupDocumentTypeMapping(String salesOrg, String lang){
        Map<String,String> mapOfDocTypeMapping = new Map<String,String>();
        
        for (D1_Financial_Document_Type__mdt billingDocTypeConfig : [SELECT MasterLabel,Document_Type__c,Sales_Org__c, Document_Label__c,D1_User_Locale_Setting__r.LanguageLocaleKey__c 
                                                                    FROM D1_Financial_Document_Type__mdt
                                                                    WHERE Sales_Org__c =: salesOrg 
                                                                    AND D1_User_Locale_Setting__r.LanguageLocaleKey__c=:lang]) {
            mapOfDocTypeMapping.put(billingDocTypeConfig.MasterLabel, billingDocTypeConfig.Document_Label__c); 
        }
        return mapOfDocTypeMapping;
    }

    @AuraEnabled
    public static Map<String,D1_Financial_Document_Type__mdt> getDocumentTypeMapping(String salesOrg, String lang){
        Map<String,D1_Financial_Document_Type__mdt> mapOfDocTypeMapping = new Map<String,D1_Financial_Document_Type__mdt>();
        
        for (D1_Financial_Document_Type__mdt billingDocTypeConfig : [SELECT MasterLabel,Document_Type__c,Sales_Org__c, Document_Label__c,D1_User_Locale_Setting__r.LanguageLocaleKey__c,Is_Default__c
                                                                    FROM D1_Financial_Document_Type__mdt
                                                                    WHERE Sales_Org__c =: salesOrg 
                                                                    AND D1_User_Locale_Setting__r.LanguageLocaleKey__c=:lang ORDER BY Document_Label__c]) {
            mapOfDocTypeMapping.put(billingDocTypeConfig.MasterLabel, billingDocTypeConfig); 
        }
        return mapOfDocTypeMapping;
    }


    /**
     * @description NCP-6197: Return financial document type value as per market and language
     * @param salesOrg 
     * @param language 
     * @return  `List<String>`
     */
    @AuraEnabled
    public static Map<String,D1_Financial_Document_Type__mdt> getDocumentTypes(String salesOrg, String language){

        
        Map<String,D1_Financial_Document_Type__mdt> documentTypeByCode = getDocumentTypeMapping(salesOrg,language);
       
        
        return documentTypeByCode;
    }
       

    /**
     * Setup Billing History Detail
     * @param {D1_BillingHistoryWSDL.DT_BillingHistory_Docs_D1} billingResponce SAP response each
     * @param {Integer} slNo
     * @return {BillingDetail}
     */
    	@TestVisible private static BillingDetail setupBillingDetail(D1_BillingHistoryWSDL.DT_BillingHistory_Docs_D1 billingResponce, Integer slNo, String docLabel){
        BillingDetail billing = new BillingDetail();

        D1_Billing_Type_Mapping__mdt typeConfig = mapOfBillingTypeMapping.get(billingResponce.DOCTY);

        billing.documentNumber = billingResponce.DOCID;
        billing.docType = billingResponce.DOCTY;
        billing.type = docLabel;
        billing.description = billingResponce.DESCR;
        billing.documentDate = billingResponce.DDATE;
        billing.value = getDisplayAmount(billingResponce.VALUE, typeConfig);
        billing.currencyType = billingResponce.DOCCUR;
        billing.dueDate = billingResponce.DOCDUEDATE;

        billing.slNo = slNo;

        return billing;
    }

    /**
     * Display Cancelled Invoices
     * @return {D1_Setting.Display_cancelled_invoices}
     */
    @TestVisible private static Boolean displayCancelledInvoices(){
        User loggedInUser = [SELECT Available_Countries__c,LanguageLocaleKey FROM User WHERE ID =: UserInfo.getUserId()];
        
        List<String> availableCountry= loggedInUser.Available_Countries__c!=Null?loggedInUser.Available_Countries__c.split(','):new List<String>();
        
        List<D1_Setting__c> d1Settings = [SELECT Id,Display_cancelled_invoices__c
                                          FROM D1_Setting__c 
                                          WHERE Market__r.Code__c IN: availableCountry 
                                          AND Language__c =: loggedInUser.LanguageLocaleKey];
        Boolean displayCancelledInv = true;
        if(!d1Settings.isEmpty()){
            displayCancelledInv = d1Settings[0].Display_cancelled_invoices__c;
        }
        return displayCancelledInv;  
    }

    /**
     * Calculate Amount sign
     * @param {String} amount
     * @param {D1_Billing_Type_Mapping__mdt} typeConfig
     * @return {String} amount
     */
    @TestVisible private static String getDisplayAmount(String amount, D1_Billing_Type_Mapping__mdt typeConfig){
        if(String.isEmpty(amount)){
            return '';
        }

        if(typeConfig?.is_Negative_Amount__c == true){
            return '-' + amount;
        }

        return amount;
    }

    /**
     * Setup Billing Type Configuration
     */
    @TestVisible private static void setupBillingTypeMapping(){
        mapOfBillingTypeMapping = new Map<String,D1_Billing_Type_Mapping__mdt>();
        
        for (D1_Billing_Type_Mapping__mdt billingTypeConfig : [SELECT MasterLabel,Value__c,is_Negative_Amount__c FROM D1_Billing_Type_Mapping__mdt ]) {
            mapOfBillingTypeMapping.put(billingTypeConfig.MasterLabel, billingTypeConfig);
           // System.debug('mapOfBillingTypeMapping'+mapOfBillingTypeMapping);
        }
    }
    /**
     * @description Download Finacial document pdf base64 encoded data. 
     * @param CUSTOMER 
     * @param DOCTY 
     * @param DOCID 
     * @param DOCDATE 
     * @param SALES_ORG //152924
     * @return  `String`
     */    
    @AuraEnabled 
    public static String downloadFinancialDoc(String CUSTOMER, String DOCTY, String DOCID, String DOCDATE, String SALES_ORG){
        D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Request request;
        D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Response_D1 response;

        try{
            request = new D1_FinancialDocumentRetrievalWSDL.DT_FinancialDocumentRetrieval_Request();
            request.CUSTOMER = CUSTOMER;
            request.DOCTY = DOCTY;
            request.DOCID = DOCID;
            request.DOCDATE = DOCDATE;
            request.SALES_ORG = SALES_ORG;

            D1_FinancialDocumentRetrievalWSDL.HTTPS_Port financialDocController = new D1_FinancialDocumentRetrievalWSDL.HTTPS_Port();
            response = financialDocController.SI_FinancialDocumentRetrieval_Sync_Out_D1(CUSTOMER,DOCTY,DOCID,DOCDATE,SALES_ORG);            
            return response.PDF_DATA;
            //return 'JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YWxvZw0KL091dGxpbmVzIDIgMCBSDQovUGFnZXMgMyAwIFINCj4+DQplbmRvYmoNCg0KMiAwIG9iag0KPDwNCi9UeXBlIC9PdXRsaW5lcw0KL0NvdW50IDANCj4+DQplbmRvYmoNCg0KMyAwIG9iag0KPDwNCi9UeXBlIC9QYWdlcw0KL0NvdW50IDINCi9LaWRzIFsgNCAwIFIgNiAwIFIgXSANCj4+DQplbmRvYmoNCg0KNCAwIG9iag0KPDwNCi9UeXBlIC9QYWdlDQovUGFyZW50IDMgMCBSDQovUmVzb3VyY2VzIDw8DQovRm9udCA8PA0KL0YxIDkgMCBSIA0KPj4NCi9Qcm9jU2V0IDggMCBSDQo+Pg0KL01lZGlhQm94IFswIDAgNjEyLjAwMDAgNzkyLjAwMDBdDQovQ29udGVudHMgNSAwIFINCj4+DQplbmRvYmoNCg0KNSAwIG9iag0KPDwgL0xlbmd0aCAxMDc0ID4+DQpzdHJlYW0NCjIgSg0KQlQNCjAgMCAwIHJnDQovRjEgMDAyNyBUZg0KNTcuMzc1MCA3MjIuMjgwMCBUZA0KKCBBIFNpbXBsZSBQREYgRmlsZSApIFRqDQpFVA0KQlQNCi9GMSAwMDEwIFRmDQo2OS4yNTAwIDY4OC42MDgwIFRkDQooIFRoaXMgaXMgYSBzbWFsbCBkZW1vbnN0cmF0aW9uIC5wZGYgZmlsZSAtICkgVGoNCkVUDQpCVA0KL0YxIDAwMTAgVGYNCjY5LjI1MDAgNjY0LjcwNDAgVGQNCigganVzdCBmb3IgdXNlIGluIHRoZSBWaXJ0dWFsIE1lY2hhbmljcyB0dXRvcmlhbHMuIE1vcmUgdGV4dC4gQW5kIG1vcmUgKSBUag0KRVQNCkJUDQovRjEgMDAxMCBUZg0KNjkuMjUwMCA2NTIuNzUyMCBUZA0KKCB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiApIFRqDQpFVA0KQlQNCi9GMSAwMDEwIFRmDQo2OS4yNTAwIDYyOC44NDgwIFRkDQooIEFuZCBtb3JlIHRleHQuIEFuZCBtb3JlIHRleHQuIEFuZCBtb3JlIHRleHQuIEFuZCBtb3JlIHRleHQuIEFuZCBtb3JlICkgVGoNCkVUDQpCVA0KL0YxIDAwMTAgVGYNCjY5LjI1MDAgNjE2Ljg5NjAgVGQNCiggdGV4dC4gQW5kIG1vcmUgdGV4dC4gQm9yaW5nLCB6enp6ei4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kICkgVGoNCkVUDQpCVA0KL0YxIDAwMTAgVGYNCjY5LjI1MDAgNjA0Ljk0NDAgVGQNCiggbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiApIFRqDQpFVA0KQlQNCi9GMSAwMDEwIFRmDQo2OS4yNTAwIDU5Mi45OTIwIFRkDQooIEFuZCBtb3JlIHRleHQuIEFuZCBtb3JlIHRleHQuICkgVGoNCkVUDQpCVA0KL0YxIDAwMTAgVGYNCjY5LjI1MDAgNTY5LjA4ODAgVGQNCiggQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgKSBUag0KRVQNCkJUDQovRjEgMDAxMCBUZg0KNjkuMjUwMCA1NTcuMTM2MCBUZA0KKCB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBFdmVuIG1vcmUuIENvbnRpbnVlZCBvbiBwYWdlIDIgLi4uKSBUag0KRVQNCmVuZHN0cmVhbQ0KZW5kb2JqDQoNCjYgMCBvYmoNCjw8DQovVHlwZSAvUGFnZQ0KL1BhcmVudCAzIDAgUg0KL1Jlc291cmNlcyA8PA0KL0ZvbnQgPDwNCi9GMSA5IDAgUiANCj4+DQovUHJvY1NldCA4IDAgUg0KPj4NCi9NZWRpYUJveCBbMCAwIDYxMi4wMDAwIDc5Mi4wMDAwXQ0KL0NvbnRlbnRzIDcgMCBSDQo+Pg0KZW5kb2JqDQoNCjcgMCBvYmoNCjw8IC9MZW5ndGggNjc2ID4+DQpzdHJlYW0NCjIgSg0KQlQNCjAgMCAwIHJnDQovRjEgMDAyNyBUZg0KNTcuMzc1MCA3MjIuMjgwMCBUZA0KKCBTaW1wbGUgUERGIEZpbGUgMiApIFRqDQpFVA0KQlQNCi9GMSAwMDEwIFRmDQo2OS4yNTAwIDY4OC42MDgwIFRkDQooIC4uLmNvbnRpbnVlZCBmcm9tIHBhZ2UgMS4gWWV0IG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gKSBUag0KRVQNCkJUDQovRjEgMDAxMCBUZg0KNjkuMjUwMCA2NzYuNjU2MCBUZA0KKCBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSB0ZXh0LiBBbmQgbW9yZSApIFRqDQpFVA0KQlQNCi9GMSAwMDEwIFRmDQo2OS4yNTAwIDY2NC43MDQwIFRkDQooIHRleHQuIE9oLCBob3cgYm9yaW5nIHR5cGluZyB0aGlzIHN0dWZmLiBCdXQgbm90IGFzIGJvcmluZyBhcyB3YXRjaGluZyApIFRqDQpFVA0KQlQNCi9GMSAwMDEwIFRmDQo2OS4yNTAwIDY1Mi43NTIwIFRkDQooIHBhaW50IGRyeS4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gQW5kIG1vcmUgdGV4dC4gKSBUag0KRVQNCkJUDQovRjEgMDAxMCBUZg0KNjkuMjUwMCA2NDAuODAwMCBUZA0KKCBCb3JpbmcuICBNb3JlLCBhIGxpdHRsZSBtb3JlIHRleHQuIFRoZSBlbmQsIGFuZCBqdXN0IGFzIHdlbGwuICkgVGoNCkVUDQplbmRzdHJlYW0NCmVuZG9iag0KDQo4IDAgb2JqDQpbL1BERiAvVGV4dF0NCmVuZG9iag0KDQo5IDAgb2JqDQo8PA0KL1R5cGUgL0ZvbnQNCi9TdWJ0eXBlIC9UeXBlMQ0KL05hbWUgL0YxDQovQmFzZUZvbnQgL0hlbHZldGljYQ0KL0VuY29kaW5nIC9XaW5BbnNpRW5jb2RpbmcNCj4+DQplbmRvYmoNCg0KMTAgMCBvYmoNCjw8DQovQ3JlYXRvciAoUmF2ZSBcKGh0dHA6Ly93d3cubmV2cm9uYS5jb20vcmF2ZVwpKQ0KL1Byb2R1Y2VyIChOZXZyb25hIERlc2lnbnMpDQovQ3JlYXRpb25EYXRlIChEOjIwMDYwMzAxMDcyODI2KQ0KPj4NCmVuZG9iag0KDQp4cmVmDQowIDExDQowMDAwMDAwMDAwIDY1NTM1IGYNCjAwMDAwMDAwMTkgMDAwMDAgbg0KMDAwMDAwMDA5MyAwMDAwMCBuDQowMDAwMDAwMTQ3IDAwMDAwIG4NCjAwMDAwMDAyMjIgMDAwMDAgbg0KMDAwMDAwMDM5MCAwMDAwMCBuDQowMDAwMDAxNTIyIDAwMDAwIG4NCjAwMDAwMDE2OTAgMDAwMDAgbg0KMDAwMDAwMjQyMyAwMDAwMCBuDQowMDAwMDAyNDU2IDAwMDAwIG4NCjAwMDAwMDI1NzQgMDAwMDAgbg0KDQp0cmFpbGVyDQo8PA0KL1NpemUgMTENCi9Sb290IDEgMCBSDQovSW5mbyAxMCAwIFINCj4+DQoNCnN0YXJ0eHJlZg0KMjcxNA0KJSVFT0YNCg==';//response.PDF_DATA;
        }catch(Exception ex){
            //NCP-3577
            D1_CustomLoggingUtility.logMessage('D1_BillingHistoryController', 'downloadFinancialDoc', ex, (request != NULL? JSON.serialize(request):''), (response != NULL? JSON.serialize(response):''));
            return null;
        }
    }
}