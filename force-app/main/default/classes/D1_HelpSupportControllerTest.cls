/*
* @name: D1_HelpSupportControllerTest
* @discription: Test Class for D1_HelpSupportController & D1_HelpSupportControllerExtnsn
* @history
* VERSION       AUTHOR              DATE            DETAIL
* 1.0           Ayush               20/10/2020      CreateCase
* 2.0           Dipanjan Das        20/10/2020      CreateCase
* 3.0           Saurav Paul         20/10/2020      CreateCase
* 4.0           Sayan               30/06/2021      Test Class Refractor [NCP-3803]
* 5.0           Kapil Baliyan       14/04/2022      NCP-6489
*/
@isTest
public class D1_HelpSupportControllerTest {
    private static final Id DIAGEOONECASERECTYPE = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
    /**
    * @name : getCaseTopicArticles
    * @description : This method is used to test all methods related to Topic/SubTopic/Article
    */
    @isTest
    public static void getCaseTopicArticles(){
        Knowledge__kav kw1 = [SELECT Id FROM  Knowledge__kav WHERE UrlName = 'Sample'];
        Knowledge__kav kw2 = [SELECT Id FROM  Knowledge__kav WHERE UrlName = 'Sample1'];
        
		User admUser = [SELECT Id, isActive, D1_User_Type__c, D1_User_Type_Id__c FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        admUser.isActive = true;
        admUser.Available_Countries__c = 'GB';
        admUser.LanguageLocaleKey='en_GB';
        admUser.D1_User_Type_Id__c  = [SELECT Id FROM D1_User_Type__c WHERE User_Type__c = 'Outlet/Retailers' LIMIT 1].Id;
        admUser.D1_User_Type__c = 'Outlet/Retailers'; 
        update admUser;
        
        List<D1_HelpSupportController.TopicWrapper> topicList = new List<D1_HelpSupportController.TopicWrapper>();

        Test.startTest();
            system.runAs(admUser){
                D1_HelpSupportController.caseTypeAndSubTypeWrp newTypeSubtypeWrap = D1_HelpSupportController.getTopicsSubTopicsNew();//NCP-8210
                topicList = newTypeSubtypeWrap.listOftypeSubtypeMap; 
                D1_HelpSupportController.getLinks(kw1.Id, 'Issue_Placing_Order_General');
                D1_HelpSupportController.getLinks(kw2.Id, 'General');
                
                D1_HelpSupportController.articleName(kw1.Id);
                D1_HelpSupportController.articleName(kw2.Id);
                
                D1_HelpSupportController.getPickUpOptionsList();
                D1_HelpSupportController.getPickUpOptionsRecord('Others');
            }
        Test.stopTest();
        
        System.assert(topicList != NULL, 'LIST DOESNOT EXIST');
        Assert.isNotNull(topicList, 'LIST DOESNOT EXIST');
    }
    
    /**
    * @name : getCaseListTest
    * @description : This method is used to test all methods related to case data 
    */
    @isTest
    public static void getCaseListTest(){
        List<Case> caseList = [SELECT Id FROM Case WHERE RecordTypeId =: DIAGEOONECASERECTYPE];        
        List<Case> caseListItems = new List<Case>();
        
        Test.startTest();
            caseListItems = D1_HelpSupportController.getCaseList();
            for(Case cs : caseList){
                caseListItems.add(D1_HelpSupportControllerExtnsn.getCreatedCase(cs.Id));
                D1_HelpSupportController.getCaseDetail(cs.id);
                D1_HelpSupportControllerExtnsn.getCaseFeeds(cs.id);
            }
        Test.stopTest();
        
        System.assert(caseListItems.size() > 0, 'CASELIST DOESNOT EXIST');
        Assert.isTrue(caseListItems.size() > 0, 'CASELIST DOESNOT EXIST');
    }
    
    /**
    * @name : createCaseAttachmentTest
    * @description : This method is used to test all methods related to attachments
    */
    @isTest
    public static void createCaseAttachmentTest(){
        List<Case> caseList = [SELECT Id FROM Case WHERE RecordTypeId =: DIAGEOONECASERECTYPE]; 
        ContentDocument documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE LatestPublishedVersion.Title = 'Case Detail' LIMIT 1];       
        Test.startTest();
            D1_HelpSupportController.createAttachment(caseList[0].id, documents.id);
            D1_HelpSupportControllerExtnsn.createAttachment(caseList[2].id, documents.LatestPublishedVersionId);
            D1_HelpSupportControllerExtnsn.createAttachment(caseList[3].id, documents.LatestPublishedVersionId);
        	D1_HelpSupportController.removeContentDocument(documents.Id);
        Test.stopTest();
        
        List<ContentDocument> cdList = new List<ContentDocument>();
        cdList = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersion.Title = 'Case Detail'];
        System.assert(cdList.size() == 0, 'DOC NOT REMOVED');
        Assert.isTrue(cdList.size() == 0, 'DOC NOT REMOVED');
    }
    
    /**
    * @name : testCreateCase
    * @description : This method is used to test all generic methods
    */
    @isTest
    public static void testCreateCase() {
        User externalUser = [SELECT Id FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        Case caseRec = [SELECT Id FROM Case WHERE D1_Subject__c = null LIMIT 1];
        contactpointAddress cpa = [SELECT Id FROM contactpointAddress LIMIT 1];
        
        D1_HelpSupportControllerExtnsn.ContactPointAddressWrapper cpAddressWrapper;
        Map<String,String> testMap = new Map<String,String>();
        Map<String,Boolean> testMaps = new Map<String,Boolean>();
        D1_User_Type__c userType;
        Id caseIds;
        
        Test.startTest();
            System.runAs(externalUser){
                D1_HelpSupportControllerExtnsn.CaseWrapper wrapObj = new D1_HelpSupportControllerExtnsn.CaseWrapper();
                wrapObj.topic = 'General';
                wrapObj.subject = 'I Have A Complaint';
                wrapObj.description = 'Create Test case';
                wrapObj.selectedDeliverToAddressId = cpa.Id;
                caseIds = D1_HelpSupportControllerExtnsn.createCase(wrapObj, False);
                
                cpAddressWrapper = D1_HelpSupportControllerExtnsn.getOutletDetail(caseIds);
                testMap = D1_HelpSupportControllerExtnsn.getSubjectBlockMap();
                testMaps = D1_HelpSupportControllerExtnsn.getSubjectVisibilityMap();
                
                userType = D1_HelpSupportController.getUserTypeInfo();
                D1_HelpSupportController.getCaseDetailBasedOnMapping(caseRec.Id);
                D1_HelpSupportController.createCaseFeed(caseRec.Id,'',false);
                D1_HelpSupportController.createCaseFeed(caseRec.Id,'',true);
                D1_HelpSupportControllerExtnsn.getReasonForCancellation(null);
            }
        Test.stopTest();
        
        System.assert(caseIds!= null, 'CASE NOT CREATED');
        Assert.isNotNull(caseIds, 'CASE NOT CREATED');
        
        System.assert(cpAddressWrapper != null, 'NO OUTLET DETAILS');
        Assert.isNotNull(cpAddressWrapper, 'NO OUTLET DETAILS');
        
        System.assert(testMap.size() > 0, 'NO SUBJECT MAP');
        Assert.isTrue(testMap.size() > 0, 'NO SUBJECT MAP');
        
        System.assert(testMaps.size() > 0, 'NO SUBJECT VISIBILITY');
        Assert.isTrue(testMaps.size() > 0, 'NO SUBJECT VISIBILITY');
        
        System.assert(userType != null, 'NO USER TYPE DETAILS');
        Assert.isNotNull(userType, 'NO USER TYPE DETAILS');
    }
    
    /**
    * @name : caseTest
    * @description : This method is used to test feed related methods
    */
    @isTest
    public static void caseTest(){
        Case caseRec = [SELECT Id FROM Case WHERE D1_Subject__c = null LIMIT 1];
        Id feedId = [SELECT Id FROM feedItem LIMIT 1].Id;
        List<ContentDocument> documents = [SELECT Id  FROM ContentDocument WHERE LatestPublishedVersion.Title = 'Penguins'];
        Id cvId = [SELECT Id FROM ContentVersion WHERE Title != 'Case Detail' LIMIT 1].Id;

        List<D1_HelpSupportControllerExtnsn.FeedItemWrapper> feedItemList = new List<D1_HelpSupportControllerExtnsn.FeedItemWrapper>();
        DateTime startTime = dateTime.now();
        FeedItem feedRec;
        
        Test.startTest();
            feedRec = D1_HelpSupportController.createCaseFeed(caseRec.id , 'Test Case Feed' , True);
        	D1_HelpSupportController.createFeedAttachment(feedId, documents[0].id, caseRec.id);
            feedItemList = D1_HelpSupportControllerExtnsn.getCaseFeeds(caseRec.id);

            D1_HelpSupportControllerExtnsn.getElapsedTime(startTime);
        	D1_HelpSupportControllerExtnsn.getContentDocumentURL(caseRec.id, new List<String>{cvId});
            D1_HelpSupportControllerExtnsn.checkContentDocumentSize(documents[0].id);
        	D1_HelpSupportControllerExtnsn.checkFileSize(documents[0].id);
        	D1_HelpSupportControllerExtnsn.removeFile(documents[0].id);
        
        Test.stopTest();
        
        System.assert(feedRec != NULL, 'NO FEED CREATED');
        System.assert(feedItemList != NULL, 'NO CASE FEEDS');
        Assert.isTrue(feedRec != NULL, 'NO FEED CREATED');
    }

    @isTest
    public static void createCaseTest(){
        User externalUser = [SELECT Id, AccountId, ContactId, Email FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        ContactPointAddress cpa = [SELECT Id FROM contactpointAddress LIMIT 1];
        D1_HelpSupportControllerExtnsn.CaseWrapperr caseWrapper = new D1_HelpSupportControllerExtnsn.CaseWrapperr();
        caseWrapper.caseType = 'General';
        caseWrapper.caseSubType = 'I Have A Complaint';
        caseWrapper.caseDescription = 'Test Case';
        caseWrapper.accountId = externalUser.AccountId;
        caseWrapper.contactId = externalUser.ContactId;
        caseWrapper.email = externalUser.Email;
        caseWrapper.deliverToAddress = null;

        System.runAs(externalUser){
            Test.startTest();
                D1_HelpSupportControllerExtnsn.createCasee(caseWrapper, false, null);
            Test.stopTest();
        }
    }
    
    /**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        //Set up Geography & networkId;
        Id countryId = D1_TestDataUtility.setupCountry('GB');        
        String networkId = [SELECT Id FROM Network WHERE Name = 'DiageoOne'].Id;
        
        Geography__c country = new Geography__c(Id = countryId);
        country.isDiageoOneEnabled__c = True;
        upsert country;
        
        //Add Contact point Address
        contactpointAddress cpa = D1_TestDataUtility.insertContactPointAddress();
        cpa.Source__c = 'Diageo One';
        cpa.Account_Number__c = '987867';
        insert cpa;
        
        //Set up Customer and User
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Test');
        pickupOption.Name = 'Gold[GB]';
        insert pickupOption;
        
        Account testoutlet = D1_TestDataUtility.getD1Customer();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert testoutlet;
        
        D1_TestDataUtility.setUpExternalUser(testoutlet, 'Outlet/Retailers');
        
        //Create Knowledge__kav with UrlName as parameter.
        List<Knowledge__kav> knwList = new List<Knowledge__kav>{D1_TestDataUtility.createKnowledgeKav('Sample','My Financials','Account Balance'), 
                                                                D1_TestDataUtility.createKnowledgeKav('Sample1','General','I Have A Question')};
        insert knwList;     
        
        Knowledge__DataCategorySelection newArtDC = new Knowledge__DataCategorySelection();
        newArtDC.DataCategoryGroupName = 'Market';//'Topics'; changed for NCP-8210
        newArtDC.DataCategoryName = 'GB';//Issue_Placing_Order_General'; changed for NCP-8210
        newArtDC.ParentId = knwList[1].id;
        insert newArtDC;
		
        
        string obj1 = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id =: knwList[1].Id].KnowledgeArticleId;            
        KbManagement.PublishingService.publishArticle(obj1, true);
        
        //Create Case (with parameters RecordTypeId, Type, D1_Subject__c, Description and Status respectively) and Content Version For getCaseList().
        Pick_Up_Options__c eqpIssue = D1_TestDataUtility.getPickUpOption(countryId, 'Equipment Issue', '', 'Equipment Issue [ES]');
        eqpIssue.Type__c = 'Equipment Issue';
        insert eqpIssue;
        
        List<Case> caseList = new List<Case>();
        caseList.add(D1_TestDataUtility.createCase(DIAGEOONECASERECTYPE, 'Account Management', 'My Profile', 'Test Comments', 'Open'));
        caseList.add(D1_TestDataUtility.createCase(DIAGEOONECASERECTYPE, 'General', 'I Have A Complaint', 'Test Comments', 'Open'));
        caseList.add(D1_TestDataUtility.createCase(DIAGEOONECASERECTYPE, 'Quality Issues', 'My Equipment', 'Test Comments', 'Open'));
        caseList.add(D1_TestDataUtility.createCase(DIAGEOONECASERECTYPE,'','','Test Case','Open'));
        
        caseList[0].Origin = 'Diageo One';
        caseList[2].D1_Equipment_Issue__c = eqpIssue.Id;
        caseList[3].AccountId = testoutlet.id;
        insert caseList;
        
        //Add content versions
        List<ContentVersion> cvList = new List<ContentVersion>();
        ContentVersion contentVersion1 = D1_TestDataUtility.getContentVersion();
        contentVersion1.Title = 'Case Detail';      
        cvList.add(contentVersion1);
        
        ContentVersion contentVersion2 = D1_TestDataUtility.getContentVersion();
        contentVersion2.Title = 'Penguins';
        contentVersion2.PathOnClient = 'Penguins.jpg';
        cvList.add(contentVersion2);
        
        ContentVersion contentVersion3 = D1_TestDataUtility.getContentVersion();
        contentVersion3.Title = 'Penguins1';
        contentVersion3.PathOnClient = 'Penguins1.jpg';
        contentVersion3.VersionData = Blob.valueOf('Test Content1');
        cvList.add(contentVersion3);
        insert cvList;
        
        //Create FeedItem with parameters parentid and RelatedRecordId.
        FeedItem feed = D1_TestDataUtility.createFeed(caseList[3].id, cvList[2].id);
        feed.Visibility = 'AllUsers';
        insert feed;
    }
}