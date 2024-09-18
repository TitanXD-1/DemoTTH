/**
 * @name : D1_IpServiceController
 * @description : Controller Class to get IP and do callout to Maxmind to get IP Details
 * @history :
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           01/09/2022      Initial Development (NCP-437)
 */
public with sharing class D1_IpServiceController {
    public String ipAddress{get; set;}
    public String response{get; set;}

    public D1_IpServiceController() {
        this.ipAddress = ApexPages.currentPage().getHeaders().get('True-Client-IP');       

        //this will work if no caching is in place or
        //user is logged in via secure URL
        if(String.isEmpty(ipAddress)){
            this.ipAddress = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        }
         
        //this logic will execute if proxy is in use
        if(String.isEmpty(ipAddress)){
           this.ipAddress = ApexPages.currentPage().getHeaders().get('X-Forwarded-For');
        }
    }

    public void getMyLocation(){
        try {
            //Do Callout
            HttpResponse httpResponse = doCallout(this.ipAddress);
            
            //Parse Response
            string countryCode = parseResponse(httpResponse);

            //Get Market Specific Domain
            response = getCountryDomain(countryCode);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
    }

    public static HttpResponse doCallout(string ipAddress){
        HttpRequest httpRequest;
        HttpResponse httpResponse;

        try{
            //Get Custom Metadata Records
            Map<String, D1_Commerce_SAP_Setting__mdt> commerceSettingMap = D1_Commerce_SAP_Setting__mdt.getAll();

            //Create Request
            httpRequest = new HttpRequest();
            httpRequest.setMethod('GET');
            httpRequest.setHeader('Accept','application/json');
            httpRequest.setHeader('Authorization','Basic' + ' ' + commerceSettingMap.get('Get_Ip_Token').Value__c);
            httpRequest.setEndpoint(commerceSettingMap.get('Get_Ip').Value__c + '/' + ipAddress);
            httpRequest.setTimeout(120000);

            Http http = new Http();
            httpResponse = http.send(httpRequest);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }

        return httpResponse;
    }

    public static string parseResponse(HttpResponse httpResponse){
        Integer statusCode = httpResponse.getStatusCode();
        String responseBody = httpResponse.getBody();
        string countryCode = '';

        if (statusCode == 200){
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            if(responseMap != null){
                Map<String, Object> responseCountryMap = (Map<String, Object>)responseMap.get('country');

                countryCode = String.valueOf(responseCountryMap.get('iso_code'));

                //if countryCode = GB, check Region because Diageo treats Northern Ireland as a country instead part of GB
                if(countryCode == 'GB'){
                    List<Object> subDivisions = (List<Object>)responseMap.get('subdivisions');
                    for(Object subDivision : subDivisions){
                        Map<String, Object> responseSubDivisionsMap = (Map<String, Object>)subDivision;
                        string subDivisionCode = String.valueOf(responseSubDivisionsMap.get('iso_code'));
                        if(subDivisionCode == 'NIR'){
                            countryCode = subDivisionCode;

                            break;
                        }
                    }
                }
            }
        }else {
            System.debug(LoggingLevel.INFO, statusCode);
        }

        return countryCode;
    }

    public static string getCountryDomain(string countryCode){
        string languageWraperStr = '{"error": "No Match"}';
        if(String.isNotBlank(countryCode)){
            List<D1_LocationSelectorController.LanguageWrapper> languageWrapperList = D1_LocationSelectorController.getLocationWithLanguage();
            if(languageWrapperList != null && languageWrapperList.size()>0){
                for(D1_LocationSelectorController.LanguageWrapper languageWrapper : languageWrapperList){
                    if(languageWrapper.isDefault && languageWrapper.countryName == countryCode){
                        languageWraperStr = JSON.serialize(languageWrapper);
                        return languageWraperStr;
                    }
                }
            }
        }
        return languageWraperStr;
    }
}