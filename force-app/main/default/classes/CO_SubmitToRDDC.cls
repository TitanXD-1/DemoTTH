/*
@Name: CO_SubmitToRDDC

@Purpose: This class is used to send Customer Request data from SF to RDDC.

@History                                                                                                           
VERSION    AUTHOR            DATE              DETAIL
1.0        Gaurav Singh      08-08-2022        Initial Development
2.0        Jayashree R       24-01-2023        CONS-355 
3.0		   Jayashree R       06-02-2023        CONS-582
3.1		   Tupesh Bhagat     21-03-2023        CONS-750
3.2		   Tupesh Bhagat     28-03-2023        CONS-809
3.3        Anamika Shukla    29/02/2024        EDGE Global: Mulesoft OAuth2 migration-358242
*/

public with sharing class CO_SubmitToRDDC {
    //public static final String CO_RDDC_DETAILS_ENDPOINT = 'CO_RDDC_Details';
    public static final String CO_RDDC_DETAILS_ENDPOINT = 'CO_RDDC_Add_Thirdparty';//358242
    public static Boolean isValid = true;
    public static String message = '';
    
    @InvocableMethod
    public static List<Results> sendDataToRDDC(List<ID> ids) {
        try {
            Set<String> queryFieldsSet = new Set<String>();
            for(Schema.FieldSetMember f : SObjectType.Customer_Request__c.FieldSets.RDDC_Fields.getFields()){
                queryFieldsSet.add(f.getFieldPath());
            }
          
            queryFieldsSet.add('CO_Address__CountryCode__s');
            queryFieldsSet.add('CO_Sales_Organisation__r.Country__r.Parent_Geography__r.Parent_Geography__r.Name'); 
            
            List<CO_RDDC_Custom_Fields_Mapping__mdt> rddcCustomFieldMap = CO_RDDC_Custom_Fields_Mapping__mdt.getAll().values();
            List<CO_RDCC_Questionnaire_Response_Mapping__mdt> rddcQueResMap = CO_RDCC_Questionnaire_Response_Mapping__mdt.getAll().values();
            
            Id custReqId = ids[0];
            system.debug(System.LoggingLevel.INFO,'custReqId: '+custReqId);
            for (CO_RDDC_Custom_Fields_Mapping__mdt rddcCustomField : rddcCustomFieldMap ){
                if(rddcCustomField.API_Name__c == 'Countrie_s_where_goods_service_provided__c'){
                    queryFieldsSet.add('toLabel('+rddcCustomField.API_Name__c+')');
                }else{
                    queryFieldsSet.add(rddcCustomField.API_Name__c);
                }
            }
            for (CO_RDCC_Questionnaire_Response_Mapping__mdt rddcQueRes : rddcQueResMap){
                if(rddcQueRes.API_Name__c == 'Countrie_s_where_goods_service_provided__c' || rddcQueRes.API_Name__c == 'CO_Location_of_Headquarters__c'){
                    queryFieldsSet.add('toLabel('+rddcQueRes.API_Name__c+')');
                }else{
                    queryFieldsSet.add(rddcQueRes.API_Name__c);
                }
             
            }
            
            String queryFields = String.join(new List<String>(queryFieldsSet), ',');
            system.debug(System.LoggingLevel.INFO,'queryFields: '+queryFields);
            
            String crQuery = String.escapeSingleQuotes('Select '+queryFields+' from Customer_Request__c where Id =:custReqId LIMIT 1');
            
            SObject crObj = Database.query(crQuery);
            String jsonString = generateRequestJson(crObj, rddcCustomFieldMap, rddcQueResMap);
            RDDCResponse rddcRes = sendRDDCRequest(jsonString);
            parseRDDCResponseAndSetCRFields(crObj.Id, jsonString, rddcRes);
            
        } catch (Exception e) {
            system.debug(System.LoggingLevel.INFO, 'Exception:'+e.getStackTraceString());
            isValid = false;
            message = Label.CO_RDDC_Error_Msg+' '+e.getMessage();
            System.debug(System.LoggingLevel.INFO, 'error '+message);
            EventsLog_Utility.createIntegrationLog('Fail', 'CO_SubmitToRDDC', 'sendDataToRDDC', e.getMessage(), 0, e.getTypeName(), '', '', e.getStackTraceString(), 'Customer Onboarding', 'Customer Onboarding SF <> RDDC');
        }
        
        List<Results> output = new List<Results>();
        Results result = new Results();
        result.isValid = isValid;
        result.message = message;
        output.add(result);
        return output;
    }
    
    private static String generateRequestJson(SObject crObj,List<CO_RDDC_Custom_Fields_Mapping__mdt> rddcCustomFieldMap, List<CO_RDCC_Questionnaire_Response_Mapping__mdt> rddcQueResMap){
        CO_RDDCWrapper.DataWrapper dataWrapper = new CO_RDDCWrapper.DataWrapper();
        dataWrapper.referenceNo = (String)crObj.get('Id');
        dataWrapper.name = (String)crObj.get('CO_Customer_Name__c');
        dataWrapper.currencyCR = (String)crObj.get('CurrencyIsoCode');
        dataWrapper.worldCheckGroup = (String)crObj.get('WorldCheckGroup__c');//Modified as per CONS-750
        dataWrapper.workflowGroupId = '6371ef1e6976da17c10118ad';
        dataWrapper.responsibleParty = (String)crObj.get('CO_Customer_CoP_Email__c');
        dataWrapper.divisions = new String[]{(String)crObj.getSobject('CO_Sales_Organisation__r').getSobject('Country__r').getSobject('Parent_Geography__r').getSobject('Parent_Geography__r').get('Name')};
            
        CO_RDDCWrapper.AddressWrapper addObj = new CO_RDDCWrapper.AddressWrapper();
        addObj.country = (String)crObj.get('CO_Address__CountryCode__s');
        dataWrapper.address = addObj;
        
        dataWrapper.description = (String)crObj.get('Comments_for_approvers__c');
        
        if(crObj.get('CO_Customer_Name_4__c') != null){
            CO_RDDCWrapper.OtherNamesWrapper otherNamesObj = new CO_RDDCWrapper.OtherNamesWrapper();
            otherNamesObj.countryOfRegistration = (String)crObj.get('CO_Address__CountryCode__s');
            otherNamesObj.name = (String)crObj.get('CO_Customer_Name_4__c');
            otherNamesObj.iwNameType = 'Doing Business As';
            otherNamesObj.worldCheckGroup = (String)crObj.get('WorldCheckGroup__c');//Modified as per CONS-750
            dataWrapper.otherNames = new List<CO_RDDCWrapper.OtherNamesWrapper>{otherNamesObj};
        }
        
        CO_RDDCWrapper.LanguagePreferenceWrapper languagePreObj = new CO_RDDCWrapper.LanguagePreferenceWrapper();
        //languagePreObj.languageId = (String)crObj.get('CO_Language__c');
        languagePreObj.languageId = 'en_us';
        
        CO_RDDCWrapper.ContactInformationWrapper conInfoObj = new CO_RDDCWrapper.ContactInformationWrapper();
        conInfoObj.email= new String[]{(String)crObj.get('CO_Contact_Person_Email__c')};
            
        CO_RDDCWrapper.ContactDetailsWrapper conDetailsObj = new CO_RDDCWrapper.ContactDetailsWrapper();
        conDetailsObj.firstName = (String)crObj.get('CO_First_Name__c');
        conDetailsObj.lastName = (String)crObj.get('CO_Surname_Name__c');
        conDetailsObj.contactInformation = conInfoObj;
        conDetailsObj.languagepreference = languagePreObj;
        dataWrapper.contactDetails = conDetailsObj;
        
        
        List<CO_RDDCWrapper.CustomFieldsWrapper> customFieldsList = new List<CO_RDDCWrapper.CustomFieldsWrapper>();
        for (CO_RDDC_Custom_Fields_Mapping__mdt rddcCustomField : rddcCustomFieldMap){
            CO_RDDCWrapper.CustomFieldsWrapper cusFieldObj = CO_SubmitToRDDCCusFieldQuesResBuild.generateCustomFieldObj(crObj, rddcCustomField);
            if(cusFieldObj != NULL){
                customFieldsList.add(cusFieldObj); 
            }
        }
        dataWrapper.customFields = customFieldsList;
        
        CO_RDDCWrapper.QuestionnaireWrapper quesWrapperObj = new CO_RDDCWrapper.QuestionnaireWrapper();
        quesWrapperObj.questionnaireNames = new String[]{'Step 1 - (Internal) Customer Questionnaire'};
        quesWrapperObj.assignee = (String)crObj.get('CO_Customer_CoP_Email__c');
        quesWrapperObj.questionnaireType = 'INTERNAL';
        quesWrapperObj.overallReviewer = '';
        DateTime d = Date.Today();
        quesWrapperObj.dueDate = d.format('yyyy-MM-dd');
        quesWrapperObj.initiatedBy = (String)crObj.get('CO_Customer_CoP_Email__c');
        
        dataWrapper.assignquestionnaire = quesWrapperObj;
        
       Map<String, List<CO_SubmitToRDDCCusFieldQuesResBuild.RDDCOptionValue>> quesOptValMap = CO_SubmitToRDDCCusFieldQuesResBuild.getOptionValueMappings();
        
        List<CO_RDDCWrapper.QuestionWrapper> quesResList = new List<CO_RDDCWrapper.QuestionWrapper>();
        for (CO_RDCC_Questionnaire_Response_Mapping__mdt rddcQuesRes : rddcQueResMap){
            CO_RDDCWrapper.QuestionWrapper rddcQuesObj;
            rddcQuesObj = CO_SubmitToRDDCCusFieldQuesResBuild.generateQuestionObj(crObj, rddcQuesRes,quesOptValMap.get(rddcQuesRes.DeveloperName));
            
            if(rddcQuesObj != null){
                quesResList.add(rddcQuesObj);
            }
        }
        
        CO_RDDCWrapper.QuestionResponseWrapper quesResObj = new CO_RDDCWrapper.QuestionResponseWrapper();
        quesResObj.tabId = 'tab-1673705248821';
        quesResObj.questions = quesResList;
        
        dataWrapper.questionnaireResponse = new List<CO_RDDCWrapper.QuestionResponseWrapper>{quesResObj};
        
        //Added as part of CONS-809//
        CO_RDDCWrapper.ScreeningCriteria scrnCriteria = new CO_RDDCWrapper.ScreeningCriteria();
        scrnCriteria.enableOngoingScreening = true;
        dataWrapper.ScreeningCriteria = scrnCriteria;
        //Added as part of CONS-809//
        
        dataWrapper.language = 'EN';
        
        system.debug(System.LoggingLevel.INFO, 'jsonString:::' +JSON.serialize(dataWrapper).replace('currencyCR', 'currency'));
        return JSON.serialize(dataWrapper).replace('currencyCR', 'currency');
    }
    
    public static void parseRDDCResponseAndSetCRFields(Id crId, String requestBody, RDDCResponse resp) {
        String respString = resp.jsonBody;
        Customer_Request__c cr = [Select Id,CO_KYC_Record_Number__c,CO_KYC_StatusCode__c,CO_KYC_Error_Message__c
                                  From Customer_Request__c Where id = :crId WITH SECURITY_ENFORCED];
        try {
            
            if(resp.statusCode != 200){
                cr.CO_KYC_StatusCode__c = String.valueOf(resp.statusCode);
                cr.CO_KYC_Error_Message__c = respString.left(255);
                isValid = false;
                message = Label.CO_RDDC_Error_Msg+' '+'Failed to get valid response from RDDC; Status code: '+resp.statusCode; 
                
                EventsLog_Utility.createIntegrationLog('Fail', 'CO_SubmitToRDDC', 'parseRDDCResponseAndSetCRFields', respString, resp.statusCode, '', requestBody, resp.jsonBody, '', 'Customer Onboarding', 'Customer Onboarding SF <> RDDC');
            }else{
                if(!respString.contains('error')){
                    CO_RDDCWrapper.CO_RDDCToSFResposne rddcCRData = (CO_RDDCWrapper.CO_RDDCToSFResposne) JSON.deserialize(respString, CO_RDDCWrapper.CO_RDDCToSFResposne.class);
                    
                    cr.CO_KYC_Record_Number__c = rddcCRData.id;
                    cr.CO_KYC_StatusCode__c = String.valueOf(resp.statusCode);
                    cr.CO_KYC_Error_Message__c = null;
                    message = Label.CO_RDDC_Success_Msg+' '+rddcCRData.message; 
                    isValid = true;                    
                    
                }else{
                    CO_RDDCWrapper.RddcDataError rddcDataError = (CO_RDDCWrapper.RddcDataError) JSON.deserialize(respString, CO_RDDCWrapper.RddcDataError.class);
                    
                    message = Label.CO_RDDC_Error_Msg;
                    for(CO_RDDCWrapper.ErrorWrapper err : rddcDataError.errors){
                        message = message +' ' + err.description;
                    } 
                    cr.CO_KYC_Error_Message__c = message.left(255);
                    isValid = false;
                }
            }
            if (Customer_Request__c.sObjectType.getDescribe().isCreateable() && Customer_Request__c.sObjectType.getDescribe().isUpdateable()){
                upsert cr;
            }
        } catch (Exception e) {
            cr.CO_KYC_StatusCode__c = String.valueOf(resp.statusCode);
            cr.CO_KYC_Error_Message__c = Label.CO_RDDC_Error_Msg+' '+e.getMessage();
            if (Customer_Request__c.sObjectType.getDescribe().isUpdateable()){
                update cr;
            }
            isValid = false;
            message = Label.CO_RDDC_Error_Msg+' '+e.getMessage();
            System.debug(System.LoggingLevel.INFO, 'error '+message);
            System.debug(System.LoggingLevel.INFO, 'errorLineNumber '+e.getLineNumber());
            EventsLog_Utility.createIntegrationLog('Fail', 'CO_SubmitToRDDC', 'parseRDDCResponseAndSetCRFields', 'Failed to get valid response from RDDC. message: ', resp.statusCode, '', requestBody, resp.jsonBody, '', 'Customer Onboarding', 'Customer Onboarding SAP <> SF');
        }   
    }
    
    
    public static RDDCResponse sendRDDCRequest(string jsonPayload){
        //Map<String, CO_Client_Id_Client_Secret__mdt> clientSettingMap = CO_Client_Id_Client_Secret__mdt.getAll();
        RDDCResponse rddcResp = new RDDCResponse(); 
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' +CO_RDDC_DETAILS_ENDPOINT);
        request.setMethod('POST');
        //request.setHeader('client_id',clientSettingMap.get('Client_Id').Value__c);
        //request.setHeader('client_secret',clientSettingMap.get('Client_secret').Value__c);
        request.setHeader('Content-Type','application/json');
        request.setBody(jsonPayload);
        request.setTimeout(120000);
        try {
            Http http = new Http();
            HttpResponse res = http.send(request);
            
            system.debug(System.LoggingLevel.INFO, 'res = '+res);
            system.debug(System.LoggingLevel.INFO, 'resBody = '+res.getBody());
            
            if(res.getStatusCode() == 200){
                rddcResp.jsonBody = res.getBody();
                rddcResp.statusCode = res.getStatusCode();
            }else{
                rddcResp.jsonBody = res.getBody();
                rddcResp.statusCode = res.getStatusCode();
            }
        }catch(Exception ex){
            isValid = false;
            message = Label.CO_RDDC_Error_Msg+' '+ex.getMessage();
            System.debug(System.LoggingLevel.INFO, 'error '+message);
            EventsLog_Utility.createIntegrationLog('Fail', 'CO_SubmitToRDDC', 'sendResponse', ex.getMessage(), 0, ex.getTypeName(), 'request', 'response', ex.getStackTraceString(), 'Customer Onboarding', 'Customer Onboarding SF <> RDDC');
        }
        return rddcResp;
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