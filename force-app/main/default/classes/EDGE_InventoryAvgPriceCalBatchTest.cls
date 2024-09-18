/*
* @description :  EDGE_InventoryAvgPriceCalBatchTest

* @purpose : This is the test class for EDGE_InventoryAvgPriceCalculationBatch

* @history : 

Author              Version       Date           Detail
Monalisa Halder      V1.0        19/09/2020     Test class for EDGE_InventoryAvgPriceCalculationBatch
Sakshi Shah          V2.0        24/08/2024     PMD Fix
*/

@isTest
public class EDGE_InventoryAvgPriceCalBatchTest {

    @isTest
    public static void createTestData(){
		List<Outlet_Inventory__c> outInvList = new List<Outlet_Inventory__c>();
        // added setupCountryCO by Anamika
        Id countryId = EDGE_UtilityTestClass.setupCountryCO('CO');
        Map<String,Id> geoMap = EDGE_UtilityTestClass.geoMap;
        Test.startTest();
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold [CO]';
        insert pickOp;
        system.assert(pickOp.Name!= null,'PickUp Option name should not be null.');// Added by Divya
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickOp.Id;
        outlet.Country__c = countryId;
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market');
        outlet.Area__c = geoMap.get('Area');
        outlet.Region__c = geoMap.get('Region');
        insert outlet;
        
        Call__c call = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        insert call;
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        prod.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        prod.Country__c = countryId;
        insert prod;
        EDGE_UtilityTestClass.createOrgSettings();
        for(integer i=0; i< 199; i++){
        Outlet_Inventory__c outInv = new Outlet_Inventory__c();
        outInv.Account__c = outlet.Id;
        outInv.Product__c = prod.Id;
        outInv.Date__c = system.today() - i;
        outInv.Type__c = 'Inventory';
        outInv.Price__c = 2540;
        outInv.Call__c = call.Id;
        outInv.Stock_Available__c = 500;
        outInvList.add(outInv);
        }
        Outlet_Inventory__c outInv = new Outlet_Inventory__c();
        outInv.Account__c = outlet.Id;
        outInv.Product__c = prod.Id;
        outInv.Date__c = system.today();
        outInv.Type__c = 'Average';
        outInv.Price__c = 2540;
        outInv.Call__c = call.Id;
        outInvList.add(outInv);
        insert outInvList;
        testOutletInventoryBatch();
        Test.stopTest();
        
    }
     /**
 * @description create test outlet inventory batch method
 */
    public static void testOutletInventoryBatch(){
        
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_InventoryAvgPriceCalculationBatch'
                                                  and Country_Code__c ='CO'];
        system.assert(batchSetting.Id != null,'Batch setting id should not be null.');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        
    }
}