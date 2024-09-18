/*
* Name: ECM_OneTimeDistributionKPIUpdate
* Purpose: This Class for fetch contract with Status - Active, Expired
*			update Depletion%
*			Note: One time update Distribution Achieved in Contract Items
* History                                                            

VERSION			AUTHOR					DATE				DETAIL
1.0			    Sneha			8/8/2023			Initial Development 
*/

@isTest
public class ECM_OneTimeDistributionKPIUpdateTest {
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id defaulttypeRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();
    public static String productRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
    public static String outletExecutionMASRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    
    @isTest
    public static void checkForDataAndProcess () {
        List<Product__c> productList = new List<Product__c>();
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.Available_Countries__c = 'GB';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        salesRep.Available_Countries__c = 'GB';
        insert salesRep1;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Sales_Org__c ='GB01';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Country__c = geographyId;
        
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
        contr.StartDate = System.today();
        contr.Contract_End_Date__c = System.today().adddays(20);
        contr.ECM_Parent_Contract__c = objContract.Id;
        contr.ECM_Amended__c = true;
        insert contr;
        
        contr.Status = 'Active';
        update contr;
        
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
        
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Item').getRecordTypeId();
        product1.Brand_Varient__c = product.Id;
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        
        Product__c product2 = ECM_UtilityTestClass.createProduct(geographyId,'Test 3');
        product2.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('CRI').getRecordTypeId();
        product2.Product_Full_Name__c='Test 3';
        product2.Item__c = product1.Id;
        productList.add(product2);
        
        //create product
        Product__c product3 = ECM_UtilityTestClass.createProduct(geographyId,'Test 4');
        product3.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        product3.Brand_Varient__c = product.Id;
        product3.Item__c = product1.Id;
        product3.CRI__c = product2.Id;
        product3.Product_Full_Name__c='Test 4';
        productList.add(product3);
		insert  productList;  
        
        //create marketassort product 
        List<Market_Assortment_Product__c> mapList = new List<Market_Assortment_Product__c>();
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = salesRep1.Id;
        mapList.add(marketassort);
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = salesRep1.Id;
        mapList.add(marketassort1);
		insert mapList;        
        Test.startTest();
        
        //create Contract_Item
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(contr.Id,mapList[0].id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        newcontractitem.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem.ECM_CTD_Overall_Investment__c = 30;
        conItemList.add(newcontractitem);
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(contr.Id,mapList[1].id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        newcontractitem1.ECM_CTD_A_P_Investment__c = 10;  //ECM-6223
        newcontractitem1.ECM_CTD_Trade_Lump_Sum__c = 20;
        newcontractitem1.ECM_CTD_Overall_Investment__c = 30;
        conItemList.add(newcontractitem1);
        Insert conItemList;
        
        //OE
        Outlet_Execution__c oe = new Outlet_Execution__c();
        oe.Outlet__c =  acc.Id;
        oe.Product__c = product.Id;
        oe.Distribution_TRAX__c='Yes';
        oe.RecordTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
        oe.Date_of_Execution__c = System.today().adddays(2);
        insert oe;
       
        // Enqueue the batch job with your test data
        ECM_OneTimeDistributionKPIUpdate batch = new ECM_OneTimeDistributionKPIUpdate('GB');
        Database.executeBatch(batch);
        test.stopTest();

    }
}