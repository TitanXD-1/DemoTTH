/**
*  @ Req: This is the test class for EDGE_LineCleaningTaskValidationBatch and EDGE_LineCLeaningCaseTaskCreationBatch
*  @ Class Name: EDGE_LineCleaningTaskValidationBatchTest
*  @ History                    
*  @	Author            Version    			Date           Detail
*  @	Prasanth T      Initial Development	   07/12/2021     ES20-11718
*  @	Anand U			Initial Development	   07/12/2021     ES20-10426
**/
@isTest
public class EDGE_LineCleaningTaskValidationBatchTest {
    
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    final static String QUALITYASSETRECORDTYPEID = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String QUALITYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();        
    public static Map<String,Id> geoMap = new Map<String,Id>();
    public static Id countryId =setupCountry('IE'); 
    @isTest
    public static void updateCaseTask(){
        
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Bronze[IE]';
        pOption.Geography__c = countryId;
        pOption.Type__c = 'Outlet Visit Prioritization';
        pOption.RecordTypeId = outletpriorRecTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'CaseT Test Outlet';
        outlet.Country__c = countryId;
        //outlet.BillingState = 'Leinster';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        outlet.Status__c='Active';
        insert outlet;
        
        date myDate = date.today();
        date weekStart = myDate.toStartofWeek();
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
        
        Line_Cleaning_Cycle__c lineCycle = [SELECT Id FROM Line_Cleaning_Cycle__c WHERE Name = 'Test LCC' LIMIT 1];  
        Line_Cleaning_Holiday__c lh1=new Line_Cleaning_Holiday__c();
        lh1.Active__c=true;
        lh1.Exclusion_Date__c=weekStart.addDays(15);
        lh1.Line_Cleaning_Cycle__c=lineCycle.Id;
        lh1.Country__c=countryId;
        insert lh1;
        Test.startTest();
        Call_Type__c callType=EDGE_UtilityTestClass.getCallType(countryId);
        callType.Name='Quality Planned Call';
        callType.Country__c=countryId;
        callType.Global_Equivalent_Call_Type__c = 'Physical';
        Insert callType;
        
        List<Quality_Case_Configuration__c> caseConfigList = new List<Quality_Case_Configuration__c>();
        String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Service [IE]';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        caseConfigType.Active__c = true;
        caseConfigType.Country__c = countryId;
        caseConfigList.add(caseConfigType);
        
        String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Line Cleaning & Maintenance [IE]';
        caseConfigSubType.Case_Type__c = caseConfigType.Id;
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        caseConfigSubType.Active__c = true;
        caseConfigSubType.Country__c = countryId;
        caseConfigList.add(caseConfigSubType);
        
        String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
        Quality_Case_Configuration__c caseTaskConfig = new Quality_Case_Configuration__c();
        caseTaskConfig.Name = 'Clean Lines';
        caseTaskConfig.Description__c = 'Test Case Configuration Record';
        caseTaskConfig.RecordTypeId = caseTaskTypeRecTypeId;
        caseTaskConfig.Active__c = true;
        caseTaskConfig.Country__c = countryId;
        caseConfigList.add(caseTaskConfig);
        Insert caseConfigList;
        
        Quality_Case_Configuration__c caseConfigType1 = [SELECT Id from Quality_Case_Configuration__c WHERE RecordType.Name = 'Case Type' LIMIT 1];
        Quality_Case_Configuration__c caseConfigSubType1 = [SELECT Id from Quality_Case_Configuration__c WHERE RecordType.Name = 'Case Sub Type' LIMIT 1];
        Quality_Case_Configuration__c caseTaskConfig1 = [SELECT Id from Quality_Case_Configuration__c WHERE RecordType.Name = 'Case Task Type' LIMIT 1];
        
        
        String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();        
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Account__c=outlet.Id;
        callObj.Status__c='Planned';
        callObj.Type_of_Call__c = callType.Id;
        callObj.Plan_Start_Date__c=DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0));
        insert callObj;
 
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet.Id;
        caseObj.Call__c = callobj.Id;
        caseObj.Case_Type__c = caseConfigType1.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType1.Id;
        insert caseObj;
        
        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = caseObj.Id;
        ct.Account__c = outlet.Id;
        ct.Case_Task_Type__c = caseTaskConfig1.Id;
        ct.Achievement_Status__c = 'Open';
        ct.Batch_Generated__c = true;
        ct.Call__c = callObj.Id;
        ct.Line_Cleaning_Cycle__c = lineCycle.Id;
        insert ct;
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'EDGE_LineCleaningTaskValidationBatch'
                                                  AND Country_Code__c='IE' LIMIT 1];
        system.assert(batchSetting.Id != null,'batch Setting Id should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
    }
    
    @isTest
    public static void createCaseTask()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        
        Call_Type__c callType=EDGE_UtilityTestClass.getCallType(countryId);
        callType.Name='Quality Planned Call';
        callType.Country__c=countryId;
        callType.Global_Equivalent_Call_Type__c = 'Physical';
        Insert callType;
        List<Quality_Case_Configuration__c> caseConfigList = new List<Quality_Case_Configuration__c>();
        String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Service [IE]';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        caseConfigType.Active__c = true;
        caseConfigType.Country__c = countryId;
        caseConfigList.add(caseConfigType);
        
        String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Line Cleaning & Maintenance [IE]';
        caseConfigSubType.Case_Type__c = caseConfigType.Id;
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        caseConfigSubType.Active__c = true;
        caseConfigSubType.Country__c = countryId;
        caseConfigList.add(caseConfigSubType);
        
        String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
        Quality_Case_Configuration__c caseTaskConfig = new Quality_Case_Configuration__c();
        caseTaskConfig.Name = 'Clean Lines';
        caseTaskConfig.Description__c = 'Test Case Configuration Record';
        caseTaskConfig.RecordTypeId = caseTaskTypeRecTypeId;
        caseTaskConfig.Active__c = true;
        caseTaskConfig.Country__c = countryId;
        caseConfigList.add(caseTaskConfig);
        Insert caseConfigList;
        
        Market_Setting__c marketSetting=EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Threshold__c = 10;
        marketSetting.Manager_Threshold__c = null;
        marketSetting.Line_Cleaning_Duration__c = 25.0;
        insert marketSetting;
        
        date myDate = date.today();
        date weekStart = myDate.toStartofWeek();
        
        List<Line_Cleaning_Cycle__c> lcList=new List<Line_Cleaning_Cycle__c>();
        Line_Cleaning_Cycle__c lcc = new Line_Cleaning_Cycle__c();
        lcc.Name = 'Test LCC';
        lcc.Active__c=true;
        lcc.Start_Date__c =myDate;
        lcc.Change_in_Holidays__c = true;
        lcc.Change_in_Start_Date__c = true;
        lcc.Country__c = countryId;
        lcList.add(lcc);
        
        Line_Cleaning_Cycle__c lcc2 = new Line_Cleaning_Cycle__c();
        lcc2.Name = 'Test LCIE';
        lcc2.Active__c=true;
        lcc2.Start_Date__c = myDate.addDays(15);
        lcc2.Country__c = countryId;
        lcc2.Change_in_Holidays__c = true;
        lcc2.Change_in_Start_Date__c = true;
        lcList.add(lcc2);   
        insert lcList;
        
        Line_Cleaning_Cycle__c lineCycle = [SELECT Id FROM Line_Cleaning_Cycle__c WHERE Name = 'Test LCC' LIMIT 1];
        Line_Cleaning_Holiday__c lh1=new Line_Cleaning_Holiday__c();
        lh1.Active__c=true;
        lh1.Exclusion_Date__c=weekStart.addDays(24);
        lh1.Line_Cleaning_Cycle__c=lineCycle.Id;
        lh1.Country__c=countryId;
        insert lh1;
        
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Bronze[IE]';
        pOption.Geography__c = countryId;
        pOption.Type__c = 'Outlet Visit Prioritization';
        pOption.RecordTypeId = outletpriorRecTypeId;
        pOption.Days_between_visit__c = 5;
        pOption.Status__c = 'Active';
        insert pOption;
        
        User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Quality Representative');
        usr1.Business_Role__c = 'Dispense Rep';
        usr1.Available_Countries__c = 'IE';
        insert usr1;
        
        
        Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.RecordTypeId = QualityRecordTypeId;
        territory.Territory_Type__c = 'Quality Dispense';
        insert territory;
        Test.startTest();
        Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
        terrMember.User__c = usr1.Id;
        terrMember.Territory__c = territory.Id;
        terrMember.End_Date__c = system.today().AddDays(20);
        terrMember.Type__c = 'Primary';
        insert terrMember;
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'CaseT Test Outlet';
        outlet.Country__c = countryId;
        //outlet.BillingState = 'Leinster';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        outlet.Status__c='Active';
        insert outlet;
        
        Outlet_Territory__c qoutletTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        insert qoutletTer; 
        
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test';
        masterAsst.GUID__c = 'TWRFSHJAKSVGG';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = countryId;
        masterAsst.Priority_Assets__c = true;
        masterAsst.Line_Cleaning_Asset__c = true;
        masterAsst.Active__c = true;
        insert masterAsst;
        
        Asset asst = new Asset();
        asst.Name = 'Test_Asset';
        asst.GUID__c = 'TWRFSHJAKAFF';
        asst.AccountId = outlet.Id;
        asst.Country__c = countryId;
        asst.Quantity = 2;
        asst.Master_Asset__c = masterAsst.Id;
        asst.InstallDate = null;
        asst.Offset_Day__c = 2;
        asst.Batch_Processed__c = true;
        asst.Asset_Removed__c = false;
        asst.Is_OffsetDay_Changed__c = false;
        asst.RecordTypeId = QUALITYASSETRECORDTYPEID;
        Insert asst;
        
        Asset asst2 = new Asset();
        asst2.Name = 'NEW_Asset';
        asst2.GUID__c = 'RAJKSHJSDSCF';
        asst2.AccountId = outlet.Id;
        asst2.Country__c = countryId;
        asst2.Asset_Location__c='Bar';
        asst2.Quantity = 1;
        asst2.Master_Asset__c = masterAsst.Id;
        asst2.Offset_Day__c = 4;
        asst2.Batch_Processed__c = true;
        asst2.Asset_Removed__c = false;
        asst2.Is_OffsetDay_Changed__c = false;
        asst2.RecordTypeId = QUALITYASSETRECORDTYPEID;
        
        Insert asst2;        
        
        Asset offAsset = new Asset(Id = asst.Id);
        offAsset.Offset_Day__c = 4;
        offAsset.Is_OffsetDay_Changed__c = true;
        update offAsset;
        Test.stoptest();
        
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_LineCLeaningCaseTaskCreationBatch'
                                                  AND Country_Code__c='IE' LIMIT 1];
        system.assert(batchSetting.Id != null,'batch setting Id should not be null');
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
        //marketMap.put('Market',market.Id);
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