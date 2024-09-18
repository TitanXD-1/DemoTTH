/*

*   @Class Name: EDGE_OutletExecutionFindLatestEntryBatch 

*   @Author                  Version       Date           Detail
    Shivam Chauhan		     1.1		08/11/2022       ES20-13432
*/


@isTest
public class EDGE_OutletExecutionFindLatestBatchTest {
   @testSetup
    static void setup() {
       	String productRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
        String activationRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        Id userKPIRecordTypeId;
        userKPIRecordTypeId =Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        insert outlet;
 
		String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.Name = 'Test Product';
        product.Product_Code__c = 'Test1123';
        product.Diageo_Cost__c = 12;
        product.A_P_Cost__c = 14;
        product.POS_Related_Brand__c ='test';
        product.Units_per_POS__c =12;
        product.Limit_Per_Order__c = 12;
        product.Outlet_Cost__c = 12;
        product.POS_Related_Item__c = 'test';
        product.SAP_IO_Number__c = 'test'; 
        product.Pricing_Type__c = 'By Unit';
        product.Country__c = countryId;
        product.RecordTypeId = posRecordTypeId;
        product.POS_Item_Short_Description__c = 'test';
        product.Start_Date__c =  Date.today();
        insert product;
        
  		List<Outlet_Execution__c> outletExecutionList = new List<Outlet_Execution__c>();
        Outlet_Execution__c oE1 = new Outlet_Execution__c();
        oE1.RecordTypeId = productRecordTypeId;
        oE1.Outlet__c = outlet.id;
        oE1.Product__c = product.id;
        oE1.Date_of_Execution__c = System.today();
        outletExecutionList.add(oE1);
        Outlet_Execution__c oE2 = new Outlet_Execution__c();
        oE2.RecordTypeId = productRecordTypeId;
        oE2.Outlet__c = outlet.id;
        oE2.Product__c = product.id;
        oE2.Date_of_Execution__c = System.today().adddays(1);
        outletExecutionList.add(oE2);
        Outlet_Execution__c oE3 = new Outlet_Execution__c();
        oE3.RecordTypeId = activationRecordTypeId;
        oE3.Outlet__c = outlet.id;
        oE3.Activation_Reference__c = 'TestActivation';
        oE3.Date_of_Execution__c = System.today();
        outletExecutionList.add(oE3);
        Outlet_Execution__c oE4 = new Outlet_Execution__c();
        oE4.RecordTypeId = activationRecordTypeId;
        oE4.Outlet__c = outlet.id;
        oE4.Activation_Reference__c = 'TestActivation2';
        oE4.Date_of_Execution__c = System.today().adddays(1);
        outletExecutionList.add(oE4);
        insert outletExecutionList;
        
        Test.setCreatedDate(outletExecutionList[0].id,System.today().adddays(-1));
        Test.setCreatedDate(outletExecutionList[1].id,System.today().adddays(-1));
        Test.setCreatedDate(outletExecutionList[2].id,System.today().adddays(-1));
        Test.setCreatedDate(outletExecutionList[3].id,System.today().adddays(-1));
    }
    
    @isTest 
    static void testExecuteMethod(){
        /*EDGE_OutletExecutionFindLatestEntryBatch batch = new EDGE_OutletExecutionFindLatestEntryBatch();
        Database.executeBatch(batch,200);*/
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletExecutionFindLatestEntryBatch'
                                                  and Country_Code__c ='GB'];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));

    }
}