/**

@ History       

@ VERSION      AUTHOR                  DATE              DETAIL
   1.0         Monalisa Halder         18/01/2020        ES20-9195
   2.0 		   Subhodeep sarkar		   15/02/2022		 ES20-11839	
   3.0         Mayukh SRoy             26/10/2022        ES20-13391

**/
@isTest
public class EDGE_KPIAchievementResetBatchTest {
    @isTest
    public static void createTestData(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        system.assert(countryId!=null);
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);//added as part of ES20-11839
        market.Threshold_Format__c = 'Percent';
        market.A_P_Threshold__c = 100;
        insert market;
        
        Market_Cycle__c mCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        mCycle.Start_Date__c=Date.Today();
        insert mCycle;
        List<User> users = new List<User>();
        
        
        
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null);
        
        //Creating Sales Rep 1
        User salesRep1 = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.FirstName = 'SalesRep001';
        salesRep1.Available_Countries__c = 'AU';
        salesRep1.ManagerId = salesManager.Id;
        users.add(salesRep1);
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        testAdminUser.FirstName = 'SalesAdmin001';
        users.add(testAdminUser);
        insert users;
        Test.startTest();
        
        String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        
        Territory_Hierarchy__c terrHirBU = new Territory_Hierarchy__c();
        terrHirBU.RecordTypeId =terrHierBURecordTypeId;
        terrHirBU.Name = 'Australia Territory Hierarchy';
        terrHirBU.Geography__c = countryId;
        insert terrHirBU;
        
        Territory_Hierarchy__c terrHirSA = new Territory_Hierarchy__c();
        terrHirSA.RecordTypeId =terrHierSARecordTypeId;
        terrHirSA.Name = 'Australia Territory Hierarchy';
        terrHirSA.Geography__c = countryId;
        terrHirSA.Parent_BU__c = terrHirBU.Id;
        insert terrHirSA;
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'Australia Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG;
        
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.Territory_Type__c = 'Sales';
        territory.Region__c = terrHirRG.id;
        territory.Pending_For_Batch__c = True;
        insert territory;
                
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Primary_Sales_Territory__c=territory.Id;
        outlet1.Outlet_Visit_Prioritisation_Grade__c=pickupOption.id;
        insert outlet1;
        
        Outlet_Territory__c oTerr = new Outlet_Territory__c();
        oTerr.Territory__c=territory.id;
        oTerr.Outlet__c=outlet1.id;
        insert oTerr;
        
        List<KPI_Achivement__c> KpiList = new List<KPI_Achivement__c>();
        KPI_Achivement__c kpi = new KPI_Achivement__c();
        kpi.Territory__c = territory.Id;
        kpi.KPI_Type__c = 'SoS';
        kpi.Actual_Numerator__c = 10;
        kpi.Total_Denominator__c = 20;
        kpi.Achievement__c =30;
        kpi.Target__c = 40;
        kpi.Previous_Achievement__c = 50;
        kpi.Total_Outlets__c = 1;
        KpiList.add(kpi);
        
        String kpiRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        KPI_Achivement__c kpi1 = new KPI_Achivement__c();
        kpi1.RecordTypeId = kpiRecordTypeId;
        kpi1.KPI_Type__c = 'Volume Category Performance';
        kpi1.Territory__c = territory.Id;
        kpi1.Actual_Numerator__c = 10;
        kpi1.Total_Denominator__c = 20;
        kpi1.Achievement__c =30;
        //kpi1.Target__c = 40;
        kpi1.Target_Number__c = 40;
        kpi1.Previous_Achievement__c = 50;
        kpi1.Total_Outlets__c = 1;
        KpiList.add(kpi1);
        
        String UsrkpiRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        KPI_Achivement__c kpi2 = new KPI_Achivement__c();
        kpi2.RecordTypeId = UsrkpiRecordTypeId;
        kpi2.KPI_Type__c = 'Virtual Call Compliance';
        kpi2.Territory__c = territory.Id;
        kpi2.Actual_Numerator__c = 11;
        kpi2.Total_Denominator__c = 0;
        kpi2.Achievement__c =11;
        KpiList.add(kpi2);
        
        
        String terrKpiRecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        KPI_Achivement__c kpi3 = new KPI_Achivement__c();
        kpi3.RecordTypeId = terrKpiRecordTypeId;
        kpi3.KPI_Type__c = 'Total Activation Survey';
        kpi3.Territory__c = territory.Id;
        kpi3.Actual_Numerator__c = 10;
        kpi3.Total_Denominator__c = 20;
        kpi3.Achievement__c =30;
        //kpi1.Target__c = 40;
        kpi3.Target_Number__c = 40;
        kpi3.Previous_Achievement__c = 50;
        kpi3.Total_Outlets__c = 1;
        kpi3.Pending_Reset__c=true;
        KpiList.add(kpi3);
        
        insert KpiList;
        
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_KPIAchievementResetBatch'
                                                  and Country_Code__c ='AU'];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    
    
}