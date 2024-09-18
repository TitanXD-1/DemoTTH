/*
 * @name: D1_CaptchaControllerTest
 * @description: Test class for D1_CaptchaController
 * @history
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Ajay            11/11/20    Google Captcha Validation Module(NCP-702)
 **/
@isTest
public class D1_CaptchaControllerTest {
    /**
     * @description 
     */    
    @isTest 
    static void testValidateCaptchaToken() {
        List<D1_GoogleCaptchaSettings__mdt> configRecords = [SELECT isActive__c,Secret_Key__c,Site_Key__c,Captcha_API_URL__c,Captcha_Validation_URL__c
        FROM D1_GoogleCaptchaSettings__mdt
        LIMIT 1]; 
        Test.startTest();
        if(configRecords.isEmpty() || configRecords[0].isActive__c!=true){
            System.assert(new D1_CaptchaController().validateCaptchaToken(null) == true, 'In Active Captcha validation Failed');
        }else{
            Test.setMock(HttpCalloutMock.class, new CaptchaSuccessMock());
            System.assert(new D1_CaptchaController().validateCaptchaToken('1234567') == true, 'Success Captcha validation Failed');
            
            Test.setMock(HttpCalloutMock.class, new CaptchaFailMock());
            System.assert(new D1_CaptchaController().validateCaptchaToken('1234567') != true, 'Fail Captcha validation Failed');
        }
        Test.stopTest();  
    }
    
    class CaptchaSuccessMock implements HttpCalloutMock{
        /**
         * @description 
         * @param req 
         * @return  `HTTPResponse`
         */        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
    class CaptchaFailMock implements HttpCalloutMock{
        /**
         * @description 
         * @param req 
         * @return  `HTTPResponse`
         */        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":false}');
            res.setStatusCode(200);
            return res;
        }
    }
}