/**
 * @name : D1_PartnerPlusPopUpControllerTest
 * @description : Test class for D1_PartnerPlusPopUpController
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0         Pratap Sen      	16/11/2022        NCP-7427
**/
@isTest
public class D1_PartnerPlusPopUpControllerTest {
    /**
    * @name : testUpdateJoiningInfo
    * @description : This method is used to test the updateJoiningInfo() & isPrimary() of the D1_PartnerPlusPopUpController class
    */
    @isTest
    public static void testUpdateJoiningInfo(){
        User currentUser = [SELECT Id,Effective_Account_Id__c,ContactId FROM User 
                            WHERE username ='testclassextuser1@testdomain.com' AND isActive = true LIMIT 1];
        Boolean isPrimary;
        
        Test.startTest();
            System.runAs(currentUser){
                D1_PartnerPlusPopUpController.updateJoiningInfo(currentUser.Id);
                isPrimary = D1_PartnerPlusPopUpController.isPrimary(currentUser.Id);
                D1_PartnerPlusPopUpController.updateLastReminderLoginCount(currentUser.Id);
            }
            Account acc = [SELECT Partner_Plus_Joining_Date__c,Partner_Plus_Enabled__c FROM Account
                        WHERE Id =: currentUser.Effective_Account_Id__c];
        Test.stopTest();

        System.Assert(acc.Partner_Plus_Enabled__c == true, 'PARTNER PLUS NOT ENABLED');
        System.Assert(isPrimary == true, 'NO PRIMARY CONTACT');
        Assert.isTrue(acc.Partner_Plus_Enabled__c, 'PARTNER PLUS NOT ENABLED');
		Assert.isTrue(isPrimary, 'NO PRIMARY CONTACT');
    }
    
    /**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = new Geography__c(Id = countryId);
        upsert country;  
        
        D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(country);
        insert d1Setting;      
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
        insert pickupOption;
        
        Account testOutlet = D1_TestDataUtility.getD1Customer();
        testOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert testoutlet;
        
        Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
        insert primaryContact;
        
        List<AccountContactRelation> relations = [Select id,D1_Active__c,D1_User_Role__c,D1_Roles__c from AccountContactRelation];
        for(AccountContactRelation acr: relations){
            acr.D1_Active__c = true;
            acr.D1_User_Role__c = 'Primary';
            acr.D1_Roles__c = 'Default Access;Manage Wholesalers';
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
        externalUser1.LanguageLocaleKey ='es';
        insert externalUser1;
    } 
}