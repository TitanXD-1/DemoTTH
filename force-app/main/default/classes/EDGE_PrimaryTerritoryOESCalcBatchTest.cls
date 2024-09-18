/**********************************************************************
Name: EDGE_PrimaryTerritoryOESCalcBatchTest
=======================================================================
Req: This is the test class for EDGE_PrimaryTerritoryOESCalcBatch
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0   Dipanjan Das     21/05/2019      Initial Development
***********************************************************************/
/* Commented as part of User Story ES20-6590*/
@isTest
public class EDGE_PrimaryTerritoryOESCalcBatchTest
{
    @isTest 
    public static void testoesCalc()
    {
        EDGE_PrimaryTerritoryOESCalcBatch newcls = new EDGE_PrimaryTerritoryOESCalcBatch();
        system.assert(newcls!=null);
    }
    /* @isTest 
public static void testoesCalc()
{
Test.startTest(); 

createData();

Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_PrimaryTerritoryOESCalcBatch'
and Country_Code__c ='AU' LIMIT 1];
String className = batchSetting.Batch_Class__c;
Type t = Type.forName(className);
BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
job.getBatchDetails(batchSetting);
Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
List<Territory__c> territoryLst = [SELECT id FROM Territory__c LIMIT 1];
system.assertEquals(territoryLst.size(), 1);
Test.stopTest();         

}


public static void createData()
{    

Id countryId = EDGE_UtilityTestClass.setupCountry('AU');

User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
salesManager.Available_Countries__c = 'AU';
insert salesManager;  
System.assert(salesManager.Id!=null);

User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
salesRep.Available_Countries__c = 'AU';
salesRep.ManagerId = salesManager.id;
insert salesRep; 
System.assert(salesRep.Id!=null);

EDGE_UtilityTestClass.createOrgSettings();
List<Territory__c> terrlst = new List<Territory__c>();
Set<Id> territoryIdSet = new Set<Id>();


Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
insert terriHierBU;

Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
terriHierSA.Parent_BU__c = terriHierBU.Id;
insert terriHierSA;

Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
terriHier.Parent_BU__c = terriHierSA.Id;
insert terriHier;

Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
territory.Current_OES_Rank__c= 12.0;
territory.Country__c = countryId;
territory.Current_OES_Score__c = 10.0;
territory.Current_OES_Rank__c = 11.0;
territory.Territory_Type__c = 'Sales';      
territory.Status__c = 'Active';
territory.Region__c = terriHier.Id;
territoryIdSet.add(territory.id);
terrlst.add(territory);

Territory__c  territory1 = EDGE_UtilityTestClass.getTerritoryRec();
territory1.Current_OES_Rank__c= 14.0;
territory1.Country__c = countryId;
territory1.Current_OES_Score__c = 15.0;
territory1.Current_OES_Rank__c = 19.0;
territory1.Status__c = 'Active';
territory1.Territory_Type__c = 'Sales';
territory1.Region__c = terriHier.Id;
terrlst.add(territory1);
insert terrlst;

// Market_Setting__c msc = EDGE_UtilityTestClass.getMarketSetting(countryId);
//  insert msc ;

Account acc = EDGE_UtilityTestClass.getOwnerOperatorAccount();
acc.Primary_Sales_Territory__c = territory.Id;
acc.Minimum_Activation_Standards__c = 100;
acc.Minimum_Product_Assortment__c = 100;
acc.Person_Responsible__c = salesRep.id;
insert acc;

Account acc1 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
acc1.Primary_Sales_Territory__c = territory.Id;
acc1.Minimum_Activation_Standards__c = 100;
acc1.Minimum_Product_Assortment__c = 100;
acc1.Person_Responsible__c = salesRep.id;
insert acc1;        
}*/
}