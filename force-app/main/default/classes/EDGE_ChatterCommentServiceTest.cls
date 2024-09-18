/**********************************************************************
Name: EDGE_ChatterCommentServiceTest

=======================================================================
Req: This is the test class for EDGE_ChatterCommentServiceTest,EDGE_ChatterCommentController

=======================================================================
VERSION   AUTHOR              DATE            DETAIL
1.0       Divya Bansal        16/03/2021      ES20-9878 
***********************************************************************/
@isTest
public class EDGE_ChatterCommentServiceTest {
    public static User salesRep;
    public static User salesMgr;
    public static User actSplst;
    public static Account outlet;
    public static FeedItem feed;
    @isTest
    public static void testChatterCommentService(){
        
        Test.startTest();
        createData();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/EDGE_ChatterCommentService?feedid=';
        requri = requri + String.valueOf(feed.Id);
        req.requestUri =requri;
        req.params.put('feedid',feed.Id);		
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        EDGE_ChatterCommentService.doGet();
        EDGE_ChatterCommentWrapper chatterCommentWrapList = EDGE_ChatterCommentService.doGet();
        system.assert(chatterCommentWrapList != null,'chatterCommentWrapList should not be null');
        Test.stopTest();
    }
    
    public static void createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Business_Role__c businessRole = EDGE_UtilityTestClass.getBusinessRole();
        businessRole.Country__c = countryId;
        businessRole.Global_Equivalent__c = 'Sales Rep';
        insert businessRole;
        
        salesRep = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.Business_Role_ID__c = businessRole.Id;
        salesRep.Business_Role__c = 'Test Role' ;
        insert salesRep;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'pickupOption should not be null');
        
        outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Outlet_Member__c outMem = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, salesRep.Id, 'Primary'); 
        insert outMem;
        
        //Create Document
        ContentVersion cv = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        cv.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        cv.Content_Type__c = 'Direct Customer';
        cv.Title = 'Test.jpeg';
        insert cv;
        
        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals(cvList.size(), 1,'CvList size should match');
        
        //Get Content Documents        
        
        feed = new FeedItem(ParentId = outlet.Id, Body = 'Test Body',RelatedRecordId=cvList[0].id);
        insert feed;
        
        FeedComment feedCmntRec = new FeedComment();
        feedCmntRec.CommentBody = 'test comment b';
        feedCmntRec.FeedItemId = feed.id;
        feedCmntRec.IsRichText = false;
        insert feedCmntRec;
        System.assert(feedCmntRec.id != null,'feedCmntRec should not be null');
    }
}