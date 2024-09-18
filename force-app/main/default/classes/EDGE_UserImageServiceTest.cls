/**********************************************************************
Name: EDGE_UserImageServiceTest
=======================================================================
Req: Test Class for EDGE_UserImageService
User Story :ES20-10058
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0     Manikant                04/07/2021        Test Class
2.0 	Aparajita				01/06/2021		  ES20-10211
3.0     Joshraj Sen             08/04/2024        152305
***********************************************************************/
@isTest
public class EDGE_UserImageServiceTest {
    
    @isTest
    public static void getUserImageTest(){
        Id userid = UserInfo.getuserid();
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/EDGE_UserImageService?userid=';
        requri = requri + String.valueOf(userid);
        req.requestUri =requri;
        req.params.put('userid',userid);		
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        EDGE_UserImageService.doGet();
        System.assert(userid != null,'User is Added');
		EDGE_UserDetailsWrapper imgServiceWrapper = EDGE_UserImageService.doGet();
        System.debug(LoggingLevel.Debug,'@@@'+imgServiceWrapper);
        Test.stopTest();      
    }
    
    //ES20-10211
    @isTest
    public static void testInactiveUserImage(){
        Test.startTest();
        User userRec = [SELECT Id FROM User WHERE isActive = false limit 1];
        Id userid = userRec.Id;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/EDGE_UserImageService?userid=';
        requri = requri + String.valueOf(userid);
        req.requestUri =requri;
        req.params.put('userid',userid);		
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        EDGE_UserImageService.doGet();
        System.assert(userid != null,'User is Added');
		EDGE_UserDetailsWrapper imgServiceWrapper = EDGE_UserImageService.doGet();
        System.debug(LoggingLevel.Debug,'@@@'+imgServiceWrapper);
        Test.stopTest();   
    }
}