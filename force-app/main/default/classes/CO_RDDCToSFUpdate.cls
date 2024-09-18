/*
@Name : CO_RDDCToSFUpdate
@Purpose : This class is used send receive data from RDDC
History                                                            
@VERSION    AUTHOR            DATE              DETAIL
1.0        Gaurav Singh      1-12-2022        Initial Development
2.0		   Jayashree R       7-03-2023        CONS-726
3.0		   Venkatesh Varma   12-03-2023       CONS-727
4.0		   Venkatesh Varma   07-04-2023       CONS-468
5.0        Anamika Shukla    29-02-2024       EDGE Global: Mulesoft OAuth2 migration-358242
*/
public with sharing class CO_RDDCToSFUpdate {
    //public static final String CO_RDDC_DETAILS_ENDPOINT = 'CO_RDDC_To_SF';
    public static final String CO_RDDC_DETAILS_ENDPOINT = 'CO_RDDC_Retrieve_Thirdparty';//358242
    //public static final String CR_IN_REVIEW_STATUS = 'IN REVIEW';
    // CONS-727
    public static Boolean isValid = false;
    public static String error = '';
    
    @InvocableMethod
    public static List<Results> getDataFromRDDC(List<ID> crIds) {
        try {
            processGetDataFromRDDC(crIds);
        } catch (Exception e) {
            isValid = false;
            error = 'Failed to get data from RDDC. Error : '+e.getMessage();
            EventsLog_Utility.createIntegrationLog('Fail', 'CO_RDDCToSFUpdate', 'getDataFromRDDC', e.getMessage(), 0, e.getTypeName(), '', '', e.getStackTraceString(), 'Customer Onboarding', 'Customer Onboarding RDDC <> SF');
        }
        
        List<Results> output = new List<Results>();
        Results result = new Results();
        result.isValid = isValid;
        result.message = error;
        output.add(result);
        return output;
    }
    
    private static void processGetDataFromRDDC(List<ID> crIds) {
        List<Customer_Request__c> crList = [Select id, CO_KYC_Record_Number__c,CO_Bank_Name__c, CO_Bank_Branch_Name__c from Customer_Request__c where Id IN :crIds WITH SECURITY_ENFORCED ];
        
        processCustomerRequests(crList);
        
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, crList);
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.allowFieldTruncation = true;
        
        List<Customer_Request__c> crListToUpdate = securityDecision.getRecords();
        if (!Schema.sObjectType.Customer_Request__c.isUpdateable()) {
            return;
        }
        
        //Start CONS-727
        Database.SaveResult[] srList = Database.update(crListToUpdate, dml);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug(System.LoggingLevel.INFO,'Successfully inserted CR. CR ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug(System.LoggingLevel.INFO, err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(System.LoggingLevel.INFO, 'CR fields that affected this error: ' + err.getFields());
                    isValid = false;
                    error += err.getMessage();
                }
            }
        }
        //End CONS-727
    }
    
    private static void processCustomerRequests(List<Customer_Request__c> crList) {
        for(Customer_Request__c cr : crList){
            
            RDDCResponse resp = sendRequestToRDDC(cr.CO_KYC_Record_Number__c);
            
            parseRDDCResponseAndSetCRFields(cr, resp);
        }
    }
    
    private static RDDCResponse sendRequestToRDDC(String rddcId){
        //Map<String, CO_Client_Id_Client_Secret__mdt> clientSettingMap = CO_Client_Id_Client_Secret__mdt.getAll();
        RDDCResponse rddcResp = new RDDCResponse();
        
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint('callout:' +CO_RDDC_DETAILS_ENDPOINT+'/'+rddcId);
        //request.setHeader('client_id',clientSettingMap.get('Client_Id').Value__c);
        //request.setHeader('client_secret',clientSettingMap.get('Client_secret').Value__c);
        request.setTimeout( 120000 );
        request.setMethod('GET');
        
        
        Http http = new Http();
        HttpResponse res = http.send(request);
        
        System.debug(System.LoggingLevel.INFO,request.getEndpoint());
        system.debug(System.LoggingLevel.INFO, 'res = '+res);
        system.debug(System.LoggingLevel.INFO, 'resBody = '+res.getBody());
        
        rddcResp.jsonBody = res.getBody();
        rddcResp.statusCode = res.getStatusCode();
        
        
        return rddcResp;
    }
    
    private static void parseRDDCResponseAndSetCRFields(Customer_Request__c cr, RDDCResponse resp) {
        String respString = resp.jsonBody;
        if(resp.statusCode == 200){
            CO_RDDCWrapper.DataResponseWrapper rddcCRData = new CO_RDDCWrapper.DataResponseWrapper();
            rddcCRData =   (CO_RDDCWrapper.DataResponseWrapper) JSON.deserialize(respString, CO_RDDCWrapper.DataResponseWrapper.class);
            cr.CO_Customer_Name__c = rddcCRData.name;
            cr.CO_KYC_Risk_Category__c = rddcCRData.riskTier;
            if( rddcCRData.customFields != null && rddcCRData.customFields != null ){
                setCRFields(cr, rddcCRData.customFields);
            }
            //cr.CO_Status__c = CR_IN_REVIEW_STATUS;
            //commented for CONS-468
            // CONS-727
            isValid = true;
            cr.CO_Is_Retrieved__c = true;
        }else{
            CO_RDDCWrapper.CO_ErrorResposneGetDetails resWrap = (CO_RDDCWrapper.CO_ErrorResposneGetDetails) JSON.deserialize(respString, CO_RDDCWrapper.CO_ErrorResposneGetDetails.class);
            isValid = false;
            error= resWrap.error?.errorMessage;
            EventsLog_Utility.createIntegrationLog('Fail', 'CO_RDDCToSFUpdate', 'parseRDDCResponseAndSetCRFields', (resWrap.error?.errorMessage), resp.statusCode, '', '', resp.jsonBody, '', 'Customer Onboarding', 'Customer Onboarding RDDC <> SF');
        }
    }   
    
    
    static void setCRFields(Customer_Request__c cr, List<CO_RDDCWrapper.CustomFieldsResponseWrapper> customFields ) {
        Map<String, CO_RDDC_Custom_Fields_Mapping__mdt> customFieldNameToMDMap = new Map<String, CO_RDDC_Custom_Fields_Mapping__mdt>();
        for(CO_RDDC_Custom_Fields_Mapping__mdt customFieldsMetadata : CO_RDDC_Custom_Fields_Mapping__mdt.getAll().values()){
            customFieldNameToMDMap.put(customFieldsMetadata.Name__c, customFieldsMetadata);
        }
        
        
        for(  CO_RDDCWrapper.CustomFieldsResponseWrapper customField : customFields ){
            CO_RDDC_Custom_Fields_Mapping__mdt customFieldMetadata = customFieldNameToMDMap.get(customField.name);
            Object retVal;
            if(customFieldMetadata != NULL){
                Map<String,String> statusApiToLabelMap = new Map<String,String>();
                if(customFieldMetadata.Field_Type__c == 'Picklist'){
                    statusApiToLabelMap = getPicklistValues(customFieldMetadata.API_Name__c);
                }
                retVal = setCRFields(customField, customFieldMetadata, statusApiToLabelMap);
            }
            if( retVal != NULL ){
                cr.put(customFieldMetadata.API_Name__c, retVal);
            }
            
        }
    }
    
    static Map<String, String> getPicklistValues(String fieldApiName){
        Map<String,String> statusApiToLabelMap = new Map<String,String>();
        List<Schema.PicklistEntry> values; 
        SObject instance = (SObject) Type.forName('Schema.Customer_Request__c').newInstance();
        Schema.DescribeSObjectResult objDescribeSobject = instance.getSObjectType().getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
        values = fieldResult.getPicklistValues();
        
        For(Schema.PicklistEntry sp : values){
            //Map to hold Picklist API as Key and Picklist Label as Value
            statusApiToLabelMap.put(sp.getLabel(),sp.getValue());
        }
        return statusApiToLabelMap;
    }
    
    static Object setCRFields(CO_RDDCWrapper.CustomFieldsResponseWrapper customField, CO_RDDC_Custom_Fields_Mapping__mdt customFieldMetadata, Map<String,String> statusApiToLabelMap ) {
        if(!customFieldMetadata.API_Name__c.contains('.') && customField.name == customFieldMetadata.Name__c && customField.value != null && customFieldMetadata.Field_Type__c != null){
            if(customFieldMetadata.Field_Type__c == 'Picklist' && statusApiToLabelMap.containskey(customField.value))
            {
                return statusApiToLabelMap.get(customField.value); 
            }
            else if(customFieldMetadata.Field_Type__c != 'Picklist')
            {
                return customField.value; 
            }
        }
        return null;
    }
    
    
    
    public class Results {
        @InvocableVariable(label='Is Valid' description='Is Request Valid')
        public Boolean isValid;
        
        @InvocableVariable(label='Message' description='User Message')
        public String message;
    }
    
    public class RDDCResponse {
        public String jsonBody;
        public Integer statusCode;
    }
    
}