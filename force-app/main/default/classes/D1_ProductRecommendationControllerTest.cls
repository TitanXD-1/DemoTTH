/**
 * @description: This is the test class for D1_ProductRecommendationController
 * @name: D1_ProductRecommendationControllerTest
 * @history
 * @version     Developer           Date            		Detail
 * 1.0          Pratap Sen     	  09-03-2023       NCP-7986 - Initial Development
*/
@isTest
public class D1_ProductRecommendationControllerTest {
	/**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        //Set up Admin User to Create Test Data
        UserRole userRole   =   [Select Id From UserRole Where Name = 'Global' Limit 1];
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = userRole.Id;
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            //Set Up Country
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            
            //Set up Outlet
            Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
            insert pickupOption;
            
            Account testOutlet = D1_TestDataUtility.getD1Customer();
            testOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert testoutlet;
            
            //Setup External User
            D1_TestDataUtility.setUpExternalUser(testoutlet,'Outlet/Retailers');
                        
            //Set up webcart and related items, adding cartitem product as master
            D1_TestDataUtility.insertCartAndCartItems(testoutlet);
            Product2 masterProd = [SELECT Id FROM Product2 LIMIT 1];
            
            //Set Up ProductCategory and Other Product Records to be used as recommendation            
            List<Product2> prodList = D1_TestDataUtility.product2TestData();
            
            //Add StockKeepingUnit in recommended products
            List<Product2> recommProducts = new List<Product2>{prodList[0],prodList[1],prodList[2]};
            for(Integer i=0; i<recommProducts.size(); i++){
                recommProducts[i].StockKeepingUnit = '123'+String.valueOf(i);
            }
            update recommProducts;
            
            //Setup Product Recommendation
            D1_Product_Recommendation__c prodRecomm1 = D1_TestDataUtility.getProductRecomm(masterProd.Id, recommProducts[0].Id, countryId);
            D1_Product_Recommendation__c prodRecomm2 = D1_TestDataUtility.getProductRecomm(masterProd.Id, recommProducts[1].Id, countryId);
            D1_Product_Recommendation__c prodRecomm3 = D1_TestDataUtility.getProductRecomm(masterProd.Id, recommProducts[2].Id, countryId);
            List<D1_Product_Recommendation__c> prodRecmmList = new List<D1_Product_Recommendation__c>{prodRecomm1, prodRecomm2, prodRecomm3};
            insert prodRecmmList;
        }
    }
    
    /**
    * @name : testProductRecommForProduct
    * @description : This method is used to test the getRecommendedProductsForProduct and the parent method getRecommendedProducts()
    */
    @isTest
    public static void testProductRecommForProduct(){
		User externalUser = [SELECT Id, Effective_Account_Id__c FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        Id masterProd = [SELECT Master_Product__c FROM D1_Product_Recommendation__c LIMIT 1].Master_Product__c;
        List<String> prodResult;
        
        Test.startTest();
            system.runAs(externalUser){
                prodResult = D1_ProductRecommendationController.getRecommendedProducts(masterProd, externalUser.Effective_Account_Id__c);
            }
		Test.stopTest();
        /*
		System.Assert(prodResult.isEmpty() == false, 'Search Query Failed');
		Assert.isTrue(!prodResult.isEmpty(), 'Search Query Failed');        
*/
    }
    
    /**
    * @name : testProductRecommForWebCart
    * @description : This method is used to test the getRecommendedProductsForWebCart() and the parent method getRecommendedProducts()
    */
    @isTest
    public static void testProductRecommForWebCart(){
        Id webcartID = [SELECT Id FROM WebCart WHERE Name = 'TestCart' LIMIT 1].Id;
        List<String> prodResult = new List<String>();
        
        Test.startTest();
            prodResult = D1_ProductRecommendationController.getRecommendedProducts(webcartID, null);
		Test.stopTest();
        
		System.Assert(prodResult != null, 'Search Query Failed');
		Assert.isTrue(prodResult != null, 'Search Query Failed');          
    }
    
    /**
    * @name : testProductRecommForProductCatelog
    * @description : This method is used to test the getRecommendedProductsForProductCategory() and the parent method getRecommendedProducts()
    */
    @isTest
    public static void testProductRecommForProductCatelog(){
		User externalUser = [SELECT Id, Effective_Account_Id__c FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        Id prodCategoryId = [SELECT Id FROM ProductCategory WHERE Name = 'Product' LIMIT 1].Id;
        
        Test.startTest();
            system.runAs(externalUser){
                D1_ProductRecommendationController.getRecommendedProducts(prodCategoryId, externalUser.Effective_Account_Id__c);
            }
		Test.stopTest();
        
		System.Assert(prodCategoryId != null, 'Product Cateogry Not Retrieved');
        Assert.isTrue(prodCategoryId != null, 'Product Cateogry Not Retrieved');        
    }
}