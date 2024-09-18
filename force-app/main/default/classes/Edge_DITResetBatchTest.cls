/**
* @description :  Edge_DITResetBatchTest
* @purpose : This is the test class for Edge_DITResetBatchTest
* @history :
* Version   Developer         Date             User Story	          			  Purpose
*  1.0      Supriya G      29/07/2024       Initial Development()    This is the test class for EDGE_DITResetBatch
*/
@isTest
public class Edge_DITResetBatchTest {
    static Map<String,Id> geoMap=new Map<String,Id>();
    static Id countryId;
    static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    private static Id setupCountry(String countryCode){
        //Id countryId;
        
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
        //marketMap.put('Market',market.Id);
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
        country.Code__c = countryCode;
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
        return countryId;
    }
    
    @isTest
    public static void createDataElsePart(){
        Id countryId = setupCountry('GB');
        
        
        Geography__c country = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:countryId];
        Id clusterId = country.Parent_Geography__c;
        Geography__c cluster = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:clusterId];
        Id hubId = cluster.Parent_Geography__c;
        Geography__c hub = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:hubId];
        
        //Id countryId= EDGE_UtilityTestClass.setupCountry('GB');
        User testSalesRepAU = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        testSalesRepAU.Available_Countries__c = country.Code__c;
        testSalesRepAU.Assigned_Clusters__c = cluster.Code__c;
        testSalesRepAU.Assigned_Hubs__c = hub.Code__c;
        
        insert testSalesRepAU;
        
        User testSalesMgr = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Sales Manager');    
        insert testSalesMgr;
        User testQRep = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Quality Representative');
        insert testQRep; 
      
        //market setting creation
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.A_P_Threshold__c = 100;
        market.Language__c = 'en_US';
        market.Geography__c = countryId;
        insert market;
        
        
        EDGE_UtilityTestClass.createOrgSettings();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_DITResetBatch'
                                                  and Country_Code__c ='GB' LIMIT 1];
        system.assert(batchSetting.Id != null,'Batch is Added');
        
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        System.debug(LoggingLevel.Debug,'1.1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
        //outlet-visit prioritization
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        insert pickupOption;
        
        //geography hierarchy creation
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region'); 
        insert outlet;
        
        //market cycle creation
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marc.Start_Date__c= System.today();
        marc.End_Date__c=marc.Start_Date__c.addDays(365);
        insert marc;
         
        Test.startTest();
        Database.executeBatch((Database.Batchable<SObject>)job, 100);      
        Test.stopTest(); 
    } 
    
}