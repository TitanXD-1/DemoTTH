/**********************************************************************
Name: EDGE_BonusDetailResultCalcBatchTest
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan D          27/01/2020        Test class for EDGE_BonusDetailResultCalcBatch
2.0         Swaraj S            06/09/2022        Test Class Correction Due to Failure(ES20-13284)
***********************************************************************/
@isTest
public class EDGE_BonusDetailResultCalcBatchTest {
    public static Map<String,Id> geoMap = new Map<String,Id>();
    
    @isTest
    public static void testBonusDetailResultCal(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_BonusDetailResultCalcBatch'
                                                  and Country_Code__c ='ES'];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
    }
    
    
    public static void createData(){
        List<Bonus_Detail__c> bonusDetList = new  List<Bonus_Detail__c>();
        List<KPI_Achivement__c> kpiAchList = new  List<KPI_Achivement__c>();
        List<Bonus_Assignment__c> bonusAssList = new  List<Bonus_Assignment__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = setupCountry('ES');
        //Id plCountryId = setupCountryPL('PL');
        //Id ieCountryId = setupCountryIE('IE');
        //Id nirCountryId = setupCountryNIR('NIR');
        
        Pick_Up_Options__c surveyPickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        surveyPickOp.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        surveyPickOp.Name='Survey[ES]';
        insert surveyPickOp;
        
        
        
        Product__c prod = EDGE_UtilityTestClass.getProd();
        prod.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        insert prod;
        
        
        Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Service';
        terr.Country__c = countryId;
        insert terr;
        
        Market_Cycle__c markCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        markCycle.Start_Date__c = system.today();
        insert markCycle;
        
        Territory_Cycle__c terrCycle = new Territory_Cycle__c();
        terrCycle.Market_Cycle__c = markCycle.Id;
        terrCycle.Territory__c = terr.Id;
        insert terrCycle;
        
        
        KPI_Achivement__c kpiAch = new KPI_Achivement__c();
        kpiAch.RecordTypeId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch.KPI_Type__c = 'NPD';
        kpiAch.Territory__c = terr.Id;
        kpiAch.Product__c = prod.Id;
        kpiAch.Achievement__c = 200;
        kpiAch.Target__c = 350;
        
        KPI_Achivement__c kpiAch1 = new KPI_Achivement__c();
        kpiAch1.RecordTypeId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('Survey KPI').getRecordTypeId();
        kpiAch1.KPI_Type__c = 'Survey';
        kpiAch1.Survey_KPI__c = surveyPickOp.Id;
        kpiAch1.Territory__c = terr.Id;
        kpiAch1.Achievement__c = 200;
        kpiAch1.Target__c = 350;
        
        kpiAchList.add(kpiAch);
        kpiAchList.add(kpiAch1);
        insert kpiAchList;
        Test.startTest();
        Bonus_Header__c bonusHeader = new Bonus_Header__c();
        bonusHeader.Country__c = countryId;
        bonusHeader.Status__c = 'Draft';
        bonusHeader.Max_Cap_total_Bonus__c = 52;
        insert bonusHeader;
        
        Bonus_Detail__c bonusDetail1 = new  Bonus_Detail__c();
        bonusDetail1.RecordTypeId = Schema.SObjectType.Bonus_Detail__c.getRecordTypeInfosByName().get('KPI - Product Level').getRecordTypeId();
        bonusDetail1.Bonus_Header__c =  bonusHeader.Id;
        bonusDetail1.KPI_Type__c = 'NPD';
        bonusDetail1.Weight__c = 50;
        bonusDetail1.Product__c = prod.Id;
        
        Bonus_Detail__c bonusDetail2 = new  Bonus_Detail__c();
        bonusDetail2.RecordTypeId = Schema.SObjectType.Bonus_Detail__c.getRecordTypeInfosByName().get('Survey').getRecordTypeId();
        bonusDetail2.Bonus_Header__c =  bonusHeader.Id;
        bonusDetail2.KPI_Type__c = 'Survey';
        bonusDetail2.Survey_KPI__c = surveyPickOp.Id;
        bonusDetail2.Weight__c = 50;
        bonusDetail2.Product__c = prod.Id;
        bonusDetList.add(bonusDetail1);
        bonusDetList.add(bonusDetail2);
        
        insert bonusDetList;
        
        Bonus_Assignment__c bonusAssignment = new Bonus_Assignment__c();
        bonusAssignment.RecordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
        bonusAssignment.Bonus_Header__c = bonusHeader.Id;
        bonusAssignment.Territory__c = terr.Id;
        bonusAssignment.Global_Percentage__c = 60;
        bonusAssignment.Territory_Percentage__c = 30;
        bonusAssignment.Total__c = 90;
        bonusAssList.add(bonusAssignment);
        
        Bonus_Assignment__c bonusAssignment1 = new Bonus_Assignment__c();
        bonusAssignment1.RecordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
        bonusAssignment1.Bonus_Header__c = bonusHeader.Id;
        bonusAssignment1.Bonus_Detail__c = bonusDetail1.Id;
        bonusAssignment1.Territory__c = terr.Id;
        bonusAssignment1.Global_Percentage__c = 60;
        bonusAssignment1.Territory_Percentage__c = 30;
        bonusAssignment1.Total__c = 90;
        bonusAssList.add(bonusAssignment1);
        
        Bonus_Assignment__c bonusAssignment2 = new Bonus_Assignment__c();
        bonusAssignment2.RecordTypeId = Schema.SObjectType.Bonus_Assignment__c.getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
        bonusAssignment2.Bonus_Header__c = bonusHeader.Id;
        bonusAssignment2.Bonus_Detail__c = bonusDetail2.Id;
        bonusAssignment2.Territory__c = terr.Id;
        bonusAssignment2.Global_Percentage__c = 60;
        bonusAssignment2.Territory_Percentage__c = 30;
        bonusAssignment2.Total__c = 90;
        bonusAssList.add(bonusAssignment2);
        insert bonusAssList;
        
        Bonus_Header_Result__c bonusHeadRes = new Bonus_Header_Result__c();
        bonusHeadRes.Bonus_Header__c = bonusHeader.Id;
        bonusHeadRes.Territory__c = terr.Id;
        bonusHeadRes.Territory_Cycle__c = terrCycle.Id;
        bonusHeadRes.Bonus_Assignment__c = bonusAssignment.Id;
        bonusHeadRes.Market_Cycle__c = markCycle.Id;
        insert bonusHeadRes;
        
        Achievement_Tier__c achvTier =new Achievement_Tier__c();
        achvTier.Bonus_Detail__c = bonusDetail1.Id;
        achvTier.Range_Start__c = 2;
        achvTier.Range_End__c = 30;
        achvTier.Value__c = 52;
        insert achvTier; 
        
        bonusHeader.Status__c = 'Active';
        update bonusHeader;
        Test.stopTest();
        
        
    }
    
    public static Id setupCountry(string countryCode){
        
        //List<Geography__c> geosToInsert = new List<Geography__c>();
        
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GL';
        globalRec.RecordTypeId= EDGE_UtilityTestClass.GlobalRecTypeId;
        //geosToInsert.add(globalRec);
        upsert globalRec;
        //geoMap.put('Global',globalRec.Id);
        
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId= EDGE_UtilityTestClass.marketRecTypeId;
        //geosToInsert.add(market);
        upsert market;
        //geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Southern Europe';
        hub.Code__c = 'SEH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId= EDGE_UtilityTestClass.HubRecTypeId;
        //geosToInsert.add(hub);
        upsert hub;
        //geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Spain';
        cluster.Code__c = 'SPC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId= EDGE_UtilityTestClass.ClusterRecTypeId;
        //geosToInsert.add(cluster);
        upsert cluster;
        //geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Spain';
        country.Code__c = 'ES';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId= EDGE_UtilityTestClass.CountryRecTypeId;
        //geosToInsert.add(country);
        upsert country;
        //geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Spain Mainland';
        area.Code__c = 'ESM';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId= EDGE_UtilityTestClass.AreaRecTypeId;
        //geosToInsert.add(area);
        upsert area;
        //geoMap.put('Area',area.Id);
        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'CANTABRIA';
        region.Code__c = 'ES17';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId= EDGE_UtilityTestClass.RegionRecTypeId;
        //geosToInsert.add(region);
        upsert region;
        //geoMap.put('Region',region.Id);
        
        Geography__c state = EDGE_UtilityTestClass.createGeography('State');
        state.Name = 'Burgos State';
        state.Code__c = 'BRGS';
        state.Parent_Geography__c = country.Id;
        state.RecordTypeId= EDGE_UtilityTestClass.stateRecTypeId;
        //geosToInsert.add(state);
        upsert state;
        //geoMap.put('State',state.Id);
        
        //Database.insert(geosToInsert);
        
        geoMap.put('Global',globalRec.Id);
        geoMap.put('Market',market.Id);
        geoMap.put('Hub',hub.Id);
        geoMap.put('Cluster',cluster.Id);
        geoMap.put('Country',country.Id);
        geoMap.put('Area',area.Id);
        geoMap.put('Region',region.Id);
        geoMap.put('State',state.Id);
        
        
        return country.Id;
        
    }
    
    public static Id setupCountryPL(string countryCode){
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Central Europe';
        cluster.Code__c = 'CEE';
        cluster.Parent_Geography__c = geoMap.get('Hub');
        cluster.RecordTypeId= EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('PLCluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Poland';
        country.Code__c = 'PL';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId= EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('PLCountry',country.Id);
        
        return country.Id;
        
    }
    
    public static Id setupCountryIE(string countryCode){
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'North Western Europe';
        cluster.Code__c = 'NWE';
        cluster.Parent_Geography__c = geoMap.get('Hub');
        cluster.RecordTypeId= EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('IECluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Ireland';
        country.Code__c = 'IE';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId= EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('IECountry',country.Id);
        
        return country.Id;
        
    }
    
    public static Id setupCountryNIR(string countryCode){
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Northen Ireland';
        country.Code__c = 'NIR';
        country.Parent_Geography__c = geoMap.get('IECluster');
        country.RecordTypeId= EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('NIRCountry',country.Id);
        
        return country.Id;
    }
    
}