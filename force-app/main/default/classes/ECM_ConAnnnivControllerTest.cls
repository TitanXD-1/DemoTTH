/*
@Name: ECM_ConAnnnivControllerTest 
@Description: This class is used to cover test data for the class - ECM_ConAnnnivController.
@History                                                                                                                       
VERSION         AUTHOR                     DATE              DETAIL
1.0             AShivam                16/09/2020        Initial Development
2.0             Wribhu Bose            09/12/2022        ECM-6457 Added Product Growth Driver data
2.1             Wribhu Bose            12/12/2022        ECM-6555 (BUG): Added PGD map data
*/

@istest
public class ECM_ConAnnnivControllerTest {
    @isTest
    static void getSummaryDetailsTest(){
        String pickupRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert hirarchy; 
        
        //create territory rec
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Activation_Territory__c = hirarchy.Id;
        insert territory;
        
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=pickupRecordTypeId;
        insert budjectEU;
        
        Id pgdRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product growth-driver').getRecordTypeId();
        
        Pick_Up_Options__c pgd = ECM_UtilityTestClass.createPickUpOption(geographyId, pgdRecordTypeId);
        pgd.ECM_Product_Growth_Driver_Category__c = 'Draught Cocktail';
        pgd.Name = 'Test Cocktail[ES]';
        pgd.Status__c = 'Active';
        insert pgd;
        
        Pick_Up_Options__c pgd2 = ECM_UtilityTestClass.createPickUpOption(geographyId, pgdRecordTypeId);
        pgd2.ECM_Product_Growth_Driver_Category__c = 'Pouring';
        pgd2.Name = 'Test Pouring[ES]';
        pgd2.Status__c = 'Active';
        insert pgd2;
        
        //Setting up Required Item for EU Contract: Account - RecordType Outlet
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c='sale';
        acc.SAP_Sold_to__c='sapsold';
        acc.Email_for_contracts_payments__c = userInfo.getUserEmail();
        acc.Independent_of_Operator__c=true;
        acc.Independent_of_Owner__c=true;
        insert acc;
        System.assert(acc.id!=null,'className should not be null');
        
        Product__c pdt = ECM_UtilityTestClass.createProduct(geographyId,'Test Product');
        pdt.Product_Full_Name__c = 'Test Product';
        pdt.Category__c = 'Cocktails';
        pdt.Classification__c = 'RTD';
        insert pdt;
        
        Market_Assortment_Product__c maPdt = ECM_UtilityTestClass.createMarketAssortmentProduct(pdt.id,geographyId);
        insert maPdt;
        
        Profile prof = [SELECT Id FROM Profile WHERE Name =:'Sales Representative'];
        User conOwner = new User();
        conOwner.firstName = 'test1';
        conOwner.lastName = 'test2';
        conOwner.profileId = prof.Id;        
        conOwner.email = 'test@test.com';
        conOwner.Username ='conowner@test.com';
        conOwner.Alias='test';
        conOwner.Timezonesidkey='America/Los_Angeles';
        conOwner.LocaleSidKey='en_US';
        conOwner.LanguageLocaleKey='en_US';
        conOwner.EmailEncodingKey='UTF-8';
        conOwner.Available_Countries__c='GB';
        conOwner.Title='Legal';
        insert conOwner;
        
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Volume_UoM_for_RTD__c = 'Not Applicable';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = 'Not Applicable';
        contractType.ECM_Anniversary_Email_to_Customer__c = 'To Customer';
        insert contractType;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContract.ECM_Type_of_Contract__c = 'Outlet';
        objContract.OwnerId = conOwner.Id;
        objContract.AccountId = acc.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        insert objContract;
        
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(objContract.id,maPdt.id);
        contractItem.ECM_Lead_Brand__c = true;
        contractItem.ECM_Product_growth_driver__c = 'Test Pouring';
        contractItem.ECM_Product__c=maPdt.Id;
        insert contractItem;
        
        ECM_Contract_Item__c contractItem2 = ECM_UtilityTestClass.createcontractitem(objContract.id,maPdt.id);
        contractItem2.ECM_Lead_Brand__c = true;
        contractItem2.ECM_Product_growth_driver__c = 'Test Cocktail';
        contractItem2.ECM_Product__c=maPdt.Id;
        insert contractItem2;
        
        
        Id salesDriverRecTypeId = Schema.SObjectType.ECM_Sales_Driver__c.getRecordTypeInfosByName().get('Investment').getRecordTypeId();
        Id salesDriverItemRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        Id salesDriverItemDetailRecTypeId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.RecordTypeId = salesDriverRecTypeId;
        salesDriver.ECM_Category__c ='Draught Cocktail';
        insert salesDriver;
        
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract.Id,ECM_Sales_Driver__c=SalesDriver.Id);
        eSCDI.RecordTypeId = salesDriverItemRecTypeId;
        eSCDI.ECM_Total_Investment_Amount__c = 150;
        eSCDI.Contract__c =objContract.Id;
        insert eSCDI;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(ESCDI, contractItem);
        salesDetails1.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails1.ECM_Investment_Amount__c = 200;
        insert salesDetails1;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(ESCDI, contractItem2);
        salesDetails2.Recordtypeid = salesDriverItemDetailRecTypeId;
        salesDetails2.ECM_Investment_Amount__c = 250;
        insert salesDetails2;
        
        ECM_ConAnnnivController getProductsContractDetails = new ECM_ConAnnnivController();
        getProductsContractDetails.targetObjectId = objContract.Id;
        getProductsContractDetails.getContractDetails();   
    }
}