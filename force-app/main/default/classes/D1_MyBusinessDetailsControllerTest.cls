/*
* @name: D1_MyBusinessDetailsControllerTest
* @discription : Test class for D1_MyBusinessDetailsControllerTest
* @history
* VERSION       AUTHOR              DATE            DETAIL
* 1.0           Ajay                -               -
* 2.0           Rubeena             29/06/2021      Test Class Refractor [NCP-3781]
* 3.0           Sayan Samaddar      21/09/2022      NCP-6977 (testWholesalerList)
* 4.0			Swagat/Subhrojit	19/10/2022		NCP-7415
*/
@isTest
public with sharing class D1_MyBusinessDetailsControllerTest {

    @isTest
    public static void testIndirectCustomer(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id = :countryId];
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test[GB]');  
        insert pickupOption;
        Account outletAccount = D1_TestDataUtility.getD1Customer();//outlet record
        outletAccount.Direct_Customer__c = false;
        
        D1_TestDataUtility.setUpExternalUser(outletAccount,'Outlet/Retailers');
        
        D1_User_Type__c userType = [SELECT Id,Tax_Identification_Number__c FROM D1_User_Type__c limit 1];
        userType.Tax_Identification_Number__c = '';
        update userType;
        
        User externalUserTest= [Select id from User where Email ='testclassextuser1@testdomain.com' limit 1];
        Test.startTest();
        System.runAs(externalUserTest){
            List<D1_MyBusinessDetailsController.AccountWrapper> accountsList = D1_MyBusinessDetailsController.getDirectAndIndirectAccounts(externalUserTest.Id);
            System.assertEquals('Test Customer Account',accountsList[0].accountName, 'Invalid Account Name');
        }
        Test.stopTest();     
    }
    
    @isTest
    public static void testDirectCustomer(){
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        
        PNR_Partner_Function__c pf = D1_TestDataUtility.getPartnerFunction(directCustomer,'Ship-To');
        insert pf;

        User externalUserTest= [Select id from User where Email ='testclassextuser1@testdomain.com' limit 1];
        Test.startTest();
        System.runAs(externalUserTest){
            List<D1_MyBusinessDetailsController.AccountWrapper> accountsList = D1_MyBusinessDetailsController.getDirectAndIndirectAccounts(externalUserTest.Id);
            System.assertEquals('Test Direct Account',accountsList[0].accountName, 'Invalid Account Name');
        }
        Test.stopTest();
    }

    //NCP-6977
    @isTest
    public static void  testWholesalerList(){
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id = :countryId];
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test[GB]'); 
        insert pickupOption;

        Account outletAccount = D1_TestDataUtility.getD1Customer();//outlet record
        outletAccount.Direct_Customer__c = false;
        insert outletAccount;
        
        Account  distributor = D1_TestDataUtility.getDistributerAccountRecord();
        insert distributor;
        
        List<Supplier_Outlet__c> sOutletList = new List<Supplier_Outlet__c>();
        Supplier_Outlet__c supplierOutlet = D1_TestDataUtility.suppOutletRec(outletAccount.Id,distributor.Id);
        supplierOutlet.Wholesaler_Account_Number__c = '1234';
        supplierOutlet.Preferred_Wholesaler__c = false;
        supplierOutlet.isPrimary__c = false;
        sOutletList.add(supplierOutlet);
        
        Supplier_Outlet__c supplierOutlet2 = D1_TestDataUtility.suppOutletRec(outletAccount.Id,distributor.Id);
        supplierOutlet2.Wholesaler_Account_Number__c = '12345';
        supplierOutlet2.Preferred_Wholesaler__c = true;
        supplierOutlet2.isPrimary__c = false;
        sOutletList.add(supplierOutlet2);
        
        
        Supplier_Outlet__c supplierOutlet3 = D1_TestDataUtility.suppOutletRec(outletAccount.Id,distributor.Id);
        supplierOutlet3.Wholesaler_Account_Number__c = '123456';
        supplierOutlet3.Preferred_Wholesaler__c = true;
        supplierOutlet3.isPrimary__c = true;
        sOutletList.add(supplierOutlet3);
        
        insert sOutletList;
        
        D1_TestDataUtility.setUpExternalUser(outletAccount,'Outlet/Retailers');
        
		User externalUserTest= [Select id from User where Email ='testclassextuser1@testdomain.com' limit 1];
        Test.startTest();
        system.runAs(externalUserTest){
            List<D1_MyBusinessDetailsController.WholesalerWrapper> preferredSupplierList = D1_MyBusinessDetailsController.getWholesalerList(true);
            System.AssertEquals(2, preferredSupplierList.size(), 'preferredSupplierList is Empty');

            List<D1_MyBusinessDetailsController.WholesalerWrapper> allSupplierList = D1_MyBusinessDetailsController.getWholesalerList(false);
            System.AssertEquals(3, allSupplierList.size(), 'allSupplierList is Empty');

            Boolean response = D1_MyBusinessDetailsController.updateWholesalerDetails(allSupplierList);
            System.AssertEquals(true, response, 'Update Wholesaler Failed');
            
            List<D1_MyBusinessDetailsController.WholesalerWrapper> allSupplierListt = D1_MyBusinessDetailsController.removeWholesaler(allSupplierList[0].outletId);
            System.AssertEquals(2, allSupplierListt.size(), 'allSupplierListt is Empty');
        }
        Test.stopTest();
    }
}