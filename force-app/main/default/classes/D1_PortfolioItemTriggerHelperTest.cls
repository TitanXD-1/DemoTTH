/**
 * @name D1_PortfolioItemTriggerHelperTest
 * @purpose This provides test coverage to following controller: D1_PortfolioItemTriggerHelper
 * @history
 * VERSION     AUTHOR         DATE               DETAIL
 * 1.0         Ankit Garg	   04/01/2021		     -
 * 2.0			Rubeena		   01/07/2021		  Test Class Refractor [NCP-3763]
**/

@isTest
public class D1_PortfolioItemTriggerHelperTest {
    /**
     * @description Test data setup for D1_PortfolioItemTriggerHelperTest
     */    
    @testSetup
    public static void testSetup(){
        Account account = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        
        D1_TestDataUtility.createOrgSettings();
        
        Sales_Area__c sa= [select Id from Sales_Area__c limit 1];
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true);
 
        Pricebook2 priceBookObj = D1_TestDataUtility.getPricebook2('Test112233');
        insert priceBookObj;
        
        Pricebook2 priceBookObj2 = D1_TestDataUtility.getPricebook2('PF-1234');
        insert priceBookObj2;

        
        List<Product2> proList = new List<Product2>();
        
        Product2 prodObj = D1_TestDataUtility.getProduct();
        prodObj.Name = 'TestProduct1';
        proList.add(prodObj);
        
        Product2 prodObj1 = D1_TestDataUtility.getProduct();
        prodObj1.Name = 'TestProduct123';
        prodObj1.SAP_Material_Id__c = '0000012346';
        proList.add(prodObj1);
        insert proList;
        
        OrderSplit__c oSpilt = D1_TestDataUtility.insertOrderSplit(sa.Id);
        insert oSpilt;

        List<CommerceEntitlementPolicy> policyList = new List<CommerceEntitlementPolicy>();
        
        CommerceEntitlementPolicy entPolicyObj = D1_TestDataUtility.getCommerceEntitlementPolicy('Test Policy','PF-1234');
        policyList.add(entPolicyObj);
        
        CommerceEntitlementPolicy entPolicyObj1 = D1_TestDataUtility.getCommerceEntitlementPolicy('Test Policy1','PF-12345');
        policyList.add(entPolicyObj1);
        
        CommerceEntitlementPolicy entPolicyObj2 = D1_TestDataUtility.getCommerceEntitlementPolicy('Test Policy123','PF-123456');
        policyList.add(entPolicyObj2);
        
        insert policyList;
        
        List<CommerceEntitlementProduct> commerceProductList = new List<CommerceEntitlementProduct>();
        
        CommerceEntitlementProduct entProdObj = D1_TestDataUtility.getCommerceEntitlementProduct(prodObj.Id,entPolicyObj.Id);
        entProdObj.Portfolio_Item_ID__c = 'Test1234';
        commerceProductList.add(entProdObj);
        
		CommerceEntitlementProduct entProdObj1 = D1_TestDataUtility.getCommerceEntitlementProduct(prodObj.Id,entPolicyObj1.Id);
       	entProdObj1.Portfolio_Item_ID__c = 'Test12345';
        commerceProductList.add(entProdObj1);
        
        insert commerceProductList;
        
        PricebookEntry priceBookEntryObj1 = D1_TestDataUtility.getPricebookEntry(standardPricebook.Id,prodObj.Id);
        insert priceBookEntryObj1;
        
        PricebookEntry priceBookEntryObj = D1_TestDataUtility.getPricebookEntry(priceBookObj.Id,prodObj.Id);
        insert priceBookEntryObj;
        
        //List<CommerceEntitlementProduct> cepList = [SELECT Id,Portfolio_Item_ID__c from CommerceEntitlementProduct];
        //System.debug('commerceProductList>>>>'+commerceProductList);
        
    }
    /**
     * @description testPortfolioItemInactive method
     */    
    @isTest
    public static void testPortfolioItemInactive() {
        
        Product2 prodObj =[Select id from Product2 WHERE Name = 'TestProduct1' LIMIT 1];
        Product2 prodObj1 =[Select id from Product2 WHERE Name = 'TestProduct123'LIMIT 1];  

        OrderSplit__c oSpilt = [Select Id FROM OrderSplit__c  limit 1];
      
        
        Test.startTest();
        
        List<Portfolio_Item__c> updateList = new List<Portfolio_Item__c>();
        
        Portfolio_Item__c portItem1 = D1_TestDataUtility.getPortfolioItem(prodObj.Id,oSpilt.Id);
        portItem1.Portfolio_ID__c ='PF-1234';
        portItem1.Portfolio_Item_ID__c = 'Test1234';
        insert portItem1;
        System.assert(portItem1!=null,'Insertion failed');
        
        PricebookEntry pe = [select id from PricebookEntry WHERE Portfolio_Item_ID__c=:portItem1.Portfolio_Item_ID__c];
        System.assert(pe!=null,'Pricebook Entry not created successfully');
        
        portItem1.Inactive__c = true;
        updateList.add(portItem1);
        
        Portfolio_Item__c portItem2 = D1_TestDataUtility.getPortfolioItem(prodObj1.Id,oSpilt.Id);
        portItem2.Portfolio_ID__c ='PF-12345';
        portItem2.Portfolio_Item_ID__c = 'Test12345';
        portItem2.Inactive__c = true;
        insert portItem2;
        System.assert(portItem2!=null,'Insertion failed');
        
        
        portItem2.Inactive__c = false;
        updateList.add(portItem2);
        
        
        Portfolio_Item__c portItem3 = D1_TestDataUtility.getPortfolioItem(prodObj1.Id,oSpilt.Id);
        portItem3.Portfolio_ID__c ='PF-123456';
        portItem3.Portfolio_Item_ID__c = 'Test123456';
        portItem3.Inactive__c = true;
        portItem3.UnitPrice__c = 10;
        insert portItem3;
        System.assert(portItem3!=null,'Insertion failed');
        
        portItem3.Inactive__c = false;
        updateList.add(portItem3);
        
        update updateList;
        System.assert(updateList.size()==3, 'portfolio item not updated');

        System.assertEquals([select id from CommerceEntitlementProduct WHERE Portfolio_Item_ID__c=:'Test1234'].size(),0, 'ID not found');
        
        delete portItem1;
        Test.stopTest();
        
    }
    
}