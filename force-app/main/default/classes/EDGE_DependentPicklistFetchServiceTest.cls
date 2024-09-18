/**********************************************************************
Name: EDGE_DependentPicklistFetchServiceTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                 DATE            DETAIL
1.0         Anuja Chattopadhyay    02/05/2019      Test Class for EDGE_DependentPicklistFetchService,
                                                   EDGE_DepentdentPicklistFetchWrapper and
                                                   EDGE_DependentPicklistFetchHelper
***********************************************************************/
@isTest
public class EDGE_DependentPicklistFetchServiceTest {
    /*******************************************************************
    Method  : validateDepdntPcklstFtchForChnnel
    Purpose : To Populate Dependent Picklist Based on Channel
    ********************************************************************/
    @isTest
    public static void validateDepdntPcklstFtchForChnnel(){
        List<EDGE_DepentdentPicklistFetchWrapper> wrapperList = new List<EDGE_DepentdentPicklistFetchWrapper>();
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.params.put('objType','Account');
        req.params.put('parentField','Global_Channel__c');
        req.params.put('chlField','Global_Sub_Channel__c');
        RestContext.request = req;
        RestContext.response = res;
        wrapperList = EDGE_DependentPicklistFetchService.doGet();
        Test.stopTest();
        System.assertEquals('Off Trade',wrapperList[0].parentValue,'off Trade should match');
    }
    /*******************************************************************
    Method  : validateDepdntPcklstFtchForSbChnnl
    Purpose : To Populate Dependent Picklist Based on Sub-Channel
    ********************************************************************/
    @isTest
    public static void validateDepdntPcklstFtchForSbChnnl(){
        List<EDGE_DepentdentPicklistFetchWrapper> wrapperList = new List<EDGE_DepentdentPicklistFetchWrapper>();
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.params.put('objType','Account');
        req.params.put('parentField','Global_Sub_Channel__c');
        req.params.put('chlField','Global_Segment__c');
        RestContext.request = req;
        RestContext.response = res;
        wrapperList = EDGE_DependentPicklistFetchService.doGet();
        Test.stopTest();
        System.assertEquals('Retailer',wrapperList[0].parentValue,'Retailer should match');
    }
    /*******************************************************************
    Method  : validateDepdntPcklstFtchForSgmnt
    Purpose : To Populate Dependent Picklist Based on Segment
    ********************************************************************/
    @isTest
    public static void validateDepdntPcklstFtchForSgmnt(){
        List<EDGE_DepentdentPicklistFetchWrapper> wrapperList = new List<EDGE_DepentdentPicklistFetchWrapper>();
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.httpMethod = 'GET';
        req.params.put('objType','Account');
        req.params.put('parentField','Global_Segment__c');
        req.params.put('chlField','Global_Sub_Segment__c');
        RestContext.request = req;
        RestContext.response = res;
        wrapperList = EDGE_DependentPicklistFetchService.doGet();
        Test.stopTest();
        System.assertEquals('Airline In-Flight Catalogue',wrapperList[0].parentValue,'Airline In-Flight Catalogue should match');
        
    }
}