/*
@Name : CO_SendToSAP
@Purpose : This class is used send Customer Request data from SF to SAP
History                                                            
@VERSION    AUTHOR            DATE              DETAIL
1.0        Gaurav Singh      8-28-2022        Initial Development
1.1        Anamika Shukla    29/02/2024       EDGE Global: Mulesoft OAuth2 migration-358242
*/
public with sharing class CO_SendToSAP {
    public static final String CO_SAP_MULESOFTINT = 'CO_Mulesoft_SAP';//358242
    public static Boolean isValid = true;
    public static String error = '';

    public static List<Results> sendDataToSAP(List<ID> ids) {
        try {
            processSendDataToSAP(ids);
        }catch (Exception e) {
            isValid = false;
            error = 'Send To SAP Failed. Error : '+e.getMessage();

            EventsLog_Utility.createIntegrationLog('Fail', 'CO_SendToSAP', 'sendDataToSAP', e.getMessage(), 0, e.getTypeName(), '', '', e.getStackTraceString(), 'Customer Onboarding', 'Customer Onboarding SAP <> SF');
        }
        
        List<Results> output = new List<Results>();
        Results result = new Results();
        result.isValid = isValid;
        result.message = error;
        output.add(result);
        return output;
    }

    public static void processSendDataToSAP(List<ID> ids) {
        List<Customer_Request__c> crList = [Select id, CO_Response_received_from_SAP__c, RecordType.DeveloperName, Country__r.Code__c, CO_Sales_Organisation__r.Code__c from Customer_Request__c where Id IN :ids WITH SECURITY_ENFORCED ];
        
        List<CO_SF_To_SAP_Mapping__mdt> requestMappingsRecords = getSFToSAPMappingRecords(crList, 'SAP');
        List<RequestMapping> requestMappingHierarchy = createRequestMappingHierarchy( requestMappingsRecords );

        Map<Id,Customer_Request__c> crMapWithMappingInfo = new Map<Id,Customer_Request__c>(getCRRecordWithMappingFields(ids, requestMappingHierarchy));

        processCustomerRequests(crList, requestMappingHierarchy, crMapWithMappingInfo);
        
        Map<Id,Customer_Request__c> crListForUpdate = new Map<Id,Customer_Request__c>([Select id, CO_Status__c, CO_Response_received_from_SAP__c, RecordType.DeveloperName, Country__r.Code__c, CO_Sales_Organisation__r.Code__c from Customer_Request__c where Id IN :ids WITH SECURITY_ENFORCED FOR UPDATE]);
        for( Customer_Request__c cr : crList ){
            Customer_Request__c crForUpdate = crListForUpdate.get(cr.Id);
            if( crForUpdate.CO_Status__c == 'IN REVIEW' ){
                cr.CO_Status__c = 'SENT TO SAP';
            }
            cr.CO_Response_received_from_SAP__c = (crForUpdate.CO_Response_received_from_SAP__c != NULL? crForUpdate.CO_Response_received_from_SAP__c:0) + 1;
        }

        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, crList);
        update securityDecision.getRecords();
    }

    public static void processCustomerRequests(List<Customer_Request__c> crList, List<RequestMapping> requestMappingHierarchy, Map<Id,Customer_Request__c> crMapWithMappingInfo) {
        for(Customer_Request__c cr : crList){
            String requestBody = CO_SendToSAPRequest.createRequestBody(crMapWithMappingInfo.get(cr.Id),requestMappingHierarchy,'SAP');
            system.debug(System.LoggingLevel.INFO, '-------- '+requestBody);

            SAPResponse resp = sendResponse(requestBody);
            
            parseSAPResponseAndSetCRFields(cr, requestBody, resp);
        }
    }
    
    @InvocableMethod
    public static List<Results> sendDataToSAP(List<List<ID>> ids) {
        List<ID> idList = ids.get(0);
        return sendDataToSAP(idList);
    }

    public static void parseSAPResponseAndSetCRFields(Customer_Request__c cr, String requestBody, SAPResponse resp) {
        String respString = resp.jsonBody;

        if(resp.statusCode != 200){
            try{
            	CO_SAPResponseParser resWrap = CO_SAPResponseParser.parser(respString);
                
                cr.Status_Code__c = resp.statusCode;
            	cr.CO_Error_Message__c = resWrap.errorMessage;
                
                EventsLog_Utility.createIntegrationLog('Fail', 'CO_SendToSAP', 'sendDataToSAP', resWrap.errorMessage, resp.statusCode, '', requestBody, resp.jsonBody, '', 'Customer Onboarding', 'Customer Onboarding SAP <> SF');
            }catch(System.JSONException e){
                cr.Status_Code__c = resp.statusCode;
                cr.CO_Error_Message__c = 'Failed to get valid response from SAP.';

                isValid = false;
                error = 'Failed to get valid response from SAP.';
                
                EventsLog_Utility.createIntegrationLog('Fail', 'CO_SendToSAP', 'sendDataToSAP', 'Failed to get valid response from SAP.', resp.statusCode, '', requestBody, resp.jsonBody, '', 'Customer Onboarding', 'Customer Onboarding SAP <> SF');
            }
        }else{
            cr.Status_Code__c = resp.statusCode;
            cr.CO_Error_Message__c = null;
        }
        
        cr.CO_Response_received_from_SAP__c = (cr.CO_Response_received_from_SAP__c != NULL? cr.CO_Response_received_from_SAP__c:0) + 1;
    }

    public Static List<CO_SF_To_SAP_Mapping__mdt> getSFToSAPMappingRecords( List<Customer_Request__c> crList , String sourceSystem){
        Set<String> countryCodeList = new Set<String>();
        Set<String> salesOrgList = new Set<String>();
        Set<String> customerTypeList = new Set<String>();
        for(Customer_Request__c cr : crList){
            if( cr.Country__r.Code__c != NULL ){
                countryCodeList.add(cr.Country__r.Code__c);
            }
            if( cr.CO_Sales_Organisation__r.Code__c != NULL ){
                salesOrgList.add(cr.CO_Sales_Organisation__r.Code__c);
            }
            customerTypeList.add(cr.RecordType.DeveloperName);
        }

        if( sourceSystem == 'SAP' ){ 
            return getAllRequestMappings(countryCodeList, salesOrgList, customerTypeList);
        }else if( sourceSystem == 'RDDC' ){
            return getAllRequestMappingsRDDC(countryCodeList, salesOrgList, customerTypeList);
        }

        return null;
    }

    private Static List<CO_SF_To_SAP_Mapping__mdt> getAllRequestMappings( Set<String> countryCodeList, Set<String> salesOrgList, Set<String> customerTypeList ){
        return [Select Id, DeveloperName, Attribute_Name__c, Attribute_Data_Type__c, Length__c, API_Name__c, Country__c, Customer_Type__c, Sales_Orgnanization__c, Parent_Name__c, Source_System__c, Child_Relationship_API_Name__c from CO_SF_To_SAP_Mapping__mdt where (Country__c = NULL OR Country__c IN :countryCodeList) AND (Sales_Orgnanization__c = NULL OR Sales_Orgnanization__c IN :salesOrgList) AND (Customer_Type__c = NULL OR Customer_Type__c IN :customerTypeList) AND (Source_System__c = NULL OR Source_System__c = 'SAP') WITH SECURITY_ENFORCED order by Parent_Name__c NULLS FIRST, Customer_Type__c NULLS LAST, Sales_Orgnanization__c NULLS LAST, Country__c NULLS LAST];
    }

    private Static List<CO_SF_To_SAP_Mapping__mdt> getAllRequestMappingsRDDC( Set<String> countryCodeList, Set<String> salesOrgList, Set<String> customerTypeList ){
        return [Select Id, DeveloperName, Attribute_Name__c, Attribute_Data_Type__c, Length__c, API_Name__c, Country__c, Customer_Type__c, Sales_Orgnanization__c, Parent_Name__c, Source_System__c, Child_Relationship_API_Name__c from CO_SF_To_SAP_Mapping__mdt where (Country__c = NULL OR Country__c IN :countryCodeList) AND (Sales_Orgnanization__c = NULL OR Sales_Orgnanization__c IN :salesOrgList) AND (Customer_Type__c = NULL OR Customer_Type__c IN :customerTypeList) AND Source_System__c = 'RDDC' WITH SECURITY_ENFORCED order by Parent_Name__c NULLS FIRST, Customer_Type__c NULLS LAST, Sales_Orgnanization__c NULLS LAST, Country__c NULLS LAST];
    }

    public Static List<RequestMapping> createRequestMappingHierarchy( List<CO_SF_To_SAP_Mapping__mdt> requestMappingRecords ){
        Map<String,RequestMapping> requestMappings = new Map<String,RequestMapping>();
        for( CO_SF_To_SAP_Mapping__mdt requestMapping : requestMappingRecords ){
            if( String.isBlank(requestMapping.Parent_Name__c) ){
                requestMappings.put( requestMapping.DeveloperName, new RequestMapping(requestMapping) );
            }else{
                addChildMappingRecords(requestMapping, requestMappings.values() );
            }
        }

        return requestMappings.values();
    }

    

    private Static void addChildMappingRecords( CO_SF_To_SAP_Mapping__mdt requestMapping, List<RequestMapping> requestMappings ){
        for( RequestMapping requestMappingWrap : requestMappings ){
            if( requestMappingWrap.uniqueName == requestMapping.Parent_Name__c ){
                requestMappingWrap.childRequestMappings.add( new requestMapping(requestMapping) );
                break;
            }

            if( !requestMappingWrap.childRequestMappings.isEmpty() ){
                addChildMappingRecords(requestMapping, requestMappingWrap.childRequestMappings);
            }
        }
    }

    public Static List<Customer_Request__c> getCRRecordWithMappingFields( List<ID> ids, List<RequestMapping> requestMappingHierarchy ){
        Set<String> queryFieldsSet = populatedFieldsForQueryMap(requestMappingHierarchy);
        queryFieldsSet.addAll(new Set<String>{'RecordType.DeveloperName', 'Country__r.Code__c', 'CO_Sales_Organisation__r.Code__c'});
        
        String queryFields = String.join(new List<String>(queryFieldsSet), ',');
        system.debug(System.LoggingLevel.INFO,'queryFields: '+queryFields);

        String crQuery = String.escapeSingleQuotes('Select '+queryFields+' from Customer_Request__c where Id IN :ids');

        List<Customer_Request__c> crRecords = (List<Customer_Request__c>)Database.query(crQuery);
        return crRecords;
    }

    public Static Set<String> populatedFieldsForQueryMap( List<RequestMapping> requestMappingHierarchy ){
        Set<String> queryFieldsSet = new Set<String>();
        for( RequestMapping requestMappingWrap : requestMappingHierarchy ){
            if( String.isNotBlank(requestMappingWrap.requestMappingRecord.API_Name__c) && !queryFieldsSet.contains(requestMappingWrap.requestMappingRecord.API_Name__c) ){
                queryFieldsSet.add(requestMappingWrap.requestMappingRecord.API_Name__c);
            }else if( String.isNotBlank(requestMappingWrap.requestMappingRecord.Child_Relationship_API_Name__c) ){
                Set<String> childQueryFieldsSet = populatedFieldsForQueryMap(requestMappingWrap.childRequestMappings);
                queryFieldsSet.add('(Select '+String.join(new List<String>(childQueryFieldsSet), ',')+' From '+requestMappingWrap.requestMappingRecord.Child_Relationship_API_Name__c+')');
            }else if( !requestMappingWrap.childRequestMappings.isEmpty() ){
                Set<String> childFields = populatedFieldsForQueryMap(requestMappingWrap.childRequestMappings);
                queryFieldsSet.addAll(childFields);
            }
        }
        return queryFieldsSet;
    }
    
    
    /*
    * @description : sendResponse
    * @return : string
    * @param : string jsonPayload
    */  
    public static SAPResponse sendResponse(string jsonPayload){
        SAPResponse sapResp = new SAPResponse();
        
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(Label.CO_SAP_Endpoint);
        request.setEndpoint('callout:' +CO_SAP_MULESOFTINT);
        request.setMethod('POST');
        //request.setHeader('client_id',Label.CO_SAP_Client_ID);
        //request.setHeader('client_secret',Label.CO_SAP_Client_Secret);
        request.setHeader('Content-Type','application/json');
        request.setBody(jsonPayload);
        request.setTimeout(120000);
        try {
            Http http = new Http();
            HttpResponse res = http.send(request);

            system.debug(System.LoggingLevel.INFO, 'res = '+res);
            system.debug(System.LoggingLevel.INFO, 'resBody = '+res.getBody());
           
            if(res.getStatusCode() == 200){
                sapResp.jsonBody = res.getBody();
                sapResp.statusCode = res.getStatusCode();
            }else{
                sapResp.jsonBody = res.getBody();
                sapResp.statusCode = res.getStatusCode();
            }
        }catch(Exception ex){
            EventsLog_Utility.createIntegrationLog('Fail', 'CO_SendToSAP', 'sendResponse', ex.getMessage(), 0, ex.getTypeName(), 'request', 'response', ex.getStackTraceString(), 'Customer Onboarding', 'Customer Onboarding SAP <> SF');
            // return null;
        }
        return sapResp;
    }

    public class Results {
        @InvocableVariable(label='Is Valid' description='Is Request Valid')
        public Boolean isValid;

        @InvocableVariable(label='Message' description='User Message')
        public String message;
    }
    
    public class SAPResponse {
        public String jsonBody;
        public Integer statusCode;
    }

    public class RequestMapping {
        public String uniqueName;
        public CO_SF_To_SAP_Mapping__mdt requestMappingRecord;
        public List<RequestMapping> childRequestMappings;

        public RequestMapping( CO_SF_To_SAP_Mapping__mdt requestMappingRecord ){
            this.uniqueName = requestMappingRecord.DeveloperName;
            this.requestMappingRecord = requestMappingRecord;
            this.childRequestMappings = new List<RequestMapping>();
        }
    }
    
    public class SendToSAPException extends Exception{
        
    }
}