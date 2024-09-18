/*
* @Name: ECM_SelectProductsController_Test
* @Purpose: This class is used to cover test data for the - ECM_SelectProductsController
* @History                                                          
                                                          
* VERSION    AUTHOR                 DATE              DETAIL
*  1.0		 ECM Development Team					  Initial Development

*/
@isTest
public with sharing class ECM_SelectProductsController_Test {
    @isTest
    public static void selectProductsControllerTestMethodOne() {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        //outletAccount.Person_Responsible__c= usr.Id;
        //outletAccount.OwnerId = usr.Id;
        insert outletAccount;
        system.assert(outletAccount!= null,'outletAccount should not be null');

        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        insert testterritory;

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';

        insert contractType;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.ECM_Agreement_Type__c= contractType.Id;
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        insert objContract;
        
        Product__c prdt1 = new Product__c();
        prdt1.Name = 'Test Product 1';
        prdt1.Product_Full_Name__c = 'Test Product 1 full name';
        insert prdt1;
        Product__c prdt2 = new Product__c();
        prdt2.Name = 'Test Product 2';
        prdt2.Product_Full_Name__c = 'Test Product 2 full name';
        insert prdt2;
        
        Market_Assortment_Product__c mrtAsorPrdt1 = new Market_Assortment_Product__c();
        mrtAsorPrdt1.Market_Assortment__c = geographyId;
        mrtAsorPrdt1.Product__c = prdt1.Id;
        mrtAsorPrdt1.ECM_CM_UoM__c = 'BTL';
        insert mrtAsorPrdt1;
        
        Market_Assortment_Product__c mrtAsorPrdt2 = new Market_Assortment_Product__c();
        mrtAsorPrdt2.Market_Assortment__c = geographyId;
        mrtAsorPrdt2.Product__c = prdt2.Id;
        mrtAsorPrdt2.Base_UoM__c = '9L';
        insert mrtAsorPrdt2;
            
        list<ECM_Product_Agreement__c> prodagrList = new list<ECM_Product_Agreement__c>();
        list<ECM_Product_Agreement__c> prodagrList1 = new list<ECM_Product_Agreement__c>();
        ECM_Product_Agreement__c prdtAgreement1 = new ECM_Product_Agreement__c();
       	prdtAgreement1.ECM_Market_Assortment_Product__c = mrtAsorPrdt1.Id;
        prdtAgreement1.ECM_Contract_Type__c = contractType.Id;
        prdtAgreement1.ECM_Preferred__c = true;
        insert prdtAgreement1;
        prodagrList.add(prdtAgreement1);
        ECM_Product_Agreement__c prdtAgreement2 = new ECM_Product_Agreement__c();
       	prdtAgreement2.ECM_Market_Assortment_Product__c = mrtAsorPrdt2.Id;
        prdtAgreement2.ECM_Contract_Type__c = contractType.Id;
        insert prdtAgreement2;
        //prodagrList.add(prdtAgreement2);
        
        Depletions__c depl1 = new Depletions__c();
        depl1.ECM_Product__c = prdt1.Id;
        depl1.ECM_Volume__c = 10;
        depl1.ECM_Start_Period__c = System.today()-365;
        depl1.ECM_End_Period__c = System.today().toStartOfMonth();
        depl1.ECM_Outlet__c = outletAccount.Id;
        insert depl1;
        
        Depletions__c depl2 = new Depletions__c();
        depl2.ECM_Product__c = prdt2.Id;
        depl2.ECM_Volume__c = 10;
        depl2.ECM_Start_Period__c = System.today()-365;
        depl2.ECM_End_Period__c = System.today().toStartOfMonth();
        depl2.ECM_Outlet__c = outletAccount.Id;
        insert depl2;
        
        ECM_SelectProductsController.fetchProductAgreements(contractType.Id,prodagrList,objContract,True);
        ECM_SelectProductsController.fetchProductAgreements(contractType.Id,prodagrList,objContract,false);
        ECM_SelectProductsController.fetchProductAgreements(contractType.Id,prodagrList1,objContract,false);
        ECM_SelectProductsController.fetchProductAgreements(contractType.Id,prodagrList1,objContract,True);
        ECM_SelectProductsController.cancelContract(objContract.Id);
        ECM_SelectProductsController.insertContractitems(objContract,prodagrList,null);
    }
    @isTest
    public static void selectProductsControllerTestMethodTwo() {
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        //outletAccount.Person_Responsible__c= usr.Id;
        //outletAccount.OwnerId = usr.Id;
        insert outletAccount;
        system.assert(outletAccount!= null,'outletAccount should not be null');
        Geography__c geo = [SELECT Id FROM Geography__c WHERE Name = 'Australia'];
        geo.Name  = 'spain';
        UPDATE geo;
        
        ECM_Price_List__c priceList = ECM_UtilityTestClass.createPriceList('Test PL', geo.Id);
        INSERT priceList;
        
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        insert testterritory;

        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';

        insert contractType;
        
        ECM_Contract_Type__c contractType2=new ECM_Contract_Type__c();
        contractType2.Name='Canaries Tier 0';
        contractType2.Geography__c=geographyId;
        contractType2.ECM_Abbreviation__c='POM';
        contractType2.Volume_UoM_for_Spirits__c='BTL';
        contractType2.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Volume Target;Investment';
        contractType2.ECM_Volume_UoM_for_Beer__c = 'KEG';

        insert contractType2;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.ECM_Agreement_Type__c= contractType2.Id;
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        insert objContract;
        
        Product__c prdt1 = new Product__c();
        prdt1.Name = 'Test Product 1';
        prdt1.Product_Full_Name__c = 'Test Product 1 full name';
        insert prdt1;
        Product__c prdt2 = new Product__c();
        prdt2.Name = 'Test Product 2';
        prdt2.Product_Full_Name__c = 'Test Product 2 full name';
        insert prdt2;
        
        Market_Assortment_Product__c mrtAsorPrdt1 = new Market_Assortment_Product__c();
        mrtAsorPrdt1.Market_Assortment__c = geographyId;
        mrtAsorPrdt1.Product__c = prdt1.Id;
        insert mrtAsorPrdt1;
        Market_Assortment_Product__c mrtAsorPrdt2 = new Market_Assortment_Product__c();
        mrtAsorPrdt2.Market_Assortment__c = geographyId;
        mrtAsorPrdt2.Product__c = prdt2.Id;
        mrtAsorPrdt2.Base_UoM__c = '9L';
        insert mrtAsorPrdt2;
            
        list<ECM_Product_Agreement__c> prodagrList = new list<ECM_Product_Agreement__c>();
        ECM_Product_Agreement__c prdtAgreement1 = new ECM_Product_Agreement__c();
       	prdtAgreement1.ECM_Market_Assortment_Product__c = mrtAsorPrdt1.Id;
        prdtAgreement1.ECM_Contract_Type__c = contractType.Id;
        prdtAgreement1.ECM_Preferred__c = true;
        insert prdtAgreement1;
        //prodagrList.add(prdtAgreement1);
        ECM_Product_Agreement__c prdtAgreement2 = new ECM_Product_Agreement__c();
       	prdtAgreement2.ECM_Market_Assortment_Product__c = mrtAsorPrdt2.Id;
        prdtAgreement2.ECM_Contract_Type__c = contractType.Id;
        
        insert prdtAgreement2;
        prodagrList.add(prdtAgreement2);
        
        ECM_Product_Agreement__c prdtAgreement3 = new ECM_Product_Agreement__c();
       	prdtAgreement3.ECM_Market_Assortment_Product__c = mrtAsorPrdt2.Id;
        prdtAgreement3.ECM_Contract_Type__c = contractType.Id;
        insert prdtAgreement3;
        prodagrList.add(prdtAgreement3);
        
        
        ECM_Product_Agreement__c prdtAgreement4 = new ECM_Product_Agreement__c();
       	prdtAgreement4.ECM_Market_Assortment_Product__c = mrtAsorPrdt2.Id;
        prdtAgreement4.ECM_Contract_Type__c = contractType2.Id;
        insert prdtAgreement4;
        //prodagrList.add(prdtAgreement4);
        ECM_Product_Agreement__c prdtAgreement5 = new ECM_Product_Agreement__c();
       	prdtAgreement5.ECM_Market_Assortment_Product__c = mrtAsorPrdt2.Id;
        prdtAgreement5.ECM_Contract_Type__c = contractType2.Id;
        insert prdtAgreement5;
        //prodagrList.add(prdtAgreement3);
        
        Depletions__c depl1 = new Depletions__c();
        depl1.ECM_Product__c = prdt1.Id;
        depl1.ECM_Volume__c = 10;
        depl1.ECM_Start_Period__c = System.today()-365;
        depl1.ECM_End_Period__c = System.today();
        insert depl1;
        
        Depletions__c depl2 = new Depletions__c();
        depl2.ECM_Product__c = prdt2.Id;
        depl2.ECM_Volume__c = 10;
        depl2.ECM_Start_Period__c = System.today()-365;
        depl2.ECM_End_Period__c = System.today();
        insert depl2;
        
        ECM_Contract_Item__c contrtItem = new ECM_Contract_Item__c();
        contrtItem.ECM_Contract__c = objContract.Id;
        contrtItem.ECM_Product__c = mrtAsorPrdt1.Id;
        insert contrtItem;
        
        Test.startTest();
        ECM_SelectProductsController.fetchProductAgreements(contractType.Id,prodagrList,objContract,True);
        ECM_SelectProductsController.cancelContract(objContract.Id);
        ECM_SelectProductsController.insertContractitems(objContract,prodagrList,null);
        Test.stopTest();
    }
}