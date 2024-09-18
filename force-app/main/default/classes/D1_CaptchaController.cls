/**
 * @name D1_CaptchaController
 * @description Google Captcha Validation Module
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0         Ajay            11/11/20    Google Captcha Validation Module(NCP-702)
 **/
public without sharing class D1_CaptchaController {
    
    class ResponseWrapper{
        Boolean success;
    }

    private String secretKey {get;set;}
    private String captchaValidationURL{get;set;}

    public Boolean isActive{get;private set;}
    public String siteKey{get;private set;}
    public String captchaAPIURL{get; private set;}
    /**
     * @description 
     */    
    public D1_CaptchaController(){

        List<D1_GoogleCaptchaSettings__mdt> configRecords = [SELECT isActive__c,Secret_Key__c,Site_Key__c,Captcha_API_URL__c,Captcha_Validation_URL__c
        FROM D1_GoogleCaptchaSettings__mdt
        LIMIT 1];

        if(configRecords.isEmpty()){
            isActive = false;
        }else{
            D1_GoogleCaptchaSettings__mdt config = configRecords[0];

            secretKey = config.Secret_Key__c;
            captchaValidationURL= config.Captcha_Validation_URL__c;

            isActive= config.isActive__c;
            siteKey = config.Site_Key__c;
            captchaAPIURL= config.Captcha_API_URL__c;
        }
    }


    /**
     * @description Validate Google Captcha Token
     * @userStory NCP-4261
     * @param Google captcha client side token
     * @param param2
     * @return true/false -> success/fail
     * Throws: Nil
     **/
    public Boolean validateCaptchaToken(String token){
        token = token == NULL ? '': token;
        if(this.isActive != true){
            return true;
        }
        
        String secret= this.secretKey;

        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        request.setEndpoint(this.captchaValidationURL);
        request.setMethod('POST');
        request.setBody('secret='+ EncodingUtil.urlEncode(secret, 'UTF-8')
        + '&response='+ EncodingUtil.urlEncode(token, 'UTF-8'));

        response = http.send(request);

        String responseString = response.getbody();
        if(response.getstatusCode() == 200 &&  responseString!= null){

            ResponseWrapper responseObj = (ResponseWrapper) JSON.deserialize(responseString, ResponseWrapper.class);
            if(responseObj.success == true){
                return true;
            }
        }

        return false;
    }
}