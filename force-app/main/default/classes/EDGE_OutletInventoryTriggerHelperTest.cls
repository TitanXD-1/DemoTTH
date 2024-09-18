/**********************************************************************
Name: EDGE_OutletInventoryTriggerHelperTest
=======================================================================
Purpose: Test Class for EDGE_OutletInventoryTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            		DATE              DETAIL
1.0      Shahbaz Khan        13-10-2020        Initial Development
***********************************************************************/
@isTest
public class EDGE_OutletInventoryTriggerHelperTest {
    @isTest
    public static void testOutletInventoryTrigger(){
        Id countryId = EDGE_UtilityTestClass.setupCountryPL('PL');
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold [PL]';
        insert pickOp;
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickOp.Id;
        insert outlet;
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        prod.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        insert prod;
        
        Outlet_Inventory__c outInv = new Outlet_Inventory__c();
        outInv.Account__c = outlet.Id;
        outInv.Product__c = prod.Id;
        outInv.Date__c = system.today();
        outInv.Type__c = 'Inventory';
        outInv.Price__c = 2540;
        insert outInv;
        Outlet_Inventory__c createdInv = [SELECT Unique_Id__c FROM Outlet_Inventory__c WHERE Id =:outInv.Id];
        System.assertEquals(outlet.Id+'_'+prod.Id+'_'+'Inventory'+'_'+system.today().format(),createdInv.Unique_Id__c);
        outInv.Type__c = 'Average';
        update outInv;
        delete outInv;
        undelete outInv;
        Test.stopTest();
        
    }

}