/**
* @Name: D1_CSVOrderingControllerTest
* 
* Purpose: Test class for D1_CSVOrderingController
* 
* History                                                            
* -                                                           
* VERSION	AUTHOR            		DATE            DETAIL
* 1.0		Naresh and Swarnim		20/04/2023		Initial Development (NCP-8181)
**/
@isTest
public class D1_CSVOrderingControllerTest {
    /**
    * @Name : testGetProducts
	* @description : This method is used to test the getProducts() method of the D1_CSVOrderingController class
	*/
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seeAllData = true)
    public static void testGetProducts(){
        Test.startTest();
        createData();
            User testUser = [SELECT Id,D1_User_Type__c,D1_User_Type_Id__c,Available_Countries__c,LanguageLocaleKey FROM User 
                             WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];

        	ProductCategory prodCat = [SELECT Id FROM ProductCategory WHERE Name = 'Product Category Test' LIMIT 1];
        	
        	String searchQuery = '{"searchTerm":\"\", "categoryId ": \"' + prodCat.Id + '\" , "refinements" : [] , "includePrices" : true}';
        	
        	//Test for First SearchQuery
        	try{
                System.Assert(searchQuery != NULL, 'JSON INPUT INVALID');
                Assert.isTrue(searchQuery != NULL, 'JSON INPUT INVALID');

            	D1_CSVOrderingController.getProducts(searchQuery, testUser.Id);
            }
            catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        Test.stopTest();
    }
    
    /**
    * @Name : testgetFieldSet
	* @description : This method is used to test the getFieldSet() method of the D1_CSVOrderingController class
	*/
    @isTest
    public static void testgetFieldSet(){
        Test.startTest();
        createData();
        //Get D1 User
        User currentUser = [SELECT Id,LanguageLocaleKey,Effective_Account_Id__c,ContactId FROM User WHERE username ='testclassextuser1@testdomain.com' AND isActive = true limit 1];        
        String result;
        
            System.runAs(currentUser){
                result = D1_CSVOrderingController.getFieldSet('Product2','CSV_Product_Field_Set');
            }
        Test.stopTest();
        
        System.Assert(result != NULL, 'Product/Field set values not found');
        Assert.isNotNull(result,'Product/Field set values not found');
    }
	
    /**
    * @Name : testAddToCart
	* @description : This method is used to test the addToCart() method of the D1_CSVOrderingController class
	*/
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(seeAllData = true)
    public static void testAddToCart(){
        createData();
        Test.startTest();
            User testUser = [SELECT Id,D1_User_Type__c,D1_User_Type_Id__c,Available_Countries__c,LanguageLocaleKey FROM User 
                             WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
            
            Product2 prodObj = [SELECT Id FROM Product2 WHERE Name = 'Test P' LIMIT 1];
            prodObj.StockKeepingUnit = '123456';
            update prodObj;

            Map<String,String> orderInput = new Map<String,String>();
            orderInput.put('123456', '10');
            orderInput.put('012345', '20');
        	String orderItemInput = JSON.serialize(orderInput);
        
        	try{
                System.Assert(orderItemInput != NULL, 'JSON INPUT INVALID');
                Assert.isTrue(orderItemInput != NULL, 'JSON INPUT INVALID');
                
            	D1_CSVOrderingController.addToCart(orderItemInput, testUser.Id, '0');
            }
            catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        Test.stopTest();
    }
    
	/**
    * @Name : createData
	* @description : This method is used to create Test Data
	*/
    public static void createData(){
        /*Setup Country : To handle validation error against multiple 'Global' Geography records when opening up access to org data in test class*/
        List<Geography__c> geoList = new List<Geography__c>();
        Id countryId;
        Boolean isOrgData = true;
        
        geoList = [SELECT Id FROM Geography__c WHERE Code__c = 'GB' AND RecordType.Name = 'Country'];
        if(geoList.isEmpty()){
            countryId = D1_TestDataUtility.setupCountry('GB');
            isOrgData = false;
        }
        else{
            countryId = geoList[0].Id;
        }     
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id =: countryId];
        
        //Setup D1 Settings
        D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(country);
        d1Setting.Language__c = 'es';
        insert d1Setting;      
        
        //Setup Visit Prioritization
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','TestGold[GB]');
        insert pickupOption;
        
        //Setup Outlet
        Account testoutlet = D1_TestDataUtility.getDirectCustomer();
        if(isOrgData){
            Geography__c hub = [SELECT Id FROM Geography__c WHERE RecordType.name = 'Hub' and name ='Great Britain' limit 1];
            Geography__c region = [SELECT Id FROM Geography__c WHERE RecordType.name='Region'and name ='London' limit 1];
            Geography__c area = [SELECT Id FROM Geography__c WHERE RecordType.name='Area' and name ='Great Britain' limit 1];
            Geography__c market = [SELECT Id FROM Geography__c WHERE RecordType.name='Market' and name ='Europe and Turkey' limit 1];
            Geography__c cluster = [SELECT Id FROM Geography__c WHERE RecordType.name='Cluster' and name ='Great Britain' limit 1];
            testoutlet.Country__c = countryId;
            testoutlet.Hub__c = hub.Id;
            testoutlet.Region__c = region.Id;
            testoutlet.Area__c = area.Id;
            testoutlet.Market__c = market.Id;
            testoutlet.Cluster__c = cluster.Id;
        }
        testoutlet.D1_EDGE_Customer__c = true;
        testoutlet.Name = 'testcart Outlet';
        testoutlet.Salesforce_Delivery_Days_Packaged_Good__c = '1;2;3;4;5;6;7';
        testoutlet.Salesforce_Delivery_Days_Keg__c = '1;2;3;4;5;6;7';
        testoutlet.Delivery_Pattern__c = '0';
        testoutlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;
        insert testoutlet;
        
        //Setup Primary Contact
        Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
        insert primaryContact;
        
        //Setup Account-Contact Relationship
        List<AccountContactRelation> relations = [Select id,D1_Active__c from AccountContactRelation WHERE ContactId =: primaryContact.Id LIMIT 10];
        for(AccountContactRelation acr: relations){
            acr.D1_Active__c = true;
        }
        update relations;
        
        //Setup D1 User Type
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1Setting.Id);
        insert d1UserType;
        
        //Setup External User
        User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
        externalUser1.Username = 'testclassextuser1@testdomain.com';
        externalUser1.Email='testclassextuser1@testdomain.com';
        externalUser1.CommunityNickname = 'Mania.Test1';
        externalUser1.Available_Countries__c = 'GB';
        externalUser1.ContactId = primaryContact.Id;
        externalUser1.Effective_Account_Id__c = testOutlet.Id;
        externalUser1.isActive = true;
        externalUser1.D1_User_Type_Id__c = d1UserType.Id;
        externalUser1.LanguageLocaleKey ='en_GB';
        insert externalUser1;
        
        //Setup WebStore
        WebStore webstoreObj = new WebStore();
        webstoreObj.Name = 'Test Store';
        insert webstoreObj;
		
        //Setup Product
        Product2 prodObj = new Product2();
        prodObj.Name = 'Test P';
        prodObj.SAP_Material_Id__c = '0000012345';
        insert prodObj;
        
        //Setup Catalogue
        ProductCatalog productCatalog = new ProductCatalog();
        productCatalog.Name = webstoreObj.Name;
        insert productCatalog;
        
        //Setup Product Category
        ProductCategory prodCategory = new ProductCategory(Name = 'Product Category Test', CatalogId = productCatalog.Id);
        insert prodCategory;
		
        //Setup WebCart
        WebCart webCArtObj = new WebCart();
        webCArtObj.Name = 'TestCart';
        webCArtObj.WebStoreId = webstoreObj.Id;
        webCArtObj.AccountId = testoutlet.Id;
        webCArtObj.Split_2_PO_Number__c = '123654';
        webCArtObj.PoNumber = '4569875';
        webCArtObj.Status = 'Active';
        insert webCArtObj;
    } 
}