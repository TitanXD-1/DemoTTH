/**********************************************************************
Name: EDGE_OpportunityGenerationBatchTest
=======================================================================
Req: 
User Story : ES20-6532
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Manikant p       1st Jan 2020     Test class to cover EDGE_OpportunityGenerationBatch 
2.0     Prasanth T       23rd Sep 2022    Test class correction due to Failure(ES20-13324)
***********************************************************************/
/** 
* @description  Test class for EDGE_OpportunityGenerationBatch
**/

@isTest
public class EDGE_OpportunityGenerationBatchTest {
    /** 
* @description  Validate the opportunity template for Trax type opportunity
**/
    @isTest
    public static void testOpportunityGenerationBatch(){
        
        //Test.startTest();  
        createData(); 
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OpportunityGenerationBatch'
                                                  AND Country_Code__c = 'AU' LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'batch Setting should not be null');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        //Test.stopTest(); 
        Opportunity_Template__c oppTemp = [SELECT Id  FROM Opportunity_Template__c LIMIT 1];
        system.assert(oppTemp.id != null,'opp Temp id should not be null');
        
    }
     /** 
* @description  Create Data
**/
    public static void createData(){
        //String pickupRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        System.debug(LoggingLevel.Debug,'Condition 1 '+Limits.getQueries());
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        System.debug(LoggingLevel.Debug,'Condition 2 '+Limits.getQueries());
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier;
        System.debug(LoggingLevel.Debug,'Condition 3 '+Limits.getQueries());
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Region__c = terriHier.id;
        insert primaryTerr;
        System.debug(LoggingLevel.Debug,'Condition 4 '+Limits.getQueries());
        
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        System.debug(LoggingLevel.Debug,'Condition 5 '+Limits.getQueries());
        
        system.assert(prodObj.id != null,'prod Object Id should not be null');
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = 'Nightclub';
        oppTemp1.Sub_Segment__c = 'Modern Nightclub';
        oppTemp1.Territory__c = primaryTerr.Id;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        insert oppTemp1;
        System.debug(LoggingLevel.Debug,'Condition 6 '+Limits.getQueries());
        
        Pick_Up_Options__c pick = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pick.Name = 'Gold [AU]';
        insert pick;
        System.debug(LoggingLevel.Debug,'Condition 7 '+Limits.getQueries());
        test.startTest();
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Outlet_Visit_Prioritisation_Grade__c = pick.Id;
        acc.Primary_Sales_Territory__c = primaryTerr.Id;
        insert acc;
        System.debug(LoggingLevel.Debug,'Condition 8 '+Limits.getQueries());
        
        Outlet_Territory__c outTerr = EDGE_UtilityTestClass.getOutltTerritory(acc.id,primaryTerr.Id); 
        insert outTerr;
        System.debug(LoggingLevel.Debug,'Condition 9 '+Limits.getQueries());
        
        Outlet_Execution__c outEx = EDGE_UtilityTestClass.getOutletExecution(acc.Id);
        outEx.Product__c = prodObj.Id;
        outEx.MAS__c = 'No';
        insert outEx;
        System.debug(LoggingLevel.Debug,'Condition 10 '+Limits.getQueries());
        test.stopTest();
    }
    
}