/*
* @name: D1_FeedItemTriggerHelper
* @description: This is the test class for D1_FeedItemTriggerHelperTest
* @history
* VERSION   AUTHOR          DATE        	DETAIL
* 1.0		Amar      		30/07/2021		NCP-3815
* 2.0		Subhrojit		07/04/2023		NCP-8113
* */
@isTest
public class D1_FeedItemTriggerHelperTest {
    
    /**
     * @Name : setup
	 * @description : This method is used to create test data for D1_FeedItemTriggerHelperTest class
	 */
    @testsetup
    public static void setup()
    {   
        //Setup Direct Customer
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        //Setup External User
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        
        //Update Contact's Preferred Language
        Contact customer = [Select Id from Contact limit 1];
        customer.Preferred_Language__c = 'en_GB';
        update customer;
        
        //Update D1Setting
        D1_Setting__c d1Setting = [SELECT ID,D1_Send_Case_Update_Email_to_Customer__c FROM D1_Setting__c LIMIT 1];
        d1Setting.D1_Send_Case_Update_Email_to_Customer__c = TRUE;
        update d1Setting;
    }
    
    /**
     * @Name : sendNotificationToCaseCreaterTest
	 * @description : This method is used to test the sendNotificationToCaseCreater() method of the D1_FeedItemTriggerHelper class
	 */
    @isTest
    public static void sendNotificationToCaseCreaterTest(){
        
        //Create Org Settings
        D1_TestDataUtility.createOrgSettings();
        
        Case caseRecd;
        User extUser = [SELECT Id,Available_Countries__c,D1_User_Type__c,D1_User_Type_Id__c FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];

		Test.startTest();        
        
        System.runAs(extUser){
            Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();
            caseRecd = D1_TestDataUtility.createCase(caseRecTypeId,'Quality & Equipment Issues', 'Equipment Fault', 'Testing Description', 'Open');
            caseRecd.AccountId = account.Id;
            caseRecd.ContactId = contact.Id;
            insert caseRecd;        
        }
        
        FeedItem feedRecd = D1_TestDataUtility.getFeedItem(caseRecd.Id, 'Commented', 'AllUsers');
        insert feedRecd;
        feedRecd.Body = 'Update';
        update feedRecd;
        
        Test.stopTest();
        
        System.assert(feedRecd.Id != null, 'Feed item not found');
        Assert.isNotNull(feedRecd.Id, 'Feed item not found');
    }
}