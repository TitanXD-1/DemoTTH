/**
 * @Name: D1_RewardControllerTest
 * 
 * Purpose: Test class for D1_RewardController
 * 
 * History                                                            
 * -                                                           
 * VERSION	AUTHOR     DATE             DETAIL
 * 1.0				   23/11/2022		Initial Development 
 **/

/**
 * Note - We are annotating the methods with seeAllData set to true as the controller class queries on Survey object.
 * As of 2022, Salesforce doesn't allow us to perform any DML operations on Survey object.
 */

@isTest
public class D1_RewardControllerTest {
    
    private static String geoId;
    private static String communityId;
    private static String survInvId;
   
    /**
     * @Name : testGetNewRewards
	 * @description : This method is used to test the getNewRewards() method of the D1_RewardController class
	 */
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seeAllData = true)
    public static void testGetNewRewards(){        
        createData();
        Test.startTest();
        
        User currentUser = [SELECT Id, LanguageLocaleKey, Effective_Account_Id__c, ContactId FROM User WHERE username ='testclassextuser1@testdomain.com' AND isActive = TRUE LIMIT 1];
        
        List<D1_RewardController.RewardWrapper> newRewards = new List<D1_RewardController.RewardWrapper>();
        newRewards = D1_RewardController.getNewRewards(currentUser.Id);
        
        System.assert(newRewards != null, 'NEW REWARD DOESNOT EXISTS');
        Assert.isTrue(newRewards != null, 'NEW REWARD DOESNOT EXISTS');
      
        Test.stopTest();  
    }
    
    /**
     * @Name : testGetPastRewards
	 * @description : This method is used to test the getPastRewards() method of the D1_RewardController class
	 */
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seeAllData = true)
    public static void testGetPastRewards(){
        
        createData();
        
        Test.startTest();
        
        User currentUser = [SELECT Id, LanguageLocaleKey, Effective_Account_Id__c, ContactId FROM User WHERE username ='testclassextuser1@testdomain.com' AND isActive = TRUE LIMIT 1];
		createSurveySubject(survInvId, currentUser.Effective_Account_Id__c);
        
        List<D1_RewardController.RewardWrapper> past1MonthRewards = new List<D1_RewardController.RewardWrapper>();
        List<D1_RewardController.RewardWrapper> past6MonthRewards = new List<D1_RewardController.RewardWrapper>();
        List<D1_RewardController.RewardWrapper> past1YearRewards = new List<D1_RewardController.RewardWrapper>();
        List<D1_RewardController.RewardWrapper> allPastRewards = new List<D1_RewardController.RewardWrapper>();
        
        //Get rewards for the past 1 month
        past1MonthRewards = D1_RewardController.getPastRewards(currentUser.Id,'past1Month');
        
        //Get rewards for the past 6 months
        past6MonthRewards = D1_RewardController.getPastRewards(currentUser.Id,'past6Month');
        
        //Get rewards for the past 1 year
        past1YearRewards = D1_RewardController.getPastRewards(currentUser.Id,'past1Year');
        
        //Get all past rewards
        allPastRewards = D1_RewardController.getPastRewards(currentUser.Id,'all');
        
        System.assert(allPastRewards != null, 'PAST REWARD DOESNOT EXIST');
        Assert.isTrue(allPastRewards != null, 'PAST REWARD DOESNOT EXIST');

        Test.stopTest();  
    }
    
    /**
     * @Name : testGetPastRewardCount
	 * @description : This method is used to test the getPastRewardCount() method of the D1_RewardController class
	 */
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seeAllData = true)
    public static void testGetPastRewardCount(){
        
        createData();
        
        Test.startTest();
        
        User currentUser = [SELECT Id, LanguageLocaleKey, Effective_Account_Id__c, ContactId FROM User WHERE username ='testclassextuser1@testdomain.com' AND isActive = TRUE LIMIT 1];
        createSurveySubject(survInvId, currentUser.Effective_Account_Id__c);
        
        D1_RewardController.RewardFilterWrapper rewardAggregateCount=  D1_RewardController.getPastRewardCount(currentUser.Id);

        System.assert(rewardAggregateCount != null, 'PAST REWARD COUNT FAILED');
        Assert.isTrue(rewardAggregateCount != null, 'PAST REWARD COUNT FAILED');
        
        Test.stopTest();
    }
    
    /**
     * @Name : createData
	 * @description : This method is used to create test data for the D1_RewardControllerTest class
	 */
    public static void createData(){    
        Id countryId;
        /*To handle validation error against multiple 'Global' Geography records when opening up access to org data in test class*/
        List<Geography__c> geoList = new List<Geography__c>();
        geoList = [SELECT Id FROM Geography__c WHERE Code__c = 'GB' AND RecordType.Name = 'Country'];
        if(geoList.isEmpty()){
            countryId = D1_TestDataUtility.setupCountry('GB');
        }
        else{
            countryId = geoList[0].Id;
        }     
        geoId = countryId;
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id =: geoId];
        
        D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(country);
        d1Setting.Language__c = 'es';
        insert d1Setting;      
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','TestGold [GB]');
        insert pickupOption;
        
        Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
        Geography__c hub =[SELECT Id FROM Geography__c WHERE RecordType.name='Hub' and name ='Great Britain' limit 1];
        Geography__c region =[SELECT Id FROM Geography__c WHERE RecordType.name='Region'and name ='London' limit 1];
        Geography__c area =[SELECT Id FROM Geography__c WHERE RecordType.name='Area' and name ='Great Britain' limit 1];
        Geography__c market =[SELECT Id FROM Geography__c WHERE RecordType.name='Market' and name ='Europe and Turkey' limit 1];
        Geography__c cluster =[SELECT Id FROM Geography__c WHERE RecordType.name='Cluster' and name ='Great Britain' limit 1];
        testoutlet.Country__c = geoId;
        testoutlet.Hub__c = hub.Id;
        testoutlet.Region__c=region.Id;
        testoutlet.Area__c=area.Id;
        testoutlet.Market__c = market.Id;
        testoutlet.Cluster__c= cluster.Id;
        testoutlet.D1_EDGE_Customer__c =true;
        testoutlet.Name='testcart Outlet ';
        testoutlet.Salesforce_Delivery_Days_Packaged_Good__c='1;2;3;4;5;6;7';
        testoutlet.Salesforce_Delivery_Days_Keg__c='1;2;3;4;5;6;7';
        testoutlet.Delivery_Pattern__c='0';
        testoutlet.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        insert testoutlet;
        
        Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
        insert primaryContact;
        
        List<AccountContactRelation> relations = [Select id,D1_Active__c from AccountContactRelation WHERE AccountId =: testoutlet.Id];
        for(AccountContactRelation acr: relations){
            acr.D1_Active__c = true;
            acr.D1_Roles__c = 'Manage Partner Plus';
            acr.D1_User_Role__c = 'Primary';
        }
        update relations;
        
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1Setting.Id);
        insert d1UserType;
        
        User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
        externalUser1.Username = 'testclassextuser1@testdomain.com';
        externalUser1.Email='testclassextuser1@testdomain.com';
        externalUser1.CommunityNickname = 'Mania.Test1';
        externalUser1.Available_Countries__c = 'GB';
        externalUser1.ContactId = primaryContact.Id;
        externalUser1.Effective_Account_Id__c = primaryContact.AccountId;
        externalUser1.isActive = true;
        externalUser1.D1_User_Type_Id__c = d1UserType.Id;
        externalUser1.LanguageLocaleKey ='en_GB';
        insert externalUser1;
        
        communityId = [SELECT ID FROM Network WHERE Name = 'DiageoOne' LIMIT 1].ID;
        
        /*Survey and related object(s) test data setup*/
        
        Survey surv = new Survey();
        surv = [SELECT Id FROM Survey LIMIT 1];
        survInvId = createSurveyInvitation(surv.Id , externalUser1.ContactId);
    }
    
    /**
     * @Name : createSurveyInvitation
	 * @description : This method is used to create survey invitation record for D1_RewardControllerTest class
	 */
    private static String createSurveyInvitation(String surveyId, String participantId) {
        
        SurveyInvitation surveyInv = new SurveyInvitation();
        try{
            surveyInv.Name = 'TestSurveyInvitation'; 
            surveyInv.ParticipantId = participantId;
            surveyInv.CommunityId = communityId; 
            surveyInv.OptionsAllowGuestUserResponse = true;
            surveyInv.SurveyId = surveyId;  
            surveyInv.Applicable_to__c = 'Primary User';
            surveyInv.Geography__c = geoId; 
            surveyInv.Reward_Description__c = 'TestClassReward';
            surveyInv.Reward_Type__c = 'Gift Box';
            surveyInv.End_Date__c = System.today()+1;
            
            upsert surveyInv;
        }catch(dmlexception e){
            System.debug(LoggingLevel.ERROR, e);
        } 
        return surveyInv.Id;
    }
    
    /**
     * @Name : createSurveySubject
	 * @description : This method is used to create survey subject record for D1_RewardControllerTest class
	 */
    private static void createSurveySubject(String invitationId, String associatedRecordId) {
        SurveySubject subj = new SurveySubject();
        subj.Name = 'TestSurveySubject';
        subj.ParentId = invitationId; 
        subj.SubjectId = associatedRecordId;
        
        insert subj;
    }
}