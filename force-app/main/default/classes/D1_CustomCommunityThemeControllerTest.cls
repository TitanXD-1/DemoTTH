/*
 * @name: D1_CustomCommunityThemeControllerTest
 * @description: This is the Test Class for D1_CustomCommunityThemeController.
 * @History
 * VERSION     AUTHOR           DATE			DETAIL
 * 1.0         Saurav Paul      09/25/2020   	Initial Development
 * 2.0		   Narayana		    12/07/2021		NCP-3785 (refactor)
 * 3.0		   Subhrojit		26/01/2023		Refactor
 **/
@isTest
public with sharing class D1_CustomCommunityThemeControllerTest
{
    /**
     * @Name : setup
	 * @Description : This method is used to create dummy data for D1_CustomCommunityThemeControllerTest class
	 */    
    @testSetup 
    public static void setup()
    {
        //Setup Admin User - to avoid MixedDML operation errors
        UserRole userRole   =   [Select Id From UserRole Where Name = 'Global' Limit 1];
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = userRole.Id;
        insert testAdminUser;  
        
        //Run test setup method as Admin User
        System.runAs(testAdminUser){
            
            //Setup Country
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            
            //Setup Pickup Option
            Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            //Setup D1 Customer Account
            Account testoutlet=D1_TestDataUtility.getD1Customer();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.D1_Registration_Status__c = '';
            testoutlet.Current_Approval_Step__c ='';
            testoutlet.Status__c='';
            testoutlet.D1_Partner_Reminder_Display_Login_Count__c = null;
            testoutlet.Partner_Plus_Enabled__c = false;
            testoutlet.Direct_Customer__c = false;
            insert testoutlet;
            
            //Setup Contact for D1 Customer Account
            Contact con=D1_TestDataUtility.getContact(testoutlet.id,'Secondary');
            con.D1_Login_Counter__c = 1;
            insert con;   
            
            //Setup External User
            D1_TestDataUtility.setUpExternalUser(testoutlet,'Outlet/Retailers');
            
            //Query newly created External User
            User externalUser = [SELECT Id,D1_User_Type__c,D1_User_Type_Id__c,Available_Countries__c,LanguageLocaleKey,ContactId, Contact.accountId 
                                 FROM User
                                 WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
            
            //Update External User Contact's login counter
            Contact conForNPS = new Contact(Id = externalUser.contactId, D1_Login_Counter__c = 3, D1_Generic_Login_Counter__c = 2, MD_SubscriptionDate__c = System.today());
            update conForNPS;
            
            //Assign Permission Set to External User
            List<String> permissionSetNameMD = new List < String > { 'MD - MyDiageo User', 'MD - Community Manager', 'CMS User', 'Manage Users', 'Order'}; 
            List< PermissionSet> permSetId = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSetNameMD];
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.PermissionSetId = permSetId[0].Id;
            psa.AssigneeId = externalUser.Id;
            insert psa;
            
            //Update ACR records
            List<AccountContactRelation> acrs = [SELECT Id, D1_Roles__c from AccountContactRelation];
            List<AccountContactRelation> acrps = new List<AccountContactRelation>();
            for(AccountContactRelation acr :acrs)
            {
                acr.D1_Roles__c='Ordering;POS & Equipment Ordering';//NCP-2341
                acr.D1_Active__c = true;
                acr.Last_POS_Order_Date__c = System.Now();
                acr.D1_User_Role__c = 'Primary';
                acr.MD_AssignedPermissions__c = 'Manage Users;Order';
                acrps.add(acr);
            }
            update acrps;
            
            //Update D1 Settings
            D1_Setting__c d1setting2 = [SELECT Self_Registration__c, Partner_OptIn_Reminder_Interval__c,Partner_Plus_Enabled__c,
                                        D1_opt_in_reminder_interval__c,NPS_Survey_URL__c, NPS_Session_Frequeny_Reminder__c FROM D1_Setting__c];
        	
            d1setting2.NPS_Survey_URL__c = 'https://www.diageo.com';
        	d1setting2.NPS_Session_Frequeny_Reminder__c = 3;
          	d1setting2.Partner_Plus_Enabled__c = true;
            d1setting2.Partner_OptIn_Reminder_Interval__c = 2;
        	
            upsert d1setting2;
            
            //Insert Cart Items
            D1_TestDataUtility.insertCartAndCartItems(testoutlet);
        }
    }
    
    /**
     * @Name : testGetUserAndAcc
	 * @Description : This method is used to test the getUserAndAcc() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testGetUserAndAcc(){
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        
        Test.startTest();
        D1_CustomCommunityThemeController.UserWrapper wrapperObj = D1_CustomCommunityThemeController.getUserAndAcc(testUser.Id);
        Test.stopTest();
        
        //Assertions
        System.assertEquals('Test Customer Account', wrapperObj.accName, 'ACCOUNT FETCH FAILED');
        Assert.areEqual('Test Customer Account', wrapperObj.accName, 'ACCOUNT FETCH FAILED');
    }
    
    /**
     * @Name : testRemoveMyDiageoPermissionSet
	 * @Description : This method is used to test the removeMyDiageoPermissionSet() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testRemoveMyDiageoPermissionSet(){

        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser)
        {
        	D1_CustomCommunityThemeController.removeMyDiageoPermissionSet(testUser.Id); 
        }
        Test.stopTest();
        
        //Data for assertions
        List<String> permissionSetNameMD = new List < String > {'MD - MyDiageo User'}; 
        List< PermissionSet> permSetId = [SELECT Id FROM PermissionSet WHERE Label IN: permissionSetNameMD];
        List<PermissionSetAssignment> listPermissionSetAssignment = [SELECT Id from PermissionSetAssignment WHERE PermissionSetId IN: permSetId AND AssigneeId = : testUser.Id];

        //Assertions
        System.assert(true, listPermissionSetAssignment.isEmpty()); 
        Assert.isTrue(listPermissionSetAssignment.isEmpty(), 'LIST PEMISSIONSETASSIGNMENT IS NOT EMPTY');
    }

    /**
     * @Name : testGetD1Setting
	 * @Description : This method is used to test the getD1Setting() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testGetD1Setting(){

        Geography__c geography =[Select Code__c from Geography__c WHERE Code__c='GB'];

        Test.startTest();
        D1_Setting__c testD1Setting = D1_CustomCommunityThemeController.getD1Setting(geography.Code__c,'en_GB');
        Test.stopTest();

        //Assertions
        System.assert(testD1Setting.Id != null, 'D1SETTING NOT FOUND');
        Assert.isNotNull(testD1Setting.Id, 'D1SETTING NOT FOUND');
    }

    /**
     * @Name : testSetSubscription
	 * @Description : This method is used to test the setSubscription() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testSetSubscription(){
        
        User testUser = [Select Id, ContactId FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        String testSubscriptionString = 'Email;Phone';
        
        Test.startTest();
        System.runAs(testUser)
        {
            D1_CustomCommunityThemeController.setSubscription(testSubscriptionString);       
        }    
        Test.stopTest();
        
        //Data for assertions
        Contact testContact = [SELECT Id, MD_ContactSubscriptions__c FROM Contact WHERE Id = :testUser.ContactId];
        
        //Assertions
        System.assertEquals(testSubscriptionString, testContact.MD_ContactSubscriptions__c, 'SUBJECT NOT FETCHED');
        Assert.areEqual(testSubscriptionString, testContact.MD_ContactSubscriptions__c, 'SUBJECT NOT FETCHED');
    }
    
    /**
     * @Name : testShowOptInPopup
	 * @Description : This method is used to test the showOptInPopup() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testShowOptInPopup(){
        
        User testUser = [SELECT Id, Contact.MD_SubscriptionDate__c, Contact.MD_ContactSubscriptions__c, Contact.D1_Last_opt_in_reminder_date__c, Contact.accountId 
                         FROM User WHERE Profile.Name = 'DiageoOne External User' and UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        
        D1_Setting__c testD1Setting = [SELECT D1_opt_in_reminder_interval__c FROM D1_Setting__c];
        Boolean testFlag = false;

        Test.startTest();
        System.runAs(testUser)
        {
            testFlag = D1_CustomCommunityThemeController.showOptInPopup(testUser, testD1Setting, null);    
        }
        Test.stopTest();
        
        //Assertions
        System.assertEquals(true, testFlag, 'OPTIN POPUP FAILED');
        Assert.isTrue(testFlag, 'OPTIN POPUP FAILED');
    }
    
    /**
     * @Name : testDisplayPartnerPlusReminder
	 * @Description : This method is used to test the displayPartnerPlusReminder() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testDisplayPartnerPlusReminder(){
        
        User testUser = [SELECT Id, ContactId, Contact.D1_Generic_Login_Counter__c, Contact.accountId FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        D1_Setting__c testD1Setting = [Select Id, Partner_OptIn_Reminder_Interval__c, Partner_Plus_Enabled__c FROM D1_Setting__c];
        Account testAccount = [SELECT ID, D1_Partner_Reminder_Display_Login_Count__c, Partner_Plus_Enabled__c FROM Account WHERE ID = :testUser.Contact.accountId LIMIT 1];
        Boolean testFlag = false;

        Test.startTest();
        System.runAs(testUser)
        {
            testFlag = D1_CustomCommunityThemeController.displayPartnerPlusReminder(testUser, testD1Setting, testAccount);    
        }
        Test.stopTest();
        
        //Assertions
        System.assertEquals(true, testFlag, 'PARTNER+ POPUP FAILED');
        Assert.isTrue(testFlag, 'PARTNER+ POPUP FAILED');
    }
    
    /**
     * @Name : testDisplayNpsSurvey
	 * @Description : This method is used to test the displayNpsSurvey() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testDisplayNpsSurvey(){
        
        User testUser = [SELECT Id, Contact.D1_Login_Counter__c FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        D1_Setting__c testD1Setting = [SELECT Id, NPS_Survey_URL__c, NPS_Session_Frequeny_Reminder__c FROM D1_Setting__c];
        Boolean testFlag = false;

        Test.startTest();
        System.runAs(testUser)
        {
            testFlag = D1_CustomCommunityThemeController.displayNpsSurvey(testUser, testD1Setting, null);    
        }
        Test.stopTest();
        
        //Assertions
        System.assertEquals(true, testFlag, 'NPS POPUP FAILED');
        Assert.isTrue(testFlag, 'NPS POPUP FAILED');
    }
    
    /**
     * @Name : testNpsBlockHandler
	 * @Description : This method is used to test the npsBlockHandler() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testNpsBlockHandler(){
        
        User testUser = [SELECT Id, ContactId FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        
        Test.startTest();
        System.runAs(testUser)
        {
            D1_CustomCommunityThemeController.npsBlockHandler(testUser.Id);    
        }
        Test.stopTest();
        
        //Data for assertions
        Contact testContact = [SELECT Id, D1_Login_Counter__c FROM Contact WHERE Id = :testUser.ContactId];
        
        //Assertions
        System.assertEquals(999, testContact.D1_Login_Counter__c, 'NPS BLOCK FAILED');
        Assert.areEqual(999, testContact.D1_Login_Counter__c, 'NPS BLOCK FAILED');
    }
    
    /**
     * @Name : testSetOptInSubscription
	 * @Description : This method is used to test the testSetOptInSubscription() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testSetOptInSubscription(){
        
        User testUser = [Select Id, ContactId FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        String testSubscriptionString = 'Email;Phone';
        
        Test.startTest();
        System.runAs(testUser)
        {
            //Test 1: Invalid Subscription Data(blank or null)
            D1_CustomCommunityThemeController.setOptInSubscription('');
            
            //Test 2: Valid Subscription Data
            D1_CustomCommunityThemeController.setOptInSubscription(testSubscriptionString);
        }
        Test.stopTest();
        
        //Data for assertions
        Contact testContact = [SELECT Id, MD_ContactSubscriptions__c FROM Contact WHERE Id = :testUser.ContactId];
        
        //Assertions
        System.assertEquals(testSubscriptionString, testContact.MD_ContactSubscriptions__c, 'NOT SUBSCRIBED');
        Assert.areEqual(testSubscriptionString, testContact.MD_ContactSubscriptions__c, 'NOT SUBSCRIBED');
    }
    
    /**
     * @Name : testGetUserDetails
	 * @Description : This method is used to test the testGetUserDetails() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testGetUserDetails(){
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        List<D1_User_Type__c> userDetails = new List<D1_User_Type__c>();
        
        Test.startTest();
        System.runAs(testUser)
        {
            userDetails = D1_CustomCommunityThemeController.getUserDetails(testUser.Id);   
        }
        Test.stopTest();
        
        //Assertion
        System.assert(userDetails != null, 'USERDETAIL NOT FETCHED');
        Assert.isNotNull(userDetails, 'USERDETAIL NOT FETCHED');
    }
    
    /**
     * @Name : testGetUserType
	 * @Description : This method is used to test the getUserType() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testGetUserType(){
        
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        String userType;
        String expectedUserType;
        
        Test.startTest();
        System.runAs(testUser)
        {
            userType = D1_CustomCommunityThemeController.getUserType();
            expectedUserType=UserInfo.getUserType();    
        }
        Test.stopTest();
        
        //Assertions
        System.assertEquals(expectedUserType, userType, 'User type mismatch');
        Assert.areEqual(expectedUserType, userType, 'User type mismatch');
    }
   
    /**
     * @Name : testGetProductCategoryId
	 * @Description : This method is used to test the getProductCategoryId() method of the D1_CustomCommunityThemeController class
	 */
    @isTest
    public static void testGetProductCategoryId()
    {
        WebStore webstoreObj = [SELECT Id, Name FROM WebStore LIMIT 1];
        webstoreObj.Name=System.Label.D1_Commerse_StoreName;
        update webstoreObj;
        
        ProductCatalog catalog = [SELECT Id, Name FROM ProductCatalog LIMIT 1];
        catalog.Name =  System.Label.D1_Commerse_CatalogName;
        update catalog;
        
        ProductCategory category = new ProductCategory(Name='test Products', CatalogId=catalog.Id, IsNavigational = true);
        insert category;
        
        User testUser = [SELECT Id,D1_User_Type__c,D1_User_Type_Id__c,Available_Countries__c,LanguageLocaleKey FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1]; 
        
        String productCategoryId;
        
        Test.startTest();
        System.runAs(testUser)
        {
            productCategoryId = D1_CustomCommunityThemeController.getProductCategoryId();
        }
        Test.stopTest();
        
        //Assertions
        System.assertEquals(productCategoryId,category.id , 'Product category not found');
        Assert.areEqual(productCategoryId,category.id , 'Product category not found');
    }
    
    //CartWrapper to test Cart based methods
    public class CartWrapper
    {
       	@AuraEnabled
        public List<String> datesArray{get;set;}
        @AuraEnabled
        public List<String> oSplitArray{get;set;}
    }
    
    
    /**
     * @Name : testIsDeliveryDatesValid
	 * @Description : This method is used to test the IsDeliveryDatesValid() method of the D1_CustomCommunityThemeController class
	 */
    
     /* commented out this method since the method in main class is not in use
    @isTest
    public static void testIsDeliveryDatesValid() 
    {
           
        User testUser = [SELECT Id,D1_User_Type__c,D1_User_Type_Id__c,Available_Countries__c,LanguageLocaleKey,Contact.AccountId,
                        Contact.Account.Name,Name,ProfileId,ContactId,Profile.Name,Contact.Account.D1_Registration_Status__c,Contact.Registration_Source__c FROM User WHERE Profile.Name = 'DiageoOne External User'
                        AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1]; 
        
        List<String> o1 = new List<String>();
        List<OrderSplit__c> orderSplitobj=[SELECT Id from OrderSplit__c];
        
        D1_TestDataUtility.b2bCommercePermissionset(testUser);
        
        List<AccountContactRelation> accConRelationList =[SELECT Id,ContactId,Contact_Type__c,D1_Roles__c,MD_AssignedPermissions__c,D1_User_Role__c,D1_Active__c 
                                     					 FROM AccountContactRelation WHERE accountId =:testUser.Contact.accountId
                                     					 AND Contactid =: testUser.ContactId];
        System.Assert(accConRelationList != NULL, 'ACR NOT CREATED');
        for(OrderSplit__c osplit:orderSplitobj)
        {
            o1.add(osplit.id);
        }
        
        List<String> d1 = new List<String>();
        d1.add('2021-01-26');
        d1.add('2021-01-26');
        
        Boolean isValid = false;
        
        Test.startTest();
        System.runAs(testUser)
        {
            D1_CustomCommunityThemeController.CartWrapper obj = new D1_CustomCommunityThemeController.CartWrapper();
            obj.datesArray= d1;            
            obj.oSplitArray= o1;
            obj.shipToNumber = new List<string>{'1234','223343'};
                
            isValid = D1_CustomCommunityThemeController.IsDeliveryDatesValid(obj);
        }
        Test.stopTest(); 
        
        //Assertions
        System.assertEquals(false, isValid, 'DELIVERY DATE VALIDATION FAILED');
        Assert.isFalse(isValid,  'DELIVERY DATE VALIDATION FAILED');
    } */
}