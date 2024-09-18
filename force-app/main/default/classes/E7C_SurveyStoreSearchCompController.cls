public without sharing class E7C_SurveyStoreSearchCompController {
    
    @AuraEnabled
    public static String createOrUpdateSurvey(String userMarket, String outlet, String outletName, String outletAddress, String outletLat, String outletLong){
        String surveyId = E7C_Utility.getSurveyId(userMarket);
        String surResponseId = E7C_Utility.getSurveyResponseId(surveyId);
        String srId;
        String status = 'Draft';
        if(surResponseId != null){
            srId = E7C_Utility.updateSurveyResponseRecord(surResponseId, surveyId, outlet, status, '', outletName, outletAddress, outletLat, outletLong);
        }else{
            srId = E7C_Utility.createSurveyResponseRecord(surveyId, outlet, status, '', outletName, outletAddress, outletLat, outletLong);
        }
        
        return srId;
    }
    
    @AuraEnabled
    public static String getNearbyLocations(String latitude, String longitude){
        Decimal latitudeDecimal = Decimal.valueOf(latitude).setScale(4);
        Decimal longitudeDecimal = Decimal.valueOf(longitude).setScale(4);
        
        String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location='+latitudeDecimal+','+longitudeDecimal+'&type=bar&rankby=distance&key='+E7C_SurveyStoreSearchCompController.getGoogleMapsAPIKey();
        //String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location='+latitudeDecimal+','+longitudeDecimal+'&type=bar&rankby=distance&key=AIzaSyBeIqOSyDRotGoT8Zar2nhOXFebVabLkOk';
        //String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=13.20095,77.70851&type=bar&rankby=distance&key=AIzaSyBeIqOSyDRotGoT8Zar2nhOXFebVabLkOk';
        
        return E7C_SurveyStoreSearchCompController.getHttp(url);
    }
     
    @AuraEnabled
    public static String searchOutlets(String searchKey){
        
        String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=';
        url += EncodingUtil.urlEncode(searchKey, 'UTF-8');
        url += '&inputtype=textquery&fields=photos,formatted_address,name,geometry';
        url += '&key='+E7C_SurveyStoreSearchCompController.getGoogleMapsAPIKey();//AIzaSyBeIqOSyDRotGoT8Zar2nhOXFebVabLkOk';
        
        return E7C_SurveyStoreSearchCompController.getHttp(url);
    }
    
    public static String getGoogleMapsAPIKey(){
        
        String GMapkey= 'AIzaSyBeIqOSyDRotGoT8Zar2nhOXFebVabLkOk';
        return GMapkey;
    }
    
    public static string getHttp(String url){
        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            return response.getBody();
            
        }catch(Exception e){    
            return e.getMessage();
        }
    } 
    
}