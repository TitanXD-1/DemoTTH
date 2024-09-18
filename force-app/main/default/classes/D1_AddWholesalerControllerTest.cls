/**
* @Name: D1_AddWholesalerControllerTest
* 
* Purpose: Test class for D1_AddWholesalerController
* 
* History                                                            
* -                                                           
* VERSION	AUTHOR            		DATE            DETAIL
* 1.0		Subhrojit Majumdar		21/09/2022		NCP-7289
**/

@isTest
public class D1_AddWholesalerControllerTest {
    /**
     * @Name : testGetWholesalerMasterList
	 * @description : This method is used to test the getWholesalerMasterList() method of the D1_AddWholesalerController class
	 */
    @isTest
    public static void testGetWholesalerMasterList(){
        
        //Get D1 User
        User currentUser = [SELECT Id,LanguageLocaleKey,Effective_Account_Id__c,ContactId FROM User WHERE username ='testclassextuser1@testdomain.com' AND isActive = true limit 1];
        
        List<Account> wholesalerMasterList = new List<Account>();
        
        Test.startTest();
        System.runAs(currentUser)
        {
            wholesalerMasterList = D1_AddWholesalerController.getWholesalerMasterList(currentUser.Id);
        }
        Test.stopTest();
        
        //Assertions
        System.assert(wholesalerMasterList != NULL, 'wholeseller list not found');
        Assert.isNotNull(wholesalerMasterList, 'wholeseller list not found');
    }
    
    /**
     * @Name : testSaveSupplierOutletRecordSuccess
	 * @description : This method is used to test the saveSupplierOutletRecord() method of the D1_AddWholesalerController class
	 */
    @isTest
    public static void testSaveSupplierOutletRecordSuccess(){

        //Get D1 User
        User currentUser = [SELECT Id,LanguageLocaleKey,Effective_Account_Id__c,ContactId FROM User WHERE username ='testclassextuser1@testdomain.com' AND isActive = true limit 1];
        
        //Get Distributor Account
        Account newDistributor = new Account();
        newDistributor = [SELECT Id FROM Account WHERE Name ='Test Distributor Account'];
        
        Boolean result;
        
        Test.startTest();
        System.runAs(currentUser)
        {
            result = D1_AddWholesalerController.saveSupplierOutletRecord(newDistributor.Id, '1234' , true, currentUser.Id);
        }
        Test.stopTest();
        
        //Assertions
        System.assert(result == true, 'result not found');
        Assert.isTrue(result, 'result not found');
    }
    
    /**
     * @Name : createData
	 * @description : This method is used to create test data for D1_AddWholesalerControllerTest class
	 */
    @testSetup
    public static void createData(){
        
        //Setup Country
        Id countryId = D1_TestDataUtility.setupCountry('ES');
        Geography__c country = new Geography__c(Id = countryId);
        upsert country;  
        
        //Setup D1 Settings
        D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(country);
        insert d1Setting;      
        
        //Setup Visit Prioritization
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[ES]');
        insert pickupOption;
        
        //Setup D1 Customer Outlet
        Account testOutlet=D1_TestDataUtility.getD1Customer();
        testOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert testoutlet;
        
        //Setup Primary Contact
        Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
        insert primaryContact;
        
        //Setup Account-Contact Relationship
        List<AccountContactRelation> relations = [Select id,D1_Active__c from AccountContactRelation];
        for(AccountContactRelation acr: relations){
            acr.D1_Active__c = true;
        }
        update relations;
        
        //Setup Distributor Account
        Account distributorAccount = D1_TestDataUtility.getDistributerAccountRecord();
        insert distributorAccount;
        
        //Setup D1 User Type
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1Setting.Id);
        insert d1UserType;
        
        //Setup External User
        User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
        externalUser1.Username = 'testclassextuser1@testdomain.com';
        externalUser1.Email='testclassextuser1@testdomain.com';
        externalUser1.CommunityNickname = 'Mania.Test1';
        externalUser1.Available_Countries__c = 'ES';
        externalUser1.ContactId = primaryContact.Id;
        externalUser1.Effective_Account_Id__c = primaryContact.AccountId;
        externalUser1.isActive = true;
        externalUser1.D1_User_Type_Id__c = d1UserType.Id;
        externalUser1.LanguageLocaleKey ='es';
        insert externalUser1;
    } 
}