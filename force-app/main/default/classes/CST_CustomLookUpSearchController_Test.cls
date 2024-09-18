/*
*  Class Name : CST_CustomLookUpSearchController_Test
*  @description : This is Custom Lookup Search Controller Test
*  @history
*  ------------------------------------------------------------------------
*  1.0         CST Team              19/08/2021        Initial Development
*/
@isTest
public class CST_CustomLookUpSearchController_Test {    
    @isTest static void testMethod1(){
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id uid = userinfo.getUserId();
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Tax Code');
        pickupOption1.Name = 'Gold[SEU]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        upsert pickupOption1;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c = 'Test Product 1 full name';
        product.Country__c=geographyId;
        insert product;
        
        Territory_Hierarchy__c TerritoryHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
        insert TerritoryHierarchy;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Business_Unit__c = TerritoryHierarchy.Id;
        insert territory;
        
        Territory_Budget__c TerritoryBudget = new Territory_Budget__c();
        TerritoryBudget.ECM_Type__c =  'TI';
        TerritoryBudget.Territory__c = territory.id;
        TerritoryBudget.End_Date__c = system.today()+5;
        TerritoryBudget.Initial_Amount__c = 100.00;
        TerritoryBudget.Start_Date__c = system.today()+10;
        TerritoryBudget.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
        insert TerritoryBudget;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        insert acc;
        
        acc.country__c = geographyId;
        acc.Direct_Customer__c= true;
        update acc;
        
        ECM_Internal_Order__c IORecord = new ECM_Internal_Order__c();
        IORecord.Name = 'IO-123456789';
        IORecord.ECM_Product__c = product.Id;
        IORecord.ECM_Budget_Type__c = TerritoryBudget.Id;
        IORecord.ECM_Budget_Type_Pickup_Option__c = pickupOption1.Id;
        IORecord.ECM_Geography__c = geographyId;
        IORecord.ECM_Description__c = 'Testing Record';
        IORecord.ECM_Start_Date__c = Date.newInstance(System.today().year(), 7, 17);
        IORecord.ECM_End_Date__c = Date.newInstance(System.today().year(), 7, 27);
        IORecord.ECM_Budget_Amount__c = 100;
        IORecord.SAP_IO_Type__c='A&P IO';
        insert IORecord;
        
        General_Ledger__c genLed =  new General_Ledger__c();
        genLed.Code__c='123';
        genLed.Name__c='test';
        genLed.Type__c='A&P';
        genLed.Pricing_Condition__c='test';
        genLed.Name='test1';
        insert genLed;
        
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(geographyId, acc.Id);
        claim.CST_Total_Amount__c=30.00;
        claim.Claim_Tax_Code__c = pickupOption1.id;
        claim.Billing_notes__c = '1234567';
        claim.CST_Approver__c=UserInfo.getUserId();
        insert claim;
       
        List<String> extraFields = new List<String>();
        
        Test.startTest();
        CST_CustomLookUpSearchController.fetchLookUpValues('', 'General_Ledger__c', 'A&P', String.valueOf(claim.Id));
        CST_CustomLookUpSearchController.fetchLookUpValues('', 'ECM_Internal_Order__c', 'A&P', String.valueOf(claim.Id));
        CST_CustomLookUpSearchController.fetchLookUpValues('', 'Pick_Up_Options__c', 'A&P', String.valueOf(claim.Id));
        CST_CustomLookUpSearchController.fetchLookUpTableValues('IO', 'ECM_Internal_Order__c', 'A&P',String.valueOf(claim.Id),extraFields);
        Test.stopTest();

    }
    
    /*@testSetup static void setup() {
        Test.startTest();
        Account acc=EDGE_UtilityTestClass.getOwnerOperatorAccount();
        acc.Person_Responsible__c=UserInfo.getUserId();
        Insert acc;  
        Test.stopTest();
    }
    @isTest static void fetchLookUpValues_Test_Negative() {
        Test.startTest();
        //CST_CustomLookUpSearchController.fetchLookUpValues('TestAcct','Account');
        Test.stopTest();
    }
    @isTest static void fetchLookUpValues_Test_Postive() {
        Test.startTest();
        //CST_CustomLookUpSearchController.fetchLookUpValues('Test_OwnerAccount','Account');
        Test.stopTest();
    }*/
}