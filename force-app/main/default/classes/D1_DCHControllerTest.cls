/**
 * @name : D1_DCHControllerTest
 * @description : Test Class for D1_DCHController
 * @history :
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           01/09/2022      Initial Development (NCP-5611)
 */
@isTest
public with sharing class D1_DCHControllerTest {

    @testSetup
    static void dataSetup(){
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        
        D1_Event__c event = D1_TestDataUtility.getEvent();
        D1_Brand__c brand = D1_TestDataUtility.getBrand();

        //Insert Content Assignment
        List<D1_Content_Assignment__c> caList = new List<D1_Content_Assignment__c>();
        D1_Content_Assignment__c ca1 = D1_TestDataUtility.getContentAssignment(event.Id, null, null, 'Christmas'); //Insert Event
        D1_Content_Assignment__c ca2 = D1_TestDataUtility.getContentAssignment(null, brand.Id, null, 'Ciroc'); //Insert Brand

        caList.add(ca1);
        caList.add(ca2);

        insert caList;

        //Insert Download Folder Item
        for(D1_Content_Assignment__c ca : [SELECT Id, Folder_Content_Document_Id__c, Folder_Content_version_Id__c FROM D1_Content_Assignment__c]){
            D1_Download_Folder_Item__c dFolderItem;
            dFolderItem = D1_TestDataUtility.getDownloadFolderItem(ca);
        }
    }

    @isTest static void getEventAssetDetailsTest(){
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetDCHAssetResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        //Get Content Assignent
        List<D1_Content_Assignment__c> caList = [SELECT Id FROM D1_Content_Assignment__c];
        // Call method to test
        Test.startTest();
        D1_DCHController.DCHResponseWrapper dchResponseWrapper = new D1_DCHController.DCHResponseWrapper();
        try{
             dchResponseWrapper = D1_DCHController.getAssets(caList[0].Id, 0, new List<String>(), '');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        System.assertNotEquals(null, dchResponseWrapper, 'The callout returned a null response.');
        
        Test.stopTest();

    }
    
    @isTest static void getBrandAssetDetailsTest(){
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetDCHAssetResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        //Get Content Assignent
        List<D1_Content_Assignment__c> caList = [SELECT Id FROM D1_Content_Assignment__c];
        // Call method to test
        Test.startTest();
        D1_DCHController.DCHResponseWrapper dchResponseWrapper = new D1_DCHController.DCHResponseWrapper();
        try{
            dchResponseWrapper = D1_DCHController.getAssets(caList[1].Id, 0, new List<String>(), '');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
        System.assertNotEquals(null, dchResponseWrapper, 'The callout returned a null response.');
        
        Test.stopTest();
    }

    @isTest static void getFolderItemAssetDetailsTest(){
        // Create the mock response based on a static resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetDCHAssetResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        
        //Get Content Assignent
        List<D1_Download_Folder_Item__c> folderItemList = [SELECT Id FROM D1_Download_Folder_Item__c];
        // Call method to test
        Test.startTest();
        D1_DCHController.DCHResponseWrapper dchResponseWrapper = new D1_DCHController.DCHResponseWrapper();
        try{
            dchResponseWrapper = D1_DCHController.getAssets(folderItemList[1].Id, 0, new List<String>(), '');
        }catch(Exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }
        System.assertNotEquals(null, dchResponseWrapper, 'The callout returned a null response.');
        
        Test.stopTest();
    }
}