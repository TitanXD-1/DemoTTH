/**
* @ Name : EDGE_LineCleaningDateOutletUpdtBatchTest
* @ Description : Test class for EDGE_LineCleaningDateOutletUpdateBatch
* @ History  
* @ Author                   Version    			 Date           Detail
* @	Rajarshi Lahiri       Initial Development	   30/01/2023     ES20-13471
* @ Joshraj Sen           SCA Fix                  08/04/2024     152305
**/

@isTest
public class EDGE_LineCleaningDateOutletUpdtBatchTest {

    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();        
    public static Map<String,Id> geoMap = new Map<String,Id>();
    public static Line_Cleaning_Cycle__c lineCycle;
    public static Line_Cleaning_Cycle__c lineCycle2;
    //Creating test Data
    public static void createData(){
        
        Id countryId =setupCountry('IE');
        EDGE_UtilityTestClass.createOrgSettings();
        final String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting;

        
        date myDate = date.today();
        List<Line_Cleaning_Cycle__c> lcList=new List<Line_Cleaning_Cycle__c>();
        Line_Cleaning_Cycle__c lcc = new Line_Cleaning_Cycle__c();
        lcc.Name = 'Test LCC';
        lcc.Active__c=true;
        lcc.Start_Date__c =myDate;
        lcc.Change_in_Holidays__c = true;
        lcc.Change_in_Start_Date__c = true;
        lcc.Country__c = countryId;
        lcc.End_Date__c = myDate.addDays(14);        
        lcList.add(lcc);
        
        Line_Cleaning_Cycle__c lcc2 = new Line_Cleaning_Cycle__c();
        lcc2.Name = 'Test LCIE';
        lcc2.Active__c=true;
        lcc2.Start_Date__c = myDate.addDays(15);
        lcc2.Country__c = countryId;
        lcc2.End_Date__c = lcc2.Start_Date__c.addDays(14);
        lcc2.Change_in_Holidays__c = true;
        lcc2.Change_in_Start_Date__c = true;
        lcList.add(lcc2);   
        insert lcList;

        
        lineCycle = [SELECT Id,Start_Date__c FROM Line_Cleaning_Cycle__c WHERE Name = 'Test LCC' LIMIT 1];
        lineCycle2 = [SELECT Id,Start_Date__c FROM Line_Cleaning_Cycle__c WHERE Name = 'Test LCIE' LIMIT 1];
        
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Bronze[IE]';
        pOption.Geography__c = countryId;
        pOption.Type__c = 'Outlet Visit Prioritization';
        pOption.RecordTypeId = outletpriorRecTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;

        List<Account> accList=new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Country__c = countryId;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = countryId;//geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
        outlet.Status__c='Active';
        accList.add(outlet);
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Country__c = countryId;
        outlet2.Area__c = geoMap.get('Area');
        outlet2.Cluster__c = geoMap.get('Cluster');
        outlet2.Country__c = countryId;//geoMap.get('Country');
        outlet2.Hub__c = geoMap.get('Hub');
        outlet2.Market__c = geoMap.get('Market'); 
        outlet2.Region__c = geoMap.get('Region');
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
        outlet2.Status__c='Active';
        outlet2.Next_Line_Cleaning_Date__c=date.today().addDays(-2);
        accList.add(outlet2);
		
        insert accList;
        
        List<Asset> assetList = new List<Asset>();
        
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test';
        masterAsst.GUID__c = 'TWRFSHJAKSVGG';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = countryId;
        masterAsst.Priority_Assets__c = TRUE;
        masterAsst.Line_Cleaning_Asset__c = TRUE;
        masterAsst.Active__c = TRUE;
        insert masterAsst;

        
        Asset asst = new Asset();
        asst.Name = 'Test_Asset';
        asst.GUID__c = 'TWRFSHJAKSVGG';
        asst.AccountId = outlet.Id;
        asst.Country__c = countryId;
        asst.Quantity = 1;
        asst.Master_Asset__c = masterAsst.Id;
        asst.InstallDate = null;
        asst.Offset_Day__c = 2;
        asst.Batch_Processed__c = false;
        asst.RecordTypeId = qualityAssetRecordTypeId;
        assetList.add(asst);
        insert assetList;

        
        Test.startTest();
        Call__c callobj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        insert callObj;

        
        List<Quality_Case_Configuration__c> qualityCaseConfigList = new List<Quality_Case_Configuration__c>();
        String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        qualityCaseConfigList.add(caseConfig);
        
        String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Service [IR]';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        qualityCaseConfigList.add(caseConfigType);

		String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Service [IR]';
        caseConfigSubType.Case_Type__c = caseConfigType.Id;
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        qualityCaseConfigList.add(caseConfigSubType);
        insert qualityCaseConfigList;

        
       
    }
    
    
    @isTest
    public static void testLineCleaningDateOutletUpdtBatch()
    {
        createData();

        
        Account outlet = [SELECT Id from Account where RecordType.name= 'Outlet' and Country__r.Code__c ='IE' LIMIT 1];
        Call__c callObj = [SELECT Id from Call__c LIMIT 1];
        Asset asst = [SELECT Id from Asset where Recordtype.Name = 'Quality' and Country__r.Code__c = 'IE' LIMIT 1];
        Quality_Case_Configuration__c caseConfigType = [SELECT Id from Quality_Case_Configuration__c where RecordType.Name = 'Case Type' LIMIT 1];
        Quality_Case_Configuration__c caseConfigSubType = [SELECT Id from Quality_Case_Configuration__c where RecordType.Name = 'Case Sub Type' LIMIT 1];
        Quality_Case_Configuration__c caseConfig = [SELECT Id from Quality_Case_Configuration__c where RecordType.Name = 'Case Task Type' LIMIT 1];
        
        String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        System.debug(LoggingLevel.Debug,'qualityRecordTypeId :' + qualityRecordTypeId);
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet.Id;
        caseObj.Call__c = callObj.Id;
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;

        
        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = caseObj.Id;
        ct.Account__c = outlet.Id;
        ct.Case_Task_Type__c = caseConfig.Id;
        ct.Achievement_Status__c = 'Open';
        ct.Batch_Generated__c = true;
        ct.Line_Cleaning_Asset__c = asst.Id;
        ct.Line_Cleaning_Due_Date__c=lineCycle.Start_Date__c.addDays(2);
        ct.Call__c = callObj.Id;
        ct.Line_Cleaning_Cycle__c = lineCycle.Id;
        insert ct;
        Test.stopTest();

        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_LineCleaningDateOutletUpdateBatch'
                                                  AND Country_Code__c='IE' LIMIT 1];
        system.assert(batchSetting.Id != null,'Batch is Added');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));

    }
    public static Id setupCountry(string countryCode){
        
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global';
        globalRec.Code__c = 'GL';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global',globalRec.Id);
        
        Geography__c market =EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        geoMap.put('Market',market.Id);
        
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Island of Ireland';
        hub.Code__c = 'IOIH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Ireland';
        cluster.Code__c = 'IOIC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Republic of Ireland';
        country.Code__c = countryCode;
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        country.Extended_Country_Code__c = 'IE-ROI';
        insert country;
        geoMap.put('Country',country.Id);
        
        
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Republic of Ireland';
        area.Code__c = 'IEA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);
        
        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Carlow';
        region.Code__c = 'IE01';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        
        Geography__c state = EDGE_UtilityTestClass.createGeography('State');
        state.Name = 'Leinster';
        state.Code__c = 'ABCD';
        state.Parent_Geography__c = country.Id;
        state.RecordTypeId=EDGE_UtilityTestClass.stateRecTypeId;
        insert state;
        geoMap.put('State',state.Id);
        
        return country.Id;
        
        }
}