/**
 * @name D1_GlasswareAndNozzleControllerTest
 * @description Test class for D1_GlasswareAndNozzleController
 * @history                                                                                                                       
 * VERSION      AUTHOR              DATE            DETAIL
 * 1.0          D1 Dev Team                         Initial Development
 * 2.0          Kapil Baliyan       06/11/2023      147593 (Code-Refactor)
 **/
@isTest
public class D1_GlasswareAndNozzleControllerTest {

    @testSetup
    public static void datasetup(){
        //Insert Geography Hierarchy
        Id countryId = D1_TestDataUtility.setupCountry('GB');

        //Insert Pick Up Option Data
        List<Pick_Up_Options__c> pickupOptions = new List<Pick_Up_Options__c>();
        Pick_Up_Options__c outletVisitPriotisation = D1_TestDataUtility.getPickUpOption(countryId, 'Outlet Prioritization', 'Outlet Visit Prioritization', 'Gold[GB]');
        Pick_Up_Options__c productType = D1_TestDataUtility.getPickUpOption(countryId, 'Product Type', 'Product Type', 'Point Of Sale[GB]');
        productType.Product_Type__c = 'Point Of Sale';

        pickupOptions.add(outletVisitPriotisation);
        pickupOptions.add(productType);

        insert pickupOptions;

        Pick_Up_Options__c productSubType = D1_TestDataUtility.getPickUpOption(countryId, 'Product Sub Type', 'Product Type', 'Glassware[GB]');
        productSubType.Parent_Option__c = pickupOptions.get(1).Id;

        insert productSubType;

        Pick_Up_Options__c reasonForRequest = D1_TestDataUtility.getPickUpOption(countryId, 'Reason For Request', 'Reason For Request', 'Broken[GB]');
        reasonForRequest.Parent_Option__c = productSubType.Id;

        insert reasonForRequest;

        //Get Account Instance
        Account outlet = D1_TestDataUtility.getD1Customer();
        outlet.Direct_Customer__c = false;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOptions.get(0).Id;

        //Insert External User
        D1_TestDataUtility.setUpExternalUser(outlet, 'Outlet/Retailers'); //testclassextuser1@testdomain.com

        Account acc = [SELECT Id FROM Account LIMIT 1];

        //Insert Product
        Product__c product= D1_TestDataUtility.getProduct(countryId, 'POS', pickupOptions.get(1).Id);
        product.Product_Sub_Type__c = productSubType.Id;
        System.assert(product != NULL, 'Product not available');
        insert product;
        
        //Insert Stock
        Stock__c stock = D1_TestDataUtility.getStock(countryId, null, product.Id, acc.Id, 'Allocation');
        System.assert(stock != NULL, 'No stock found');
        insert stock;
    }

    @isTest
    static void getProductSubTypesWithTranslationsTest(){
        List<String> productSubTypes = new List<String>{'Glassware[GB]'};
        List<Pick_Up_Options__c> subTypes = D1_GlasswareAndNozzleController.getProductSubTypesWithTranslations(productSubTypes);
        System.AssertEquals(1, subTypes.size(), 'subTypes is NULL');
    }

    @isTest
    static void getProductsPageConfigurationsTest(){
        D1_GlasswareAndNozzleController.ProductConfiguration pConfig = D1_GlasswareAndNozzleController.getProductsPageConfigurations();
        System.AssertEquals(true, pConfig != null, 'Product Config is NULL');
    }

    @isTest
    static void getReasonForRequestsTest(){
        String productSubType = 'Glassware[GB]';
        List<Pick_Up_Options__c> reasonForRequests = D1_GlasswareAndNozzleController.getReasonForRequests(productSubType);
        System.AssertEquals(1, reasonForRequests.size(), 'Reason For Request is NULL');
    }

    @isTest
    static void getProductsTest(){
        User usr = [SELECT Id, AccountId FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        System.runAs(usr){
            List<D1_GlasswareAndNozzleController.ProductWrapper> productWrapperList = D1_GlasswareAndNozzleController.getProducts('Point Of Sale', 'Glassware[GB]', usr.AccountId);
            System.AssertEquals(1, productWrapperList.size(), 'Product List is NULL');
        }
    }

    @isTest
    static void submitOrderTest(){
        User usr = [SELECT Id, AccountId FROM User WHERE Email = 'testclassextuser1@testdomain.com' LIMIT 1];
        Product__c prod = [SELECT Id FROM Product__c LIMIT 1];
        System.runAs(usr){
            Order__c ord = D1_TestDataUtility.createOrder(usr.AccountId, null);

            List<Order_Item__c> orderItems = new List<Order_Item__c>();
            Order_Item__c orderItem = D1_TestDataUtility.createOrderItem(null);
            orderItem.Product__c = prod.Id;

            orderItems.add(orderItem);

            Id orderId = D1_GlasswareAndNozzleController.submitOrder(ord, orderItems);
            System.AssertEquals(true, orderId != null, 'Order is not inserted');
        }
    }
}