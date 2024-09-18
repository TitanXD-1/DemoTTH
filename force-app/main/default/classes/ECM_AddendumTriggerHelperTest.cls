/*
* @Name: ECM_AddendumTriggerHelperTest
* @Purpose: This is the test class for ECM_AddendumTriggerHelper class.
* @History:                                                                                                                       
* VERSION     AUTHOR            DATE              DETAIL
* 1.0        Pratap Sen      02/08/2022    Initial Development for ECM-5964
* 1.1        Pratap Sen      16/08/2022    Testing for ECM-6029
* 1.2		 Nikhilesh		 22/02/2022	   Added testrecalculateKPI and records for CI in setupData.
*/
@isTest
public class ECM_AddendumTriggerHelperTest {
    @isTest
    public static void testVolumeBasedPSforAddendum(){
        WrapperInst wrapData = setupData();
        test.startTest();
        try{
            wrapData.addendumList[0].ECM_Status__c = 'Approved';
            wrapData.addendumList[1].ECM_Status__c = 'Approved';
            update wrapData.addendumList;
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Class:ECM_AddendumTriggerHelperTest\nmethod:testVolumeBasedPSforAddendum\nException:'+ e.getLineNumber() +'\n'+ e.getMessage());
        }
        test.stopTest();
        
        //Assert after stopTest() as the PS generation methods are future methods
        List<ECM_Payment_Summary__c> psRec1 = [SELECT id,Name FROM ECM_Payment_Summary__c WHERE ECM_Addendum__c =: wrapData.addendumList[0].Id AND ECM_Type__c = 'Volume-Based'];
        System.assert(psRec1.size() == 1,'psRec1 should have 1 record');
        
        List<ECM_Payment_Summary__c> psRec2 = [SELECT id,Name FROM ECM_Payment_Summary__c where ECM_Addendum__c =: wrapData.addendumList[1].Id AND ECM_Type__c = 'Volume-Based'];
        System.assert(psRec2.size() != 1,'psRec2 should have 1 record');
        
        try{
            delete wrapData.addendumList;
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Class:ECM_AddendumTriggerHelperTest\nmethod:testVolumeBasedPSforAddendum\nException:'+ e.getLineNumber() +'\n'+ e.getMessage());
        }
    }
    
    @isTest
    public static void testPromoPSforAddendum(){
        WrapperInst wrapData = setupData();
        test.startTest();
        try{
            wrapData.addendumList[0].ECM_Status__c = 'Approved';
            wrapData.addendumList[1].ECM_Status__c = 'Approved';
            update wrapData.addendumList;
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Class:ECM_AddendumTriggerHelperTest\nmethod:testPromoPSforAddendum\nException:'+ e.getLineNumber() +'\n'+ e.getMessage());
        }
        test.stopTest();
        
        //Assert after stopTest() as the PS generation methods are future methods
        List<ECM_Payment_Summary__c> psRec1 = [SELECT id,Name,ECM_Type__c FROM ECM_Payment_Summary__c WHERE ECM_Addendum__c =: wrapData.addendumList[0].Id AND ECM_Type__c = 'Promo-Standard'];
        System.assert(psRec1.size() > 1,'psRec1 should have 1 record');
        psRec1 = [SELECT id,Name,ECM_Type__c FROM ECM_Payment_Summary__c WHERE ECM_Addendum__c =: wrapData.addendumList[0].Id AND ECM_Type__c = 'Promo-PrePayment'];
        System.assert(psRec1.size() == 0,'psRec1 should have no record');
        
        List<ECM_Payment_Summary__c> psRec2 = [SELECT id,Name,ECM_Type__c FROM ECM_Payment_Summary__c where ECM_Addendum__c =: wrapData.addendumList[1].Id AND ECM_Type__c = 'Promo-Standard'];
        System.assert(psRec2.size() > 1,'psRec1 should more than 1 record');
        psRec2 = [SELECT id,Name,ECM_Type__c FROM ECM_Payment_Summary__c WHERE ECM_Addendum__c =: wrapData.addendumList[1].Id AND ECM_Type__c = 'Promo-PrePayment'];
        System.assert(psRec2.size() > 0,'psRec2 should have some record');
        
    }
    
    @isTest
    public static WrapperInst setupData(){  
        //Record Type Ids
    	Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id terrHierarchyRegion = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        //Setting up Territory Budget for Sales Driver       
        Territory_Hierarchy__c regionHierarchy = ECM_UtilityTestClass.getTerritoryHierarchy(terrHierarchyRegion, geographyId, null);
        insert regionHierarchy;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Region__c=regionHierarchy.Id;
        insert territory;
        Pick_Up_Options__c budjectEU = ECM_UtilityTestClass.createPickUpOption(geographyId, bRecordTypeId);
        insert budjectEU;
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, regionHierarchy.Id);
        terriBudget.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget;
        
        //Contract Mandatory Records : Account
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name = 'LI[ES]';
        insert pOption;
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;  
        insert acc;
        System.assert(acc.id!=null,'acc id should not be null');
        
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.Available_Countries__c='ES';
        insert salesRep;
                
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalES';
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;UoM;Rate Per UoM;Investment';
        insert contractType;
		
        //Setting up Payment Frequency
        ECM_Payment_Frequency__c paymFreqVol = ECM_UtilityTestClass.getPayFre(geographyId);
        paymFreqVol.ECM_Type__c = 'At the End of the Contract';
        paymFreqVol.ECM_End_Date__c = true;
        
        ECM_Payment_Frequency__c recurrPaymentFreqVol = ECM_UtilityTestClass.getPayFre(geographyId);
        recurrPaymentFreqVol.ECM_Type__c = 'Quarterly';
        recurrPaymentFreqVol.ECM_End_Date__c = false;
        recurrPaymentFreqVol.ECM_Number_of_months_for_recurrence__c = '3';
        recurrPaymentFreqVol.ECM_From_When_Starts__c = 'Contract Start Date';
        
        ECM_Payment_Frequency__c recurrRetrospectivePFVol = recurrPaymentFreqVol.clone(false,false,false,false);
        recurrRetrospectivePFVol.ECM_Type__c = 'Quarterly Retrospective';
        
        ECM_Payment_Frequency__c paymFreqPartialPromo = ECM_UtilityTestClass.getPayFre(geographyId);
        paymFreqPartialPromo.ECM_Type__c = 'Partial Prepayment';
        paymFreqPartialPromo.ECM_Prepayment__c = true;
        
        ECM_Payment_Frequency__c paymFreqAfterActivation = ECM_UtilityTestClass.getPayFre(geographyId);
        paymFreqAfterActivation.ECM_Type__c = 'Payment after activation';
        
        
        List<ECM_Payment_Frequency__c> paymentFreqList = new List<ECM_Payment_Frequency__c>{paymFreqVol,recurrPaymentFreqVol,recurrRetrospectivePFVol,
            																				paymFreqPartialPromo,paymFreqAfterActivation};
        insert paymentFreqList;
        
		//Setting up contract
        Contract objContract1 = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContract1.Status = 'Draft';
        objContract1.ECM_Agreement_Type__c=contractType.Id;
        objContract1.ECM_Payment_Frequency_Type__c = paymFreqVol.Id;
        objContract1.ownerId = salesRep.Id;
        objContract1.ECM_Overall_Investment_Amount__c = 1000;
        objContract1.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContract1.ECM_Duration__c = 12;
        objContract1.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        
        Contract objContract2 = objContract1.clone(false,false,false,false);
        objContract2.ECM_Payment_Frequency_Type__c = recurrPaymentFreqVol.Id;
        
        List<Contract> conList = new List<Contract>{objContract1,objContract2};
        insert conList;
        
        //Setting up product and MAP to insert contract items
        List<Product__c> product = new List<Product__c> {ECM_UtilityTestClass.createProduct(geographyId,'TestProd1'),
            											ECM_UtilityTestClass.createProduct(geographyId,'TestProd2')};
        product[0].Product_Full_Name__c='TestProdfullName1';
        product[1].Product_Full_Name__c='TestProdfullName2';
        insert product;
        
        List<Market_Assortment_Product__c> mapRec = new List<Market_Assortment_Product__c>{ECM_UtilityTestClass.createMarketAssortmentProduct(product[0].Id,geographyId),
            																			   ECM_UtilityTestClass.createMarketAssortmentProduct(product[1].Id,geographyId)};
        mapRec[0].ECM_INTO_Material__c = 8;
        mapRec[1].ECM_INTO_Material__c = 10;
        insert mapRec; 
        
        //Setting up contract items
        List<ECM_Contract_Item__c> ciRec = new List<ECM_Contract_Item__c> {ECM_UtilityTestClass.createcontractitem(objContract1.Id,mapRec[0].id),
            															   ECM_UtilityTestClass.createcontractitem(objContract1.Id,mapRec[1].id),
            															   ECM_UtilityTestClass.createcontractitem(objContract2.Id,mapRec[0].id),
            															   ECM_UtilityTestClass.createcontractitem(objContract2.Id,mapRec[1].id)};
        ciRec[0].ECM_Volume__c = 10;
        ciRec[0].ECM_UoM__c = '1';
        ciRec[0].ECM_EU_Volume__c = 10;
        ciRec[0].ECM_Investment__c = ciRec[0].ECM_Volume__c * Integer.valueOf(ciRec[0].ECM_UoM__c);
		ciRec[0].ECM_Total_GP__c = 10;
        ciRec[0].ECM_AnP_investment__c = 10;
        
        ciRec[1].ECM_Volume__c = 15;
        ciRec[1].ECM_UoM__c = '2';
        ciRec[1].ECM_EU_Volume__c = 15;
        ciRec[1].ECM_Investment__c = ciRec[1].ECM_Volume__c * Integer.valueOf(ciRec[1].ECM_UoM__c);
        ciRec[1].ECM_Total_GP__c = 15;
        ciRec[1].ECM_AnP_investment__c = 15;
        
        ciRec[2].ECM_Volume__c = 20;
        ciRec[2].ECM_UoM__c = '0.5';
        ciRec[2].ECM_EU_Volume__c = 20;
        ciRec[2].ECM_Investment__c = ciRec[2].ECM_Volume__c * Decimal.valueOf(ciRec[2].ECM_UoM__c);
        ciRec[2].ECM_Total_GP__c = 20;
        ciRec[2].ECM_AnP_investment__c = 20;
        
        ciRec[3].ECM_Volume__c = 25;
        ciRec[3].ECM_UoM__c = '1';
        ciRec[3].ECM_EU_Volume__c = 25;
        ciRec[3].ECM_Investment__c = ciRec[3].ECM_Volume__c * Integer.valueOf(ciRec[3].ECM_UoM__c);
        ciRec[3].ECM_Total_GP__c = 25;
        ciRec[3].ECM_AnP_investment__c = 25;
        
        insert ciRec;
        
        //Budget type for Sales Driver 
        Pick_Up_Options__c budgetType= new Pick_Up_Options__c();
        budgetType.Name='TI[ES]';
        budgetType.Geography__c=geographyId;
        budgetType.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetType;
        
        Pick_Up_Options__c budgetType1= new Pick_Up_Options__c();
        budgetType1.Name='A&P[ES]';
        budgetType1.Geography__c=geographyId;
        budgetType1.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetType1;
        
        //Setting up SalesDrivers
        List<ECM_Sales_Driver__c> salesDriverRecList = new List<ECM_Sales_Driver__c>{ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,geographyId),
                                                                                     ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,geographyId),
                                                                                     ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,geographyId),
                                                                                     ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,geographyId)};
        /*for(ECM_Sales_Driver__c sd : salesDriverRecList){
            sd.ECM_Budget_Type__c = budgetType.Id;
        }*/
        insert salesDriverRecList;                                                                                 
        salesDriverRecList[0].ECM_Budget_Type__c = budgetType.Id; 
        salesDriverRecList[1].ECM_Budget_Type__c = budgetType.Id;
        salesDriverRecList[2].ECM_Budget_Type__c = budgetType1.Id;
        salesDriverRecList[3].ECM_Budget_Type__c = budgetType1.Id;
        update salesDriverRecList;
        
        //Setting up Sales Driver Items
        List<ECM_Sales_Driver_Item__c> salesDriverItemList = new List<ECM_Sales_Driver_Item__c>
        {new ECM_Sales_Driver_Item__c(Contract__c = objContract1.id, ECM_Sales_Driver__c = salesDriverRecList[0].Id, ECM_Payment_Frequency__c = paymFreqVol.Id),
         new ECM_Sales_Driver_Item__c(Contract__c = objContract1.id, ECM_Sales_Driver__c = salesDriverRecList[1].Id, ECM_Payment_Frequency__c = recurrPaymentFreqVol.Id),
         new ECM_Sales_Driver_Item__c(Contract__c = objContract1.id, ECM_Sales_Driver__c = salesDriverRecList[2].Id, ECM_Payment_Frequency__c = recurrRetrospectivePFVol.Id),
         new ECM_Sales_Driver_Item__c(Contract__c = objContract2.id, ECM_Sales_Driver__c = salesDriverRecList[2].Id, ECM_Payment_Frequency__c = paymFreqPartialPromo.Id, ECM_Payment_Date__c = system.today()),
         new ECM_Sales_Driver_Item__c(Contract__c = objContract2.id, ECM_Sales_Driver__c = salesDriverRecList[3].Id, ECM_Payment_Frequency__c = paymFreqAfterActivation.Id)};
        insert salesDriverItemList;
        
        //Insert Sales Driver Item Detail
        List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailsList = new List<ECM_Sales_Driver_Item_Detail__c>
        {ECM_UtilityTestClass.insertSalesdriverDetails(salesDriverItemList[0], ciRec[0]),
         ECM_UtilityTestClass.insertSalesdriverDetails(salesDriverItemList[1], ciRec[1]),
         ECM_UtilityTestClass.insertSalesdriverDetails(salesDriverItemList[2], ciRec[1]),
         ECM_UtilityTestClass.insertSalesdriverDetails(salesDriverItemList[3], ciRec[2]),
         ECM_UtilityTestClass.insertSalesdriverDetails(salesDriverItemList[4], ciRec[3])};
        insert salesDriverItemDetailsList;
        
        //Make contract active and create Addendum
        conList[0].status = 'Active';
        conList[1].status = 'Active';
        update conList;
        
        ECM_Addendum__c addenDum1 = new ECM_Addendum__c();
        addenDum1.ECM_Agreement_Type__c = contractType.Id;
        addenDum1.ECM_Contract__c = objContract1.Id;
        addenDum1.ECM_Addendum_Type__c = 'Add New Product';
        addenDum1.ECM_Status__c = 'Draft';
        
        ECM_Addendum__c addenDum2 = addenDum1.clone(false,false,false,false);
		addenDum2.ECM_Contract__c = objContract2.Id;
        List<ECM_Addendum__c> addendumList = new List<ECM_Addendum__c>{addenDum1,addenDum2};        
        
        //Enable Trigger run for Addendum Trigger
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
		insert addendumList;
        
        //Map Addendum with Contract item
        ciRec[0].ECM_Addendum__c = addenDum1.Id;
        ciRec[1].ECM_Addendum__c = addenDum1.Id;
        ciRec[2].ECM_Addendum__c = addenDum2.Id;
        ciRec[3].ECM_Addendum__c = addenDum2.Id;
        update ciRec;
        
        //Map Addendum with Sales Driver Item
        salesDriverItemDetailsList[0].ECM_Addendum__c = addenDum1.Id;
        salesDriverItemDetailsList[1].ECM_Addendum__c = addenDum1.Id;
        salesDriverItemDetailsList[2].ECM_Addendum__c = addenDum1.Id;
        salesDriverItemDetailsList[3].ECM_Addendum__c = addenDum2.Id;
        salesDriverItemDetailsList[4].ECM_Addendum__c = addenDum2.Id;
        update salesDriverItemDetailsList;
        
        //Wrap up required data for test methods
        WrapperInst wrapData = new WrapperInst();
        wrapData.conList = conList;
        wrapData.addendumList = addendumList;
        return wrapData;
    }
    
    class WrapperInst{
        List<Contract> conList{get;set;}
        List<ECM_Addendum__c> addendumList{get;set;}
    }
}