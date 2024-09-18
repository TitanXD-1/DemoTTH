/*
 * @Name: ECM_ConRelatedItemsTriggerHelperTest
 * @Description: This is the test class for ECM_ContractItemTriggerHelper & ECM_SalesDriverItemTriggerHelper
 * @History                                                            
                                                         
 VERSION    AUTHOR            DATE                    DETAIL
 1.0        Pratap Sen     12/02/2022      Initial Development for ECM-5127 & ECM-5218	
*/
@isTest
public class ECM_ConRelatedItemsTriggerHelperTest {
    @isTest

    public static void testMethod1(){
        List<ECM_Contract_Item__c> lstConItem1 = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item__c> lstConItem2 = new List<ECM_Contract_Item__c>();
        //Map<Id, SObject> items = new Map<Id, SObject>();
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        system.assert(orgSetting.Id != null,'orgSetting Id should not be null');
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        Test.startTest();
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='LI[ES]';
        insert pOption;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;  
        insert acc;
        
        Contract con1 = new Contract();
        con1.Name = 'Test Contract 1';
        con1.AccountId = acc.Id;
        con1.Contract_End_Date__c = System.today();
        insert con1;
        
        ECM_Contract_Item__c conit1 = new ECM_Contract_Item__c();
        conit1.ECM_Contract__c = con1.Id;
        //conit1.ECM_NSV_After_TI__c=10;
        lstConItem1.add(conit1);
        
        ECM_Contract_Item__c conit3 = new ECM_Contract_Item__c();
        conit3.ECM_Contract__c = con1.Id;
        conit3.ECM_CTD_Total_NSV__c=10;
        lstConItem1.add(conit3);
        
        Contract con2 = new Contract();
        con2.Name = 'Test Contract 2';
        con2.AccountId = acc.Id;
        con2.Contract_End_Date__c = System.today();
        insert con2;
        
        ECM_Contract_Item__c conit4 = new ECM_Contract_Item__c();
        conit4.ECM_Contract__c = con2.Id;
        //conit4.ECM_CTD_GP__c=100;
        lstConItem1.add(conit4);
        
        ECM_Contract_Item__c conit2 = new ECM_Contract_Item__c();
        conit2.ECM_Contract__c = con1.Id;
        conit2.ECM_CTD_A_P_Investment__c=20;
        
        lstConItem1.add(conit2);
        insert lstConItem1;
        
        conit3.ECM_CTD_Total_NSV__c=null;
        conit2.ECM_CTD_A_P_Investment__c=33;
        update lstConItem1;
        
        conit2.ECM_CTD_A_P_Investment__c=null;
        conit3.ECM_CTD_Total_NSV__c=32;
        update lstConItem1;
        
        delete conit3;
        delete conit2;
        
       // ECM_ContractItemTriggerHelper.disableConItem(Null, Items);
       // ECM_ContractItemTriggerHelper.disableConItemEdit(lstConItem1);
        
        lstConItem2.addAll(lstConItem1);
        //ECM_ContractItemTriggerHelper.disableConItemDelete(lstConItem2);
        Test.stopTest();
    }
    @isTest

    public static void positiveCaseSDItemTriggerHelper(){
        WrapperTestData testData = createData();
        EDGE_UtilityTestClass.createOrgSettings();
        system.runAs(testData.salesRepUser){
            try{
                testData.salesDriverItem.ECM_Prepayment__c = 80;
                update testData.salesDriverItem;
            }
            catch(Exception ex){
            	system.assert(ex.getMessage().contains('Update failed'),'null');
            }
            try{
                delete testData.salesDriverItem;
            }
            catch(Exception ex){
            	system.assert(ex.getMessage().contains('Delete failed'),'null');
            }
        }
    }
    @isTest
    public static void positiveCaseConItemTriggerHelper(){
        WrapperTestData testData = createData();
        EDGE_UtilityTestClass.createOrgSettings();
        system.runAs(testData.salesRepUser){
            try{
                testData.contractItem.ECM_Volume__c = 100;
                update testData.contractItem;
            }
            catch(Exception ex){
            	system.assert(ex.getMessage().contains('Update failed'),'null');
            }
            try{
                delete testData.contractItem;
            }
            catch(Exception ex){
            	system.assert(ex.getMessage().contains('Delete failed'),'null');
            }
        }
    }
    @isTest
    public static void negativeCase(){
        WrapperTestData testData = createData();
        EDGE_UtilityTestClass.createOrgSettings();
        try{
            testData.salesDriverItem.ECM_Prepayment__c = 80;
            update testData.salesDriverItem;
            delete testData.salesDriverItem;

            undelete testData.salesDriverItem;

            
            testData.contractItem.ECM_Volume__c = 100;
            update testData.contractItem;
            delete testData.contractItem;
        }
        catch(Exception ex){
            system.assert(ex.getMessage() == NULL,'null');
        }
    }

    public static WrapperTestData createData(){
        //Setting up record types & Geography
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        //Id regionId = [SELECT Id from Geography__c WHERE RecordTypeId =: EDGE_UtilityTestClass.RegionRecTypeId LIMIT 1].Id;
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id bRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id terrHierarchyRegion = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        //Setting up Territory Budget        
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

        //Setting up a sales rep & sys adm user to run test as
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp123@test.com';
        insert salesRep;
        
        //Setting up mandatory contract field records
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractType;    
        
        //Setting up contract to link with Related Objects
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        insert contr;
        contr.status = 'Active';
        update contr;
        
        //Setting up mandatory recs for contract item
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'TestProd');
        product.Product_Full_Name__c='TestProd';
        insert product;      
        Market_Assortment_Product__c mapRec = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        //mapRec.ECM_INTO_Material__c = 8;
        insert mapRec;
        
        //Setting up Contract Item
        ECM_Contract_Item__c contractItem = ECM_UtilityTestClass.createcontractitem(contr.Id,mapRec.id);
        insert contractItem;
        
        //Setting up SalesDrivers
        ECM_Sales_Driver__c salesDriverRec = ECM_UtilityTestClass.getSalesdriver(terriBudget.Id,geographyId);
        insert salesDriverRec;
        
        //Setting up Sales Driver Items
        ECM_Sales_Driver_Item__c salesDriverItem = new ECM_Sales_Driver_Item__c();
        salesDriverItem.Contract__c = contr.id;
        salesDriverItem.ECM_Sales_Driver__c = salesDriverRec.Id;
        insert salesDriverItem;
        
        //wrapping up test data
        WrapperTestData wrapObj = new WrapperTestData();
        wrapObj.salesDriverItem = salesDriverItem;
        wrapObj.contractItem = contractItem;
        wrapObj.salesRepUser = salesRep;
        return wrapObj;
    }
     class WrapperTestData{
        ECM_Sales_Driver_Item__c salesDriverItem{get;set;}
        ECM_Contract_Item__c contractItem{get;set;}
        User salesRepUser{get;set;}
    }
}