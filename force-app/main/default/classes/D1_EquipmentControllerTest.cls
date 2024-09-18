/**
 * @name : D1_EquipmentControllerTest
 * @description : Test class for D1_EquipmentController
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0        Pratap Sen         11/01/23         NCP-7724
**/
@isTest
public class D1_EquipmentControllerTest {
    
    /*Declare RecordType Ids*/
    private static final Id QUALITYASSETRECTYPEID = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    /**
    * @name : testEquipments
    * @description : This method is used to test all methods from D1_EquipmentController
    */
    @isTest
    public static void testEquipments(){
        List<EDGE_MasterBundleWrapper> masterBundle = new List<EDGE_MasterBundleWrapper>();
        List<EDGE_OutletBundleWrapper> bundleRecs = new List<EDGE_OutletBundleWrapper>();
        List<EDGE_BundleAssetWrapper> assetRecs;
        List<Pick_Up_Options__c> equipmentIssues;
        
        Test.startTest();
        User currentUser = [SELECT Id,Effective_Account_Id__c,ContactId, Available_Countries__c FROM User 
                            WHERE username ='testclassextuser1@testdomain.com' AND isActive = true LIMIT 1];
        System.runAs(currentUser){
			masterBundle = D1_EquipmentController.getMasterBundlebyCountry();
            String dummyOutletId = '';
            bundleRecs = D1_EquipmentController.getBundlesbyOutlet(dummyOutletId);
            bundleRecs = D1_EquipmentController.getBundlesbyOutlet(currentUser.Effective_Account_Id__c);
            if(!bundleRecs.isEmpty()){
                assetRecs = D1_EquipmentController.getAssetbyBundle(bundleRecs[0].recordId);
            }
            equipmentIssues = D1_EquipmentController.getEquipmentIssues(null);
            equipmentIssues = D1_EquipmentController.getEquipmentIssues(currentUser.Available_Countries__c);
        }
        Test.stopTest();
        
        System.Assert(!bundleRecs.isEmpty() && !assetRecs.isEmpty() && !equipmentIssues.isEmpty(), 'Bundle does not exist');
        Assert.isTrue(!bundleRecs.isEmpty() && !assetRecs.isEmpty() && !equipmentIssues.isEmpty(), 'Bundle does not exist');
    }
    
    /**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        //Set up Admin User to prepare data set up using Admin User context
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Global' LIMIT 1].Id;
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            //set up country
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            Geography__c country = new Geography__c(Id = countryId);
            upsert country;  
                 
            //set up pickup option to insert Account
            Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
            insert pickupOption;
            
            //Set up Outlet Account to Link User with
            Account testOutlet = D1_TestDataUtility.getD1Customer();
            testOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert testoutlet;
            
            //Set up Contact and ACR to Link User with
            Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
            insert primaryContact;
            
            List<AccountContactRelation> relations = [SELECT Id,D1_Active__c,D1_User_Role__c,D1_Roles__c FROM AccountContactRelation];
            for(AccountContactRelation acr: relations){
                acr.D1_Active__c = true;
                acr.D1_User_Role__c = 'Primary';
                acr.D1_Roles__c = 'Default Access';
            }
            update relations;
            
            //Set up D1 Setting to insert D1 User Type
            D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(country);
            insert d1Setting; 
            
            D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1Setting.Id);
            insert d1UserType;
            
            //Set up External User with Outlet,Contact & D1 User Type
            User externalUser = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
            externalUser.Username = 'testclassextuser1@testdomain.com';
            externalUser.Email='testclassextuser1@testdomain.com';
            externalUser.ContactId = primaryContact.Id;
            externalUser.Effective_Account_Id__c = testoutlet.Id;
            externalUser.D1_User_Type_Id__c = d1UserType.Id;
            insert externalUser;
            
            //Set up Equipment Issue records
            Pick_Up_Options__c eqpIssue = D1_TestDataUtility.getPickUpOption(countryId, 'Equipment Issue', '', 'Equipment Issue [GB]');
            eqpIssue.Type__c = 'Equipment Issue';
            insert eqpIssue;
            
            /*EDGE Setup - Create Master Bundle, Bundle, Master Asset & Asset*/
            Master_Bundle__c masterBundle = new Master_Bundle__c();
            masterBundle.Name = 'Test Master Bundle';
            masterBundle.Description__c = 'Test description';
            masterBundle.Country__c = countryId;
            masterBundle.Active__c = TRUE;
            insert masterBundle;
            
            Bundle__c bundle = new Bundle__c();
            bundle.Name ='Bundle';
            bundle.Account__c = testoutlet.Id;
            bundle.Master_Bundle__c = masterBundle.Id;
            bundle.Bundle_Location__c = 'Bar';
            bundle.Description__c = 'This is the 1st Bundle';
            insert bundle;
            
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Test';
            masterAsst.GUID__c = 'TWRFSHJAKSVGG';
            masterAsst.Short_Description__c = 'test';
            masterAsst.Country__c = countryId;
            masterAsst.Priority_Assets__c = true;
            masterAsst.Line_Cleaning_Asset__c = true;
            masterAsst.Active__c = true;
            insert masterAsst;
            
            Asset asst = new Asset();
            asst.Name = 'Test_Asset';
            asst.GUID__c = 'TWRFSHJAKAFF';
            asst.AccountId = testoutlet.Id;
            asst.Country__c = countryId;
            asst.Quantity = 2;
            asst.Master_Asset__c = masterAsst.Id;
            asst.InstallDate = null;
            asst.Offset_Day__c = 2;
            asst.Batch_Processed__c = true;
            asst.Asset_Removed__c = false;
            asst.Is_OffsetDay_Changed__c = false;
            asst.RecordTypeId = QUALITYASSETRECTYPEID;
            asst.Bundle__c = bundle.Id;
            Insert asst;
        }
    }
}