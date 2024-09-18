/*
 * Name: EDGE_ComplianceMetricResetBatchTest
 * Req: This is the test class for EDGE_ComplianceMetricResetBatchTest
 * History                                                            
 * VERSION       AUTHOR                  DATE              DETAIL
 * 1.0           Anuja Chattopadhyay     31/10/2019      Initial Development
*/
@isTest
public class EDGE_ComplianceMetricResetBatchTest {
    public static void createData(){
        
        
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.A_P_Threshold__c = 100;
        market.Language__c = 'en_US';
        insert market;
        
        User testSalesMgr = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Sales Manager');    
        insert testSalesMgr;
        
        EDGE_UtilityTestClass.createOrgSettings();
        System.debug(LoggingLevel.Debug,'1.1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        Test.startTest();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
                
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        marc.Start_Date__c= System.today();
        insert marc;
        
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        insert terrHierBsUnitobj; 
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj;
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj1 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj1.Parent_BU__c=terrHierSalAreaobj.Id;
        insert terrHierRegionobj1;
        
        
        Territory_Hierarchy_member__c terrHierMem = new Territory_Hierarchy_member__c();
        terrHierMem.Territory_Hierarchy__c = terrHierRegionobj1.Id;
        // Handling the lookup filter for user on Territory Hierarchy Member
        terrHierMem.User__c= testSalesMgr.Id;
        //terrHierMem.User__c= testMDMUser.Id;
        terrHierMem.Start_Date__c = Date.today().addDays(2);
        terrHierMem.End_Date__c = Date.today().addDays(10);
        insert terrHierMem;
        
        Territory__c territoryObj1=EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj1.Territory_Type__c ='Sales';
        territoryObj1.Region__c = terrHierRegionobj1.Id;
        territoryObj1.Country__c	= countryId;
        insert territoryObj1;
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Country__c = countryId;
        outlet.BillingState = 'Tasmania';
        outlet.Primary_Sales_Territory_Region__c=terrHierRegionobj1.id; 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Primary_Sales_Area__c = terrHierSalAreaobj.id;
        outlet.Primary_Sales_Territory__c = territoryObj1.id;
        insert outlet;
        Test.stopTest();
        system.assert(outlet.Id != null,'outlet should not be null');
        
        Call__c objCall = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        objCall.Status__c = 'Planned';
        objCall.Plan_Start_Date__c = System.today();
        objCall.Plan_End_Date__c = System.today().addDays(1);
        insert objCall;
        System.debug(LoggingLevel.Debug,'1.2.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        KPI_Achivement__c achiRec = new KPI_Achivement__c();
        achiRec.Territory__c = territoryObj1.id;
        achiRec.Area__c = terrHierSalAreaobj.id;
        achiRec.Region__c = terrHierRegionobj1.id;
        achiRec.Country__c = countryId;
        achiRec.Achievement__c = 15;
        achiRec.Total_Denominator__c = 10;
        //achiRec.Activation_Type__c = 'MPA';
        
        insert achiRec;
        
    }
    @isTest
    public static void testRepDeleteBatch(){
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_ComplianceMetricResetBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null,'batchSettings should not be null');
        
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));              
        
    }      
}