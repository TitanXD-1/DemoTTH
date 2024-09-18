/*
 * Class Name : EDGE_CSTClaimItemTriggerHelperTest
 * @description: Test class for EDGE_CSTClaimItemTriggerHelper
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  			21/05/2021        Initial Development
*/

@isTest
public class EDGE_CSTClaimItemTriggerHelperTest {
    
    /*
	* @description : Test method for EDGE_CSTClaimItemTriggerHelper
	* @return : void
	* @param : 
	*/
    
    @isTest
    public static void updateCurrencyFromClaimTest(){
         
        EDGE_UtilityTestClass.createOrgSettings();
        
        CSTClaimItemTriggerHandler cstClaimItemHandler = new CSTClaimItemTriggerHandler();
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        
        
        Sales_Organisation__c salesOrg = new Sales_Organisation__c();
        salesOrg.Name='Test';
        salesOrg.Description__c='test';
        salesOrg.Code__c='BE01';
        salesOrg.Country__c=countryId;
        insert salesOrg;
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[SEU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        pickupOption.Sales_Organisation__c= salesOrg.Id;
        upsert pickupOption;
        
        ////
        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Tax Code');
        pickupOption1.Name = 'Gold[SEU]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        pickupOption1.Sales_Organisation__c= salesOrg.Id;
        upsert pickupOption1;
        
        ////
        //Account prospect = EDGE_UtilityTestClass.getProspectRecord(pickupOption.Id);
        //insert prospect; 
        Test.startTest();       
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        //outletAccount.Direct_Customer__c= true;
        upsert outletAccount;
        outletAccount.Direct_Customer__c= true;
        outletAccount.Sales_Organisation__c = salesOrg.Id;
        update outletAccount;
        ECM_Internal_Order__c IORecord = new ECM_Internal_Order__c();
        IORecord.Name = 'IO-123456789';
        //IORecord.ECM_Product__c = product.Id;
        //IORecord.ECM_Budget_Type__c = TerritoryBudget.Id;
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

        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, outletAccount.Id);
        claim.Claim_Tax_Code__c= pickupOption1.id;
        claim.Claim_Tax_Code__c = pickupOption1.id;
        claim.CST_Sales_Organisation__c=salesOrg.Id;
        insert claim;
        CST_Claim_Item__c claimItem = EDGE_UtilityTestClass.getclaimItemRecord(claim.Id);
        claimItem.Type__c = 'A&P'; 
        claimItem.CST_Internal_Order__c=IORecord.Id;
        claimItem.CST_General_Ledger__c=genLed.Id;
        insert claimItem;
        
        
        claimItem.CST_Net_Value__c = 13;
        update claimItem;
        
        delete claimItem;
        
        //cstClaimItemHandler.beforeDelete(null);
        //cstClaimItemHandler.afterDelete(null);
        cstClaimItemHandler.afterUndelete(null);
        List<CST_Claim_Item__c> listnewItems = new List<CST_Claim_Item__c>(); 
        listnewItems.add(claimItem);
        //EDGE_CSTClaimItemTriggerHelper.updateCurrencyFromClaim(listnewItems);
        
        Test.stopTest();
    }
}