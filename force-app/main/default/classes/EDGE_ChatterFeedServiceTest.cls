/**********************************************************************
Name: EDGE_ChatterFeedServiceTest

=======================================================================
Req: This is the test class for EDGE_ChatterFeedServiceTest,EDGE_ChatterFeedController

=======================================================================
VERSION   AUTHOR              DATE            DETAIL
1.0       Juned Khan          05/02/2021       ES20-9721 
***********************************************************************/
@isTest
public class EDGE_ChatterFeedServiceTest {
    public static User salesRep;
	public static Account outlet;
    @isTest
    public static void testChatterFeedService(){
        
        Test.startTest();
        createData();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String requri='services/apexrest/EDGE_ChatterFeedService?outletid=';
       // requri = requri+ String.valueOf(salesRep.Id);
		requri = requri + String.valueOf(outlet.Id);
        req.requestUri =requri;
		req.params.put('outletid',outlet.Id);		
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        EDGE_ChatterFeedService.doGet();
        EDGE_ChatterFeedWrapper chatterFeedWrapList = EDGE_ChatterFeedService.doGet();
        system.assert(chatterFeedWrapList != null,'chatterFeedWrapList should not be null');
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
        
        Market_Cycle__c  marketCycle=EDGE_UtilityTestClass.getMarketCycle(countryId);
        marketCycle.Start_Date__c = Date.Today();
        marketCycle.End_Date__c = Date.Today().addDays(30);
        marketCycle.Geography__c = countryId;
        insert marketCycle;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Outlet_Member__c outMem = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, salesRep.Id, 'Primary'); 
        insert outMem;
        
        Market_Setting__c marketSettingRec = EDGE_UtilityTestClass.getMarketSetting(countryId); 
        marketSettingRec.Number_of_Notes_per_Outlet__c = 2;
        insert marketSettingRec;
          
        //Create Document
        ContentVersion cv = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        cv.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Direct Customer').getRecordTypeId();
        cv.Content_Type__c = 'Direct Customer';
        cv.Title = 'Test.jpeg';
        insert cv;
 
        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals(cvList.size(), 1,'cvList.size should match');
         
        //Get Content Documents
        List<ContentDocument> cdList = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(cdList.size(), 1,'cdList.size should match');
        
        //Create Related Feed Item Record
		FeedItem fi = new FeedItem(ParentId = outlet.Id, Body = 'Test Body',RelatedRecordId=cvList[0].id);
		insert fi;
		
		//Check Feed Comment Parent Id
		//System.assertEquals(objFC.ParentId, outlet.Id);
        
    }
}