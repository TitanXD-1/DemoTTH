/**********************************************************************
Name: EDGE_TerritoryHistoricMonthlyBatchTest
=======================================================================
Req: Test class of EDGE_TerritoryHistoricMonthlyBatch
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR             DATE      DETAIL
1.0      Sagar Barman      07/02/2020   Initial Development        
***********************************************************************/
@istest
public class EDGE_TerritoryHistoricMonthlyBatchTest {
    @isTest
    public static void territoryHistoricMonthlyBatchTest(){
         Test.startTest(); 
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryHistoricMonthlyBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null);
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
    public static void createData(){  
       Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        List<KPI_Achivement__c> kpiAchList = new List<KPI_Achivement__c>();
        String territoryKPIRecId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Territory_KPI').getRecordTypeId();
        String monthlyRecTypeId = Territory_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Territory_KPIs').getRecordTypeId();
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Status__c = 'Active';
        terr.Country__c = countryId;
        insert terr;
        
		KPI_Achivement__c kpiAchObj = kpiAchrec('MAS', countryId , territoryKPIRecId ,terr.id );
        kpiAchList.add(kpiAchObj);
        
        KPI_Achivement__c kpiAchObj1 = kpiAchrec('MPA', countryId , territoryKPIRecId ,terr.id );        
        kpiAchList.add(kpiAchObj1);
        
        KPI_Achivement__c kpiAchObj2 =  kpiAchrec('NPD', countryId , territoryKPIRecId ,terr.id );        
        kpiAchList.add(kpiAchObj2);
        insert kpiAchList;
        
        Territory_Historic__c terHisRecord = new Territory_Historic__c();
        terHisRecord.Territory_Name__c = terr.Id;
        terHisRecord.RecordTypeId = monthlyRecTypeId;
        terHisRecord.Date_Of_Execution__c = system.today();
        insert terHisRecord;
        
    }
    public static KPI_Achivement__c kpiAchrec(String type, id countryId , id RecordTypeId , Id territory ){
       KPI_Achivement__c kpiAchObj =  new KPI_Achivement__c(); 
        kpiAchObj.RecordTypeId = RecordTypeId;
        kpiAchObj.Country__c = countryId;
        kpiAchObj.Territory__c =territory;
        kpiAchObj.KPI_Type__c = type;
        kpiAchObj.Current_National_Ranking__c = 5;
        kpiAchObj.Achievement__c = 25;
       return  kpiAchObj;
    }
    
    
}