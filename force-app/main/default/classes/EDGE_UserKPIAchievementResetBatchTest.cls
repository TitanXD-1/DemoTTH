/**
* @description :  EDGE_UserKPIAchievementResetBatchTest
* @purpose : This is the test class for EDGE_UserKPIAchievementResetBatch
* @history :
* Version   Developer         Date         User Story	         Purpose
*  1.0     	Mayank Singh      12/11/2021   Initial Development   This is the test class for EDGE_UserKPIAchievementResetBatch
*  2.0      Debolina Saha     10/02/2022   ES20-11557            Modified the test class based on the logic applied for ES20-11557
*  3.0      Joshraj Sen       08/04/2024   152305                Fixed SCA
*/
@isTest
public class EDGE_UserKPIAchievementResetBatchTest {
    
    static Map<String,Id> geoMap=new Map<String,Id>();
    static Id countryId;
    static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
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
        //Id countryId= EDGE_UtilityTestClass.setupCountry('GB');
        Id countryId = setupCountry('GB');
        Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        
        //market setting creation
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.A_P_Threshold__c = 100;
        market.Language__c = 'en_US';
        market.Geography__c = countryId;
        insert market;
        
        User testSalesMgr = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Sales Manager');    
        insert testSalesMgr;
        User testQRep = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Quality Representative');
        insert testQRep; 
        
        EDGE_UtilityTestClass.createOrgSettings();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UserKPIAchievementResetBatch'
                                                  and Country_Code__c ='GB' LIMIT 1];
        system.assert(batchSetting.Id != null,'Batch is Added');
        
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));  
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
        
        //ES20-11557
        //creating cases and case tasks types
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        insert caseConfigSubType;
		
        //case creation
        Case caseObj1 = new Case();
        caseObj1.Status = 'New';
        caseObj1.Origin = 'EDGE 365 Global';
        caseObj1.RecordTypeId = qualityRecordTypeId;
        caseObj1.AccountId = outlet.Id;   
        caseObj1.Case_Type__c = caseConfigType.Id;
        caseObj1.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj1;
        
        Case caseObj2 = new Case();
        caseObj2.Status = 'New';
        caseObj2.Origin = 'EDGE 365 Global';
        caseObj2.RecordTypeId = qualityRecordTypeId;
        caseObj2.AccountId = outlet.Id;   
        caseObj2.Case_Type__c = caseConfigType.Id;
        caseObj2.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj2;
        
        //case task creation and assignment
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj1.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet.Id;
        ct1.User_Assigned_To__c =  testQRep.Id;
        ctList.add(ct1);
        
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj2.Id;
        ct2.Case_Task_Type__c = caseConfig.Id;
        ct2.Achievement_Status__c = 'Pending';
        ct2.Actioned_Within_SLA__c = true;
        ct2.Account__c = outlet.Id;
        ct2.User_Assigned_To__c =  testQRep.Id;
        ctList.add(ct2);
        
        Test.startTest();
        KPI_Achivement__c achiRec = new KPI_Achivement__c();
        achiRec.Country__c = countryId;
        achiRec.Achievement__c = 15;
        achiRec.Total_Denominator__c = 10;
        achiRec.RecordTypeId=userKPIRecordTypeId;
        achiRec.KPI_Type__c='Number of Visits';
        achiRec.User__c=testSalesMgr.Id;
        insert achiRec;
        
        
        
        KPI_Achivement__c achiRec1 = new KPI_Achivement__c();
        achiRec1.Country__c = countryId;
        achiRec1.Achievement__c = 15;
        achiRec1.RecordTypeId=userKPIRecordTypeId;
        achiRec1.KPI_Type__c='Case Task vs Total';
        achiRec1.User__c=testQRep.Id;
        insert achiRec1;
         
        
        
        KPI_Achivement__c achiRec2 = new KPI_Achivement__c();
        achiRec2.Country__c = countryId;
        achiRec2.Achievement__c = 15;
        achiRec2.RecordTypeId=userKPIRecordTypeId;
        achiRec2.KPI_Type__c='Case Task vs SLA';
        achiRec2.User__c=testQRep.Id;
        insert achiRec2;
        Test.stopTest(); 
    } 
}