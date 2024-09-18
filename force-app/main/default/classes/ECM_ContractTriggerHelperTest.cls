/**
* @Description: ECM_ContractTriggerHelperTest
* @Purpose: This is the test class for the Helper class of Contract Trigger for CM team
* @History:                                                            
* @VERSION   AUTHOR               			DATE           		DETAIL
*	1.0      Vinay Tummala      		   07/03/2022      	    ECM-5269
*	1.1		 Nikhilesh Chandak			   14/06/2022			ECM-5678
*   1.2		 Suvendu Roy     			   01/08/2022			ECM-5958
*   1.3		 Suvendu Roy     			   27/09/2022			ECM-6174
*   1.4		 Saurav Prasad     			   05/05/2023			CUS-324
*   1.5      Joshraj Sen                   12/05/2023           CUS-369
*   1.6      Joshraj Sen                   14/05/2024           PMD Fix
*/
@isTest
/**
 * @description Test Class for ECM_ContractTriggerHelper
 */
public class ECM_ContractTriggerHelperTest {
    
    @isTest
    public static void updateSalesAreaAndTerritoryTest(){
        
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        insert salesRep1;
        Territory_Hierarchy__c  hirarchy = new Territory_Hierarchy__c();
        hirarchy.Name='Test';
        hirarchy.RecordTypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        hirarchy.Geography__c=geographyId; 
        insert hirarchy;
        Territory__c territoryTest=ECM_UtilityTestClass.createTerritory(String.valueOf(geographyId));
        territoryTest.Primary_Sales_Rep__c=salesRep.Id;
        territoryTest.Sales_Area__c=hirarchy.Id;
        territoryTest.RecordTypeId=Schema.SObjectType.Territory__c.getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
        insert territoryTest;
        
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep1.Id;
        contr.Status = 'Draft';
        insert contr;
        System.debug(LoggingLevel.debug,contr.OwnerId);
        Test.startTest();
        contr.ownerId =salesRep.Id;
        update contr;
        List<Contract>li=[Select ECM_Primary_Sales_Territory__c from contract where Id=:contr.Id];
        System.assertEquals(territoryTest.Id, li[0].ECM_Primary_Sales_Territory__c,'Fields should match');
        Test.stopTest();
    }
    
    //ECM-5678 - UpdateApprovalLogStatustoCancel
    @isTest
    public static void updateApprovalLogStatusToCancelTest(){
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        insert salesRep1;
        Territory_Hierarchy__c  hirarchy = new Territory_Hierarchy__c();
        hirarchy.Name='Test';
        hirarchy.RecordTypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        hirarchy.Geography__c=geographyId; 
        insert hirarchy;
        Territory__c territoryTest=ECM_UtilityTestClass.createTerritory(String.valueOf(geographyId));
        territoryTest.Primary_Sales_Rep__c=salesRep.Id;
        territoryTest.Sales_Area__c=hirarchy.Id;
        territoryTest.RecordTypeId=Schema.SObjectType.Territory__c.getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
        insert territoryTest;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');

        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep1.Id;
        contr.Status = 'Draft';
        insert contr;
        
        String eCMApprovalLogRecordTypeId = ECM_Approval_Log__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        //String eCMApprovalLogExtraRecordTypeId = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
        ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
        ecmCurrentApprovalLog.Name='test@test.com';
        ecmCurrentApprovalLog.ECM_Status__c='Requested';
        ecmCurrentApprovalLog.ECM_Comment__c='Test User';
        ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
        ecmCurrentApprovalLog.ECM_Contract__c=contr.Id;
        ecmCurrentApprovalLog.RecordTypeId=eCMApprovalLogRecordTypeId;
        //ecmCurrentApprovalLogList.add(ecmCurrentApprovalLog);
        
        insert ecmCurrentApprovalLog;
        
        Test.startTest();
        ContractTriggerHandler.isFirstTime = true;
        contr.Status = 'Cancelled';
		update contr;
        Test.stopTest();
        
    }
    //ECM-5958 - updateApprovalDate
    @isTest
    public static void updateApprovalDateTest(){
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        insert salesRep1;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');

        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep1.Id;
        contr.Status = 'Draft';
        insert contr;
        
        
        Test.startTest();
        ContractTriggerHandler.isFirstTime = true;
        contr.Status = 'Approved';
		update contr;
        Test.stopTest();
    }
    
    @isTest
    public static void updateParentContractTest(){
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        insert salesRep1;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');

        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        Contract objContract = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);
        insert objContract;
        objContract.Status = 'Active';
 		update objContract;
        
        ECM_Payment_Summary__c paysumm = ECM_UtilityTestClass.getPaymentSummary(objContract.Id);
        paysumm.ECM_Payment_Summary_Status__c = 'Open';
        insert paysumm;
        
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep1.Id;
        contr.Status = 'Draft';
        contr.ECM_Parent_Contract__c = objContract.Id;
        contr.ECM_Amended__c = true;
        insert contr;
        
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        for(Integer i=0;i<2;i++){
            Outlet_Contract__c outletContract = new Outlet_Contract__c();
            outletContract.Contract__c = contr.Id;
            outletContract.Outlet__c = acc.Id;
            outletContract.Status__c ='Active';
            outletContractList.add(outletContract);
        }
        Insert outletContractList;
        
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Item').getRecordTypeId();
        product1.Brand_Varient__c = product.Id;
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product
        Product__c product2 = ECM_UtilityTestClass.createProduct(geographyId,'Test 3');
        product2.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('CRI').getRecordTypeId();
        product2.Product_Full_Name__c='Test 3';
        product2.Item__c = product1.Id;
        insert product2;
        //create product
        Product__c product3 = ECM_UtilityTestClass.createProduct(geographyId,'Test 4');
        product3.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        product3.Brand_Varient__c = product.Id;
        product3.Item__c = product1.Id;
        product3.CRI__c = product2.Id;
        product3.Product_Full_Name__c='Test 4';
        insert product3;
        
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = salesRep1.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = salesRep1.Id;
        insert marketassort1;
        Test.startTest();
        
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(contr.Id,Marketassort.id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        newcontractitem.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem.ECM_CTD_Overall_Investment__c = 30;
        insert newcontractitem;
        
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(contr.Id,Marketassort1.id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        newcontractitem1.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem1.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem1.ECM_CTD_Overall_Investment__c = 30;
        insert newcontractitem1;
        
        //OE
        Outlet_Execution__c oe = new Outlet_Execution__c();
        oe.Outlet__c =  acc.Id;
        oe.Product__c = product.Id;
        oe.RecordTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
        oe.Date_of_Execution__c = System.today().addDays(1);
        oe.Distribution_Trax__c='Yes';
        insert oe;
        
        
        ContractTriggerHandler.isFirstTime = true;
        ECM_ContractTriggerHelper.isExecutedOnce = false;
        contr.Status = 'Active';
		update contr;
        delete contr;
        Test.stopTest();
        
    }
    
    @isTest
    public static void updateParentContractTest1(){
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        insert salesRep1;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');

        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        
        Contract objContract = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);
        insert objContract;
        objContract.Status = 'Active';
 		update objContract;
        
        ECM_Payment_Summary__c paysumm = ECM_UtilityTestClass.getPaymentSummary(objContract.Id);
        paysumm.ECM_Payment_Summary_Status__c = 'Open';
        insert paysumm;
        
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep1.Id;
        contr.Status = 'Draft';
        contr.ECM_Parent_Contract__c = objContract.Id;
        contr.ECM_Amended__c = true;
        insert contr;
        
        List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
        for(Integer i=0;i<2;i++){
            Outlet_Contract__c outletContract = new Outlet_Contract__c();
            outletContract.Contract__c = contr.Id;
            outletContract.Outlet__c = acc.Id;
            outletContract.Status__c ='Active';
            outletContractList.add(outletContract);
        }
        Insert outletContractList;
        
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Item').getRecordTypeId();
        product1.Brand_Varient__c = product.Id;
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product
        Product__c product2 = ECM_UtilityTestClass.createProduct(geographyId,'Test 3');
        product2.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('CRI').getRecordTypeId();
        product2.Product_Full_Name__c='Test 3';
        product2.Item__c = product1.Id;
        insert product2;
        //create product
        Product__c product3 = ECM_UtilityTestClass.createProduct(geographyId,'Test 4');
        product3.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        product3.Brand_Varient__c = product.Id;
        product3.Item__c = product1.Id;
        product3.CRI__c = product2.Id;
        product3.Product_Full_Name__c='Test 4';
        insert product3;
        
        
        Test.startTest();
        //create marketassort product 
        Market_Assortment_Product__c marketassort2 = ECM_UtilityTestClass.createMarketAssortmentProduct(product2.Id,geographyId);
        marketassort2.OwnerId = salesRep1.Id;
        insert marketassort2;
        //create marketassort product 
        Market_Assortment_Product__c marketassort3 = ECM_UtilityTestClass.createMarketAssortmentProduct(product3.Id,geographyId);
        marketassort3.OwnerId = salesRep1.Id;
        insert marketassort3;
        

        ECM_Contract_Item__c newcontractitem2= ECM_UtilityTestClass.createcontractitem(contr.Id,Marketassort2.id);
        newcontractitem2.ECM_UoM__c = '1';
        newcontractitem2.ECM_Lead_Brand__c = false;
        newcontractitem2.ECM_Volume_Target_per_PF__c = 5.5;
        newcontractitem2.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem2.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem2.ECM_CTD_Overall_Investment__c = 30;
        insert newcontractitem2;
        
        ECM_Contract_Item__c newcontractitem3 = ECM_UtilityTestClass.createcontractitem(contr.Id,Marketassort3.id);
        newcontractitem3.ECM_UoM__c = '1';
        newcontractitem3.ECM_Lead_Brand__c = false;
        newcontractitem3.ECM_Volume_Target_per_PF__c = 5.5;
        newcontractitem3.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem3.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem3.ECM_CTD_Overall_Investment__c = 30;
        insert newcontractitem3;
        
        
        Outlet_Execution__c oe1 = new Outlet_Execution__c();
        oe1.Outlet__c =  acc.Id;
        oe1.Product__c = product2.Id;
        oe1.RecordTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
        oe1.Date_of_Execution__c = System.today().addDays(3);
        insert oe1;
        
        
        ContractTriggerHandler.isFirstTime = true;
        ECM_ContractTriggerHelper.isExecutedOnce = false;
        contr.Status = 'Active';
		update contr;
        Test.stopTest();
        
    }

}