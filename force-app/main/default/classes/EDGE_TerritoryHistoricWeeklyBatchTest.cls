/**********************************************************************
Name:EDGE_TerritoryHistoricWeeklyBatchTest
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                   DATE              DETAIL
1.0                             04/02/2020        Test class to cover EDGE_TerritoryHistoricWeeklyBatch class.   
***********************************************************************/

@isTest
public class EDGE_TerritoryHistoricWeeklyBatchTest {
    
    @isTest
    public static void testHistoricWeeklyBatch(){
        Test.startTest(); 
        
        createData();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TerritoryHistoricWeeklyBatch'
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
        String monthlyRecTypeId = Territory_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Weekly_KPIs').getRecordTypeId();
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Status__c = 'Active';
        terr.Country__c = countryId;
        insert terr;
        
        //Inserting User
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        salesManager.Calls_Per_Day__c = 15;
        insert salesManager; 
        
        //Inserting Account
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Primary_Sales_Territory__c = terr.Id;
        insert outlet;
        
        //Inserting KPI_Achivement__c type MAS
        KPI_Achivement__c kpiAchObj = kpiAchrec('MAS', countryId , territoryKPIRecId ,terr.id );
        kpiAchList.add(kpiAchObj);
        //Inserting KPI_Achivement__c type MPA
        KPI_Achivement__c kpiAchObj1 = kpiAchrec('MPA', countryId , territoryKPIRecId ,terr.id );
        kpiAchList.add(kpiAchObj1);
        //Inserting KPI_Achivement__c type NPD
        KPI_Achivement__c kpiAchObj2 =  kpiAchrec('NPD', countryId , territoryKPIRecId ,terr.id );
        kpiAchList.add(kpiAchObj2);
        //Inserting KPI_Achivement__c type OES
        KPI_Achivement__c kpiAchObj3 =  kpiAchrec('OES', countryId , territoryKPIRecId ,terr.id );
        kpiAchList.add(kpiAchObj3);
        //Inserting KPI_Achivement__c type Distribution
        KPI_Achivement__c kpiAchObj4 =  kpiAchrec('Distribution', countryId , territoryKPIRecId ,terr.id );
        kpiAchList.add(kpiAchObj4);
        insert kpiAchList;
        
        //Inserting Territory_Historic__c
        Territory_Historic__c terHisRecord = new Territory_Historic__c();
        terHisRecord.Territory_Name__c = terr.Id;
        terHisRecord.RecordTypeId = monthlyRecTypeId;
        terHisRecord.Date_Of_Execution__c = system.today().addDays(-7).toStartOfWeek();
        terHisRecord.National_MAS_Rank__c = 1;
        terHisRecord.National_MPA_Rank__c = 2;
        terHisRecord.National_OES_Rank__c = 3;
        insert terHisRecord;
        
        //Inserting Territory_Member__c
        Territory_Member__c terrMember = new Territory_Member__c();
        terrMember.Type__c = 'Primary';
        terrMember.User__c = salesManager.Id;
        terrMember.Territory__c = terr.Id;
        terrMember.Start_Date__c = system.today();
        terrMember.End_Date__c = system.today().addDays(5);
        insert terrMember;
        
        //Inserting Call__c
        Call__c callRecord = new Call__c();
        callRecord.Account__c = outlet.Id;
        callRecord.Status__c = 'Completed';
        callRecord.End_Date__c = system.today().addDays(-1);
        insert callRecord;
        
        //Inserting Opportunity
        Opportunity opp = EDGE_UtilityTestClass.getOpportunity(outlet.Id);
        opp.CloseDate = system.today().addDays(-7).toStartOfWeek();
        insert opp;
        
        
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