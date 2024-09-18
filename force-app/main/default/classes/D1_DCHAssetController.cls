/**
 * @name : D1_DCHAssetController
 * @description : Controller Class to do callout to DCH by calling Get Asset By Id API
 * @history :
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           01/09/2022      Initial Development (NCP-5613)
 */
public with sharing class D1_DCHAssetController {
    
    public static final String MULESOFT_DETAILS_NAMED_CREDENTIAL = 'D1_MuleSoftDetails';

    @AuraEnabled(cacheable=true)
    public static String getAssetDetails(String assetId){
        try {
            //Do Callout
            HttpResponse httpResponse = doCallout(assetId);

            //Parse Response
            String response = parseResponse(httpResponse);

            return response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static HttpResponse doCallout(String assetId){
        HttpRequest httpRequest;
        HttpResponse httpResponse;

        try{
            //Get Custom Metadata Records
            Map<String, D1_Commerce_SAP_Setting__mdt> commerceSettingMap = D1_Commerce_SAP_Setting__mdt.getAll();

            //Create Request
            httpRequest = new HttpRequest();
            httpRequest.setMethod('GET');
            httpRequest.setHeader('Content-Type','application/json');
            httpRequest.setHeader('X-Correlation-Id','D1');
            httpRequest.setEndpoint('callout:' + MULESOFT_DETAILS_NAMED_CREDENTIAL + '/' + commerceSettingMap.get('DCH_Asset_Detail').Value__c + '/' + assetId);
            httpRequest.setHeader('client_id',commerceSettingMap.get('DCH_Client_Id').Value__c);
            httpRequest.setHeader('client_secret',commerceSettingMap.get('DCH_Client_Secret').Value__c);
            httpRequest.setTimeout(120000);

            Http http = new Http();
            httpResponse = http.send(httpRequest);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

        return httpResponse;
    }

    public static String parseResponse(HttpResponse httpResponse){
        Integer statusCode = httpResponse.getStatusCode();
        String responseBody = '';

        if (statusCode == 200) {
            responseBody = httpResponse.getBody();
        }else{
            System.debug(LoggingLevel.INFO,statusCode);
        }
        return responseBody;
    }
}