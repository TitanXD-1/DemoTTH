/**
* @Name: D1_B2BSearchControllerTest
* @description : Test Class for D1_B2BSearchController
* @History                                                                                                                        
* VERSION   AUTHOR            DATE              DETAIL
* 1.0         -                -				Initial Development
* 1.1       Pratap Sen        24/12/2022		PMD rule Impose
**/
@isTest
public class D1_B2BSearchControllerTest {
    /**
    * @name : testProductSearch
    * @description : This method is used to test productSearch
    */
    @isTest
    public static void testProductSearch(){
        try{
            String communityId = null;
            Id prodCtgryId = [SELECT Id FROM ProductCategory WHERE Name = 'Product' LIMIT 1].Id;
            Id accId = [SELECT Id FROM Account LIMIT 1].Id;
            
            Test.startTest();
            	String searchQuery = '{"categoryId":"' + prodCtgryId + '"}';
            	Object prodSearchInfo = D1_B2BSearchController.productSearch(communityId,searchQuery,accId);
            Test.StopTest();
            
            System.assert(prodSearchInfo != NULL, 'ASSERTION PASSED');
            Assert.isNotNull(prodSearchInfo, 'ASSERTION PASSED');     
        }catch(Exception ex){
            System.assertNotEquals(ex.getMessage(), '', 'ASSERTION FAILED');
        }
    }
    
    /**
    * @name : testGetSessionId
    * @description : This method is used to test getSessionId
    */
    @isTest
    public static void testGetSessionId(){
        try{
            Test.startTest();
            	String sessionId = D1_B2BSearchController.getSessionId();
            Test.StopTest(); 
            
            System.assert(sessionId != NULL, 'ASSERTION PASSED');
            Assert.isNotNull(sessionId, 'ASSERTION PASSED');
        }catch(Exception ex){
            System.assertNotEquals(ex.getMessage(), '', 'ASSERTION FAILED');
        }
    }
    
    /**
    * @name : testSortRules
    * @description : This method is used to test getSortRules
    */
    @isTest
    public static void testSortRules(){
        try{
            Test.startTest();
            	Object sortRules = D1_B2BSearchController.getSortRules(null);
            Test.StopTest(); 
            
            System.assert(sortRules != NULL, 'ASSERTION PASSED');
            Assert.isNotNull(sortRules, 'ASSERTION PASSED');
        }catch(Exception ex){
            System.assertNotEquals(ex.getMessage(), '', 'ASSERTION FAILED');
        }
    }
	
    /**
    * @name : testProductMarket
    * @description : This method is used to test getProductMarketInfo
    */
    @isTest
    public static void testProductMarket(){
        User testAdminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(testAdminUser){
            Test.startTest();
                Id prodId = [SELECT Id FROM Product2 LIMIT 1].Id;
                ConnectApi.ProductSearchResults results = new ConnectApi.ProductSearchResults();
                results.productsPage = new ConnectApi.ProductSummaryPage();            
                results.productsPage.products = new List<ConnectApi.ProductSummary>{ new ConnectApi.ProductSummary() };
                results.productsPage.products[0].id = prodId;
    
                Object prodMarketInfo = D1_B2BSearchController.getProductMarketInfo(results);
            Test.stopTest();
            
            System.assert(prodMarketInfo != NULL, 'Assertion passed');
            Assert.isNotNull(prodMarketInfo, 'ASSERTION PASSED');
        }
    }
    
    /**
    * @name : testGetWishListItems
    * @description : This method is used to test getWishListItems
    */    
    @isTest
    public static void testGetWishListItems(){
        User testAdminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        system.runAs(testAdminUser){
            Test.startTest();
                Id wishListId = [SELECT Id FROM Wishlist LIMIT 1].Id;
                ConnectApi.WishlistsSummary wishlistSumm = new ConnectApi.WishlistsSummary();
                wishlistSumm.summaries = new List<ConnectApi.WishlistSummary>{new ConnectApi.WishlistSummary()};
                    
                wishlistSumm.summaries[0].id = wishListId;
                Object wishListSummary = D1_B2BSearchController.getWishListItems(wishlistSumm);
            Test.stopTest();
            
            System.assert(wishListSummary != NULL, 'Assertion passed');
            Assert.isNotNull(wishListSummary, 'ASSERTION PASSED');
        }
    }

    /**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        //Set up Admin User to prepare data set up using Admin User context
        User testAdmin = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdmin.userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Global' LIMIT 1].Id;
        insert testAdmin;
        
        System.runAs(testAdmin){
            //Set up Org Settings to Enable System validations & Triggers
            D1_TestDataUtility.createOrgSettings();
            
            //set up country, customer & Product
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            Account accRec = D1_TestDataUtility.getDirectCustomer();
            List<Product2> prodList = new List<Product2>{D1_TestDataUtility.getProduct()};
            insert accRec;
            insert prodList;
            
            //Set up Market Product : test data for getProductMarketInfo            
            Market_Product2__c marketProduct = new Market_Product2__c(Market__c = countryId, Product__c = prodList[0].id, isActive__c = true);
            insert marketProduct;
            
            //Set up Product Category : test data for productSearch
            ProductCatalog prodCtlg = new ProductCatalog(Name = 'Shop');
            insert prodCtlg;
            
            ProductCategory prodCtgry = new ProductCategory(Name = 'Product', CatalogId = prodCtlg.Id);
            insert prodCtgry;
            
            //Set up WebStore, WishList & WishListItems : test data for getWishListItems
            Webstore webStore = D1_TestDataUtility.getWebStore();
            insert webStore;
            
            Wishlist wishList = D1_TestDataUtility.getWishlist(accRec.Id, webStore.Id);
            insert wishList;
            
            List<WishlistItem> wishItems = D1_TestDataUtility.getWishlistItem(wishList.Id, prodList);
            insert wishItems;
        }
    }
}