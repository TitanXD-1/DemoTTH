/**
* @ Name : EDGE_TempAccessForOldUserCTBatchTest
* @ Description : Test class for EDGE_CreateTempAccessForOldUserCTBatch
* @ History  
* @	 	Author          Version    				Date           Detail
* @		Saranya L       Initial Development	   23/05/2022     Created for ES20-12764
**/

@isTest
public class EDGE_TempAccessForOldUserCTBatchTest {
    
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    final static String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String QualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();        
    public static Map<String,Id> geoMap = new Map<String,Id>();
    public static Id countryId =setupCountry('IE'); 
    @isTest
    public static void createTempAccess(){
        List<User> userList = new List<User>();
        User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Quality Representative');
        usr.Business_Role__c = 'Dispense Rep';
        usr.Available_Countries__c = 'IE';
        userList.add(usr);
        User usr2 = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Quality Representative');
        usr2.Business_Role__c = 'Dispense Rep';
        usr2.Available_Countries__c = 'IE';
        userList.add(usr2);
        insert userList;
        
        Business_Role__c busrole = EDGE_UtilityTestClass.getBusinessRole();
        busrole.Country__c = countryId;
        busrole.Global_Equivalent__c ='Dispense Rep';
        busrole.My_accounts_Fields_Display__c='Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        insert busrole;
        
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= busrole.Id ;
        ubr.User__c=usr.Id;
        insert ubr;

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
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pOption.Id;
        outlet.Area__c = geoMap.get('Area');
        outlet.Cluster__c = geoMap.get('Cluster');
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Market__c = geoMap.get('Market'); 
        outlet.Region__c = geoMap.get('Region');
        outlet.Status__c='Active';
        //outlet.Primary_Sales_Territory__c = territory1.Id;
        insert outlet;
        
		List<Territory__c> terrList = new List<Territory__c>();
        Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
       
        territory.RecordTypeId = QualityRecordTypeId;
        territory.Territory_Type__c = 'Quality Dispense';
        territory.Primary_Sales_Rep__c = usr.Id;
        terrList.add(territory);
        
        Territory__c territory1 =  EDGE_UtilityTestClass.getTerritoryRec();
        territory1.Country__c = countryId;
        
        territory1.RecordTypeId = QualityRecordTypeId;
        territory1.Territory_Type__c = 'Service Lead';
        terrList.add(territory1);
        insert terrList;
        
        List<Outlet_Territory__c> outletTerrList = new List<Outlet_Territory__c>();
        Outlet_Territory__c qoutletTer1 = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory1.Id);
        qoutletTer1.Active__c = 'Active';
        outletTerrList.add(qoutletTer1);
        
        Outlet_Territory__c qoutletTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        qoutletTer.Active__c = 'Active';
        outletTerrList.add(qoutletTer);
        insert outletTerrList;
        /*
        Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
        terrMember.User__c = usr.Id;
        terrMember.Territory__c = territory.Id;
        terrMember.Type__c = 'Primary';
        insert terrMember;*/
        
        List<Outlet_Member__c> outMemList = new List<Outlet_Member__c>();
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, usr.id, 'Primary');
        outMemList.add(omTest);
        insert outMemList;
        omTest.Flag_For_Deletion__c = true;
        update omTest;
        
        
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
        Line_Cleaning_Cycle__c lineCycle2 = [SELECT Id FROM Line_Cleaning_Cycle__c WHERE Name = 'Test LCIE' LIMIT 1];
        
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
        caseTaskConfig.Default_Business_Role__c = 'Dispense Rep';
        caseConfigList.add(caseTaskConfig);
        Insert caseConfigList;
        
        Quality_Case_Configuration__c caseConfigType1 = [SELECT Id from Quality_Case_Configuration__c WHERE RecordType.Name = 'Case Type' LIMIT 1];
        Quality_Case_Configuration__c caseConfigSubType1 = [SELECT Id from Quality_Case_Configuration__c WHERE RecordType.Name = 'Case Sub Type' LIMIT 1];
        Quality_Case_Configuration__c caseTaskConfig1 = [SELECT Id,Name,Default_Business_Role__c from Quality_Case_Configuration__c WHERE RecordType.Name = 'Case Task Type' LIMIT 1];
 
        String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();        
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Account__c=outlet.Id;
        callObj.Status__c='Planned';
        callObj.Type_of_Call__c = callType.Id;
        callObj.Assigned_To__c = usr.Id;
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
        
        Map<Id,Case_Task__c> caseTaskToUpdate = new Map<Id,Case_Task__c>();
        List<Case_Task__c> lstCaseTask= new List<Case_Task__c>();
        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = caseObj.Id;
        ct.Account__c = outlet.Id;
        ct.Case_Task_Type__c = caseTaskConfig1.Id;
        ct.Achievement_Status__c = 'Open';
        ct.Batch_Generated__c = true;
        ct.User_Assigned_To__c = usr.Id;
        ct.Call__c = callObj.Id;
        ct.Line_Cleaning_Cycle__c = lineCycle.Id;
        lstCaseTask.add(ct);
        insert lstCaseTask;
       
        //System.assertEquals(1, lstCaseTask.size(), 'msg');
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'EDGE_CreateTempAccessForOldUserCTBatch'
                                                  AND Country_Code__c='IE' LIMIT 1];
        system.assert(batchSetting.Id != null);
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