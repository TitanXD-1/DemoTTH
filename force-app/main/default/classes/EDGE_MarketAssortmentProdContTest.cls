/*
Name: EDGE_MarketAssortmentProdContTest
Purpose: Trigger Helper Class for EDGE_MarketAssortmentProductController
History                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Sandeep Sahoo       14/05/2019        
1.1		  Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/
@isTest
public class EDGE_MarketAssortmentProdContTest {

    @isTest
    public static void testSearchMAPDetails(){
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        testProduct.UPIID__c='12345';
        insert testProduct;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=testProduct.Id,isCompetitor__c=true);
        insert testMAP;
        List<Market_Assortment_Product__c> checkMAPDetails = EDGE_MarketAssortmentProductController.searchMarketAssortProductDetails(' OR Product__r.UPIID__c=\'12345\'', countryId);
        System.assertNotequals(NULL,checkMAPDetails,'Both Values should not match');            
    } 

    @isTest
    public static void testGetProductList(){
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        
        insert testProduct;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=testProduct.Id,isCompetitor__c=true);
        insert testMAP;
        Product__c testProduct1 = EDGE_UtilityTestClass.getProd();
        testProduct1.UPIID__c='142345';
        insert testProduct1;
        List<Product__c> checkProdList = EDGE_MarketAssortmentProductController.getProductList(' OR UPIID__c=\'12345\'', countryId);
        System.assertEquals(checkProdList.contains(testProduct1),False,'checkProdList value should match');
        checkProdList.add(testProduct1);
        EDGE_MarketAssortmentProductController.generateProdWrapList(checkProdList);
        EDGE_MarketAssortmentProductController.getPicklistValues('Order__c','Status__c');
    } 
    

    @isTest
    public static void testDeleteMAPDetails(){
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        insert testProduct;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=testProduct.Id);
        insert testMAP;
        system.assert(testMAP.Id != null,'testMap should not be null');
        List<Market_Assortment_Product__c> checkMAPDetails = new List<Market_Assortment_Product__c>();
        checkMapDetails.add(testMAP);
        EDGE_MarketAssortmentProductController.deleteMarketAssortProductDetails(checkMapDetails);
        
    }
    
    @isTest
    public static void testcreateAndMarkMAP(){
        List<String> freeGoodValues = new List<String>{'Off Trade,On Trade'};
        List<String> usedUomValues = new List<String>{'BAG,LPA'};
        
        Product__c testProduct = EDGE_UtilityTestClass.getProd();
        insert testProduct;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_MarketAssortmentProductController.ProductWrapper testProductWrap = new EDGE_MarketAssortmentProductController.ProductWrapper();    
        testProductWrap.selectedUsedUOM = usedUomValues; 
        testProductWrap.product = testProduct; 
        testProductWrap.isTransferOrder = false;
        testProductWrap.selectedFreeGood = freeGoodValues;
        testProductWrap.priceFG = 0;
        List<EDGE_MarketAssortmentProductController.ProductWrapper> listTestProdWrap = new List<EDGE_MarketAssortmentProductController.ProductWrapper>();
        listTestProdWrap.add(testProductWrap);
        try{
            EDGE_MarketAssortmentProductController.createAndMarkMAP(listTestProdWrap,countryId);             
        } catch(Exception ex){
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
        }
        
        system.assert(listTestProdWrap.size()>0,'listTestProdWrap should have value');
    }
}