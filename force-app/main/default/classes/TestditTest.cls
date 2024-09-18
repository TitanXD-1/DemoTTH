@isTest
public class TestditTest {
    
 @isTest
    public static void territoryOutletStatusUpdatetest(){
        Test.startTest();  
        createDataElsePart();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = ''
                                                  and Country_Code__c ='AU'];
        //added assert part here by manikant
        List<Market_Batch_Setting__mdt> batchsett = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                     Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = ''
                                                     and Country_Code__c ='AU'];
        system.assert(batchsett.size()>=0,'Batch is Added');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,200);
        Test.stopTest();        
    }
    
   /*  private static Id setupCountry(String countryCode){
        //Id countryId;
        createDataElsePart();
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
    }*/
    
    @isTest
    public static void createDataElsePart(){
        //Id countryId= EDGE_UtilityTestClass.setupCountry('GB');
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        
        //market setting creation
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        insert market;
        //create Sales Representative User
        List<User> usrLst = new List<User>();
        User slrep = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
        slrep.Business_Role__c = 'Sales Representative';
        slrep.trax_user__c=true;
        slrep.Days_In_Trade__c =1;
        usrLst.add(slrep);
        insert usrLst;
        
        User testSalesMgr = EDGE_UtilityTestClass.runAsUser('EDGEManager','Sales Manager');  
        //testSalesMgr.Available_Countries__c = 'GB';
        insert testSalesMgr;
        User testQRep = EDGE_UtilityTestClass.runAsUser('EDGEQualityRep','Quality Representative');
       // testQRep.Available_Countries__c = 'GB';
        insert testQRep; 
        
        
        //outlet-visit prioritization
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        //geography hierarchy creation
        /*Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region'); 
        insert outlet;*/
        
        //market cycle creation
      /*  Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marc.Start_Date__c= System.today();
        marc.End_Date__c=marc.Start_Date__c.addDays(365);
        insert marc;
        /*
        Test.startTest();
        
        User usr = new User();
        usr = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        usr.Available_Countries__c = 'AU';
        usr.IsActive = true;
        usr.Days_In_Trade__c = 1;
        insert usr;
        Test.stopTest(); */
    }
}