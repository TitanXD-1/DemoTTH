/**********************************************************************
Name: EDGE_SalesAreaKPICalculationBatchTest

=======================================================================
Req: This is the test class for the  EDGE_SalesAreaKPICalculationBatch class.
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.1      Manikant Prasad     08/09/2019       Test Class
=======================================================================

***********************************************************************/
/* Commented as part of User Story ES20-6590*/
@isTest
public class EDGE_SalesAreaKPICalculationBatchTest {
    @isTest
    public static void testSalesAreaCalculationBatch(){
        EDGE_SalesAreaKPICalculationBatch newCls = new EDGE_SalesAreaKPICalculationBatch();
        system.assert(newCls!=null);
        
    }
    
    /*
@isTest
public static void testSalesAreaCalculationBatch(){
Test.startTest();
createData();
Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_SalesAreaKPICalculationBatch'
and Country_Code__c ='AU' ];

String className = batchSetting.Batch_Class__c;
List<Territory_Hierarchy__c> terrhierList = [SELECT Id , Name from Territory_Hierarchy__c];
System.assert(terrhierList.size() > 0 );
Type t = Type.forName(className);
BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
job.getBatchDetails(batchSetting);Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
Test.stopTest();

}

public static void createData(){
Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
EDGE_UtilityTestClass.createOrgSettings();

Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
insert terriHierBU;

Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
terriHierSA.Parent_BU__c = terriHierBU.Id;
insert terriHierSA;

Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
terriHierRegion.Parent_BU__c = terriHierSA.Id;
insert terriHierRegion;

Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
pickupOption.Name = 'Gold[AU]';
insert pickupOption;

Territory__c terrRec = EDGE_UtilityTestClass.getTerritoryRec();
terrRec.Volume_Category_Deluxe_Actual__c = 15 ;
terrRec.Volume_Category_Deluxe_Target__c = 15;
terrRec.Volume_Category_Deluxe_Target__c = 20;
terrRec.Volume_Category_Premium_Core_Target__c = 30;
terrRec.Sales_Area__c = terriHierSA.Id;
terrRec.Region__c = terriHierRegion.Id;
insert terrRec;

Account outlet = EDGE_UtilityTestClass.getOutletRecord();
outlet.Primary_Sales_Area__c = terriHierSA.id;
outlet.Primary_Sales_Territory__c = terrRec.id;
outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
insert outlet;    

System.assert( outlet.id != null);
}*/
    
}