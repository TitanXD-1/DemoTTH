/**
* @Name: Edge_TerritoryCoverageComplianceCalTest 
* @ES20-11060 - Test class for Edge_TerritoryCoverageComplianceCalBatch  
* @History                                                            
* 	@VERSION     AUTHOR              DATE              DETAIL
*	1.0         Sudipta Nandi        11/26/2021        ES20-11060
*	2.0			Rajarshi Lahiri		 02/23/2022		   ES20-10999
*   3.0         Joshraj Sen          08/04/2024        152305

*/
@isTest
public class Edge_TerritoryCoverageComplianceCalTest {
     static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
     static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
     static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
     static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
     static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    static Map<String,Id> geoMap=new Map<String,Id>();
    //static Id countryId;
    
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
        
        //countryId=country.Id;
        return country.Id;
    }
    
    @isTest
    public static void testOutletKPIAchievementCalcBatch(){
        
        createTestData();
        


        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'Edge_TerritoryCoverageComplianceCalBatch'
                                                  and Country_Code__c ='GB'];
        system.assert(batchSetting.Id != null,'Batch is Added');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));

    }
    @isTest
    public static void createTestData(){
        Id countryId = setupCountry('GB');
        System.assert(countryId!=null,'Country is Added');
        EDGE_UtilityTestClass.createOrgSettings();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        

        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        outlet.Status__c = EDGE_Constant.Active;
        insert outlet;

     

        Map<Id,Territory__c> terrMap = new  Map<Id,Territory__c>();
        
       
        
        
        String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
        String terrHierATRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        String terrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
        String terrRecordTypeIdForSR = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
        String terrHierRegionRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();


        
        Territory_Hierarchy__c terrHirBU = new Territory_Hierarchy__c();
        terrHirBU.RecordTypeId =terrHierBURecordTypeId;
        terrHirBU.Name = 'GB Territory Hierarchy';
        terrHirBU.Geography__c = countryId;
        insert terrHirBU;
        
        Territory_Hierarchy__c terrHirSA = new Territory_Hierarchy__c();
        terrHirSA.RecordTypeId =terrHierSARecordTypeId;
        terrHirSA.Name = 'GB Territory Hierarchy';
        terrHirSA.Geography__c = countryId;
        terrHirSA.Parent_BU__c = terrHirBU.Id;
        insert terrHirSA;
        
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'GB Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG;

        
         Territory_Hierarchy__c terrHirRegion = new Territory_Hierarchy__c();
        terrHirRegion.RecordTypeId =terrHierRegionRecordTypeId;
        terrHirRegion.Name = 'GB Territory Hierarchy test';
        terrHirRegion.Geography__c = countryId;
        terrHirRegion.Parent_BU__c = terrHirSA.Id;
        insert terrHirRegion;
        
        System.debug(LoggingLevel.Debug,'1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Territory_Hierarchy__c terrHirAT = new Territory_Hierarchy__c();
        terrHirAT.RecordTypeId =terrHierATRecordTypeId;
        terrHirAT.Name = 'GB Territory Hierarchy AT';
        terrHirAT.Geography__c = countryId;
        terrHirAT.Parent_BU__c = terrHirSA.Id;
        insert terrHirAT;

        
     
        System.debug(LoggingLevel.Debug,'2.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        	Test.startTest();
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.Territory_Type__c = 'Quality Service / Executive';
        //territory.Region__c = terrHirRG.id;
        territory.Pending_For_Batch__c = True;
        territory.RecordTypeId = terrRecordTypeId;
        territory.Activation_Territory__c=terrHirAT.Id;
        territory.Status__c = EDGE_Constant.Active;
        insert territory;
        
        Territory__c territory2 = EDGE_UtilityTestClass.getTerritoryRec();
        territory2.Country__c = countryId;
        territory2.Territory_Type__c = 'Sales';
        territory2.Region__c = terrHirRegion.id;
        territory2.Pending_For_Batch__c = True;
        territory2.RecordTypeId = terrRecordTypeIdForSR;
      //  territory2.Activation_Territory__c=terrHirAT.Id;
        territory2.Status__c = EDGE_Constant.Active;
        insert territory2;
        
        terrMap.put(territory.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory.Id ]);
        terrMap.put(territory2.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory2.Id ]);
        system.debug(LoggingLevel.Debug,'terrMap++'+terrMap);
        // create custom Market Cycle
        Market_Cycle__c newMC = new Market_Cycle__c();
        newMC.Start_Date__c = Date.today();
        newMC.End_Date__c = newMC.Start_Date__c.addDays(14);
        newMC.Geography__c = countryId;
        insert newMC;
        
        // create custom Territory Cycle
        Territory_Cycle__c newTC= new Territory_Cycle__c();
        newTC.Market_Cycle__c = newMC.ID;
        newTC.Territory__c = territory.id;
        insert newTC;
        
        Outlet_Territory__c outletTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        outletTer.Active__c = 'Active';
        insert outletTer;
        Outlet_Territory__c outletTer2 = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory2.Id);
        outletTer2.Active__c = 'Active';
        insert outletTer2;

        

        System.debug(LoggingLevel.Debug,'3.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        
	
     /*   List<KPIs_Target__c> lstKPITarget = new List<KPIs_Target__c>();
        KPIs_Target__c kpiTarget = new KPIs_Target__c();
        kpiTarget.Territory__c = territory.id;
        kpiTarget.Segment__c = 'Hypermarket';
        kpiTarget.Name = 'Sample';
        kpiTarget.Target__c = 89;
        kpiTarget.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget);
        
        KPIs_Target__c kpiTarget1 = new KPIs_Target__c();
        kpiTarget1.Territory__c = territory.id;
        kpiTarget1.Segment__c = 'Hypermarket';
        kpiTarget1.Name = 'SampleHypermarket';
        kpiTarget1.Target__c = 85;
        kpiTarget1.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget1);
        insert lstKPITarget; */
        
        List<Outlet_KPI_Achievement__c> outletKPIAcivmtList = new List<Outlet_KPI_Achievement__c>();
        Outlet_KPI_Achievement__c outKPIAchSales = new Outlet_KPI_Achievement__c();
        outKPIAchSales.Target__c=90;
        outKPIAchSales.KPI_Type__c = 'Coverage for Sales';
        outKPIAchSales.Territory__c = territory2.Id;
        outKPIAchSales.Outlet__c = outlet.id;
        outKPIAchSales.Last_Compliant_Call_Date__c = Date.today().addDays(1);
        outKPIAchSales.Valid__c = true;
        outletKPIAcivmtList.add(outKPIAchSales);
        
        
       /* Outlet_KPI_Achievement__c outKPIAch = new Outlet_KPI_Achievement__c();
        outKPIAch.Target__c=90;
        outKPIAch.KPI_Type__c = 'Coverage for Sales';
        outKPIAch.Territory__c = territory.Id;
        outKPIAch.Outlet__c = outlet.id;
        outKPIAch.Last_Compliant_Call_Date__c = Date.today().addDays(1);
        outKPIAch.Valid__c = true;
        outletKPIAcivmtList.add(outKPIAch);*/


        Outlet_KPI_Achievement__c outKPIAch1 = new Outlet_KPI_Achievement__c();
        outKPIAch1.Target__c=90;
        outKPIAch1.KPI_Type__c = 'Coverage for Activation Specialist';
        outKPIAch1.Territory__c = territory.Id;
        outKPIAch1.Outlet__c = outlet.id;
        outKPIAch1.Last_Compliant_Call_Date__c = Date.today().addDays(1);
        outKPIAch1.Valid__c = true;
        outletKPIAcivmtList.add(outKPIAch1);
        insert outletKPIAcivmtList;
        System.debug(LoggingLevel.Debug,'4.Number of Queries used in this apex code so far: ' + Limits.getQueries());

        
        Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
        territoryWithCycleMap.put(newTC.Territory__c, newTC);
  Test.stopTest();
    /*    Outlet_KPI_Achievement__c outKPIAch2 = new Outlet_KPI_Achievement__c();
        outKPIAch2.Target__c=90;
        outKPIAch2.KPI_Type__c = 'Coverage for Sales';
        outKPIAch2.Territory__c = territory.Id;
        outKPIAch2.Outlet__c = outlet.id;
        outKPIAch2.Last_Compliant_Call_Date__c = Date.today().addDays(1);
        outKPIAch2.Valid__c = true;
        Test.stopTest();
        try{
            insert outKPIAch2;
        }catch(Exception e){
            System.debug('e.getStackTraceString() : '+ e.getStackTraceString());
        }*/
        
        
    } 
}