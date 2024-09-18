/**
 * @name : D1_DCHAssetController
 * @description : Test Class for D1_DCHAssetController Class
 * @history :
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           01/09/2022      Initial Development (NCP-5613)
 */
@isTest
 public with sharing class D1_DCHAssetControllerTest {
    
    @isTest static void getAssetDetailsTest(){
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetAssetByIdResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Call method to test
        String response = D1_DCHAssetController.getAssetDetails('11141085');

        System.assertNotEquals(null, response, 'The callout returned a null response.');
    }
}