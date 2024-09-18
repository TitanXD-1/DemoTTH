/**
*   Req: This is the test class for EDGE_UserKPILeaderBoardCalcBatch
*   Class Name: EDGE_UserKPILeaderBoardCalcBatchTest
*   History                    
* 	Author          Version    Date           Detail
* 	Saranya L       V1.0	   15/11/2021     Created for ES20-11206 && ES20-11306 
**/

@isTest
public class EDGE_UserKPILeaderBoardCalcBatchTest {
    //Creating test Data
    public static void createData(){
        List<KPI_Achivement__c> UserKpiAchiveList = new List<KPI_Achivement__c>();
        Id regionRecTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Market').getRecordTypeId();
        Id countryId = EDGE_UtilityTestClass.setupCountry('GB'); 
        //Creating Quality Rep User
        User testQRepUser = EDGE_UtilityTestClass.runAsUser('Qualityrep1','Quality Representative');
        testQRepUser.Available_Countries__c = 'GB';
        testQRepUser.Email = 'quality_reptest123@diageo.com';
        insert testQRepUser;
        
        String userKpiRecTypeID =  KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSetting.Ranking_calculation__c = 'Ranking as per KPI Achievement';
        insert marketSetting;
        
        List<Geography__c> areaGeoList = [SELECT Id FROM Geography__c WHERE RecordType.Name = 'Global' LIMIT 1];
        //Create Market record
        if(areaGeoList != null && !areaGeoList.isEmpty()){
            Geography__c region = new Geography__c();
            region.Name = 'Europe and Turkey';
            region.Code__c = 'GB12';
            region.Parent_Geography__c = areaGeoList[0].Id;
            region.RecordTypeId=RegionRecTypeId;
            insert region;	
        }
        
        // Creating User KPI Achivement for kpi type - Number of Visits, Case Task vs Total, Case Task vs SLA
        KPI_Achivement__c kpiAchive = new KPI_Achivement__c();
        kpiAchive.KPI_Type__c = 'Number of Visits';
        kpiAchive.RecordTypeId = userKpiRecTypeID;
        kpiAchive.Achievement__c = 10;
        kpiAchive.User__c = testQRepUser.Id;
        UserKpiAchiveList.add(kpiAchive);           
        
        KPI_Achivement__c kpiAchive1 = new KPI_Achivement__c();
        kpiAchive1.KPI_Type__c = 'Case Task vs Total';
        kpiAchive1.RecordTypeId = userKpiRecTypeID;
        kpiAchive1.Achievement__c = 10.6;
        kpiAchive1.User__c = testQRepUser.Id;
        UserKpiAchiveList.add(kpiAchive1);          
        
        KPI_Achivement__c kpiAchive2 = new KPI_Achivement__c();
        kpiAchive2.KPI_Type__c = 'Case Task vs SLA';
        kpiAchive2.RecordTypeId = userKpiRecTypeID;
        kpiAchive2.Achievement__c = 10.7;
        kpiAchive2.User__c = testQRepUser.Id;
        UserKpiAchiveList.add(kpiAchive2); 
        
        KPI_Achivement__c kpiAchive4 = new KPI_Achivement__c();
        kpiAchive4.KPI_Type__c = 'Number of Visits';
        kpiAchive4.RecordTypeId = userKpiRecTypeID;
        kpiAchive4.Achievement__c = 20;
        kpiAchive4.User__c = testQRepUser.Id;
        UserKpiAchiveList.add(kpiAchive4); 
        
        insert UserKpiAchiveList;
        
    }
    @isTest
    public static void testUserKPILeaderBoardCalcBatch(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_UserKPILeaderBoardCalcBatch'
                                                  AND Country_Code__c='GB' LIMIT 1];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
}