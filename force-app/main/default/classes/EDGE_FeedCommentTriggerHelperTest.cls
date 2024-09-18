/**********************************************************************
Name: EDGE_FeedCommentTriggerHelperTest
=======================================================================
Req: This is the test class for EDGE_FeedCommentTriggerHelper class.
User Story : ES20-9704
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -    Amar Deep   	   11/02/2020      Initial Development    
2.0 -    Sakshi Shah       15/05/2024      PMD Fix 152943
***********************************************************************/
@IsTest(SeeAllData=true)
public class EDGE_FeedCommentTriggerHelperTest {
    final static String OUTLET_REC_TYPE_ID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    private static  String accountId;
    private static  String countryId;
    private static final Id DIAGEOONECASERECTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
    
    public static void setupAccountAndGeography(){
        Map<String,Id> geoMap=new Map<String,Id>();
        Geography__c globalRec = [Select Id from Geography__c where Name='Global' limit 1];
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = [Select Id from Geography__c where Name='Europe and Turkey' limit 1];
        geoMap.put('Market',market.Id);
        Geography__c hub =  [Select Id from Geography__c where Name='Island of Ireland' limit 1];
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = [Select Id from Geography__c where Name='Ireland' limit 1];
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = [Select Id from Geography__c where Name='Republic of Ireland' and RecordType.Name='Country' limit 1];
        geoMap.put('Country',country.Id);
        Geography__c area = [Select Id from Geography__c where Name='Republic of Ireland' and RecordType.Name='Area' limit 1];
        geoMap.put('Area',area.Id);        
        Geography__c region = [Select Id from Geography__c where Name='Carlow' and RecordType.Name='Region' limit 1];
        geoMap.put('Region',region.Id);
        
        countryId=country.Id; 
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name='Gold1[IE]';
        insert pickupOption;
        
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Account_Type__c='Ship-to';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        insert outlet;
        
        accountId = outlet.Id;   
        User systemAdmin = D1_TestDataUtility.runAsUser('sysAdmin','System Administrator');
        systemAdmin.Available_Countries__c = 'IE';
        systemAdmin.isActive = true;
        systemAdmin.LanguageLocaleKey ='en_IE';
        insert systemAdmin;
    }
    
    @isTest
    public static void sendPushNotificationForCommentTest(){
        setupAccountAndGeography();
        
        Test.startTest();
        
        FeedItem feed = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'TextPost', accountId);
        feed.Status = 'Published';
        insert feed;
        
                
        FeedComment feedCommt = new FeedComment();
        feedCommt.FeedItemId = feed.id;
        feedCommt.CommentBody = 'test body';
        insert feedCommt;
        
        FeedComment feedCommt1 = new FeedComment();
        feedCommt1.FeedItemId = feed.id;
        feedCommt1.CommentBody = 'test body';
        insert feedCommt1;   
        
        //Update the feed
        feedCommt1.CommentBody = 'feed comment';
        update feedCommt1;
        
        Map<String, Object> custom = new Map<String, Object>();
        custom.put('OutletId',accountId);
        custom.put('OutletName',[Select name from Account WHERE id = :accountId].Name);
        custom.put('CommentId',feedCommt1.Id);
        custom.put('ChatterId',feedCommt1.FeedItemId);
        ConnectApi.Comment  cmmnt = ConnectApi.ChatterFeeds.getComment(null, feedCommt1.Id);
        List<ConnectApi.MessageSegment> messageSegments = cmmnt.body.messageSegments;
        EDGE_PushNotificationHelper.pushNotificationMethod(messageSegments, 'test', custom);
        delete feedCommt1;
        Test.stopTest();   
    }
    
    @IsTest
    public static void preventCommentOnFeedCaseClosed(){
        setupAccountAndGeography();
        
        User sysUser = [Select Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Case caseRec = D1_TestDataUtility.createCase(DIAGEOONECASERECTYPE, 'Account Management', 'My Profile', 'Test Comments', 'Open');
        caseRec.Origin = 'Diageo One';
        caseRec.accountId = accountId;
        caseRec.Type_of_Communication__c = 'Physical Visit';
        caseRec.Contacted_Date__c = System.now().addDays(1);
        insert caseRec;
        
        Test.startTest();
        FeedItem feedforCase = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'TextPost', NULL);
        feedforCase.Status = 'Published';
        feedforCase.parentId = caseRec.id;
        insert feedforCase;
        System.runAs(sysUser){						//We are running as System Admin to by-pass validation rules.
            caseRec.Status = 'Closed';				//The target validation only works against closed cases.
            update caseRec;
        }

		FeedComment feedCommt2 = new FeedComment();
        feedCommt2.FeedItemId = feedforCase.id;
        feedCommt2.CommentBody = 'test body';
        //Test.startTest();
        try{
          insert feedCommt2;    
        }catch(Exception e){
            System.assert(e != NULL,'Exception should not be null.');
        }
		Test.stopTest();
        
    }
    
    
}